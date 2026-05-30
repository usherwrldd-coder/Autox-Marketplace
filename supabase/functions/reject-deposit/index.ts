import { serve }        from "https://deno.land/std@0.192.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin":  "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Verify admin access
    const authHeader = req.headers.get("Authorization")!;
    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader.replace("Bearer ", "")
    );
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401, headers: corsHeaders });
    }

    // Check admin role
    const { data: profile } = await supabase
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .single();

    if (!profile || !["admin", "moderator"].includes(profile.role)) {
      return new Response(JSON.stringify({ error: "Admin access required" }), { status: 403, headers: corsHeaders });
    }

    const { deposit_id, reason } = await req.json();
    if (!deposit_id) {
      return new Response(JSON.stringify({ error: "Deposit ID required" }), { status: 400, headers: corsHeaders });
    }
    if (!reason || reason.trim().length === 0) {
      return new Response(JSON.stringify({ error: "Rejection reason is required" }), { status: 400, headers: corsHeaders });
    }

    // Get deposit record
    const { data: deposit, error: depositError } = await supabase
      .from("deposits")
      .select("*")
      .eq("id", deposit_id)
      .single();

    if (depositError || !deposit) {
      return new Response(JSON.stringify({ error: "Deposit not found" }), { status: 404, headers: corsHeaders });
    }

    if (deposit.status !== "pending") {
      return new Response(JSON.stringify({ error: "Deposit already processed" }), { status: 400, headers: corsHeaders });
    }

    // Update deposit status (wallet balance remains unchanged)
    const { error: updateError } = await supabase
      .from("deposits")
      .update({
        status: "rejected",
        reviewed_by: user.id,
        rejection_reason: reason.trim(),
        updated_at: new Date().toISOString(),
      })
      .eq("id", deposit_id);

    if (updateError) {
      return new Response(JSON.stringify({ error: "Failed to reject deposit" }), { status: 500, headers: corsHeaders });
    }

    // Notify user
    await supabase.from("notifications").insert({
      user_id: deposit.user_id,
      type: "system",
      title: "Deposit Rejected",
      body: `Your deposit of ${deposit.amount.toLocaleString()} AXC was rejected. Reason: ${reason.trim()}`,
      link: "/wallet",
    });

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: corsHeaders }
    );
  }
});