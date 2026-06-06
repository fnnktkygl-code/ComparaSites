import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/country.dart';

class ApiService {
  final Dio _dio = Dio();

  // A separate Dio instance for Zara — desktop user-agent, no mobile spoofing
  final Dio _zaraDio = Dio();

  // Cache for exchange rates (fallback defaults)
  final Map<String, double> _exchangeRates = {
    'PLN': 4.30, 'GBP': 0.85, 'RON': 4.97, 'HUF': 400.0, 'CZK': 25.3,
  };

  DateTime? _ratesLastFetched;

  ApiService() {
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.headers = {
      'User-Agent':
          'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
    };

    _zaraDio.options.connectTimeout = const Duration(seconds: 15);
    _zaraDio.options.receiveTimeout = const Duration(seconds: 15);
    _zaraDio.options.headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
      'Cache-Control': 'no-cache',
    };
  }

  // ─── Exchange Rates ────────────────────────────────────────────────────────

  Future<void> updateExchangeRates() async {
    if (_ratesLastFetched != null &&
        DateTime.now().difference(_ratesLastFetched!).inMinutes < 10) {
      return;
    }
    try {
      final response = await _dio.get('https://api.frankfurter.app/latest?from=EUR');
      if (response.statusCode == 200) {
        final data = response.data;
        Map<String, dynamic>? rates;
        if (data is String) {
          rates = (json.decode(data) as Map<String, dynamic>?)?['rates'] as Map<String, dynamic>?;
        } else if (data is Map) {
          rates = data['rates'] as Map<String, dynamic>?;
        }
        if (rates != null) {
          for (final entry in rates.entries) {
            if (entry.value is num) {
              _exchangeRates[entry.key] = (entry.value as num).toDouble();
            }
          }
          _ratesLastFetched = DateTime.now();
          debugPrint('[ApiService] Rates updated: ${_exchangeRates.keys.join(', ')}');
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Rate fetch failed (using defaults): $e');
    }
  }

  double getRate(String iso) => _exchangeRates[iso] ?? 1.0;

  // ─── Search URL builder (used for WebView navigation on mobile) ───────────

  String getSearchUrl(Country country, String brand, String id) {
    switch (brand) {
      case 'decathlon':
        return 'https://www.${country.decathlonDomain}/search?Ntt=$id';
      case 'zara':
        return 'https://www.zara.com/${country.zaraPath}/search?searchTerm=${Uri.encodeComponent(id)}';
      case 'jdsports':
        return 'https://www.${country.jdDomain}/search/${Uri.encodeComponent(id)}';
      case 'amazon':
        return 'https://www.${country.amazonDomain}/s?k=${Uri.encodeComponent(id)}';
      case 'ikea':
        return 'https://www.ikea.com/${country.ikeaPath}/search/?q=${Uri.encodeComponent(id)}';
      case 'sephora':
        return 'https://www.${country.sephoraDomain}/search?q=${Uri.encodeComponent(id)}';
      default:
        return '';
    }
  }

  // ─── Zara — Product page fetch + JSON-LD parsing ────────────────────────────
  //
  // Strategy:
  //  1. If we have the product slug (from URL extraction), build the exact product
  //     page URL per country. Zara reuses the same slug across all locales —
  //     only the locale prefix changes.
  //     e.g. /fr/fr/pantalon-lin-p05070902.html → /es/es/pantalon-lin-p05070902.html
  //  2. Fall back to search page.
  //  3. Fetch via allorigins.win (web) or direct HTTP (mobile).
  //  4. Parse JSON-LD structured data (<script type="application/ld+json">) or
  //     embedded state JSON for the price.

  Future<double?> fetchZaraPrice(
    Country country,
    String productId, {
    String? zaraSlug,
  }) async {
    // Build the target URL for this country
    final locale = country.zaraPath; // e.g. "fr/fr"

    final urls = <String>[];
    if (zaraSlug != null && zaraSlug.isNotEmpty) {
      // Primary: direct product page (most reliable — contains JSON-LD)
      urls.add('https://www.zara.com/$locale/$zaraSlug');
    }
    // Secondary: search results page
    urls.add('https://www.zara.com/$locale/search?searchTerm=${Uri.encodeComponent(productId)}');

    for (final targetUrl in urls) {
      final body = await _fetchWithProxy(targetUrl);
      if (body == null) continue;

      final price = _parseZaraPage(body, country.currency);
      if (price != null) {
        debugPrint('[ApiService] Zara ✓ ${country.name}: $price (from $targetUrl)');
        return price;
      }
      debugPrint('[ApiService] Zara - ${country.name}: no price in response from $targetUrl');
    }

    return null;
  }

  /// Fetch HTML/JSON from a URL.
  /// On web: wraps with allorigins.win CORS proxy (falls back to corsproxy.io).
  /// On mobile: direct HTTP request.
  Future<String?> _fetchWithProxy(String targetUrl) async {
    if (kIsWeb) {
      final proxies = [
        'https://api.scraperapi.com?api_key=ebf320e9726a57fe4d6e8a4397744922&url=${Uri.encodeComponent(targetUrl)}',
      ];

      for (final proxyUrl in proxies) {
        try {
          final resp = await _zaraDio.get(proxyUrl);
          if (resp.statusCode == 200) {
            final body = resp.data.toString();
            if (body.length > 500 && !_isBlocked(body)) {
              return body;
            }
          }
        } catch (e) {
          debugPrint('[ApiService] Proxy failed ($proxyUrl): $e');
        }
      }
      return null;
    } else {
      // Mobile: direct fetch
      try {
        final resp = await _zaraDio.get(targetUrl);
        if (resp.statusCode == 200) {
          final body = resp.data.toString();
          if (!_isBlocked(body)) return body;
        }
      } catch (e) {
        debugPrint('[ApiService] Direct fetch failed ($targetUrl): $e');
      }
      return null;
    }
  }

  /// Parse a Zara page (product page or search results) for a price.
  double? _parseZaraPage(String html, String currency) {
    if (html.isEmpty || html.length < 200) return null;

    // ── 1. JSON-LD structured data ──────────────────────────────────────────
    // Zara product pages include schema.org Product markup with price.
    // This is the most reliable source.
    final jsonLdRegex = RegExp(
      '<script[^>]+type=["\']application/ld\\+json["\'][^>]*>(.*?)</script>',
      dotAll: true,
      caseSensitive: false,
    );
    for (final match in jsonLdRegex.allMatches(html)) {
      try {
        final raw = match.group(1)!.trim();
        final data = json.decode(raw);
        final price = _extractPriceFromLdJson(data);
        if (price != null && price > 0.5 && price < 10000) {
          debugPrint('[ApiService] JSON-LD price: $price');
          return price;
        }
      } catch (_) {}
    }

    // ── 2. Embedded integer prices (Zara state JSON uses cents) ─────────────
    // Pattern: "price":3995  →  39.95 €
    // Only trust values that look like cents (4-6 digit integers, no decimals)
    final centPatterns = [
      RegExp(r'"price"\s*:\s*(\d{3,6})(?![.\d])'),
      RegExp(r'"salePrice"\s*:\s*(\d{3,6})(?![.\d])'),
      RegExp(r'"currentPrice"\s*:\s*(\d{3,6})(?![.\d])'),
      RegExp(r'"amount"\s*:\s*(\d{3,6})(?![.\d])'),
    ];

    final centCandidates = <double>[];
    for (final pattern in centPatterns) {
      for (final m in pattern.allMatches(html)) {
        final val = int.tryParse(m.group(1)!);
        // Cents: must be > 200 (2€) and < 99900 (999€), avoid page-size numbers
        if (val != null && val > 200 && val < 99900) {
          centCandidates.add(val / 100.0);
        }
      }
    }
    if (centCandidates.isNotEmpty) {
      centCandidates.sort();
      debugPrint('[ApiService] Cent-price candidates: $centCandidates');
      return centCandidates.first;
    }

    // ── 3. Standard decimal price strings in JSON/HTML ──────────────────────
    final decimalPatterns = [
      RegExp(r'"price"\s*:\s*"(\d{1,5}[.,]\d{2})"'),
      RegExp(r'"lowPrice"\s*:\s*"?(\d{1,5}[.,]\d{2})"?'),
      RegExp(r'"regularPrice"\s*:\s*"?(\d{1,5}[.,]\d{2})"?'),
    ];
    for (final pattern in decimalPatterns) {
      final m = pattern.firstMatch(html);
      if (m != null) {
        final val = double.tryParse(m.group(1)!.replaceAll(',', '.'));
        if (val != null && val > 0.5 && val < 10000) return val;
      }
    }

    // ── 4. Meta tag price ───────────────────────────────────────────────────
    final metaMatch = RegExp(
      '<meta[^>]+(?:property|name)=["\'](?:product:price:amount|og:price:amount)["\'][^>]+content=["\']([\\d.,]+)["\']',
      caseSensitive: false,
    ).firstMatch(html);
    if (metaMatch != null) {
      final val = double.tryParse(metaMatch.group(1)!.replaceAll(',', '.'));
      if (val != null && val > 0) return val;
    }

    // ── 5. General price regex fallback ─────────────────────────────────────
    return parsePriceFromHtml(html, currency: currency);
  }

  /// Recursively extract price from JSON-LD data.
  double? _extractPriceFromLdJson(dynamic data) {
    if (data is List) {
      for (final item in data) {
        final p = _extractPriceFromLdJson(item);
        if (p != null) return p;
      }
    }
    if (data is Map) {
      final type = data['@type'];
      if (type == 'Product' || type == 'Offer') {
        // Direct price field
        final rawPrice = data['price'];
        if (rawPrice is num && rawPrice > 0) return rawPrice.toDouble();
        if (rawPrice is String) {
          final val = double.tryParse(rawPrice.replaceAll(',', '.'));
          if (val != null && val > 0) return val;
        }
        // lowPrice / highPrice
        final lowPrice = data['lowPrice'];
        if (lowPrice is num && lowPrice > 0) return lowPrice.toDouble();
        if (lowPrice is String) {
          final val = double.tryParse(lowPrice.replaceAll(',', '.'));
          if (val != null && val > 0) return val;
        }
      }

      // Recurse into offers / nested objects
      for (final key in ['offers', 'makesOffer', 'priceSpecification']) {
        if (data.containsKey(key)) {
          final p = _extractPriceFromLdJson(data[key]);
          if (p != null) return p;
        }
      }

      // Recurse into any map/list values
      for (final val in data.values) {
        if (val is Map || val is List) {
          final p = _extractPriceFromLdJson(val);
          if (p != null) return p;
        }
      }
    }
    return null;
  }

  // ─── General HTTP fetch (non-Zara brands) ─────────────────────────────────

  Future<String?> fetchHtmlDirect(String targetUrl) async {
    if (kIsWeb) {
      final proxies = [
        'https://api.allorigins.win/raw?url=${Uri.encodeComponent(targetUrl)}',
        'https://corsproxy.io/?${Uri.encodeComponent(targetUrl)}',
        'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(targetUrl)}',
      ];

      for (final proxyUrl in proxies) {
        try {
          debugPrint('[ApiService] Direct fetch via proxy: $proxyUrl');
          final response = await _dio.get(proxyUrl);
          if (response.statusCode == 200) {
            final html = response.data.toString();
            if (html.length > 200 && !_isBlocked(html)) {
              debugPrint('[ApiService] Proxy success: $proxyUrl');
              return html;
            }
          }
        } catch (e) {
          debugPrint('[ApiService] Proxy failed ($proxyUrl): $e');
        }
      }
      return null;
    } else {
      // Mobile/Desktop: direct fetch
      try {
        final response = await _dio.get(targetUrl);
        if (response.statusCode == 200) {
          final html = response.data.toString();
          if (!_isBlocked(html)) {
            return html;
          }
        }
      } catch (e) {
        debugPrint('[ApiService] Direct fetch FAILED for $targetUrl: $e');
      }
      return null;
    }
  }

  bool _isBlocked(String html) {
    if (html.length < 200) return true;
    final lower = html.toLowerCase();
    return lower.contains('captcha') ||
        lower.contains('access denied') ||
        lower.contains('perimeterx') ||
        lower.contains('challenge-platform') ||
        lower.contains('blocked') ||
        lower.contains('robot');
  }

  Future<double?> fetchPrice(Country country, String brand, String id) async {
    // Zara always uses the dedicated page-fetch approach
    if (brand == 'zara') return null;

    final url = getSearchUrl(country, brand, id);
    try {
      final html = await fetchHtmlDirect(url);
      if (html == null) return null;
      return parsePriceFromHtml(html, currency: country.currency);
    } catch (e) {
      debugPrint('[ApiService] fetchPrice error: $e');
      return null;
    }
  }

  // ─── Price string parser ────────────────────────────────────────────────────

  double? parsePriceFromHtml(String rawInput, {String? currency}) {
    if (rawInput.isEmpty) return null;

    // Short input = direct price string from WebView JS extraction
    if (rawInput.length < 100) {
      var clean = rawInput.trim();
      debugPrint('[ApiService] Parsing short: "$clean" (currency: $currency)');

      if (currency == 'Ft' || currency == 'HUF') {
        clean = clean.replaceAll(RegExp(r'[^\d]'), '');
        return double.tryParse(clean);
      }
      if (currency == 'Kč' || currency == 'CZK') {
        clean = clean.replaceAll(RegExp(r'[^\d,.]'), '');
        if (RegExp(r'[,.]\d{3}$').hasMatch(clean)) {
          clean = clean.replaceAll(RegExp(r'[,.]'), '');
        } else if (clean.contains(',')) {
          clean = clean.replaceAll('.', '').replaceAll(',', '.');
        }
        return double.tryParse(clean);
      }

      clean = clean.replaceAll(RegExp(r'[^\d.,]'), '');
      if (clean.contains(',') && clean.contains('.')) {
        if (clean.lastIndexOf(',') > clean.lastIndexOf('.')) {
          clean = clean.replaceAll('.', '').replaceAll(',', '.');
        } else {
          clean = clean.replaceAll(',', '');
        }
      } else {
        clean = clean.replaceAll(',', '.');
      }
      return double.tryParse(clean);
    }

    // Full HTML: structured extraction
    final priceStr = _parsePrice(rawInput);
    if (priceStr != null) {
      if (currency == 'Ft' || currency == 'HUF') {
        return double.tryParse(priceStr.replaceAll(RegExp(r'[^\d]'), ''));
      }
      if (currency == 'Kč' || currency == 'CZK') {
        var s = priceStr.replaceAll(RegExp(r'[^\d,.]'), '');
        if (RegExp(r'[,.]\d{3}$').hasMatch(s)) {
          s = s.replaceAll(RegExp(r'[,.]'), '');
        } else if (s.contains(',')) {
          s = s.replaceAll('.', '').replaceAll(',', '.');
        }
        return double.tryParse(s);
      }
      return double.tryParse(priceStr);
    }
    return null;
  }

  String? _parsePrice(String html) {
    if (html.isEmpty) return null;
    final clean = html.replaceAll(RegExp(r'\s+'), ' ');

    // 1) Find all prices in JSON-LD to handle promos on search pages
    final jsonLdMatches = RegExp(r'"(?:lowPrice|price)"\s*:\s*"?(\d+(?:[.,]\d{1,2})?)"?').allMatches(clean);
    if (jsonLdMatches.isNotEmpty) {
      double? minPrice;
      for (final match in jsonLdMatches) {
        final priceStr = match.group(1)?.replaceAll(',', '.');
        if (priceStr != null) {
          final p = double.tryParse(priceStr);
          if (p != null && (minPrice == null || p < minPrice)) {
            minPrice = p;
          }
        }
      }
      if (minPrice != null) return minPrice.toString();
    }

    final meta = RegExp(
      r'meta property="product:price:amount" content="([\d.]+)"',
      caseSensitive: false,
    ).firstMatch(clean);
    if (meta != null) return meta.group(1);

    const currencySymbols = r'€|EUR|£|GBP|\$|zł|PLN|lei|RON|Ft|HUF|Kč|CZK';
    final regex = RegExp(
      '(?:($currencySymbols)\\s*(\\d{1,3}(?:[ .]?\\d{3})*(?:[.,]\\d{1,2})?))|(?:(\\d{1,3}(?:[ .]?\\d{3})*(?:[.,]\\d{1,2})?)\\s*($currencySymbols))',
      caseSensitive: false,
    );

    final prices = <double>[];
    for (final m in regex.allMatches(clean)) {
      var priceStr = (m.group(2) ?? m.group(3));
      if (priceStr != null) {
        priceStr = priceStr.replaceAll(' ', '').replaceAll(',', '.');
        final val = double.tryParse(priceStr);
        if (val != null && val > 0) prices.add(val);
      }
    }
    if (prices.isEmpty) return null;
    prices.sort();
    return prices.first.toStringAsFixed(2);
  }
}
