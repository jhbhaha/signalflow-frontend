// File: notification_center_page.dart (알림 센터 화면)
// Last Modified: 2026-05-12 14:10 KST (작성자: ChatGPT)
// Insert Location: G:\stockmarket_frontend\lib\screens\notification_center_page.dart 새 파일 생성

import 'package:flutter/material.dart';

import '../models/notification_event.dart';
import '../services/api_service.dart';
import 'stock_detail_page.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> {
  final ApiService _apiService = ApiService();

  late Future<List<NotificationEvent>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _apiService.fetchNotifications();
  }

  Future<void> _refresh() async {
    setState(() {
      _notificationsFuture = _apiService.fetchNotifications();
    });
  }

  Future<void> _markAllRead() async {
    await _apiService.markNotificationsAsRead();
    await _refresh();
  }

  Color _statusColor(String status) {
    if (status.startsWith('ATTACK')) {
      return Colors.redAccent;
    }

    if (status == 'RISK') {
      return Colors.orange;
    }

    if (status == 'WATCH') {
      return Colors.yellow;
    }

    return Colors.white70;
  }

  void _openStockDetail(NotificationEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StockDetailPage(
          ticker: event.ticker,
          stockName: event.stockName,
          finalStatus: event.currentStatus,
          finalScore: event.finalScore.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 실시간 시그널 알림 제목
        // (Realtime signal alert title)
        title: const Text('시그널'),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('모두 읽음'),
          ),
        ],
      ),
      body: FutureBuilder<List<NotificationEvent>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                '알림을 불러오지 못했습니다.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(
              child: Text('현재 활성 시그널이 없습니다.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final event = items[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () => _openStockDetail(event),
                    leading: Icon(
                      event.read
                          ? Icons.notifications_none
                          : Icons.notifications_active,
                      color: event.read
                          ? Colors.white38
                          : _statusColor(event.currentStatus),
                    ),
                    title: Text(
                      '${event.stockName} (${event.ticker})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.message),
                          const SizedBox(height: 6),
                          Text(
                            '${event.prevStatus} → ${event.currentStatus} / ${event.finalScore}점',
                            style: TextStyle(
                              color: _statusColor(event.currentStatus),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.createdAt,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}