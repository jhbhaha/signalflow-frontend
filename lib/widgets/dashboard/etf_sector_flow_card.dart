import 'package:flutter/material.dart';

import '../../models/dashboard_summary.dart';

class EtfSectorFlowCard extends StatelessWidget {
  const EtfSectorFlowCard({
    super.key,
    required this.summary,
  });

  final DashboardSummary summary;

  IconData _trendIcon(String trend) {
    if (trend == 'UP') return Icons.arrow_upward_rounded;
    if (trend == 'DOWN') return Icons.arrow_downward_rounded;
    return Icons.remove_rounded;
  }

  Color _trendColor(String trend) {
    if (trend == 'UP') return const Color(0xFFEF4444);
    if (trend == 'DOWN') return const Color(0xFF2563EB);
    return const Color(0xFFF59E0B);
  }

  String _trendLabel(String trend) {
    if (trend == 'UP') return '강세';
    if (trend == 'DOWN') return '약세';
    return '중립';
  }

  @override
  Widget build(BuildContext context) {
    final sectors = summary.etfSectors.take(5).toList();

    return _buildSignalFlowCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pie_chart_outline_rounded,
                  color: Color(0xFF2563EB),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'ETF 섹터 흐름',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              Text(
                '${sectors.length}개',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (sectors.isEmpty)
            Text(
              'ETF 섹터 데이터가 없습니다.',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            )
          else
            ...sectors.map((sector) {
              final color = _trendColor(sector.trend);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.18)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_trendIcon(sector.trend), color: color, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sector.sector,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '상관 ${sector.avgCorrelation.toStringAsFixed(2)} · 표본 ${sector.count}개',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _trendLabel(sector.trend),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '상승 ${(sector.avgUpProbability * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
              : Theme.of(context).dividerColor.withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
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
  }
}