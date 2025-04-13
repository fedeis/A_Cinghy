class Commodity {
  final String symbol;
  final String? name;
  final int? precision;

  Commodity({
    required this.symbol,
    this.name,
    this.precision = 2,
  });

  @override
  String toString() {
    return symbol;
  }
}