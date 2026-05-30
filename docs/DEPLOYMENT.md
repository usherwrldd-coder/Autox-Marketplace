# Deployment Guide

## Build for Production

```bash
cd flutter_app
flutter build web --release --web-renderer html
# Output: flutter_app/build/web/
```

## Vercel (Recommended)
```bash
npm install -g vercel
cd flutter_app
flutter build web --release --web-renderer html
cd build/web
vercel --prod
```
Or connect GitHub repo in Vercel dashboard:
- Build Command: `cd flutter_app && flutter build web --release --web-renderer html`
- Output Directory: `flutter_app/build/web`
- Install Command: `flutter pub get`

## Netlify
```bash
npm install -g netlify-cli
cd flutter_app
flutter build web --release --web-renderer html
netlify deploy --prod --dir=build/web
```
`netlify.toml` is pre-configured in `/deployment/`.

## Firebase Hosting
```bash
npm install -g firebase-tools
firebase login
firebase init hosting
# Public directory: flutter_app/build/web
# SPA: yes
cd flutter_app && flutter build web --release --web-renderer html
firebase deploy --only hosting
```

## Cloudflare Pages
1. Push repo to GitHub
2. Cloudflare Dashboard → Pages → Create project
3. Connect GitHub repo
4. Build settings:
   - Framework: None
   - Build command: `cd flutter_app && flutter build web --release --web-renderer html`
   - Output directory: `flutter_app/build/web`
5. Add environment variables in Cloudflare Pages settings

## Environment Variables
Set these in your hosting platform's environment settings:
```
SUPABASE_URL
SUPABASE_ANON_KEY
PAYPAL_CLIENT_ID
PAYPAL_MODE
```

## Custom Domain
1. Add your domain in hosting platform settings
2. Update DNS: CNAME record pointing to your hosting URL
3. Update Supabase Auth → Site URL to your domain
4. Update `sitemap.xml` and `robots.txt` with your domain
5. Update PayPal webhook URL to your domain

## Post-Deploy Checklist
- [ ] Supabase URL configured
- [ ] Supabase Anon Key configured
- [ ] PayPal Client ID configured
- [ ] PayPal Webhook pointing to correct Edge Function URL
- [ ] Supabase Edge Function secrets set
- [ ] Realtime enabled on required tables
- [ ] Storage buckets created
- [ ] Admin user created and role set to 'admin' in profiles table
- [ ] robots.txt domain updated
- [ ] sitemap.xml domain updated
- [ ] SSL certificate active
