# AUTOX Marketplace

> The world's premium auto parts exchange — escrow-protected, coin-powered.

## Quick Start

```bash
# 1. Set up environment
cp .env.example flutter_app/.env
# Fill in SUPABASE_URL, SUPABASE_ANON_KEY, PAYPAL_CLIENT_ID

# 2. Install Flutter dependencies
cd flutter_app && flutter pub get

# 3. Run Supabase migrations (in Supabase SQL Editor, in order)
# supabase/migrations/001_schema.sql
# supabase/migrations/002_rls_policies.sql
# supabase/migrations/003_functions.sql
# supabase/migrations/004_triggers.sql
# supabase/migrations/005_seed_data.sql
# supabase/storage/buckets.sql

# 4. Deploy Edge Functions
# cd supabase && supabase functions deploy coin-topup
# supabase functions deploy paypal-webhook
# supabase functions deploy escrow-release
# supabase functions deploy place-bid
# supabase functions deploy send-notification

# 5. Run locally
cd flutter_app && flutter run -d chrome

# 6. Build for production
flutter build web --release --web-renderer html
```

## Full Documentation
See `/docs/` folder:
- README.md         — Full setup guide
- DEPLOYMENT.md     — Hosting on Vercel/Netlify/Firebase/Cloudflare
- SUPABASE_SETUP.md — Supabase configuration
- PAYPAL_SETUP.md   — PayPal Developer setup
- SEO_GUIDE.md      — SEO optimization guide
- ADMIN_SETUP.md    — Admin panel setup

## Interactive Mockup
Open `autox-marketplace-mockup.jsx` in any React environment or
paste into claude.ai to see the live interactive UI demo.
