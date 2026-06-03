// File: notification_page.dart (알림 화면)
// [Modified by ChatGPT | 2026-05-08 17:30 KST]
// SignalFlow 다크 알림 카드 스타일 적용 (Apply SignalFlow dark notification card style)
// Insert Location: G:\stockmarket_frontend\lib\screens\notification_page.dart 전체 교체

import 'package:flutter/material.dart';
import '../models/notification_event.dart';
import '../services/api_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final ApiService _api = ApiService();
  List<NotificationEvent> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Color _statusColor(String status) {
    if (status.startsWith('ATTACK')) return const Color(0xFF22C55E);
    if (status.startsWith('WATCH')) return const Color(0xFFF59E0B);
    if (status == 'RISK') return const Color(0xFFEF4444);
    return const Color(0xFF64748B);
  }

  IconData _statusIcon(String status) {
    if (status.startsWith('ATTACK')) return Icons.trending_up;
    if (status.startsWith('WATCH')) return Icons.visibility;
    if (status == 'RISK') return Icons.warning_amber_rounded;
    return Icons.history;
  }

  Future<void> _load() async {
    try {
      final data = await _api.fetchNotifications();

      if (!mounted) return;

      setState(() {
        _events = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
    }
  }

  // 전체 알림 읽음 처리
  // (Mark all notifications as read)
  Future<void> _markAllAsRead() async {
    try {
      await _api.markNotificationsAsRead();
      await _load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 알림을 읽음 처리했습니다.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('읽음 처리에 실패했습니다. $e'),
        ),
      );
    }
  }

  Widget _buildNotificationCard(NotificationEvent event) {
    final Color color = _statusColor(event.currentStatus);
    final bool unread = !event.read;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: unread ? 0.45 : 0.20),
        ),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: unread ? 0.16 : 0.08),
            const Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: unread ? 0.18 : 0.08),
            blurRadius: unread ? 18 : 10,
            spreadRadius: unread ? 1 : 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(
                _statusIcon(event.currentStatus),
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.stockName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${event.prevStatus} → ${event.currentStatus}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.message,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${event.finalScore}점',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        unread ? 'NEW' : 'READ',
                        style: TextStyle(
                          color: unread ? color : Colors.white38,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('알림 기록'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '전체 읽음 처리',
            icon: const Icon(Icons.done_all),
            onPressed: _events.isEmpty ? null : _markAllAsRead,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
          ? Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 28,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF94A3B8),
                  size: 34,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                '알림 기록이 없습니다',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                '새로운 ATTACK / WATCH 상태 변화가 발생하면\n이곳에 표시됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _events.length,
          itemBuilder: (context, index) {
            final event = _events[index];
            return _buildNotificationCard(event);
          },
        ),
      ),
    );
  }
}