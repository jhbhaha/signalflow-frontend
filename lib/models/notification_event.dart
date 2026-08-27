// File: notification_event.dart (알림 이벤트 모델)
// [Added by ChatGPT | 2026-04-30 13:10 KST]
// Insert Location: lib/models/notification_event.dart

class NotificationEvent {
  final String id;
  final String ticker;
  final String stockName;
  final String prevStatus;
  final String currentStatus;
  final int finalScore;
  final String message;
  final String createdAt;
  final bool read;
  // [Modified by Claude | 2026-08-27 KST] 최근 거래일 종가(백엔드가 내려주면 표시)
  final double? close;


  NotificationEvent({
    required this.id,
    required this.ticker,
    required this.stockName,
    required this.prevStatus,
    required this.currentStatus,
    required this.finalScore,
    required this.message,
    required this.createdAt,
    required this.read,
    this.close,
  });

  factory NotificationEvent.fromJson(Map<String, dynamic> json) {
    return NotificationEvent(
      id: json['id'] ?? '${json['ticker']}_${json['created_at']}',
      ticker: json['ticker'],
      stockName: json['stock_name'],
      prevStatus: json['prev_status'],
      currentStatus: json['current_status'],
      finalScore: json['final_score'],
      message: json['message'],
      createdAt: json['created_at'],
      read: json['read'],
      close: (json['close'] as num?)?.toDouble(),
    );
  }
}