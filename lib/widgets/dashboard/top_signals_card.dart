// File: top_signals_card.dart (관심종목 요약 카드)
// [Added by ChatGPT | 2026-05-22 13:40 KST]
// Insert Location: lib/widgets/dashboard/top_signals_card.dart 새 파일 생성

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/dashboard_summary.dart';
import '../../models/signal_history_item.dart';

class TopSignalsCard extends StatelessWidget {
  // [2026-05-24 02:55 KST]
  // 관심종목 요약 클릭 콜백 추가
  // (Add top signal tap callback)
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
  // [2026-05-24 02:55 KST]
  // 관심종목 요약 클릭 콜백
  // (Top signal tap callback)
  final void Function({
  required String ticker,
  required String stockName,
  }) onSignalTap;

  int _calculateScoreChange(
      String ticker,
      int currentScore,
      ) {
    final history = signalHistoryCache[ticker];

    if (history == null || history.length < 2) {
      return 0;
    }

    final previousScore = history[history.length - 2].finalScore;

    return currentScore - previousScore;
  }

  Widget _buildMiniTrendChart(
      String ticker,
      Color color,
      ) {
    final history = signalHistoryCache[ticker] ?? <SignalHistoryItem>[];

    final recent = history.length > 5
        ? history.sublist(history.length - 5)
        : history;

    final spots = recent.isEmpty
        ? <FlSpot>[
      const FlSpot(0, 50),
      const FlSpot(1, 50),
      const FlSpot(2, 50),
    ]
        : recent.asMap().entries.map(
          (entry) {
        return FlSpot(
          entry.key.toDouble(),
          entry.value.finalScore.toDouble(),
        );
      },
    ).toList();

    return SizedBox(
      width: 86,
      height: 38,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: 0,
          maxY: 100,
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2.2,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildSignalFlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '관심종목 요약',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (summary.topSignals.isEmpty)
            const Text('표시할 종목이 없습니다.')
          else
            ...summary.topSignals.map(
                  (signal) {
                final Color itemStatusColor = statusColor(signal.finalStatus);
                final bool isNewAttack =
                    signal.ticker == recentAttackTicker;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isNewAttack
                          ? const Color(0xFFEF4444).withValues(alpha: 0.60)
                          : itemStatusColor.withValues(alpha: 0.28),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        itemStatusColor.withValues(alpha: 0.10),
                        Theme.of(context).cardColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isNewAttack
                            ? const Color(0xFFEF4444).withValues(alpha: 0.42)
                            : itemStatusColor.withValues(alpha: 0.12),
                        blurRadius: isNewAttack ? 28 : 16,
                        spreadRadius: isNewAttack ? 3 : 1,
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    // [2026-05-24 02:45 KST]
                    // 관심종목 요약 클릭 시 대시보드 분석 결과 페이지 흐름 사용
                    // (Use dashboard analysis result flow when tapping top signal)
                    onTap: () {
                      onSignalTap(
                        ticker: signal.ticker,
                        stockName: signal.stockName,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${signal.stockName} (${signal.ticker})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: itemStatusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  signal.finalStatus,
                                  style: TextStyle(
                                    color: itemStatusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surface,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    signal.etfReason ?? 'ETF 영향 없음',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              _buildMiniTrendChart(
                                signal.ticker,
                                itemStatusColor,
                              ),
                              const SizedBox(width: 10),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                transitionBuilder: (child, animation) {
                                  return ScaleTransition(
                                    scale: animation,
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Builder(
                                  builder: (_) {
                                    final scoreChange = _calculateScoreChange(
                                      signal.ticker,
                                      signal.finalScore,
                                    );

                                    final bool isUp = scoreChange > 0;
                                    final bool isDown = scoreChange < 0;

                                    final Color deltaColor = isUp
                                        ? const Color(0xFFEF4444)
                                        : isDown
                                        ? const Color(0xFF3B82F6)
                                        : Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color ??
                                        Colors.grey;

                                    final String deltaText = scoreChange == 0
                                        ? ''
                                        : isUp
                                        ? ' (+$scoreChange)'
                                        : ' ($scoreChange)';

                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isUp)
                                          const Padding(
                                            padding: EdgeInsets.only(right: 4),
                                            child: Icon(
                                              Icons.arrow_drop_up,
                                              color: Color(0xFFEF4444),
                                              size: 22,
                                            ),
                                          ),
                                        if (isDown)
                                          const Padding(
                                            padding: EdgeInsets.only(right: 4),
                                            child: Icon(
                                              Icons.arrow_drop_down,
                                              color: Color(0xFF3B82F6),
                                              size: 22,
                                            ),
                                          ),
                                        Text(
                                          '${signal.finalScore}점$deltaText',
                                          key: ValueKey(
                                            '${signal.ticker}_${signal.finalScore}',
                                          ),
                                          style: TextStyle(
                                            color: deltaColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
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