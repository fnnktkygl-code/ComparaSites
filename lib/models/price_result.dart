/// Typed representation of a price scan result for a single country.
/// Replaces the untyped Map<String, dynamic> that was used previously.
class PriceResult {
  final PriceStatus status;
  final String? value;   // Formatted price string e.g. "29.99"
  final String? msg;     // Error / info message

  const PriceResult({
    required this.status,
    this.value,
    this.msg,
  });

  const PriceResult.loading()
      : status = PriceStatus.loading,
        value = null,
        msg = null;

  const PriceResult.loaded(String price)
      : status = PriceStatus.loaded,
        value = price,
        msg = null;

  const PriceResult.error([String? message])
      : status = PriceStatus.error,
        value = null,
        msg = message ?? 'Erreur';

  const PriceResult.idle()
      : status = PriceStatus.idle,
        value = null,
        msg = null;

  bool get isLoaded => status == PriceStatus.loaded;
  bool get isLoading => status == PriceStatus.loading;
  bool get isError => status == PriceStatus.error;
  bool get isIdle => status == PriceStatus.idle;
}

enum PriceStatus { idle, loading, loaded, error }
