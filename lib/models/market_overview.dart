// File: market_overview.dart (시장 흐름 모델)
// [Added by ChatGPT | 2026-05-13 14:50 KST]
// Insert Location: lib/models/market_overview.dart 새 파일 생성

class MarketOverview {
  final double kospiChange;
  final double kosdaqChange;
  final String marketStatus;

  const MarketOverview({
    required this.kospiChange,
    required this.kosdaqChange,
    required this.marketStatus,
  });

  factory MarketOverview.fromJson(
      Map<String, dynamic> json,
      ) {
    return MarketOverview(
      kospiChange:
      (json['kospi_change'] ?? 0).toDouble(),
      kosdaqChange:
      (json['kosdaq_change'] ?? 0).toDouble(),
      marketStatus:
      json['market_status'] ?? 'UNKNOWN',
    );
  }
}