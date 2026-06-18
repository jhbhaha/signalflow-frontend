// File: signal_history_page.dart (상태 변화 히스토리 화면)
// Last Modified: 2026-06-13 15:55 KST (작성자: ChatGPT)
// Insert Location: lib/screens/signal_history_page.dart 전체 교체

import 'package:flutter/material.dart';

import '../models/signal_history_item.dart';
import '../services/api_service.dart';

class SignalHistoryPage extends StatefulWidget {
  const SignalHistoryPage({super.key});

  @override
  State<SignalHistoryPage> createState() => _SignalHistoryPageState();
}

class _SignalHistoryPageState extends State<SignalHistoryPage> {
  final ApiService _apiService = ApiService();

  late Future<List<SignalHistoryItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _apiService.fetchSignalHistory();
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = _apiService.fetchSignalHistory();
    });
  }

  // [Modified by ChatGPT | 2026-06-13 15:55 KST]
  // ATTACK_NORMAL, WATCH_WEAK 같은 세부 상태도 같은 계열 색상으로 처리
  Color _statusColor(String status) {
    final upper = status.toUpperCase();

    if (upper.startsWith('ATTACK')) {
      return const Color(0xFFEF4444);
    }

    if (upper.startsWith('WATCH')) {
      return const Color(0xFFF59E0B);
    }

    if (upper.startsWith('RISK')) {
      return const Color(0xFF3B82F6);
    }

    if (upper.startsWith('WAIT')) {
      return const Color(0xFF64748B);
    }

    return const Color(0xFF64748B);
  }

  String _displayPreviousStatus(String? status) {
    if (status == null || status.isEmpty || status == 'None') {
      return 'NEW';
    }
    return _displayStatusName(status);
  }

  // [Added by ChatGPT | 2026-06-13 15:55 KST]
  // 사용자에게 보이는 상태명을 한글 중심으로 정리
  String _displayStatusName(String status) {
    final upper = status.toUpperCase();

    switch (upper) {
      case 'ATTACK_STRONG':
        return '강한 공격';
      case 'ATTACK_NORMAL':
        return '공격';
      case 'WATCH_STRONG':
        return '강한 관찰';
      case 'WATCH_WEAK':
        return '약한 관찰';
      case 'RISK':
        return '위험';
      case 'WAIT':
        return '대기';
      default:
        return status;
    }
  }

  // [Added by ChatGPT | 2026-06-13 15:55 KST]
  // 현재 API에 상세 근거 필드가 없으므로 상태 기준 설명을 우선 표시
  String _statusMeaning(String status) {
    final upper = status.toUpperCase();

    if (upper.startsWith('ATTACK')) {
      return '장기·중기 흐름과 단기 힘이 비교적 양호한 구간입니다.';
    }

    if (upper.startsWith('WATCH')) {
      return '아직 강한 공격 신호는 아니지만 흐름 전환을 관찰할 구간입니다.';
    }

    if (upper.startsWith('RISK')) {
      return '흐름이 약해지거나 변동성이 커져 주의가 필요한 구간입니다.';
    }

    if (upper.startsWith('WAIT')) {
      return '뚜렷한 공격 조건이 부족해 대기하는 구간입니다.';
    }

    return '상태 변화가 기록된 구간입니다.';
  }

  Widget _buildSummaryCard(
      BuildContext context,
      List<SignalHistoryItem> items,
      ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final latest = items.first;
    final attackCount = items
        .where((e) => e.currentStatus.toUpperCase().startsWith('ATTACK'))
        .length;

    return Card(
      color: colorScheme.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '최근 상태 요약',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${latest.stockName} (${latest.ticker})',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatusBadge(
                  label: _displayStatusName(latest.currentStatus),
                  color: _statusColor(latest.currentStatus),
                ),
                const SizedBox(width: 8),
                Text(
                  '점수 ${latest.finalScore}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '최근 변화 ${items.length}건 · 공격 전환 ${attackCount}건',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
      BuildContext context,
      SignalHistoryItem item,
      ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _statusColor(item.currentStatus);

    return Card(
      color: colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.stockName} (${item.ticker})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_displayPreviousStatus(item.previousStatus)} → ${_displayStatusName(item.currentStatus)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _statusMeaning(item.currentStatus),
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.4,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ScoreChip(score: item.finalScore),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.timestamp,
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.55),
                          ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: FutureBuilder<List<SignalHistoryItem>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                '히스토리를 불러오지 못했습니다.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(
              child: Text('아직 상태 변화 히스토리가 없습니다.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildSummaryCard(context, items);
                }

                final item = items[index - 1];
                return _buildHistoryCard(context, item);
              },
            ),
          );
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final num score;

  const _ScoreChip({
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '점수 $score',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface.withOpacity(0.75),
        ),
      ),
    );
  }
}