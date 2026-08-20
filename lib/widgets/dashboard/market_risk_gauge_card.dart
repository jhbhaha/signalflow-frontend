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
    final total = summary.attackCount +
        summary.watchCount +
        summary.riskCount +
        summary.waitCount;

    final riskScore = total == 0
        ? 0.0
        : (((summary.riskCount * 1.0) + (summary.waitCount * 0.35)) / total) *
            100;

    final riskColor = riskScore >= 70
        ? const Color(0xFF2563EB)
        : riskScore >= 40
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    final riskLabel = riskScore >= 70
        ? '높음'
        : riskScore >= 40
            ? '중간'
            : '낮음';

    final guideText = riskScore >= 70
        ? '방어적인 관점으로 시장을 확인하세요.'
        : riskScore >= 40
            ? '선별 진입이 필요한 구간입니다.'
            : '공격 후보를 살펴볼 수 있는 구간입니다.';

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
                  color: riskColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.speed_rounded,
                  color: riskColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '시장 위험도',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: riskColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  riskLabel,
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
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
                    backgroundColor:
                        Theme.of(context).dividerColor.withValues(alpha: 0.20),
                    color: riskColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${riskScore.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: riskColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            guideText,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCountChip(
                context: context,
                label: 'RISK ${summary.riskCount}개',
                color: const Color(0xFF2563EB),
              ),
              _buildCountChip(
                context: context,
                label: 'WAIT ${summary.waitCount}개',
                color: const Color(0xFF64748B),
              ),
              _buildCountChip(
                context: context,
                label: '전체 $total개',
                color: const Color(0xFF16A34A),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountChip({
    required BuildContext context,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
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
