// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class SeoHelper {
  SeoHelper._();

  static void setMetaTitle(String title) {
    if (!kIsWeb) return;
    html.document.title = '$title | AUTOX Marketplace';
    _setMeta('og:title', title);
    _setMeta('twitter:title', title);
  }

  static void setMetaDescription(String description) {
    if (!kIsWeb) return;
    _setMeta('description', description);
    _setMeta('og:description', description);
    _setMeta('twitter:description', description);
  }

  static void setMetaImage(String imageUrl) {
    if (!kIsWeb) return;
    _setMeta('og:image', imageUrl);
    _setMeta('twitter:image', imageUrl);
  }

  static void setCanonicalUrl(String url) {
    if (!kIsWeb) return;
    var link = html.document.querySelector('link[rel="canonical"]');
    if (link == null) {
      link = html.LinkElement()..rel = 'canonical';
      html.document.head!.append(link);
    }
    (link as html.LinkElement).href = url;
  }

  static void setProductSchema({
    required String name,
    required String description,
    required double price,
    required String currency,
    required String image,
    required String sku,
    String? brand,
    String condition = 'NewCondition',
  }) {
    if (!kIsWeb) return;
    final schema = '''{
      "@context": "https://schema.org/",
      "@type": "Product",
      "name": "$name",
      "description": "$description",
      "image": "$image",
      "sku": "$sku",
      ${brand != null ? '"brand": {"@type": "Brand", "name": "$brand"},' : ''}
      "offers": {
        "@type": "Offer",
        "url": "${html.window.location.href}",
        "priceCurrency": "$currency",
        "price": "$price",
        "itemCondition": "https://schema.org/$condition",
        "availability": "https://schema.org/InStock"
      }
    }''';
    _setJsonLd('product-schema', schema);
  }

  static void _setMeta(String name, String content) {
    var meta = html.document.querySelector('meta[name="$name"]') ??
               html.document.querySelector('meta[property="$name"]');
    if (meta == null) {
      meta = html.MetaElement();
      if (name.startsWith('og:') || name.startsWith('twitter:')) {
        meta.setAttribute('property', name);
      } else {
        meta.setAttribute('name', name);
      }
      html.document.head!.append(meta);
    }
    meta.setAttribute('content', content);
  }

  static void _setJsonLd(String id, String schema) {
    var script = html.document.getElementById(id);
    if (script == null) {
      script = html.ScriptElement()
        ..id   = id
        ..type = 'application/ld+json';
      html.document.head!.append(script);
    }
    script.text = schema;
  }
}
