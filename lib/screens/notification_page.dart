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
    if (status.startsWith('ATTACK')) return const Color(0xFFDC2626);
    if (status.startsWith('WATCH')) return const Color(0xFFD97706);
    if (status == 'RISK') return const Color(0xFF2563EB);
    return const Color(0xFF64748B);
  }

  IconData _statusIcon(String status) {
    if (status.startsWith('ATTACK')) return Icons.trending_up_rounded;
    if (status.startsWith('WATCH')) return Icons.visibility_rounded;
    if (status == 'RISK') return Icons.warning_amber_rounded;
    return Icons.history_rounded;
  }

  String _statusLabel(String status) {
    if (status.startsWith('ATTACK')) return '\uACF5\uACA9';
    if (status.startsWith('WATCH')) return '\uAD00\uCC30';
    if (status == 'RISK') return '\uC704\uD5D8';
    return '\uB300\uAE30';
  }

  Future<void> _load() async {
    try {
      final data = await _api.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _events = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _api.markNotificationsAsRead();
      await _load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '\uBAA8\uB4E0 \uC54C\uB9BC\uC744 \uC77D\uC74C \uCC98\uB9AC\uD588\uC2B5\uB2C8\uB2E4.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '\uC77D\uC74C \uCC98\uB9AC\uC5D0 \uC2E4\uD328\uD588\uC2B5\uB2C8\uB2E4. $error'),
        ),
      );
    }
  }

  Widget _buildNotificationCard(NotificationEvent event) {
    final color = _statusColor(event.currentStatus);
    final unread = !event.read;

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: unread
                ? color.withValues(alpha: 0.34)
                : Theme.of(context).dividerColor.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: unread ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(999),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        unread ? 'NEW' : 'READ',
                        style: TextStyle(
                          color: unread
                              ? color
                              : Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    event.ticker,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildBadge(
                        '${_statusLabel(event.prevStatus)} \u2192 ${_statusLabel(event.currentStatus)}',
                        color,
                      ),
                      _buildBadge('${event.finalScore}\uC810', color),
                      Text(
                        event.createdAt,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 40,
            ),
            const SizedBox(height: 14),
            Text(
              '\uC54C\uB9BC \uAE30\uB85D\uC774 \uC5C6\uC2B5\uB2C8\uB2E4',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\uC0C8\uB85C\uC6B4 ATTACK / WATCH \uC0C1\uD0DC \uBCC0\uD654\uAC00 \uBC1C\uC0DD\uD558\uBA74\n\uC774\uACF3\uC5D0 \uD45C\uC2DC\uB429\uB2C8\uB2E4.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
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
      appBar: AppBar(
        title: const Text('\uC54C\uB9BC \uAE30\uB85D'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '\uC804\uCCB4 \uC77D\uC74C \uCC98\uB9AC',
            icon: const Icon(Icons.done_all_rounded),
            onPressed: _events.isEmpty ? null : _markAllAsRead,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(_events[index]);
                    },
                  ),
                ),
    );
  }
}
