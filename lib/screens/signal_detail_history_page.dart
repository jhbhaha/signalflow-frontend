// File: signal_detail_history_page.dart (종목 상세 상태 흐름 화면)
// [Added by ChatGPT | 2026-05-14 17:10 KST]
// Insert Location: lib/screens/signal_detail_history_page.dart 새 파일 생성

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/signal_history_item.dart';
import '../services/api_service.dart';

class SignalDetailHistoryPage extends StatefulWidget {
  final String ticker;
  final String stockName;

  const SignalDetailHistoryPage({
    super.key,
    required this.ticker,
    required this.stockName,
  });

  @override
  State<SignalDetailHistoryPage> createState() =>
      _SignalDetailHistoryPageState();
}

class _SignalDetailHistoryPageState
    extends State<SignalDetailHistoryPage> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;

  List<SignalHistoryItem> _items = <SignalHistoryItem>[];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final items =
      await _apiService.fetchSignalHistoryByTicker(
        ticker: widget.ticker,
      );

      if (!mounted) return;

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
        '상태 변화 히스토리를 불러오지 못했습니다.\n$e';
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    // 한국 주식 시장 기준 상태 색상 적용
    // 상승=빨강 / 위험=파랑
    if (status.startsWith('ATTACK')) {
      return const Color(0xFFEF4444);
    }

    if (status.startsWith('WATCH')) {
      return const Color(0xFFF59E0B);
    }

    if (status == 'RISK') {
      return const Color(0xFF3B82F6);
    }

    return const Color(0xFF64748B);
  }

  // timestamp 표시 포맷 변환
  // (Format timestamp for display)
  String _formatTimestamp(String raw) {
    try {
      final dt = DateTime.parse(raw);

      final month =
      dt.month.toString().padLeft(2, '0');

      final day =
      dt.day.toString().padLeft(2, '0');

      final hour =
      dt.hour.toString().padLeft(2, '0');

      final minute =
      dt.minute.toString().padLeft(2, '0');

      return '$month/$day $hour:$minute';
    } catch (_) {
      return raw;
    }
  }

  // [Added by ChatGPT | 2026-05-14 17:45 KST]
// 현재 상태 Hero Header 카드
// (Current signal hero header card)
  Widget _buildHeroHeader() {
    if (_items.isEmpty) {
      return const SizedBox.shrink();
    }

    final latest = _items.last;

    final color =
    _statusColor(latest.currentStatus);

    String flowText = '흐름 관찰 필요';

    if (latest.currentStatus.startsWith('ATTACK')) {
      flowText = '강한 상승 흐름';
    } else if (latest.currentStatus.startsWith('WATCH')) {
      flowText = '상승 전환 감시';
    } else if (latest.currentStatus == 'RISK') {
      flowText = '위험 구간 진입';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.28),
            Theme.of(context).cardColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 22,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            widget.stockName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius:
                  BorderRadius.circular(999),
                ),
                child: Text(
                  latest.currentStatus,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Text(
                '${latest.finalScore}점',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            flowText,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreChart() {
    final recent = _items.length > 15
        ? _items.sublist(_items.length - 15)
        : _items;

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

    final latestStatus = recent.isEmpty
        ? 'WAIT'
        : recent.last.currentStatus;

    final chartColor = _statusColor(latestStatus);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '최근 점수 흐름',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: chartColor.withValues(alpha: 0.14),
                  borderRadius:
                  BorderRadius.circular(999),
                  border: Border.all(
                    color: chartColor.withValues(alpha: 0.28),
                  ),
                ),
                child: Text(
                  latestStatus,
                  style: TextStyle(
                    color: chartColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                // [2026-06-15 15:30 KST]
                // 점수 범위에 따라 Y축 자동 조정
                minY: 0,
                maxY: 10,

                // 상태 구간 배경 가이드 영역
                // (Signal status range background guides)
                rangeAnnotations: RangeAnnotations(
                  horizontalRangeAnnotations: [
                    HorizontalRangeAnnotation(
                      y1: 4,
                      y2: 10,
                      color: Color(0xFFEF4444)
                          .withValues(alpha: 0.05),
                    ),

                    HorizontalRangeAnnotation(
                      y1: 3,
                      y2: 4,
                      color: Color(0xFFF59E0B)
                          .withValues(alpha: 0.04),
                    ),

                    HorizontalRangeAnnotation(
                      y1: 0,
                      y2: 3,
                      color: Color(0xFF3B82F6)
                          .withValues(alpha: 0.04),
                    ),
                  ],
                ),

                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.15),
                      strokeWidth: 1,
                    );
                  },
                ),

                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withValues(alpha: 0.7),
                          ),
                        );
                      },
                    ),
                  ),

                  // [2026-06-15 16:00 KST]
                  // X축 날짜 표시
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,

                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= recent.length) {
                          return const SizedBox.shrink();
                        }

                        // 너무 많으면 3개 간격으로만 표시
                        if (recent.length > 8 && index % 3 != 0) {
                          return const SizedBox.shrink();
                        }

                        final timestamp =
                        DateTime.tryParse(
                          recent[index].timestamp,
                        );

                        if (timestamp == null) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${timestamp.month}/${timestamp.day}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),

                borderData: FlBorderData(show: false),

                lineTouchData: LineTouchData(
                  enabled: true,

                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 12,

                    getTooltipItems: (spots) {
                      return spots.map(
                            (spot) {
                          final item =
                          recent[spot.x.toInt()];

                          final color =
                          _statusColor(
                            item.currentStatus,
                          );

                          return LineTooltipItem(
                            '${item.currentStatus}\n'
                                '${item.finalScore}점\n'
                                '${_formatTimestamp(item.timestamp)}',
                            TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                      ).toList();
                    },
                  ),
                ),

                lineBarsData: [
                  LineChartBarData(
                    showingIndicators: spots.asMap().entries
                        .where(
                          (entry) {
                        final index = entry.key;

                        if (index == 0) {
                          return false;
                        }

                        final prev =
                            recent[index - 1].currentStatus;

                        final current =
                            recent[index].currentStatus;

                        return prev != current;
                      },
                    )
                        .map((e) => e.key)
                        .toList(),
                    spots: spots,
                    // [2026-06-15 16:00 KST]
                    isCurved: false,
                    color: chartColor,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter:
                          (spot, percent, bar, index) {

                        final current =
                            recent[index].currentStatus;

                        final previous =
                        index > 0
                            ? recent[index - 1].currentStatus
                            : '';

                        final bool isAttackEntry =
                            !previous.startsWith('ATTACK') &&
                                current.startsWith('ATTACK');

                        final color =
                        _statusColor(current);

                        return FlDotCirclePainter(
                          radius: isAttackEntry ? 7 : 4,

                          color: color,

                          strokeWidth:
                          isAttackEntry ? 3 : 2,

                          strokeColor:
                          isAttackEntry
                              ? const Color(0xFFEF4444)
                              : Theme.of(context).colorScheme.onSurface,
                        );
                      },
                    ),

                    belowBarData: BarAreaData(
                      show: true,
                      color: chartColor.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    if (_items.isEmpty) {
      return const SizedBox.shrink();
    }

    final reversed = _items.reversed.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '상태 변화 Timeline',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 16),

          ...reversed.map(
                (item) {
              final color = _statusColor(item.currentStatus);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: color.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.previousStatus ?? 'NEW'} → ${item.currentStatus}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            '${item.finalScore}점',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Text(
                      _formatTimestamp(item.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stockName),
      ),
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,

      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _errorMessage != null
          ? Center(
        child: Text(
          _errorMessage!,
          textAlign: TextAlign.center,
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeroHeader(),

            const SizedBox(height: 16),

            _buildScoreChart(),

            const SizedBox(height: 16),

            _buildTimeline(),
          ],
        ),
      ),
    );
  }
}