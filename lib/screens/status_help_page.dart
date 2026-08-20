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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _StatusHelpHeader(colorScheme: colorScheme, theme: theme),
          const SizedBox(height: 14),
          const _StatusHelpCard(
            icon: Icons.trending_up,
            title: '공격',
            summary: '상승 흐름 가능성이 비교적 강한 후보',
            color: Color(0xFFEF4444),
            description:
                '장기·중기 흐름이 양호하고 단기 힘도 살아 있을 때 표시됩니다. 매수 명령이 아니라 다시 볼 가치가 있는 후보라는 의미입니다.',
          ),
          const _StatusHelpCard(
            icon: Icons.visibility,
            title: '관찰',
            summary: '흐름 전환 가능성을 확인할 구간',
            color: Color(0xFFF59E0B),
            description:
                '아직 강한 신호는 아니지만 현재가가 중기선 근처에 있거나 회복 여부를 확인해야 할 때 표시됩니다.',
          ),
          const _StatusHelpCard(
            icon: Icons.warning_amber_rounded,
            title: '위험',
            summary: '주의와 리스크 점검이 필요한 상태',
            color: Color(0xFF2563EB),
            description:
                '상승 흐름이 약해지거나 변동성이 커진 구간입니다. 신규 진입이나 비중 확대보다는 관망 관점으로 확인하는 편이 좋습니다.',
          ),
          const _StatusHelpCard(
            icon: Icons.near_me,
            title: '중기선 1% 이내 임박',
            summary: '중기선 회복 여부를 볼 수 있는 위치',
            color: Color(0xFF0F766E),
            description:
                '현재가가 중기선 바로 아래 1% 이내에 접근한 상태입니다. 종가 기준 회복 여부를 함께 확인하는 구간입니다.',
          ),
          const _StatusHelpCard(
            icon: Icons.history,
            title: '상태 변화',
            summary: '이전 상태와 현재 상태가 달라진 기록',
            color: Color(0xFF7C3AED),
            description: '예를 들어 관찰에서 공격으로 바뀌거나, 공격에서 위험으로 바뀌는 흐름을 확인할 수 있습니다.',
          ),
          const SizedBox(height: 8),
          _CautionBox(colorScheme: colorScheme, theme: theme),
        ],
      ),
    );
  }
}

class _StatusHelpHeader extends StatelessWidget {
  const _StatusHelpHeader({
    required this.colorScheme,
    required this.theme,
  });

  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '신호 상태를 이렇게 읽으면 됩니다',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '상태는 매수·매도 지시가 아니라 흐름을 빠르게 분류하기 위한 참고값입니다.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.68),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusHelpCard extends StatelessWidget {
  const _StatusHelpCard({
    required this.icon,
    required this.title,
    required this.summary,
    required this.color,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String summary;
  final Color color;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    _StatusPill(label: summary, color: color),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.48,
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
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
}

class _CautionBox extends StatelessWidget {
  const _CautionBox({
    required this.colorScheme,
    required this.theme,
  });

  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            color: colorScheme.error,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '최종 투자 판단은 사용자가 직접 해야 합니다. 신호 상태는 후보를 빠르게 확인하기 위한 참고 정보로만 사용하세요.',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
