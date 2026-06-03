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
    );
  }
}