
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/brand.dart';
import '../models/country.dart';
import '../models/price_result.dart';
import '../services/api_service.dart';
import '../repositories/history_repository.dart';

class AppState extends ChangeNotifier {
  final ApiService _api = ApiService();
  final HistoryRepository _historyRepo = HistoryRepository();

  Brand _brand = Brand.decathlon;
  Brand get brand => _brand;

  String _inputUrl = '';
  String _manualId = '';
  String? _productId;
  String? get productId => _productId;

  /// For Zara: stores the product page slug (e.g. "pantalon-lin-p05070902.html")
  /// so we can build per-country product URLs for reliable price fetching.
  String? _zaraSlug;

  String _error = '';
  String get error => _error;

  String _activeTab = 'url'; // 'url' | 'manual'
  String get activeTab => _activeTab;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  /// The country currently being scanned (for UI progress indication)
  String? _currentScanCountryCode;
  String? get currentScanCountryCode => _currentScanCountryCode;

  Map<String, PriceResult> _prices = {};
  Map<String, PriceResult> get prices => _prices;

  AppState() {
    _api.updateExchangeRates();
  }

  void setBrand(Brand newBrand) {
    _brand = newBrand;
    _reset();
    notifyListeners();
  }

  void setInputUrl(String v) => _inputUrl = v;
  void setManualId(String v) => _manualId = v;

  void setActiveTab(String tab) {
    _activeTab = tab;
    notifyListeners();
  }

  void _reset() {
    _productId = null;
    _prices = {};
    _error = '';
    _inputUrl = '';
    _manualId = '';
    _isScanning = false;
    _currentScanCountryCode = null;
    _zaraSlug = null;
    _cancelHeadless();
  }

  void restoreFromHistory(ScanHistoryItem item) {
    _brand = Brand.fromKey(item.brand);
    _productId = item.productId;
    _zaraSlug = null;
    _prices = {};
    _error = '';
    for (var entry in item.prices.entries) {
       _prices[entry.key] = PriceResult.loaded(entry.value.toString());
    }
    notifyListeners();
  }

  /// Analyze the input and extract a product ID.
  /// If successful and autoScan is true, immediately starts scanning all countries.
  void analyze({bool autoScan = true}) {
    _error = '';
    _productId = null;
    _prices = {};
    _isScanning = false;
    _currentScanCountryCode = null;
    _zaraSlug = null;

    String? foundId;

    if (_activeTab == 'url') {
      if (_inputUrl.isEmpty) {
        _error = "Veuillez entrer une URL.";
        notifyListeners();
        return;
      }
      foundId = _extractIdFromText(_inputUrl, _brand);
    } else {
      if (_manualId.isEmpty) {
        _error = "Veuillez entrer une référence.";
        notifyListeners();
        return;
      }
      foundId = _validateManualId(_manualId, _brand);
      if (foundId == null && _error.isEmpty) {
        _error = "Référence introuvable.";
      }
      if (_error.isNotEmpty) {
        notifyListeners();
        return;
      }
    }

    if (foundId != null) {
      _productId = foundId;
      notifyListeners();
      // Auto-start scan after successful ID extraction
      if (autoScan) {
        scanAll();
      }
    } else {
      _error = "Référence introuvable.";
      notifyListeners();
    }
  }

  /// Validate and normalize a manual reference ID.
  /// Returns the cleaned ID or null. Sets _error if validation fails.
  String? _validateManualId(String raw, Brand currentBrand) {
    switch (currentBrand) {
      case Brand.decathlon:
        final cleaned = raw.replaceAll(RegExp(r'\D'), '');
        if (cleaned.length != 7) {
          _error = "Une référence Decathlon contient généralement 7 chiffres.";
          return null;
        }
        return cleaned;

      case Brand.zara:
        var id = raw.trim();
        if (RegExp(r'^\d{7}$').hasMatch(id)) {
          id = "${id.substring(0, 4)}/${id.substring(4)}";
        }
        if (!RegExp(r'^\d{4}\/\d{3}').hasMatch(id)) {
          _error = "Format Zara habituel : 1234/567 ou 7 chiffres";
          return null;
        }
        return id;

      case Brand.jdsports:
        final cleaned = raw.replaceAll(RegExp(r'\D'), '');
        if (cleaned.length < 5) {
          _error = "Référence JD Sports invalide.";
          return null;
        }
        return cleaned;

      case Brand.amazon:
        final trimmed = raw.trim();
        if (trimmed.isEmpty) {
          _error = "Référence Amazon invalide (ASIN ou mot-clé requis).";
          return null;
        }
        return trimmed;

      case Brand.ikea:
        final clean = raw.replaceAll(RegExp(r'\D'), '');
        if (clean.length != 8) {
          _error = "Format IKEA attendu : 8 chiffres (ex: 804.782.13).";
          return null;
        }
        return clean;

      case Brand.sephora:
        final trimmed = raw.trim();
        if (trimmed.isEmpty) {
          _error = "Référence Sephora invalide.";
          return null;
        }
        return trimmed;
    }
  }

  String? _extractIdFromText(String text, Brand currentBrand) {
    switch (currentBrand) {
      case Brand.decathlon:
        final mcMatch = RegExp(r'[?&]mc=(\d{7})').firstMatch(text);
        if (mcMatch != null) return mcMatch.group(1);
        final looseMatch = RegExp(r'\b\d{7}\b').firstMatch(text);
        if (looseMatch != null) return looseMatch.group(0);

      case Brand.zara:
        // ── Extract slug from full product URL for reliable per-country fetching ──
        // e.g. zara.com/fr/fr/pantalon-linen-p05070902.html → slug = pantalon-linen-p05070902.html
        final slugMatch = RegExp(
          r'zara\.com/[^/]+/[^/]+/([^?#]+\.html)',
          caseSensitive: false,
        ).firstMatch(text);
        if (slugMatch != null) {
          _zaraSlug = slugMatch.group(1)!;
          debugPrint('[AppState] Zara slug captured: $_zaraSlug');
        }

        // Clean product reference for display (4-digit/3-digit format)
        final directMatch = RegExp(r'(\d{4}\/\d{3}(?:\/\d{3})?)').firstMatch(text);
        if (directMatch != null) return directMatch.group(1);
        final p0Match = RegExp(r'p0(\d{7})').firstMatch(text);
        if (p0Match != null) {
          final raw = p0Match.group(1)!;
          return "${raw.substring(0, 4)}/${raw.substring(4)}";
        }
        final loose7 = RegExp(r'\b(\d{7})\b').firstMatch(text);
        if (loose7 != null) {
          final raw = loose7.group(1)!;
          return "${raw.substring(0, 4)}/${raw.substring(4)}";
        }

      case Brand.jdsports:
        final jdMatch = RegExp(r'\/(\d{6,10})_').firstMatch(text);
        if (jdMatch != null) return jdMatch.group(1);
        final looseJD = RegExp(r'\b\d{6,10}\b').firstMatch(text);
        if (looseJD != null) return looseJD.group(0);

      case Brand.amazon:
        final dpMatch = RegExp(r'/dp/([a-zA-Z0-9]{10})', caseSensitive: false).firstMatch(text);
        if (dpMatch != null) return dpMatch.group(1);
        final gpMatch = RegExp(r'/gp/product/([a-zA-Z0-9]{10})', caseSensitive: false).firstMatch(text);
        if (gpMatch != null) return gpMatch.group(1);
        final asinMatch = RegExp(r'\b(B[A-Z0-9]{9})\b', caseSensitive: false).firstMatch(text);
        if (asinMatch != null) return asinMatch.group(1);
        final textAsin = RegExp(r'([a-zA-Z0-9]{10})').firstMatch(text);
        if (textAsin != null) return textAsin.group(1);

      case Brand.ikea:
        final match = RegExp(r'\b\d{3}[.-]?\d{3}[.-]?\d{2}\b').firstMatch(text) ?? RegExp(r'\b\d{8}\b').firstMatch(text);
        if (match != null) {
          return match.group(0)!.replaceAll(RegExp(r'[.-]'), '');
        }

      case Brand.sephora:
        final pMatch = RegExp(r'/p-p(\d+)', caseSensitive: false).firstMatch(text);
        if (pMatch != null) return pMatch.group(1);
        final pCodeMatch = RegExp(r'\bp(\d{5,10})\b', caseSensitive: false).firstMatch(text);
        if (pCodeMatch != null) return pCodeMatch.group(1);
        final eanMatch = RegExp(r'\b\d{13}\b').firstMatch(text);
        if (eanMatch != null) return eanMatch.group(0);
    }
    return null;
  }

  // ─── Headless WebView Communication ───────────────────────────────

  /// The URL the headless WebView should currently load
  String? headlessUrl;

  /// Completer that the WebView resolves when it extracts a price
  Completer<String?>? _headlessCompleter;

  /// Called by the WebView widget when JS extraction succeeds
  void onHeadlessPageLoaded(String priceString) {
    debugPrint('[AppState] Headless extracted: "$priceString"');
    if (_headlessCompleter != null && !_headlessCompleter!.isCompleted) {
      _headlessCompleter!.complete(priceString);
    }
  }

  /// Called by the WebView widget if extraction fails
  void onHeadlessPageError() {
    debugPrint('[AppState] Headless extraction error');
    if (_headlessCompleter != null && !_headlessCompleter!.isCompleted) {
      _headlessCompleter!.complete(null);
    }
  }

  /// Cleanly cancel any pending headless operation
  void _cancelHeadless() {
    if (_headlessCompleter != null && !_headlessCompleter!.isCompleted) {
      _headlessCompleter!.complete(null);
    }
    _headlessCompleter = null;
    headlessUrl = null;
  }

  // ─── Shared single-country scan logic ─────────────────────────────

  /// Scans a single country and stores the result.
  /// Returns true if a price was found.
  Future<bool> _scanSingleCountry(Country country) async {
    _currentScanCountryCode = country.code;
    _prices[country.code] = const PriceResult.loading();
    notifyListeners();

    try {
      double? price;

      // ── Strategy A (Zara): Dedicated approach ──
      if (brand.key == 'zara') {
        if (kIsWeb) {
          // Zara blocks all server-side/proxy fetches (403 on everything).
          // Best UX: give user a direct link to the product page per country.
          final locale = country.zaraPath;
          final url = (_zaraSlug != null)
              ? 'https://www.zara.com/$locale/$_zaraSlug'
              : _api.getSearchUrl(country, brand.key, productId!);
          _prices[country.code] = PriceResult.webOnly(url);
          notifyListeners();
          return false;
        } else {
          // Mobile: try direct HTTP fetch
          price = await _api.fetchZaraPrice(
            country,
            productId!,
            zaraSlug: _zaraSlug,
          );
          if (price != null) {
            debugPrint('[AppState] Zara price for ${country.name}: $price');
          }
        }
      }

      // ── Strategy B: WebView JS extraction (primary for non-Zara or fallback on mobile/desktop) ──
      if (price == null && !kIsWeb) {
        // For Zara on mobile with slug, navigate to the product page directly
        headlessUrl = (brand.key == 'zara' && _zaraSlug != null)
            ? 'https://www.zara.com/${country.zaraPath}/$_zaraSlug'
            : _api.getSearchUrl(country, brand.key, productId!);
        _headlessCompleter = Completer<String?>();
        notifyListeners(); // Triggers WebView rebuild with new URL

        debugPrint('[AppState] Scanning ${country.name} → $headlessUrl');

        final extractedPrice = await _headlessCompleter!.future.timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            debugPrint('[AppState] Timeout for ${country.name}');
            return null;
          },
        );

        if (extractedPrice != null && extractedPrice.isNotEmpty) {
          if (extractedPrice.startsWith('[') && extractedPrice.endsWith(']')) {
            try {
              final List<dynamic> list = json.decode(extractedPrice);
              double? minPrice;
              for (final item in list) {
                if (item is String) {
                  final p = _api.parsePriceFromHtml(item, currency: country.currency);
                  if (p != null) {
                    if (minPrice == null || p < minPrice) {
                      minPrice = p;
                    }
                  }
                }
              }
              price = minPrice;
              debugPrint('[AppState] WebView parsed min price from list $list: $price');
            } catch (e) {
              debugPrint('[AppState] Error parsing JSON price list: $e');
              price = _api.parsePriceFromHtml(extractedPrice, currency: country.currency);
            }
          } else {
            price = _api.parsePriceFromHtml(extractedPrice, currency: country.currency);
            debugPrint('[AppState] WebView single price for ${country.name}: $price');
          }
        }
      }

      // ── Strategy C: Direct HTTP fallback (for non-Zara static sites) ──
      if (price == null && _isScanning && brand.key != 'zara') {
        debugPrint('[AppState] Trying HTTP fallback for ${country.name}...');
        price = await _api.fetchPrice(country, brand.key, productId!);
        if (price != null) {
          debugPrint('[AppState] HTTP fallback price for ${country.name}: $price');
        }
      }

      if (price != null) {
        _prices[country.code] = PriceResult.loaded(price.toStringAsFixed(2));
        notifyListeners();
        return true;
      } else {
        _prices[country.code] = const PriceResult.error('Indisponible');
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('[AppState] Error scanning ${country.name}: $e');
      _prices[country.code] = const PriceResult.error('Erreur');
      notifyListeners();
      return false;
    }
  }

  /// Saves current loaded prices to history.
  void _saveToHistory() {
    final Map<String, double> successfulPrices = {};
    _prices.forEach((code, result) {
      if (result.isLoaded && result.value != null) {
        successfulPrices[code] = double.tryParse(result.value!) ?? 0.0;
      }
    });
    if (successfulPrices.isNotEmpty) {
      _historyRepo.addToHistory(brand.key, productId!, successfulPrices);
    }
  }

  // ─── Scan All Countries ───────────────────────────────────────────

  Future<void> scanAll() async {
    if (productId == null || isScanning) return;

    _isScanning = true;
    _error = '';
    notifyListeners();

    try {
      await _api.updateExchangeRates();

      if (kIsWeb || brand.key == 'zara') {
        // On Web or for Zara (JSON API — no WebView bottleneck), run concurrently
        final futures = kCountries.map((country) => _scanSingleCountry(country)).toList();
        await Future.wait(futures);
      } else {
        // On Mobile/Desktop for non-Zara, run sequentially to avoid overlapping WebViews
        for (var country in kCountries) {
          if (!_isScanning) break;
          await _scanSingleCountry(country);
          if (_isScanning) {
            await Future.delayed(Duration(milliseconds: 200 + Random().nextInt(200)));
          }
        }
      }
    } catch (e, stack) {
      debugPrint('[AppState] scanAll error: $e\n$stack');
    } finally {
      // Cleanup
      _cancelHeadless();
      _isScanning = false;
      _currentScanCountryCode = null;
      _saveToHistory();
      notifyListeners();
    }
  }

  Future<void> scanCountry(Country country) async {
    if (productId == null || isScanning) return;

    _isScanning = true;
    notifyListeners();

    try {
      await _api.updateExchangeRates();
      await _scanSingleCountry(country);
    } catch (e, stack) {
      debugPrint('[AppState] scanCountry error: $e\n$stack');
    } finally {
      _cancelHeadless();
      _isScanning = false;
      _currentScanCountryCode = null;
      _saveToHistory();
      notifyListeners();
    }
  }

  void stopScan() {
    _isScanning = false;
    _currentScanCountryCode = null;
    _cancelHeadless();
    notifyListeners();
  }

  ApiService get api => _api;

  double? getConvertedPrice(Country country, String? priceStr) {
    if (priceStr == null) return null;
    try {
      final clean = priceStr.replaceAll(',', '.').replaceAll(RegExp(r'\s+'), '');
      final price = double.parse(clean);
      final rate = _api.getRate(country.currencyIso);
      return price / rate;
    } catch (e) {
      return null;
    }
  }
}
