// File: signal_history_item.dart (상태 변화 히스토리 아이템 모델)
// Last Modified: 2026-05-12 12:00 KST (작성자: ChatGPT)
// Insert Location: lib/models/signal_history_item.dart 새 파일 생성

class SignalHistoryItem {
  final String timestamp;
  final String ticker;
  final String stockName;
  final String? previousStatus;
  final String currentStatus;
  final int finalScore;

  SignalHistoryItem({
    required this.timestamp,
    required this.ticker,
    required this.stockName,
    required this.previousStatus,
    required this.currentStatus,
    required this.finalScore,
  });

  factory SignalHistoryItem.fromJson(Map<String, dynamic> json) {
    return SignalHistoryItem(
      timestamp: json['timestamp']?.toString() ?? '',
      ticker: json['ticker']?.toString() ?? '',
      stockName: json['stock_name']?.toString() ?? '',
      previousStatus: json['previous_status']?.toString(),
      currentStatus: json['current_status']?.toString() ?? '',
      finalScore: json['final_score'] is int
          ? json['final_score']
          : int.tryParse(json['final_score']?.toString() ?? '0') ?? 0,
    );
  }
}