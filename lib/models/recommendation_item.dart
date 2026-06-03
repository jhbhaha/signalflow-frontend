// File: recommendation_item.dart (추천 종목 모델)
// [Added by ChatGPT | 2026-04-25 22:50 KST]
// Insert Location: G:\stockmarket_frontend\lib\models\recommendation_item.dart 새 파일 생성

class RecommendationItem {
  final String ticker;
  final String stockName;
  final int finalScore;
  final String finalStatus;
  final String? etfReason;

  RecommendationItem({
    required this.ticker,
    required this.stockName,
    required this.finalScore,
    required this.finalStatus,
    required this.etfReason,
  });

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      ticker: json['ticker'] ?? '',
      stockName: json['stock_name'] ?? '',
      finalScore: json['final_score'] ?? 0,
      finalStatus: json['final_status'] ?? '',
      etfReason: json['etf_reason'],
    );
  }
}