// File: etf_sector_flow_card.dart (ETF 섹터 흐름 카드)
// [Added by ChatGPT | 2026-05-22 13:55 KST]
// Insert Location: lib/widgets/dashboard/etf_sector_flow_card.dart 새 파일 생성

import 'package:flutter/material.dart';

import '../../models/dashboard_summary.dart';

class EtfSectorFlowCard extends StatelessWidget {
  const EtfSectorFlowCard({
    super.key,
    required this.summary,
  });

  final DashboardSummary summary;

  IconData _trendIcon(String trend) {
    if (trend == 'UP') return Icons.arrow_upward;
    if (trend == 'DOWN') return Icons.arrow_downward;

    return Icons.remove;
  }

  Color _trendColor(String trend) {
    // 한국 시장 기준 색상
    // 상승=빨강 / 하락=파랑
    if (trend == 'UP') {
      return const Color(0xFFEF4444);
    }

    if (trend == 'DOWN') {
      return const Color(0xFF3B82F6);
    }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.pie_chart_outline,
                color: Color(0xFF3B82F6),
              ),
              SizedBox(width: 8),
              Text(
                'ETF 섹터 흐름',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (sectors.isEmpty)
            const Text(
              'ETF 섹터 데이터가 없습니다.',
              style: TextStyle(
                color: Color(0xFF94A3B8),
              ),
            ),

          ...sectors.map(
                (sector) {
              final color = _trendColor(sector.trend);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: color.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _trendIcon(sector.trend),
                      color: color,
                      size: 22,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            sector.sector,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            '상관 ${sector.avgCorrelation.toStringAsFixed(2)} · 표본 ${sector.count}개',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.end,
                      children: [
                        Text(
                          _trendLabel(sector.trend),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '${(sector.avgUpProbability * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
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

  Widget _buildSignalFlowCard({
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
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