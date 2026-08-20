import 'package:flutter/material.dart';

import '../../models/dashboard_summary.dart';

class SignalSummaryCard extends StatelessWidget {
  const SignalSummaryCard({
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

    return _buildSignalFlowCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '신호 분포',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              Text(
                '관심 ${summary.watchlistCount}개',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.56,
                      ),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$total',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '개 신호',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(
                          alpha: 0.58,
                        ),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DistributionBar(
            total: total,
            segments: [
              _SignalSegment(
                label: '공격',
                count: summary.attackCount,
                color: const Color(0xFF16A34A),
              ),
              _SignalSegment(
                label: '관찰',
                count: summary.watchCount,
                color: const Color(0xFFF59E0B),
              ),
              _SignalSegment(
                label: '위험',
                count: summary.riskCount,
                color: const Color(0xFF2563EB),
              ),
              _SignalSegment(
                label: '대기',
                count: summary.waitCount,
                color: const Color(0xFF64748B),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusCountPill(
                label: '공격',
                count: summary.attackCount,
                color: const Color(0xFF16A34A),
              ),
              _StatusCountPill(
                label: '관찰',
                count: summary.watchCount,
                color: const Color(0xFFF59E0B),
              ),
              _StatusCountPill(
                label: '위험',
                count: summary.riskCount,
                color: const Color(0xFF2563EB),
              ),
              _StatusCountPill(
                label: '대기',
                count: summary.waitCount,
                color: const Color(0xFF64748B),
              ),
            ],
          ),
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

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({
    required this.total,
    required this.segments,
  });

  final int total;
  final List<_SignalSegment> segments;

  @override
  Widget build(BuildContext context) {
    final activeSegments =
        segments.where((segment) => segment.count > 0).toList();

    if (total == 0 || activeSegments.isEmpty) {
      return Container(
        height: 12,
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 12,
        child: Row(
          children: activeSegments.map((segment) {
            return Expanded(
              flex: segment.count,
              child: Container(color: segment.color),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _StatusCountPill extends StatelessWidget {
  const _StatusCountPill({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        '$label $count',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SignalSegment {
  const _SignalSegment({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
}
