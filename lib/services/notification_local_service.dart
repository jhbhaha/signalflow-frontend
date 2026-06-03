// File: notification_local_service.dart (로컬 알림 서비스)
// Last Modified: 2026-05-22 18:30 KST (작성자: ChatGPT)
// Insert Location: G:\stockmarket_frontend\lib\services\notification_local_service.dart 전체 교체

import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/notification_event.dart';

class NotificationLocalService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  // [Modified by ChatGPT | 2026-05-22 18:30 KST]
  // 로컬 알림 클릭 시 payload를 main.dart로 전달
  // (Pass local notification payload to main.dart when notification is tapped)
  static Future<void> init({
    required void Function(String? payload) onNotificationTap,
  }) async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onNotificationTap(response.payload);
      },
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
  }

  static Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      0,
      '테스트 알림',
      '삼성전자 ATTACK 진입',
      details,
      payload: jsonEncode({
        'ticker': '005930',
        'stock_name': '삼성전자',
        'final_status': 'ATTACK',
        'final_score': '0',
      }),
    );
  }

  static Future<void> showEventNotification(
      NotificationEvent event,
      ) async {
    String channelId = 'signalflow_general';
    String channelName = 'SignalFlow General';
    Importance importance = Importance.defaultImportance;
    Priority priority = Priority.defaultPriority;

    final String currentStatus = event.currentStatus.toUpperCase();

    // [2026-06-03 14:50 KST]
    // 상태 코드 한글 표시명 변환 (Convert status code to Korean display label)
    String statusDisplayName(String status) {
      if (status == 'ATTACK_STRONG') return '강한 공격';
      if (status == 'ATTACK_NORMAL') return '공격';
      if (status == 'WATCH_STRONG') return '강한 관찰';
      if (status.startsWith('WATCH')) return '관찰';
      if (status == 'RISK') return '위험';
      return status;
    }

    if (currentStatus.contains('ATTACK')) {
      channelId = 'signalflow_attack';
      channelName = 'SignalFlow ATTACK';
      importance = Importance.max;
      priority = Priority.high;
    } else if (currentStatus.contains('RISK')) {
      channelId = 'signalflow_risk';
      channelName = 'SignalFlow RISK';
      importance = Importance.high;
      priority = Priority.high;
    } else if (currentStatus.contains('WATCH')) {
      channelId = 'signalflow_watch';
      channelName = 'SignalFlow WATCH';
      importance = Importance.defaultImportance;
      priority = Priority.defaultPriority;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: importance,
      priority: priority,
    );

    final details = NotificationDetails(android: androidDetails);

    final String payload = jsonEncode({
      'ticker': event.ticker,
      'stock_name': event.stockName,
      'final_status': event.currentStatus,
      'final_score': event.finalScore.toString(),
    });

    await _plugin.show(
      event.ticker.hashCode,
      '${event.stockName} 상태 변화',
      '${statusDisplayName(event.prevStatus)} → ${statusDisplayName(event.currentStatus)} / ${event.finalScore}점',
      details,
      payload: payload,
    );
  }
}