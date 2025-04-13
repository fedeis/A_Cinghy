import 'package:cinghy/models/commodity.dart';

class Amount {
  final double value;
  final Commodity commodity;
  final bool isNegative;

  Amount({
    required this.value,
    required this.commodity,
    this.isNegative = false,
  });

  factory Amount.parse(String amountStr) {
    final isNegative = amountStr.contains('-');
    final cleanedStr = amountStr.replaceAll(RegExp(r'[^\d.,A-Za-z$€£¥]'), '');
    
    // Extract commodity and value
    final RegExp commodityRegex = RegExp(r'[A-Za-z$€£¥]+');
    final commodityMatch = commodityRegex.firstMatch(cleanedStr);
    final commoditySymbol = commodityMatch != null 
      ? cleanedStr.substring(commodityMatch.start, commodityMatch.end) 
      : '\$';
    
    final valueStr = cleanedStr.replaceAll(commodityRegex, '');
    final double value = double.tryParse(valueStr) ?? 0.0;
    
    return Amount(
      value: value.abs(),
      commodity: Commodity(symbol: commoditySymbol),
      isNegative: isNegative,
    );
  }

  @override
  String toString() {
    final sign = isNegative ? '-' : '';
    final formattedValue = value.toStringAsFixed(2);
    return '$sign${commodity.symbol}$formattedValue';
  }
}