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

  const { product_id, bid_amount, auto_bid_max } = await req.json();

  // Validate product is an active auction
  const { data: product } = await supabase
    .from("products")
    .select("*")
    .eq("id", product_id)
    .eq("is_auction", true)
    .eq("is_active", true)
    .single();

  if (!product) {
    return new Response(JSON.stringify({ error: "Auction not found or inactive" }), { status: 404, headers: corsHeaders });
  }
  if (new Date(product.auction_end) < new Date()) {
    return new Response(JSON.stringify({ error: "Auction has ended" }), { status: 400, headers: corsHeaders });
  }
  if (bid_amount <= (product.current_bid ?? product.price_coins)) {
    return new Response(
      JSON.stringify({ error: `Bid must be higher than current bid of ${product.current_bid ?? product.price_coins} AXC` }),
      { status: 400, headers: corsHeaders }
    );
  }

  // Check wallet balance
  const { data: wallet } = await supabase
    .from("wallets")
    .select("balance")
    .eq("user_id", user.id)
    .single();

  if (!wallet || wallet.balance < bid_amount) {
    return new Response(JSON.stringify({ error: "Insufficient coin balance" }), { status: 400, headers: corsHeaders });
  }

  // Place bid (trigger handles winning state update)
  const { data: bid, error: bidErr } = await supabase
    .from("bids")
    .insert({ product_id, bidder_id: user.id, bid_amount, auto_bid_max })
    .select()
    .single();

  if (bidErr) {
    return new Response(JSON.stringify({ error: bidErr.message }), { status: 500, headers: corsHeaders });
  }

  return new Response(
    JSON.stringify({ success: true, bid }),
    { headers: { ...corsHeaders, "Content-Type": "application/json" } }
  );
});
