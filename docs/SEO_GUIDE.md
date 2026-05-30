# SEO Guide — AUTOX Marketplace

## Flutter Web SEO Strategy

Flutter Web renders via JavaScript (CanvasKit or HTML renderer). To maximize SEO:

### 1. Use HTML Renderer (Recommended for SEO)
```bash
flutter build web --release --web-renderer html
```
HTML renderer produces DOM elements that crawlers can read.

### 2. Dynamic Meta Tags
Use `SeoHelper` utility to update meta tags per page:
```dart
// In each page's initState or build:
SeoHelper.setMetaTitle('Brembo GT Brake Kit — AUTOX Marketplace');
SeoHelper.setMetaDescription('Buy the Brembo GT 6-Piston brake kit...');
SeoHelper.setCanonicalUrl('https://autoxmarketplace.com/product/brembo-gt-brake-kit');
```

### 3. Structured Data (Schema.org)
Product pages use `SeoHelper.setProductSchema()`:
```dart
SeoHelper.setProductSchema(
  name: product.title,
  description: product.description ?? '',
  price: product.priceCoins.toDouble(),
  currency: 'USD',
  image: product.images.first,
  sku: product.sku ?? '',
  brand: product.brand,
);
```

### 4. Static Pages for SEO
Create pre-rendered HTML pages for:
- Homepage (`/`)
- Category pages (`/marketplace?category=brakes`)
- Blog posts (`/blog/slug`)
- FAQ (`/faq`)
- About (`/about`)

### 5. Sitemap Generation
The static `sitemap.xml` covers key routes.
For dynamic product/vendor URLs, generate sitemap via Edge Function:
```sql
-- Get all approved product slugs
SELECT slug, updated_at FROM products WHERE is_approved = TRUE AND is_active = TRUE;
```

### 6. robots.txt
Pre-configured to allow public pages and block private routes.

### 7. Page Speed Optimizations
- Use `--web-renderer html` (smaller bundle)
- Enable gzip/brotli on hosting
- Use `cached_network_image` for images
- Lazy load images below the fold
- Preconnect to Supabase and Google Fonts

### 8. Open Graph for Social Sharing
Every product page updates OG tags dynamically:
```dart
SeoHelper.setMetaImage(product.images.first);
```

### 9. Blog System for Backlinks
Create blog posts targeting keywords:
- "Best brake pads for BMW M3"
- "How to choose aftermarket suspension"
- "JDM parts buying guide"

Blog posts live in the `blog_posts` table and render at `/blog/[slug]`.

### 10. Google Search Console
After deployment:
1. Verify domain at search.google.com/search-console
2. Submit sitemap: `https://autoxmarketplace.com/sitemap.xml`
3. Monitor Core Web Vitals
4. Use URL Inspection tool to force indexing of key pages
