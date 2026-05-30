# Admin Setup Guide

## Creating the First Admin User

1. Register a normal account at `/register`
2. In Supabase Dashboard → Table Editor → `profiles`
3. Find your user by email, set `role` to `admin`
4. That user now has full admin access at `/admin`

## Admin Capabilities

| Feature              | Description                                         |
|----------------------|-----------------------------------------------------|
| User Management      | View, suspend, ban, verify users                    |
| Vendor Approvals     | Approve/reject vendor applications                  |
| Listing Moderation   | Approve, remove, feature listings                   |
| Escrow Manager       | View all escrow entries, manually release if needed |
| Refund Manager       | Approve or reject refund requests                   |
| Dispute Resolution   | Review and resolve buyer/vendor disputes            |
| KYC Verification     | Review submitted KYC documents                      |
| Coin Controls        | Set exchange rates, fees, limits                    |
| Revenue Dashboard    | View platform fees, payouts, analytics              |
| Fraud Monitor        | Review flagged transactions and accounts            |
| PayPal Settings      | Update PayPal Client ID, mode (sandbox/live)        |
| CMS Pages            | Edit Terms, Privacy, FAQ, About content             |
| Blog Management      | Create and publish SEO blog posts                   |
| Featured Listings    | Manage featured product slots                       |
| Push Notifications   | Send broadcast notifications to users               |
| Marketplace Settings | Global platform configuration                       |

## Moderator Role

Create a moderator by setting `role = 'moderator'` in `profiles`.
Moderators have access to:
- Listing moderation
- Dispute review
- KYC review
- Refund requests

Moderators cannot access:
- Coin controls
- PayPal settings
- Revenue data
- System settings

## Security Notes
- Admin routes are protected by RLS `is_admin()` function
- All admin actions are logged via Supabase audit logs
- Service role key is only used in Edge Functions — never in client code
- Admin panel should ideally be on a separate subdomain (admin.autoxmarketplace.com)
