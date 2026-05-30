import { serve }        from "https://deno.land/std@0.192.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin":  "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const authHeader = req.headers.get("Authorization")!;
  const { data: { user }, error: authError } = await supabase.auth.getUser(
    authHeader.replace("Bearer ", "")
  );
  if (authError || !user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401, headers: corsHeaders });
  }

  const { order_id } = await req.json();

  // Verify buyer owns the order and it's in shipped state
  const { data: order, error: orderErr } = await supabase
    .from("orders")
    .select("*, escrow_entries(*)")
    .eq("id", order_id)
    .single();

  if (orderErr || !order) {
    return new Response(JSON.stringify({ error: "Order not found" }), { status: 404, headers: corsHeaders });
  }
  if (order.buyer_id !== user.id) {
    return new Response(JSON.stringify({ error: "Forbidden" }), { status: 403, headers: corsHeaders });
  }
  if (order.status !== "shipped") {
    return new Response(
      JSON.stringify({ error: "Order must be in shipped state to confirm delivery" }),
      { status: 400, headers: corsHeaders }
    );
  }

  // Trigger release via status update (handled by DB trigger trg_release_escrow)
  const { error: updateErr } = await supabase
    .from("orders")
    .update({ status: "delivered" })
    .eq("id", order_id);

  if (updateErr) {
    return new Response(JSON.stringify({ error: updateErr.message }), { status: 500, headers: corsHeaders });
  }

  return new Response(
    JSON.stringify({ success: true, message: "Delivery confirmed and escrow released." }),
    { headers: { ...corsHeaders, "Content-Type": "application/json" } }
  );
});
