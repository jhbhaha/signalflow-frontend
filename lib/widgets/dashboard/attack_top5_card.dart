import 'package:flutter/material.dart';

import '../../models/dashboard_summary.dart';

class AttackTop5Card extends StatelessWidget {
  const AttackTop5Card({
    super.key,
    required this.summary,
    required this.recentAttackTicker,
    required this.onAttackTap,
  });

  final DashboardSummary summary;
  final String? recentAttackTicker;
  final Future<void> Function({
    required String ticker,
    required String stockName,
  }) onAttackTap;

  @override
  Widget build(BuildContext context) {
    final attackSignals = summary.topSignals
        .where((item) => item.finalStatus.startsWith('ATTACK'))
        .toList()
      ..sort((a, b) => b.finalScore.compareTo(a.finalScore));

    final top5 = attackSignals.take(5).toList();

    return _buildSignalFlowCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.leaderboard_rounded,
                  color: Color(0xFFEF4444),
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '공격 후보 랭킹',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '전체 후보 중 점수가 높은 순서',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _CountPill(count: top5.length),
            ],
          ),
          const SizedBox(height: 15),
          if (top5.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '현재 공격 상태 종목이 없습니다.',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.62),
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ...top5.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final signal = entry.value;
              final isNewAttack = signal.ticker == recentAttackTicker;

              return _AttackRankingRow(
                rank: rank,
                ticker: signal.ticker,
                stockName: signal.stockName,
                score: signal.finalScore,
                isNewAttack: isNewAttack,
                onTap: () {
                  onAttackTap(
                    ticker: signal.ticker,
                    stockName: signal.stockName,
                  );
                },
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSignalFlowCard({
    required BuildContext context,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Theme.of(context).dividerColor.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _AttackRankingRow extends StatelessWidget {
  const _AttackRankingRow({
    required this.rank,
    required this.ticker,
    required this.stockName,
    required this.score,
    required this.isNewAttack,
    required this.onTap,
  });

  final int rank;
  final String ticker;
  final String stockName;
  final int score;
  final bool isNewAttack;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const attackColor = Color(0xFFEF4444);
    final rankColor = rank == 1
        ? const Color(0xFFF59E0B)
        : rank <= 3
            ? const Color(0xFFEF4444)
            : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isNewAttack
            ? attackColor.withValues(alpha: 0.08)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isNewAttack
                    ? attackColor.withValues(alpha: 0.40)
                    : Theme.of(context).dividerColor.withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: rankColor.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: rankColor,
                      fontWeight: FontWeight.w900,
                    ),
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
                              stockName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (isNewAttack) ...[
                            const SizedBox(width: 6),
                            const _NewPill(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ticker,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.54),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 58,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: attackColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    '$score점',
                    style: const TextStyle(
                      color: attackColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
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

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count개',
        style: const TextStyle(
          color: Color(0xFFEF4444),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NewPill extends StatelessWidget {
  const _NewPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'NEW',
        style: TextStyle(
          color: Color(0xFFEF4444),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
