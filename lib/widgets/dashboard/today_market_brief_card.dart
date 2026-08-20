import 'package:flutter/material.dart';

import '../../models/dashboard_summary.dart';
import '../../models/recommendation_item.dart';

class TodayMarketBriefCard extends StatelessWidget {
  const TodayMarketBriefCard({
    super.key,
    required this.summary,
    required this.recommendations,
    required this.onBestTap,
    required this.onSignalTap,
  });

  final DashboardSummary summary;
  final List<RecommendationItem> recommendations;
  final VoidCallback onBestTap;
  final void Function({
    required String ticker,
    required String stockName,
  }) onSignalTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final topSignals = [...summary.topSignals]
      ..sort((a, b) => b.finalScore.compareTo(a.finalScore));
    final visibleSignals = topSignals.take(3).toList();
    final confidence = topSignals.isEmpty ? 0 : topSignals.first.finalScore;
    final recommendationCount =
        recommendations.isNotEmpty ? recommendations.length : topSignals.length;
    final isGoodAttackDay = summary.attackCount >= summary.riskCount;
    final marketColor =
        isGoodAttackDay ? const Color(0xFF16A34A) : const Color(0xFFF59E0B);
    final marketText = isGoodAttackDay ? '공격하기 좋은 날' : '선별 관찰이 필요한 날';

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: marketColor.withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.22 : 0.06,
            ),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: marketColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isGoodAttackDay
                            ? Icons.trending_up_rounded
                            : Icons.visibility_rounded,
                        color: marketColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '오늘의 시장',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            marketText,
                            style: TextStyle(
                              color: marketColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: '가장 좋은 종목 보기',
                      onPressed: onBestTap,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _BriefMetric(
                        label: 'AI 신뢰도',
                        value: '$confidence점',
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _BriefMetric(
                        label: '추천 종목',
                        value: '$recommendationCount개 발견',
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _BriefDivider(color: colorScheme.outlineVariant),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(
                  icon: Icons.local_fire_department_rounded,
                  title: '지금 보기 좋은 종목',
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(height: 12),
                if (visibleSignals.isEmpty)
                  Text(
                    '아직 표시할 추천 종목이 없습니다.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  ...visibleSignals.map(
                    (signal) => _SignalBriefRow(
                      name: signal.stockName,
                      ticker: signal.ticker,
                      score: signal.finalScore,
                      color: _statusColor(signal.finalStatus),
                      onTap: () => onSignalTap(
                        ticker: signal.ticker,
                        stockName: signal.stockName,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _BriefDivider(color: colorScheme.outlineVariant),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(
                  icon: Icons.star_rounded,
                  title: '내 관심종목',
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _WatchBriefPill(
                        label: '상승 가능성',
                        value: '${summary.attackCount}개',
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _WatchBriefPill(
                        label: '관찰 필요',
                        value: '${summary.watchCount}개',
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    if (status.startsWith('ATTACK')) return const Color(0xFF16A34A);
    if (status.startsWith('WATCH')) return const Color(0xFFF59E0B);
    if (status == 'RISK') return const Color(0xFF2563EB);
    return const Color(0xFF64748B);
  }
}

class _BriefMetric extends StatelessWidget {
  const _BriefMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: 0.56,
                  ),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

class _SignalBriefRow extends StatelessWidget {
  const _SignalBriefRow({
    required this.name,
    required this.ticker,
    required this.score,
    required this.color,
    required this.onTap,
  });

  final String name;
  final String ticker;
  final int score;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ticker,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.52),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$score점',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WatchBriefPill extends StatelessWidget {
  const _WatchBriefPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: 0.58,
                  ),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _BriefDivider extends StatelessWidget {
  const _BriefDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      color: color.withValues(alpha: 0.42),
    );
  }
}
