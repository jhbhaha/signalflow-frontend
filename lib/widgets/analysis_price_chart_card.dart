// File: analysis_price_chart_card.dart (분석 가격 차트 카드)
// [Modified by ChatGPT | 2026-05-28 21:35 KST]
// Insert Location: lib/widgets/analysis_price_chart_card.dart 전체 교체

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/price_chart_point.dart';

class AnalysisPriceChartCard extends StatelessWidget {
  final List<PriceChartPoint> items;

  const AnalysisPriceChartCard({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('차트 데이터가 없습니다.'),
        ),
      );
    }

    final minPrice = items.map((e) => e.close).reduce((a, b) => a < b ? a : b);
    final maxPrice = items.map((e) => e.close).reduce((a, b) => a > b ? a : b);
    // [2026-06-11 22:10 KST]
    // 라이트/다크 모드에 맞게 차트 텍스트와 종가 라인 색상 적용 (Apply theme-aware chart text and close price line colors)
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    final Color chartTextColor =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    final Color closeLineColor =
    isDark ? Colors.white : const Color(0xFF111827);

    // [2026-05-29 00:35 KST]
    // 한국식 가격 표시용 콤마 포맷 함수 (Comma formatter for Korean stock prices)

    String formatPrice(double value) {
      return value
          .round()
          .toString()
          .replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
            (match) => ',',
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // [2026-05-29 00:20 KST]
              // 차트 제목 추가 (Add chart title)

              Text(
                '최근 90거래일 가격 및 이동평균선',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _LegendItem(color: closeLineColor, label: '종가'),
                  const _LegendItem(color: Color(0xFFEF4444), label: 'MA5'),
                  const _LegendItem(color: Color(0xFFF59E0B), label: 'MA20 기준선'),
                  const _LegendItem(color: Color(0xFF3B82F6), label: 'MA60'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LineChart(
                  LineChartData(
                    minY: minPrice * 0.98,
                    maxY: maxPrice * 1.02,
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),

                      // [2026-05-29 00:20 KST]
                      // X축 날짜 표시 (Show date labels on X axis)
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 15,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();

                            if (index < 0 || index >= items.length) {
                              return const SizedBox.shrink();
                            }

                            final date = items[index].date;

                            if (date.length < 7) {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                date.substring(5),
                                style: TextStyle(
                                  color: chartTextColor,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              formatPrice(value),
                              style: TextStyle(
                                color: chartTextColor,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      _line(
                        values: items.map((e) => e.close).toList(),
                        color: closeLineColor,
                      ),
                      _line(
                        values: items.map((e) => e.ma5).toList(),
                        color: const Color(0xFFEF4444),
                      ),
                      _line(
                        values: items.map((e) => e.ma20).toList(),
                        color: const Color(0xFFF59E0B),
                      ),
                      _line(
                        values: items.map((e) => e.ma60).toList(),
                        color: const Color(0xFF3B82F6),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LineChartBarData _line({
    required List<double?> values,
    required Color color,
  }) {
    final spots = <FlSpot>[];

    for (int i = 0; i < values.length; i++) {
      final value = values[i];

      if (value != null && value > 0) {
        spots.add(FlSpot(i.toDouble(), value));
      }
    }

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      barWidth: 2,
      // [2026-05-28 22:05 KST]
      // 마지막 현재가 점 표시 (Show latest price point)
      dotData: FlDotData(
        show: true,
        checkToShowDot: (spot, barData) {
          if (spots.isEmpty) return false;
          return spot.x == spots.last.x;
        },
      ),
      color: color,
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}