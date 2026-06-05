/// Typed representation of a price scan result for a single country.
class PriceResult {
  final PriceStatus status;
  final String? value;   // Formatted price string e.g. "29.99"
  final String? msg;     // Error / info message
  final String? actionUrl; // For webOnly: the URL to open

  const PriceResult({
    required this.status,
    this.value,
    this.msg,
    this.actionUrl,
  });

  const PriceResult.loading()
      : status = PriceStatus.loading,
        value = null,
        msg = null,
        actionUrl = null;

  const PriceResult.loaded(String price)
      : status = PriceStatus.loaded,
        value = price,
        msg = null,
        actionUrl = null;

  const PriceResult.error([String? message])
      : status = PriceStatus.error,
        value = null,
        msg = message ?? 'Erreur',
        actionUrl = null;

  const PriceResult.idle()
      : status = PriceStatus.idle,
        value = null,
        msg = null,
        actionUrl = null;

  /// Special state: price not extractable automatically (e.g. Zara on web),
  /// but we can link the user directly to the product page.
  const PriceResult.webOnly(String url)
      : status = PriceStatus.webOnly,
        value = null,
        msg = null,
        actionUrl = url;

  bool get isLoaded => status == PriceStatus.loaded;
  bool get isLoading => status == PriceStatus.loading;
  bool get isError => status == PriceStatus.error;
  bool get isIdle => status == PriceStatus.idle;
  bool get isWebOnly => status == PriceStatus.webOnly;
}

enum PriceStatus { idle, loading, loaded, error, webOnly }
