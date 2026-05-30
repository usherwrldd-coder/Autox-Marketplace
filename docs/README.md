# AUTOX Marketplace

> The world's premium auto parts exchange — escrow-protected, coin-powered.

[![Flutter](https://img.shields.io/badge/Flutter-3.19-blue?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-2.x-green?logo=supabase)](https://supabase.com)
[![PayPal](https://img.shields.io/badge/PayPal-Advanced-blue?logo=paypal)](https://developer.paypal.com)
[![License](https://img.shields.io/badge/License-Commercial-gold)](LICENSE)

---

## Tech Stack

| Layer      | Technology                              |
|------------|-----------------------------------------|
| Frontend   | Flutter Web (GoRouter + Riverpod)       |
| Backend    | Supabase (PostgreSQL + Edge Functions)  |
| Realtime   | Supabase Realtime Subscriptions         |
| Payments   | PayPal Advanced Checkout (wallet only)  |
| Storage    | Supabase Storage (S3-compatible)        |
| Hosting    | Vercel / Netlify / Firebase / Cloudflare|

---

## Project Structure

```
autox-marketplace/
├── flutter_app/              # Flutter Web application
│   ├── lib/
│   │   ├── core/             # Theme, router, constants, utils
│   │   ├── features/         # Feature-first modules (auth, wallet, etc.)
│   │   └── shared/           # Shared widgets and models
│   └── web/                  # HTML, manifest, robots, sitemap
├── supabase/
│   ├── migrations/           # 001-005 SQL migrations (run in order)
│   ├── functions/            # Deno Edge Functions
│   └── storage/              # Storage bucket setup
├── deployment/               # Vercel, Netlify, Firebase, Cloudflare configs
├── docs/                     # Documentation
└── .env.example              # Environment variable template
```

---

## Quick Start

### Prerequisites
- Flutter SDK >= 3.19 (`flutter --version`)
- Supabase CLI (`npm install -g supabase`)
- Node.js >= 18 (for Supabase CLI)

### 1. Clone & Set Up Flutter

```bash
git clone https://github.com/your-org/autox-marketplace
cd autox-marketplace/flutter_app
flutter pub get
cp ../.env.example .env
# Edit .env with your keys
```

### 2. Set Up Supabase

1. Create a new project at [supabase.com](https://supabase.com)
2. In your Supabase project → SQL Editor, run each migration **in order**:
   - `supabase/migrations/001_schema.sql`
   - `supabase/migrations/002_rls_policies.sql`
   - `supabase/migrations/003_functions.sql`
   - `supabase/migrations/004_triggers.sql`
   - `supabase/migrations/005_seed_data.sql`
   - `supabase/storage/buckets.sql`
3. Enable Realtime on these tables:
   - `messages`, `notifications`, `bids`, `products`, `orders`
4. Deploy Edge Functions:

```bash
cd supabase
supabase login
supabase link --project-ref your-project-ref
supabase functions deploy coin-topup
supabase functions deploy paypal-webhook
supabase functions deploy escrow-release
supabase functions deploy place-bid
supabase functions deploy send-notification
```

5. Set Edge Function secrets:

```bash
supabase secrets set PAYPAL_CLIENT_ID=your-client-id
supabase secrets set PAYPAL_SECRET=your-secret
supabase secrets set PAYPAL_MODE=sandbox
supabase secrets set PAYPAL_WEBHOOK_ID=your-webhook-id
```

### 3. Set Up PayPal

1. Go to [developer.paypal.com](https://developer.paypal.com)
2. Create a new App → copy Client ID & Secret
3. Enable **Advanced Credit and Debit Card Payments** in app settings
4. Under **Webhooks**, add a new webhook:
   - URL: `https://your-project.supabase.co/functions/v1/paypal-webhook`
   - Events: `PAYMENT.CAPTURE.COMPLETED`
5. Copy the Webhook ID to your secrets

### 4. Run Locally

```bash
cd flutter_app
flutter run -d chrome --dart-define=SUPABASE_URL=your-url --dart-define=SUPABASE_ANON_KEY=your-key
```

Or using `.env`:
```bash
flutter run -d chrome
```

---

## Deployment

### Vercel
```bash
flutter build web --release --web-renderer html
# Upload build/web/ to Vercel, or use vercel CLI:
vercel --prod
```

### Netlify
```bash
flutter build web --release --web-renderer html
netlify deploy --prod --dir=build/web
```

### Firebase Hosting
```bash
flutter build web --release --web-renderer html
firebase deploy --only hosting
```

### Cloudflare Pages
```bash
flutter build web --release --web-renderer html
# Push to GitHub and connect repo in Cloudflare Pages dashboard
# Build command: flutter build web --release --web-renderer html
# Output: build/web
```

---

## User Roles

| Role       | Capabilities                                                                 |
|------------|------------------------------------------------------------------------------|
| Buyer      | Browse, buy, bid, make offers, wallet, orders, chat, wishlist               |
| Vendor     | All buyer + product management, escrow earnings, payouts, analytics         |
| Moderator  | Review listings, handle disputes, KYC review                                |
| Admin      | Full access — coin controls, user management, all settings                  |

---

## Coin System Flow

```
User ──► PayPal Checkout ──► PayPal Webhook ──► Coins Added to Wallet
  │
  ├──► Buy Product ──► Coins Deducted ──► Held in Escrow
  │                                              │
  │                                    Vendor ships item
  │                                              │
  └──► Confirm Delivery ──► Escrow Released ──► Vendor Wallet
```

**Important:** PayPal processes payments for virtual coin top-ups only. All marketplace transactions use AUTOX Coins exclusively.

---

## Security Architecture

- **RLS**: Every table has Row Level Security enforced
- **Edge Functions**: All wallet mutations run server-side only
- **Webhook Verification**: PayPal signatures verified on every webhook
- **Escrow**: Coins held by platform until buyer confirms delivery
- **No direct writes**: Clients cannot write to `wallets` or `transactions` directly

---

## Database Tables (28 total)

`profiles` · `addresses` · `vendor_profiles` · `categories` · `products` · `product_images` · `product_reviews` · `shipping_options` · `wallets` · `transactions` · `coin_settings` · `orders` · `escrow_entries` · `refund_requests` · `offers` · `bids` · `conversations` · `messages` · `notifications` · `wishlists` · `saved_searches` · `disputes` · `payouts` · `blog_posts` · `cms_pages` · `marketplace_settings` · `featured_listings`

---

## Edge Functions (5 total)

| Function           | Trigger              | Purpose                          |
|--------------------|----------------------|----------------------------------|
| `coin-topup`       | Client call          | Create PayPal order for top-up   |
| `paypal-webhook`   | PayPal POST          | Credit coins on payment success  |
| `escrow-release`   | Client call          | Confirm delivery & release escrow|
| `place-bid`        | Client call          | Validate & place auction bid     |
| `send-notification`| Internal             | Push notification to user        |

---

## Support

- Docs: `/docs/`
- Issues: GitHub Issues
- Security: security@autoxmarketplace.com
