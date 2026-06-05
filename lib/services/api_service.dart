import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/country.dart';

class ApiService {
  final Dio _dio = Dio();
  
  // Cache for exchange rates (fallback defaults)
  final Map<String, double> _exchangeRates = {
    'PLN': 4.30, 'GBP': 0.85, 'RON': 4.97, 'HUF': 400.0, 'CZK': 25.3,
  };

  /// Timestamp of last successful exchange rate fetch (for TTL caching).
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
  }

  Future<void> updateExchangeRates() async {
    // Skip if rates were fetched less than 10 minutes ago
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
          final Map<String, dynamic> jsonMap = json.decode(data);
          rates = jsonMap['rates'] as Map<String, dynamic>?;
        } else if (data is Map) {
          rates = data['rates'] as Map<String, dynamic>?;
        }

        if (rates != null) {
          for (final entry in rates.entries) {
            final val = entry.value;
            if (val is num) {
              _exchangeRates[entry.key] = val.toDouble();
            }
          }
          debugPrint('[ApiService] Exchange rates updated: ${_exchangeRates.keys.join(', ')}');
          _ratesLastFetched = DateTime.now();
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Exchange rate fetch failed (using defaults): $e');
    }
  }

  double getRate(String iso) => _exchangeRates[iso] ?? 1.0;

  String getSearchUrl(Country country, String brand, String id) {
    if (brand == 'decathlon') {
      return 'https://www.${country.decathlonDomain}/search?Ntt=$id';
    } else if (brand == 'zara') {
      return 'https://www.zara.com/${country.zaraPath}/search?searchTerm=${Uri.encodeComponent(id)}';
    } else if (brand == 'jdsports') {
      return 'https://www.${country.jdDomain}/search/${Uri.encodeComponent(id)}';
    } else if (brand == 'amazon') {
      return 'https://www.${country.amazonDomain}/s?k=${Uri.encodeComponent(id)}';
    } else if (brand == 'ikea') {
      return 'https://www.ikea.com/${country.ikeaPath}/search/?q=${Uri.encodeComponent(id)}';
    } else if (brand == 'sephora') {
      return 'https://www.${country.sephoraDomain}/search?q=${Uri.encodeComponent(id)}';
    } else {
      return '';
    }
  }

  /// Direct HTTP fetch with a single retry — used as a secondary fallback only.
  /// The primary extraction path is the WebView (JS injection).
  Future<String?> fetchHtmlDirect(String targetUrl) async {
    try {
      String url = targetUrl;
      if (kIsWeb) {
        url = 'https://corsproxy.io/?${Uri.encodeComponent(targetUrl)}';
      }
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        final html = response.data.toString();
        if (!_isBlocked(html)) {
          debugPrint('[ApiService] Direct fetch OK for $targetUrl (${html.length} chars)');
          return html;
        }
        debugPrint('[ApiService] Direct fetch BLOCKED for $targetUrl');
      }
    } catch (e) {
      debugPrint('[ApiService] Direct fetch FAILED for $targetUrl: $e');
    }
    return null;
  }

  bool _isBlocked(String html) {
    final lower = html.toLowerCase();
    // Only flag truly blocked responses — not short legitimate pages
    return lower.contains('captcha') || 
           lower.contains('access denied') || 
           lower.contains('perimeterx') ||
           lower.contains('challenge-platform') ||
           html.length < 200;
  }

  Future<double?> fetchPrice(Country country, String brand, String id) async {
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

  double? parsePriceFromHtml(String rawInput, {String? currency}) {
    if (rawInput.isEmpty) return null;
    
    // If the input is SHORT (< 100 chars), it's a direct price string from WebView JS
    if (rawInput.length < 100) {
       var clean = rawInput.trim();
       debugPrint('[ApiService] Parsing short price string: "$clean" (currency: $currency)');
       
       // HUF (Hungary): No decimals, dot/space are thousands separators
       // e.g. "12.990 Ft" or "12 990" → 12990
       if (currency == 'Ft' || currency == 'HUF') {
          clean = clean.replaceAll(RegExp(r'[^\d]'), '');
          return double.tryParse(clean);
       }
       
       // CZK (Czech): Uses space as thousands separator, comma for decimals
       // e.g. "1 299,00 Kč" → 1299.00
       if (currency == 'Kč' || currency == 'CZK') {
          clean = clean.replaceAll(RegExp(r'[^\d,.]'), ''); // Remove non-numeric except , and .
          // If the comma/dot is followed by exactly 3 digits, it's a thousands separator: remove it
          if (RegExp(r'[,.]\d{3}$').hasMatch(clean)) {
            clean = clean.replaceAll(RegExp(r'[,.]'), '');
          } else if (clean.contains(',')) {
            clean = clean.replaceAll('.', '').replaceAll(',', '.');
          }
          return double.tryParse(clean);
       }

       // Standard (EUR, PLN, GBP, RON, etc): Handle 12,99 or 12.99
       clean = clean.replaceAll(RegExp(r'[^\d.,]'), '');
       
       // Handle European format: 1.299,99 → 1299.99
       if (clean.contains(',') && clean.contains('.')) {
         // If comma comes after dot, comma is decimal: 1.299,99
         if (clean.lastIndexOf(',') > clean.lastIndexOf('.')) {
           clean = clean.replaceAll('.', '').replaceAll(',', '.');
         }
         // else dot is decimal: 1,299.99 — just remove commas
         else {
           clean = clean.replaceAll(',', '');
         }
       } else {
         clean = clean.replaceAll(',', '.');
       }
       
       final result = double.tryParse(clean);
       debugPrint('[ApiService] Parsed price: $result');
       return result;
    }

    // Full HTML fallback
    final priceStr = _parsePrice(rawInput);
    if (priceStr != null) {
      if (currency == 'Ft' || currency == 'HUF') {
         final hufClean = priceStr.replaceAll(RegExp(r'[^\d]'), '');
         return double.tryParse(hufClean);
      }
      if (currency == 'Kč' || currency == 'CZK') {
         var czkClean = priceStr.replaceAll(RegExp(r'[^\d,.]'), '');
         // If the comma/dot is followed by exactly 3 digits, it's a thousands separator: remove it
         if (RegExp(r'[,.]\d{3}$').hasMatch(czkClean)) {
           czkClean = czkClean.replaceAll(RegExp(r'[,.]'), '');
         } else if (czkClean.contains(',')) {
           czkClean = czkClean.replaceAll('.', '').replaceAll(',', '.');
         }
         return double.tryParse(czkClean);
      }
      return double.tryParse(priceStr);
    }
    return null;
  }

  String? _parsePrice(String html) {
    if (html.isEmpty) return null;
    final cleanHtml = html.replaceAll(RegExp(r'\s+'), ' ');

    // 1. JSON-LD (Most reliable for structured price data)
    final jsonLdMatch = RegExp(r'"price"\s*:\s*"?(\d+[.,]\d{1,2})"?').firstMatch(cleanHtml);
    if (jsonLdMatch != null) return jsonLdMatch.group(1)?.replaceAll(',', '.');

    // 2. lowPrice in JSON-LD offers
    final lowPriceMatch = RegExp(r'"lowPrice"\s*:\s*"?(\d+[.,]\d{1,2})"?').firstMatch(cleanHtml);
    if (lowPriceMatch != null) return lowPriceMatch.group(1)?.replaceAll(',', '.');

    // 3. Meta tag (Standard OpenGraph/Schema)
    final metaMatch = RegExp(r'meta property="product:price:amount" content="([\d.]+)"', caseSensitive: false).firstMatch(cleanHtml);
    if (metaMatch != null) return metaMatch.group(1);

    // 4. Fallback: Regex to find all price-like patterns
    List<double> foundPrices = [];
    const currencySymbols = "€|EUR|£|GBP|\\\$|zł|PLN|lei|RON|Ft|HUF|Kč|CZK";
    final regex = RegExp(
        '(?:($currencySymbols)\\s*(\\d+[.,]\\d{1,2}))|(?:(\\d+[.,]\\d{1,2})\\s*($currencySymbols))',
        caseSensitive: false);
    
    final matches = regex.allMatches(cleanHtml);
    for (final m in matches) {
       final valStr = (m.group(2) ?? m.group(3))?.replaceAll(',', '.');
       if (valStr != null) {
         final val = double.tryParse(valStr);
         if (val != null && val > 0) foundPrices.add(val);
       }
    }

    if (foundPrices.isEmpty) return null;

    // Return the lowest price found as last resort
    foundPrices.sort();
    return foundPrices.first.toStringAsFixed(2);
  }
}
