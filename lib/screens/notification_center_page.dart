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

  Color _statusColor(BuildContext context, String status) {
    if (status.startsWith('ATTACK')) return const Color(0xFFDC2626);
    if (status.startsWith('WATCH')) return const Color(0xFFD97706);
    if (status == 'RISK') return const Color(0xFF2563EB);
    return Theme.of(context).colorScheme.primary;
  }

  IconData _statusIcon(String status) {
    if (status.startsWith('ATTACK')) return Icons.trending_up_rounded;
    if (status.startsWith('WATCH')) return Icons.visibility_rounded;
    if (status == 'RISK') return Icons.warning_amber_rounded;
    return Icons.schedule_rounded;
  }

  String _statusLabel(String status) {
    if (status.startsWith('ATTACK')) return '공격';
    if (status.startsWith('WATCH')) return '관찰';
    if (status == 'RISK') return '위험';
    return '대기';
  }

  Future<void> _openStockDetail(NotificationEvent event) async {
    try {
      if (!event.read) {
        await _apiService.markNotificationAsRead(event.id);
        await _refresh();
      }
    } catch (_) {
      // 상세 이동은 막지 않습니다.
    }

    if (!mounted) return;

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

  Widget _buildSummaryCard(List<NotificationEvent> items) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unread = items.where((item) => !item.read).length;
    final attack =
        items.where((item) => item.currentStatus.startsWith('ATTACK')).length;
    final risk = items.where((item) => item.currentStatus == 'RISK').length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '시그널 알림',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      unread > 0
                          ? '확인하지 않은 변화가 $unread개 있습니다.'
                          : '새로 확인할 신호는 없습니다.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.68),
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetricChip(
                label: '안읽음',
                value: '$unread',
                color: unread > 0
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF64748B),
              ),
              _buildMetricChip(
                label: '공격',
                value: '$attack',
                color: const Color(0xFFDC2626),
              ),
              _buildMetricChip(
                label: '위험',
                value: '$risk',
                color: const Color(0xFF2563EB),
              ),
              _buildMetricChip(
                label: '전체',
                value: '${items.length}',
                color: colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required String value,
    required Color color,
  }) {
    final hasValue = value.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        hasValue ? '$label $value' : label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationEvent event) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = _statusColor(context, event.currentStatus);
    final unread = !event.read;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openStockDetail(event),
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: unread
                ? color.withValues(alpha: 0.06)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: unread
                  ? color.withValues(alpha: 0.28)
                  : colorScheme.outlineVariant.withValues(alpha: 0.34),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: unread ? 0.14 : 0.09),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _statusIcon(event.currentStatus),
                      color: unread ? color : color.withValues(alpha: 0.72),
                      size: 21,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 2,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: unread ? 0.24 : 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 13),
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
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ReadStatePill(unread: unread, color: color),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      event.ticker,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.58),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      event.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.82),
                        height: 1.42,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildMetricChip(
                          label:
                              '${_statusLabel(event.prevStatus)} → ${_statusLabel(event.currentStatus)}',
                          value: '',
                          color: color,
                        ),
                        _buildMetricChip(
                          label: '점수',
                          value: '${event.finalScore}',
                          color: color,
                        ),
                        Text(
                          event.createdAt,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.54),
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
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return Container(
          height: index == 0 ? 118 : 126,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(
                  alpha: index == 0 ? 0.72 : 0.50,
                ),
            borderRadius: BorderRadius.circular(index == 0 ? 20 : 18),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.64),
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
        title: const Text('시그널'),
        actions: [
          IconButton(
            tooltip: '모두 읽음',
            onPressed: _markAllRead,
            icon: const Icon(Icons.done_all_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<NotificationEvent>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return _buildEmptyState(
              icon: Icons.cloud_off_rounded,
              title: '알림을 불러오지 못했습니다',
              message: '${snapshot.error}',
            );
          }

          final items = snapshot.data ?? <NotificationEvent>[];

          if (items.isEmpty) {
            return _buildEmptyState(
              icon: Icons.notifications_none_rounded,
              title: '현재 활성 시그널이 없습니다',
              message: '상태 변화가 생기면 이곳에서 바로 확인할 수 있습니다.',
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) return _buildSummaryCard(items);
                return _buildNotificationCard(items[index - 1]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ReadStatePill extends StatelessWidget {
  const _ReadStatePill({
    required this.unread,
    required this.color,
  });

  final bool unread;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textColor = unread
        ? color
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.48);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: unread ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        unread ? 'NEW' : 'READ',
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
