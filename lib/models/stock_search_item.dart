// File: lib/models/stock_search_item.dart (종목 검색 모델)
// [Added by ChatGPT | 2026-04-02 11:20 KST]
// 삽입 위치: 새 파일 생성

class StockSearchItem {
  final String ticker;
  final String stockName;
  // [2026-05-24 00:40 KST]
  // 최근 분석 상태 필드 추가
  // (Add recent analysis status field)
  final String? finalStatus;
  // [Modified by Claude | 2026-08-27 KST] 최근 거래일 종가(백엔드가 내려주면 표시)
  final double? close;

  StockSearchItem({
    required this.ticker,
    required this.stockName,
    this.finalStatus,
    this.close,
  });

  factory StockSearchItem.fromJson(Map<String, dynamic> json) {
    return StockSearchItem(
      ticker: json['ticker']?.toString() ?? '',
      stockName: json['stock_name']?.toString() ?? '',
      finalStatus: json['final_status'],
      close: (json['close'] as num?)?.toDouble(),
    );
  }

  String get displayText => '$stockName ($ticker)';
}
