// File: market_card.dart (시장 상태 카드)
// [Added by ChatGPT | 2026-05-22 13:10 KST]
// Insert Location: lib/widgets/dashboard/market_card.dart 새 파일 생성

import 'package:flutter/material.dart';

import '../../models/dashboard_summary.dart';
import '../../models/market_overview.dart';

class MarketCard extends StatelessWidget {
  const MarketCard({
    super.key,
    required this.summary,
    required this.marketOverview,
    required this.statusColor,
    required this.onWatchNowTap,
    required this.onAttackListTap,
  });

  final DashboardSummary summary;
  final MarketOverview? marketOverview;
  final Color Function(String status) statusColor;
  final Future<void> Function() onWatchNowTap;
  final VoidCallback onAttackListTap;

  String _getMarketSessionStatus() {
    final now = DateTime.now();

    if (now.weekday == DateTime.saturday ||
        now.weekday == DateTime.sunday) {
      return 'CLOSED';
    }

    final minutes = now.hour * 60 + now.minute;

    if (minutes < 9 * 60) {
      return 'PRE MARKET';
    }

    if (minutes >= 9 * 60 && minutes < 15 * 60 + 30) {
      return 'OPEN';
    }

    return 'AFTER MARKET';
  }

  @override
  Widget build(BuildContext context) {
    final color = statusColor(summary.marketStatus);
    final String sessionStatus = _getMarketSessionStatus();

    return _buildSignalFlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: color, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '시장 상태',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      summary.marketStatus,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(summary.marketMessage),
                  ],
                ),
              ),
            ],
          ),

          if (marketOverview != null) ...[
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KOSPI',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${marketOverview!.kospiChange.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: marketOverview!.kospiChange >= 0
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF3B82F6),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KOSDAQ',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${marketOverview!.kosdaqChange.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: marketOverview!.kosdaqChange >= 0
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF3B82F6),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: color.withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.public,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'MARKET ${marketOverview!.marketStatus}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    sessionStatus,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (summary.marketStatus == 'RISK')
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚠ 신규 진입보다 방어 전략이 우선입니다',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: summary.topSignals.isEmpty
                      ? null
                      : () {
                    onWatchNowTap();
                  },
                  child: const Text('지금 볼 종목 보기'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onAttackListTap,
                  child: const Text('공격 후보만'),
                ),
              ),
            ],
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