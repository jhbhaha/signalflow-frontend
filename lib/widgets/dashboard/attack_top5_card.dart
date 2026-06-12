// File: attack_top5_card.dart (ATTACK TOP5 카드)
// [Added by ChatGPT | 2026-05-21 18:55 KST]
// Insert Location: lib/widgets/dashboard/attack_top5_card.dart 새 파일 생성

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
        .where(
          (item) => item.finalStatus.startsWith('ATTACK'),
    )
        .toList();

    attackSignals.sort(
          (a, b) => b.finalScore.compareTo(a.finalScore),
    );

    final top5 = attackSignals.take(5).toList();

    return _buildSignalFlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.flash_on,
                color: Color(0xFFF59E0B),
              ),
              SizedBox(width: 8),
              Text(
                '실시간 ATTACK TOP5',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (top5.isEmpty)
            const Text(
              '현재 ATTACK 상태 종목이 없습니다.',
            ),
          ...top5.asMap().entries.map(
                (entry) {
              final int rank = entry.key + 1;
              final signal = entry.value;

              final bool isNewAttack =
                  signal.ticker == recentAttackTicker;

              final bool shouldPulse = isNewAttack;

              return TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0.96,
                  end: 1.0,
                ),
                duration: Duration(
                  milliseconds: 420 + (rank * 80),
                ),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    onAttackTap(
                      ticker: signal.ticker,
                      stockName: signal.stockName,
                    );
                  },
                  child: AnimatedContainer(
                    duration: Duration(
                      milliseconds: shouldPulse ? 650 : 900,
                    ),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: shouldPulse
                          ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                          : Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        if (isNewAttack)
                          BoxShadow(
                            color: const Color(0xFFEF4444)
                                .withValues(alpha: 0.45),
                            blurRadius: isNewAttack ? 32 : 0,
                            spreadRadius: isNewAttack ? 4 : 0,
                          ),
                      ],
                      border: Border.all(
                        color: isNewAttack
                            ? const Color(0xFFEF4444)
                            .withValues(alpha: 0.55)
                            : const Color(0xFFF59E0B)
                            .withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: shouldPulse
                                ? const Color(0xFFEF4444)
                                .withValues(alpha: 0.28)
                                : const Color(0xFFF59E0B)
                                .withValues(alpha: 0.25),
                          ),
                          child: Text(
                            '$rank',
                            style: const TextStyle(
                              color: Color(0xFFF59E0B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                signal.stockName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                signal.ticker,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.end,
                          children: [
                            AnimatedSwitcher(
                              duration:
                              const Duration(milliseconds: 350),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                '${signal.finalScore}점',
                                key: ValueKey(
                                  'attack_${signal.ticker}_${signal.finalScore}',
                                ),
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              signal.finalStatus,
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignalFlowCard({
    required Widget child,
  }) {
    return Builder(
      builder: (context) {
        final bool isDark =
            Theme.of(context).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Theme.of(context)
                  .dividerColor
                  .withValues(alpha: 0.20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark ? 0.25 : 0.08,
                ),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        );
      },
    );
  }
}