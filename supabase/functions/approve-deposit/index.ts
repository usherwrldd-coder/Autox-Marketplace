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

    const { deposit_id } = await req.json();
    if (!deposit_id) {
      return new Response(JSON.stringify({ error: "Deposit ID required" }), { status: 400, headers: corsHeaders });
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

    // Get current wallet balance
    const { data: wallet } = await supabase
      .from("wallets")
      .select("balance, lifetime_topup")
      .eq("user_id", deposit.user_id)
      .single();

    const balanceBefore = wallet?.balance ?? 0;
    const newBalance = balanceBefore + deposit.amount;

    // Update deposit status
    const { error: updateError } = await supabase
      .from("deposits")
      .update({
        status: "approved",
        reviewed_by: user.id,
        wallet_balance_before: balanceBefore,
        wallet_balance_after: newBalance,
        updated_at: new Date().toISOString(),
      })
      .eq("id", deposit_id);

    if (updateError) {
      return new Response(JSON.stringify({ error: "Failed to update deposit" }), { status: 500, headers: corsHeaders });
    }

    // Credit wallet
    const { error: walletError } = await supabase
      .from("wallets")
      .update({
        balance: newBalance,
        lifetime_topup: (wallet?.lifetime_topup ?? 0) + deposit.amount,
        updated_at: new Date().toISOString(),
      })
      .eq("user_id", deposit.user_id);

    if (walletError) {
      // Rollback deposit status
      await supabase
        .from("deposits")
        .update({ status: "pending", wallet_balance_before: 0, wallet_balance_after: null })
        .eq("id", deposit_id);
      return new Response(JSON.stringify({ error: "Failed to credit wallet" }), { status: 500, headers: corsHeaders });
    }

    // Record transaction
    const { error: txError } = await supabase
      .from("transactions")
      .insert({
        user_id: deposit.user_id,
        type: "topup",
        amount: deposit.amount,
        balance_before: balanceBefore,
        balance_after: newBalance,
        description: `Bank Deposit — Ref: ${deposit.reference_number}`,
        reference_id: deposit.id,
        reference_type: "deposit",
        metadata: { method: "bank_transfer", reference_number: deposit.reference_number },
      });

    if (txError) {
      console.error("Transaction recording failed:", txError);
      // Don't rollback — wallet already credited
    }

    // Notify user
    await supabase.from("notifications").insert({
      user_id: deposit.user_id,
      type: "system",
      title: "Deposit Approved! 🪙",
      body: `Your deposit of ${deposit.amount.toLocaleString()} AXC has been credited to your wallet.`,
      link: "/wallet",
    });

    return new Response(
      JSON.stringify({ success: true, new_balance: newBalance }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: corsHeaders }
    );
  }
});