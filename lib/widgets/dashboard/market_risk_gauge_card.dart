// File: market_risk_gauge_card.dart (시장 위험도 게이지 카드)
// [Added by ChatGPT | 2026-05-22 14:05 KST]
// Insert Location: lib/widgets/dashboard/market_risk_gauge_card.dart 새 파일 생성

import 'package:flutter/material.dart';

import '../../models/dashboard_summary.dart';

class MarketRiskGaugeCard extends StatelessWidget {
  const MarketRiskGaugeCard({
    super.key,
    required this.summary,
  });

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final int total = summary.attackCount +
        summary.watchCount +
        summary.riskCount +
        summary.waitCount;

    final double riskScore = total == 0
        ? 0
        : (((summary.riskCount * 1.0) + (summary.waitCount * 0.35)) / total) * 100;

    final Color riskColor = riskScore >= 70
        ? const Color(0xFF3B82F6)
        : riskScore >= 40
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    final String riskLabel = riskScore >= 70
        ? '높음'
        : riskScore >= 40
        ? '중간'
        : '낮음';

    return _buildSignalFlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '시장 위험도',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: riskScore / 100,
                    minHeight: 14,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    color: riskColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${riskScore.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: riskColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '위험도 $riskLabel · RISK ${summary.riskCount}개 / WAIT ${summary.waitCount}개',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
            ),
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