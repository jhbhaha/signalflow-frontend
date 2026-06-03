// File: price_chart_point.dart (가격 차트 포인트 모델)
// [2026-05-28 20:00 KST]
// Insert Location: lib/models/price_chart_point.dart 새 파일 생성

class PriceChartPoint {
  final String date;
  final double close;
  final double? ma5;
  final double? ma20;
  final double? ma60;

  const PriceChartPoint({
    required this.date,
    required this.close,
    this.ma5,
    this.ma20,
    this.ma60,
  });

  factory PriceChartPoint.fromJson(Map<String, dynamic> json) {
    return PriceChartPoint(
      date: json['date']?.toString() ?? '',
      close: ((json['close'] ?? 0) as num).toDouble(),
      ma5: json['ma5'] == null ? null : (json['ma5'] as num).toDouble(),
      ma20: json['ma20'] == null ? null : (json['ma20'] as num).toDouble(),
      ma60: json['ma60'] == null ? null : (json['ma60'] as num).toDouble(),
    );
  }
}