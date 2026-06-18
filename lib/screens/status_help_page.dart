// File: status_help_page.dart (상태 설명 페이지)
// Last Modified: 2026-06-13 15:40 KST
// Insert Location: lib/screens/status_help_page.dart

import 'package:flutter/material.dart';

class StatusHelpPage extends StatelessWidget {
  const StatusHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('상태 설명'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusHelpCard(
            icon: Icons.trending_up,
            title: '공격',
            color: Colors.redAccent,
            description:
            '상승 흐름 가능성이 비교적 강한 상태입니다.\n\n'
                '장기·중기 흐름이 양호하고 단기 힘도 살아 있을 때 표시됩니다.\n'
                '다만 매수 명령이 아니라 다시 볼 가치가 있는 후보라는 의미입니다.',
          ),
          const SizedBox(height: 12),
          _StatusHelpCard(
            icon: Icons.visibility,
            title: '관찰',
            color: Colors.orangeAccent,
            description:
            '아직 강한 신호는 아니지만 흐름 전환 가능성을 지켜볼 필요가 있는 상태입니다.\n\n'
                '예를 들어 현재가가 중기선 근처에 있거나 회복 여부를 확인해야 할 때 표시됩니다.',
          ),
          const SizedBox(height: 12),
          _StatusHelpCard(
            icon: Icons.warning_amber_rounded,
            title: '위험',
            color: Colors.blueGrey,
            description:
            '상승 흐름이 약해지거나 변동성이 커져 주의가 필요한 상태입니다.\n\n'
                '신규 진입이나 비중 확대보다는 관망 또는 리스크 점검이 필요한 구간입니다.',
          ),
          const SizedBox(height: 12),
          _StatusHelpCard(
            icon: Icons.near_me,
            title: '중기선 1% 이내 임박',
            color: Colors.teal,
            description:
            '현재가가 중기선 바로 아래 1% 이내에 접근한 상태입니다.\n\n'
                '중기선을 회복하면 흐름이 좋아질 수 있으므로 종가 기준 회복 여부를 확인하는 구간입니다.',
          ),
          const SizedBox(height: 12),
          _StatusHelpCard(
            icon: Icons.history,
            title: '상태 변화',
            color: Colors.deepPurpleAccent,
            description:
            '이전 상태와 현재 상태가 달라진 경우 기록되는 정보입니다.\n\n'
                '예를 들어 관찰에서 공격으로 바뀌거나, 공격에서 위험으로 바뀌는 흐름을 확인할 수 있습니다.',
          ),
          const SizedBox(height: 20),
          Text(
            '주의사항',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '이 앱의 상태 표시는 투자 판단을 돕기 위한 참고 정보입니다. '
                '매수나 매도 지시가 아니며, 최종 판단은 사용자가 직접 해야 합니다.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusHelpCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final String description;

  const _StatusHelpCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      color: colorScheme.surfaceContainerHighest,
      shadowColor: colorScheme.shadow.withOpacity(0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 30,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      color: colorScheme.onSurface.withOpacity(0.72),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}