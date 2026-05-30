# Supabase Setup Guide

## 1. Create Project
1. Go to [supabase.com](https://supabase.com) → New Project
2. Choose a region close to your users
3. Set a strong database password and save it

## 2. Run Migrations
In Supabase Dashboard → SQL Editor, run each file in order:
```
001_schema.sql       ← All 28 tables, enums, indexes
002_rls_policies.sql ← Row Level Security on every table
003_functions.sql    ← Stored functions (search, stats, analytics)
004_triggers.sql     ← Auto-wallet, escrow, bid, search vector triggers
005_seed_data.sql    ← Categories, CMS pages, default settings
storage/buckets.sql  ← Storage buckets + policies
```

## 3. Enable Realtime
Dashboard → Database → Replication → enable for:
- `messages` (chat)
- `notifications`
- `bids` (live auction)
- `orders` (order status)
- `products` (stock updates)

## 4. Auth Settings
Dashboard → Authentication → Providers:
- Email: ✅ Enable, set "Confirm email" to true
- Google: Add OAuth credentials
- Apple: Add Sign In with Apple credentials

Dashboard → Authentication → URL Configuration:
- Site URL: `https://autoxmarketplace.com`
- Redirect URLs: `https://autoxmarketplace.com/**`

## 5. Get Your Keys
Dashboard → Settings → API:
- Copy `Project URL` → `SUPABASE_URL`
- Copy `anon public` key → `SUPABASE_ANON_KEY`
- Copy `service_role` key → `SUPABASE_SERVICE_ROLE_KEY` (keep secret!)

## 6. Deploy Edge Functions
```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase functions deploy coin-topup
supabase functions deploy paypal-webhook
supabase functions deploy escrow-release
supabase functions deploy place-bid
supabase functions deploy send-notification

supabase secrets set PAYPAL_CLIENT_ID=xxx
supabase secrets set PAYPAL_SECRET=xxx
supabase secrets set PAYPAL_MODE=sandbox
supabase secrets set PAYPAL_WEBHOOK_ID=xxx
```
