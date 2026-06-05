import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as import_ui;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import '../models/brand.dart';
import '../models/country.dart';
import '../models/price_result.dart';
import '../screens/webview_screen.dart';
import '../widgets/price_card.dart';
import '../widgets/shimmer_loading.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Persistent controller so text is not lost during rebuilds
  final TextEditingController _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('À propos de ComparaSites'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ComparaSites vous permet de comparer les prix des produits à travers différents pays européens pour obtenir le meilleur prix.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Text(
              'Recherche supportée pour :\n'
              '• Decathlon, Zara, JD Sports, Amazon, IKEA et Sephora.',
              style: TextStyle(height: 1.4),
            ),
            SizedBox(height: 16),
            Text(
              'Note sur la version Web :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'En raison des restrictions de sécurité CORS des navigateurs, la recherche directe peut être bloquée pour certains magasins. '
              'Pour une fiabilité de 100% sans restrictions, nous vous recommandons d\'utiliser l\'application native.',
              style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _submitSearch(AppState state) {
    // Sync controller text into state
    if (state.activeTab == 'url') {
      state.setInputUrl(_inputController.text);
    } else {
      state.setManualId(_inputController.text);
    }
    state.analyze(autoScan: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final brandColor = state.brand.color;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ─── Decorative background blobs (wrapped in RepaintBoundary to isolate paint) ───
          RepaintBoundary(
            child: _BackgroundBlobs(brandColor: brandColor),
          ),

          // ─── Main scrollable content ─────────────────
          CustomScrollView(
            slivers: [
              // 1. Sliver App Bar
              SliverAppBar(
                floating: true,
                pinned: true,
                backgroundColor: const Color(0xFFF8FAFC).withValues(alpha: 0.8),
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                title: Text(
                  'ComparaSites', 
                  style: TextStyle(
                    fontWeight: FontWeight.w900, 
                    color: state.brand.useDarkText ? Colors.black : brandColor,
                    fontSize: 22,
                    letterSpacing: -0.5,
                  )
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.info_outline,
                      color: state.brand.useDarkText ? Colors.black : brandColor,
                    ),
                    onPressed: () => _showInfoDialog(context),
                  ),
                ],
              ),

              // 2. Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildBrandSelector(context, state, brandColor),
                      const SizedBox(height: 16),
                      _buildGlassySearchCard(context, state, brandColor),
                      const SizedBox(height: 24),
                      
                      if (state.productId != null) ...[
                        _buildResultsHeader(context, state, brandColor),
                        _buildProgressBar(state, brandColor),
                        const SizedBox(height: 12),
                        _buildSummaryBanner(context, state, brandColor),
                        _buildResultsGrid(context, state),
                      ],

                      // Empty State illustration
                      if(state.productId == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Column(
                            children: [
                              Icon(Icons.manage_search_rounded, size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                "Comparez les prix en Europe",
                                style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        )
                    ],
                  ),
                ),
              )
            ],
          ),

          // ─── Headless WebView (outside scroll, in Stack) ───
          if (state.headlessUrl != null && !kIsWeb)
            Positioned(
              left: -100,
              top: -100,
              child: SizedBox(
                width: 80,
                height: 80,
                child: Visibility(
                  visible: false,
                  maintainState: true,
                  maintainAnimation: true,
                  maintainSize: true,
                  child: _HeadlessWebView(
                    key: ValueKey(state.headlessUrl),
                    url: state.headlessUrl!,
                    onHtmlExtracted: state.onHeadlessPageLoaded,
                    onError: state.onHeadlessPageError,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBrandSelector(BuildContext context, AppState state, Color brandColor) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: Brand.values.map((b) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _brandSwitchItem(context, state, b),
          );
        }).toList(),
      ),
    );
  }

  Widget _brandSwitchItem(BuildContext context, AppState state, Brand b) {
    final isSelected = state.brand == b;
    return GestureDetector(
      onTap: () {
        state.setBrand(b);
        _inputController.clear();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? b.color : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? b.color : Colors.white.withValues(alpha: 0.65), 
            width: 1.5
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: b.color.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Text(
          b.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected 
                ? (b.useDarkText ? Colors.black : Colors.white) 
                : Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassySearchCard(BuildContext context, AppState state, Color color) {
    final isUrlMode = state.activeTab == 'url';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 35,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.5),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16)
            ),
            child: Row(
              children: [
                Expanded(child: _tabPill(state, 'url', 'Via URL')),
                Expanded(child: _tabPill(state, 'manual', 'Référence')),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Input with persistent controller + keyboard submit
          TextField(
             controller: _inputController,
             onChanged: (v) => isUrlMode ? state.setInputUrl(v) : state.setManualId(v),
             textInputAction: TextInputAction.search,
             onSubmitted: (_) => _submitSearch(state),
             style: const TextStyle(fontWeight: FontWeight.w500),
             decoration: InputDecoration(
               filled: true,
               fillColor: Colors.grey[50],
               hintText: isUrlMode 
                   ? 'Collez le lien ici...' 
                   : state.brand.hintText,
               hintStyle: TextStyle(color: Colors.grey[400]),
               border: OutlineInputBorder(
                 borderRadius: BorderRadius.circular(16),
                 borderSide: BorderSide.none,
               ),
               contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
               // Dynamic icon: link for URL mode, tag for reference mode
               prefixIcon: Icon(
                 isUrlMode ? Icons.link : Icons.sell_outlined,
                 color: Colors.grey[400],
               ),
             ),
          ),
          
          const SizedBox(height: 20),
          
          // Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: state.isScanning ? null : () => _submitSearch(state),
              icon: state.isScanning 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.search_rounded, size: 20),
              label: Text(
                state.isScanning ? "Scan en cours…" : "Rechercher & Scanner",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                disabledBackgroundColor: color.withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white70,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          if (state.error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Icon(Icons.error_rounded, color: Colors.red[400], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(state.error, style: TextStyle(color: Colors.red[400], fontWeight: FontWeight.w500))),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _tabPill(AppState state, String key, String label) {
    final isSelected = state.activeTab == key;
    return GestureDetector(
      onTap: () {
        state.setActiveTab(key);
        _inputController.clear();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: isSelected ? Colors.black : Colors.grey[500]
          ),
        ),
      ),
    );
  }

  Widget _buildResultsHeader(BuildContext context, AppState state, Color color) {
    String? scanningName;
    if (state.isScanning && state.currentScanCountryCode != null) {
      try {
        scanningName = kCountries.firstWhere((c) => c.code == state.currentScanCountryCode).name;
      } catch (_) {}
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
         Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              Text('Résultats pour', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
              Row(
                children: [
                  Text('#${state.productId}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                         if (state.productId != null) Share.share('Ref: ${state.productId}');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(Icons.share_rounded, size: 14, color: color),
                    ),
                  )
                ],
              ),
              if (scanningName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Scan: $scanningName…',
                    style: TextStyle(color: Colors.grey[400], fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ),
           ],
         ),
         if (state.isScanning)
           OutlinedButton.icon(
              onPressed: state.stopScan,
              icon: const SizedBox(
                 width: 14, 
                 height: 14, 
                 child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)
              ),
              label: const Text('Stop'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
              ),
           )
         else
           FilledButton.icon(
              onPressed: state.scanAll,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Rescanner'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
              ),
           )
      ],
    );
  }

  Widget _buildResultsGrid(BuildContext context, AppState state) {
    // Build a sorted list of countries: loaded (cheapest first), then error, then idle
    final sortedCountries = List<Country>.from(kCountries);
    
    sortedCountries.sort((a, b) {
      final prA = state.prices[a.code];
      final prB = state.prices[b.code];
      
      // Loading items stay at their natural position (treat as very high)
      int statusOrder(PriceResult? pr) {
        if (pr == null || pr.isIdle) return 2;  // idle at end
        if (pr.isLoading) return 1;             // loading in middle
        if (pr.isError) return 1;               // error in middle
        return 0;                               // loaded first
      }

      final orderA = statusOrder(prA);
      final orderB = statusOrder(prB);
      if (orderA != orderB) return orderA.compareTo(orderB);

      // Both loaded: sort by converted EUR price ascending (cheapest first)
      if (prA != null && prA.isLoaded && prB != null && prB.isLoaded) {
        final euroA = state.getConvertedPrice(a, prA.value) ?? double.infinity;
        final euroB = state.getConvertedPrice(b, prB.value) ?? double.infinity;
        return euroA.compareTo(euroB);
      }
      return 0;
    });

    // Find cheapest
    String? cheapestCountryCode;
    double minPriceEur = double.infinity;
    
    for (var country in kCountries) {
      final result = state.prices[country.code];
      if (result != null && result.isLoaded && result.value != null) {
        final converted = state.getConvertedPrice(country, result.value);
        if (converted != null && converted < minPriceEur) {
          minPriceEur = converted;
          cheapestCountryCode = country.code;
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 2;
        double childAspectRatio = 1.15;

        if (width > 900) {
          crossAxisCount = 5;
          childAspectRatio = 1.25;
        } else if (width > 700) {
          crossAxisCount = 4;
          childAspectRatio = 1.2;
        } else if (width > 500) {
          crossAxisCount = 3;
          childAspectRatio = 1.15;
        } else {
          crossAxisCount = 2;
          childAspectRatio = 1.1;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedCountries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final country = sortedCountries[index];
            final result = state.prices[country.code];
            final isCheapest = country.code == cheapestCountryCode;

            if (result != null && result.isLoading) {
              return const ShimmerLoading();
            }

            return PriceCard(
              country: country,
              result: result,
              isCheapest: isCheapest,
              convertedPrice: state.getConvertedPrice(country, result?.value),
              isScanningThis: state.isScanning && state.currentScanCountryCode == country.code,
              isAnyScanRunning: state.isScanning,
              onScan: () => state.scanCountry(country),
              onTap: () async {
                  if (state.productId != null) {
                      final url = state.api.getSearchUrl(country, state.brand.key, state.productId!);
                      final uri = Uri.parse(url);
                      try {
                        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                        if (!launched && context.mounted) {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => 
                             WebviewScreen(url: url, title: country.name)
                          ));
                        }
                      } catch (_) {
                        if (context.mounted) {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => 
                             WebviewScreen(url: url, title: country.name)
                          ));
                        }
                      }
                  }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildProgressBar(AppState state, Color brandColor) {
    if (!state.isScanning) return const SizedBox.shrink();

    int completedCount = 0;
    for (var country in kCountries) {
      final result = state.prices[country.code];
      if (result != null && (result.isLoaded || result.isError)) {
        completedCount++;
      }
    }

    final double progress = completedCount / kCountries.length;

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(brandColor),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Progression du scan...",
                style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold),
              ),
              Text(
                "${(progress * 100).toStringAsFixed(0)}%",
                style: TextStyle(fontSize: 10, color: brandColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBanner(BuildContext context, AppState state, Color brandColor) {
    String? cheapestCountryCode;
    double minPriceEur = double.infinity;
    double? frPriceEur;
    Country? cheapestCountry;

    for (var country in kCountries) {
      final result = state.prices[country.code];
      if (result != null && result.isLoaded && result.value != null) {
        final converted = state.getConvertedPrice(country, result.value);
        if (converted != null) {
          if (converted < minPriceEur) {
            minPriceEur = converted;
            cheapestCountryCode = country.code;
            cheapestCountry = country;
          }
          if (country.code == 'FR') {
            frPriceEur = converted;
          }
        }
      }
    }

    if (cheapestCountry == null) return const SizedBox.shrink();

    double? savingsPercent;
    if (frPriceEur != null && frPriceEur > minPriceEur && cheapestCountryCode != 'FR') {
      savingsPercent = ((frPriceEur - minPriceEur) / frPriceEur) * 100;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            brandColor.withValues(alpha: 0.15),
            brandColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: brandColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.stars_rounded,
              color: state.brand.useDarkText ? Colors.black : brandColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Meilleure offre trouvée !",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: state.brand.useDarkText ? Colors.black : brandColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Achetez en ${cheapestCountry.name} pour seulement ${minPriceEur.toStringAsFixed(2)} €",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (savingsPercent != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Économisez ${savingsPercent.toStringAsFixed(0)}% par rapport à la France !",
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Background Blobs — extracted into its own widget with RepaintBoundary
// to isolate the expensive blur filter from rebuilds caused by state changes.
// ═══════════════════════════════════════════════════════════════════

class _BackgroundBlobs extends StatelessWidget {
  final Color brandColor;
  const _BackgroundBlobs({required this.brandColor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -60,
          right: -60,
          child: ImageFiltered(
            imageFilter: import_ui.ImageFilter.blur(sigmaX: 90, sigmaY: 90),
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: brandColor.withValues(alpha: 0.18),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 150,
          left: -80,
          child: ImageFiltered(
            imageFilter: import_ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: brandColor.withValues(alpha: 0.12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Headless WebView — Loads a URL and extracts the price via JS
// ═══════════════════════════════════════════════════════════════════

class _HeadlessWebView extends StatefulWidget {
  final String url;
  final Function(String) onHtmlExtracted;
  final VoidCallback onError;

  const _HeadlessWebView({
    super.key,
    required this.url,
    required this.onHtmlExtracted,
    required this.onError,
  });

  @override
  State<_HeadlessWebView> createState() => _HeadlessWebViewState();
}

class _HeadlessWebViewState extends State<_HeadlessWebView> {
  late final WebViewController _controller;
  bool _hasReported = false;

  @override
  void initState() {
    super.initState();
    _hasReported = false;
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) "
        "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 "
        "Mobile/15E148 Safari/604.1"
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (e) {
            debugPrint('[HeadlessWV] Resource error: ${e.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
    
    debugPrint('[HeadlessWV] Loading: ${widget.url}');
    _startExtraction();
  }

  Future<void> _startExtraction() async {
    if (_hasReported || !mounted) return;
    
    String lastDebugStr = '';
    
    for (int attempt = 1; attempt <= 10; attempt++) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || _hasReported) return;

      try {
        final result = await _controller.runJavaScriptReturningResult(r"""
          (function() {
            var candidates = [];
            
            function addCandidate(txt) {
              if (!txt) return;
              txt = txt.trim().replace(/\s+/g, ' ');
              if (txt.length > 0 && txt.length < 50) {
                if (/\d/.test(txt)) {
                  if (candidates.indexOf(txt) === -1) {
                    candidates.push(txt);
                  }
                }
              }
            }

            // 1) Extract from JSON-LD
            try {
              var scripts = document.querySelectorAll('script[type="application/ld+json"]');
              for (var i = 0; i < scripts.length; i++) {
                try {
                  var data = JSON.parse(scripts[i].innerText);
                  if (Array.isArray(data)) {
                    var product = data.find(function(x) { return x['@type'] === 'Product'; });
                    if (product) data = product;
                    else data = data[0];
                  }
                  if (data && data['@type'] === 'Product' && data.offers) {
                    var offers = data.offers;
                    if (Array.isArray(offers)) {
                      for (var o = 0; o < offers.length; o++) {
                        if (offers[o].lowPrice) addCandidate(offers[o].lowPrice.toString());
                        if (offers[o].price) addCandidate(offers[o].price.toString());
                      }
                    } else {
                      if (offers.lowPrice) addCandidate(offers.lowPrice.toString());
                      if (offers.price) addCandidate(offers.price.toString());
                    }
                  }
                } catch(inner) {}
              }
            } catch(e) {}

            // 2) Extract from Meta tags
            try {
              var meta = document.querySelector('meta[property="product:price:amount"]');
              if (meta && meta.content) addCandidate(meta.content);
              var metaOg = document.querySelector('meta[property="og:price:amount"]');
              if (metaOg && metaOg.content) addCandidate(metaOg.content);
            } catch(e) {}

            // 3) Extract from DOM Selectors (Sale and Standard)
            var selectors = [
              '.price__amount--on-sale',
              '.product-detail-info__price-amount--on-sale',
              '.price__amount--sale',
              '.money-amount__main--on-sale',
              '[data-qa-qualifier="price-amount-current"]',
              '.vtmn-price_--sale',
              '#priceblock_dealprice',
              '.a-price .a-offscreen',
              '.pip-temp-price__integer',
              '.money-amount__main',
              '.price-current__amount',
              '.price__amount',
              '[data-testid="price"]',
              '.vtmn-price',
              '.prc--amount',
              '.product-price__current-price',
              '.dpb-price',
              '[class*="sDq_FX"]',
              '[class*="KxHAYs"]',
              'p[color="text.default"]',
              '.z-navicat-header_priceBox span',
              '.price-now',
              '.product-price',
              '[data-testid="product-price"]',
              '.pri',
              '.pdp-price',
              '.a-price-whole',
              '#price_inside_buybox',
              '#priceblock_ourprice',
              '.pip-price__integer',
              '.pip-price-current .pip-price__integer',
              '.pip-price-current',
              '.pip-temp-price',
              '.sku-price',
              '.price-amount',
              '.price-sales'
            ];

            for (var s = 0; s < selectors.length; s++) {
              try {
                var els = document.querySelectorAll(selectors[s]);
                for (var ei = 0; ei < els.length && ei < 30; ei++) {
                  addCandidate(els[ei].innerText || els[ei].textContent);
                }
              } catch(se) {}
            }

            // 4) Broad fallback
            try {
              var allElements = document.querySelectorAll('[class*="price"], [class*="Price"], [data-testid*="price"]');
              for (var j = 0; j < allElements.length && j < 30; j++) {
                addCandidate(allElements[j].innerText || allElements[j].textContent);
              }
            } catch(ge) {}

            if (candidates.length > 0) {
              return JSON.stringify(candidates);
            }

            var debugBody = document.body ? (document.body.innerText || '').substring(0, 150).replace(/\n/g, ' ') : 'NO BODY';
            var title = document.title || 'NO TITLE';
            return 'DEBUG: ' + title + ' | ' + debugBody;
          })();
        """);
        
        if (!mounted || _hasReported) return;
        
        final resultStr = result.toString();
        
        if (resultStr != 'null' && resultStr.isNotEmpty) {
          var clean = resultStr;
          if (clean.startsWith('"') && clean.endsWith('"')) {
            clean = clean.substring(1, clean.length - 1);
          }
          
          if (clean.startsWith('DEBUG:')) {
            lastDebugStr = clean;
            debugPrint('[HeadlessWV] Attempt $attempt missed. $clean');
            continue;
          }
          
          debugPrint('[HeadlessWV] SUCCESS on attempt $attempt: $clean');
          _reportSuccess(clean);
          return;
        }
      } catch (e) {
        debugPrint('[HeadlessWV] attempt $attempt error: $e');
      }
    }
    
    debugPrint('[HeadlessWV] FAILED after 10 attempts. Last saw: $lastDebugStr');
    _reportError();
  }

  void _reportSuccess(String value) {
    if (_hasReported || !mounted) return;
    _hasReported = true;
    widget.onHtmlExtracted(value);
  }

  void _reportError() {
    if (_hasReported || !mounted) return;
    _hasReported = true;
    widget.onError();
  }

  @override
  void dispose() {
    debugPrint('[HeadlessWV] Disposing controller');
    _hasReported = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
