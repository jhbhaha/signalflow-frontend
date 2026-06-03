// File: watch_item.dart (관심종목 모델)
// Last Modified: 2026-06-03 19:20 KST (작성자: ChatGPT)
// Insert Location: flutter_stock_frontend/lib/models/watch_item.dart 전체 교체

class WatchItem {
  final String ticker;
  final String stockName;

  WatchItem({
    required this.ticker,
    required this.stockName,
  });

  factory WatchItem.fromJson(Map<String, dynamic> json) {
    // [Modified by ChatGPT | 2026-06-03 19:20 KST]
    // 업데이트 후 서버 응답 키가 달라져도 관심종목이 표시되도록 보강
    // (Support multiple backend response keys after update)
    final String ticker = (json['ticker'] ??
        json['code'] ??
        json['symbol'] ??
        '')
        .toString()
        .trim();

    final String stockName = (json['stock_name'] ??
        json['stockName'] ??
        json['name'] ??
        json['stock_name_ko'] ??
        json['company_name'] ??
        ticker)
        .toString()
        .trim();

    return WatchItem(
      ticker: ticker,
      stockName: stockName.isEmpty ? ticker : stockName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticker': ticker,
      'stock_name': stockName,
      'stockName': stockName,
    };
  }
}