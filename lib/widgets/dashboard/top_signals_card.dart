import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/dashboard_summary.dart';
import '../../models/signal_history_item.dart';

class TopSignalsCard extends StatelessWidget {
  const TopSignalsCard({
    super.key,
    required this.summary,
    required this.recentAttackTicker,
    required this.signalHistoryCache,
    required this.statusColor,
    required this.onSignalTap,
  });

  final DashboardSummary summary;
  final String? recentAttackTicker;
  final Map<String, List<SignalHistoryItem>> signalHistoryCache;
  final Color Function(String status) statusColor;
  final void Function({
    required String ticker,
    required String stockName,
  }) onSignalTap;

  int _calculateScoreChange(String ticker, int currentScore) {
    final history = signalHistoryCache[ticker];

    if (history == null || history.length < 2) {
      return 0;
    }

    final previousScore = history[history.length - 2].finalScore;
    return currentScore - previousScore;
  }

  Widget _buildMiniTrendChart(String ticker, Color color) {
    final history = signalHistoryCache[ticker] ?? <SignalHistoryItem>[];
    final recent =
        history.length > 5 ? history.sublist(history.length - 5) : history;

    final spots = recent.isEmpty
        ? <FlSpot>[
            const FlSpot(0, 50),
            const FlSpot(1, 50),
            const FlSpot(2, 50),
          ]
        : recent.asMap().entries.map((entry) {
            return FlSpot(
              entry.key.toDouble(),
              entry.value.finalScore.toDouble(),
            );
          }).toList();

    return SizedBox(
      width: 72,
      height: 30,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: 0,
          maxY: 100,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    if (status.startsWith('ATTACK')) return '공격';
    if (status.startsWith('WATCH')) return '관찰';
    if (status == 'RISK') return '위험';
    return '대기';
  }

  @override
  Widget build(BuildContext context) {
    return _buildSignalFlowCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '관심종목 변화',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '저장한 종목의 상태와 점수 흐름',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${summary.topSignals.length}개',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.54,
                      ),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (summary.topSignals.isEmpty)
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
                '표시할 관심종목 변화가 없습니다.',
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
            ...summary.topSignals.map((signal) {
              final itemStatusColor = statusColor(signal.finalStatus);
              final isNewAttack = signal.ticker == recentAttackTicker;
              final scoreChange = _calculateScoreChange(
                signal.ticker,
                signal.finalScore,
              );

              return _TopSignalChangeRow(
                ticker: signal.ticker,
                stockName: signal.stockName,
                status: _statusLabel(signal.finalStatus),
                score: signal.finalScore,
                scoreChange: scoreChange,
                color: itemStatusColor,
                isNewAttack: isNewAttack,
                trendChart:
                    _buildMiniTrendChart(signal.ticker, itemStatusColor),
                onTap: () {
                  onSignalTap(
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

class _TopSignalChangeRow extends StatelessWidget {
  const _TopSignalChangeRow({
    required this.ticker,
    required this.stockName,
    required this.status,
    required this.score,
    required this.scoreChange,
    required this.color,
    required this.isNewAttack,
    required this.trendChart,
    required this.onTap,
  });

  final String ticker;
  final String stockName;
  final String status;
  final int score;
  final int scoreChange;
  final Color color;
  final bool isNewAttack;
  final Widget trendChart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final deltaColor = scoreChange > 0
        ? const Color(0xFF16A34A)
        : scoreChange < 0
            ? const Color(0xFF2563EB)
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54);
    final deltaText = scoreChange == 0
        ? '변화 없음'
        : scoreChange > 0
            ? '+$scoreChange'
            : '$scoreChange';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isNewAttack
            ? color.withValues(alpha: 0.08)
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
                    ? color.withValues(alpha: 0.38)
                    : Theme.of(context).dividerColor.withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              children: [
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
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
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
                          _StatusPill(label: status, color: color),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                trendChart,
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$score점',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deltaText,
                      style: TextStyle(
                        color: deltaColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
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
