import 'package:flutter/material.dart';

import '../../models/dashboard_summary.dart';
import '../../models/market_overview.dart';

class MarketCard extends StatelessWidget {
  const MarketCard({
    super.key,
    required this.summary,
    required this.marketOverview,
    required this.statusColor,
  });

  final DashboardSummary summary;
  final MarketOverview? marketOverview;
  final Color Function(String status) statusColor;

  String _getMarketSessionStatus() {
    final now = DateTime.now();

    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      return 'CLOSED';
    }

    final minutes = now.hour * 60 + now.minute;

    if (minutes < 9 * 60) {
      return 'PRE';
    }

    if (minutes >= 9 * 60 && minutes < 15 * 60 + 30) {
      return 'OPEN';
    }

    return 'AFTER';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = statusColor(summary.marketStatus);
    final sessionStatus = _getMarketSessionStatus();

    return _buildSignalFlowCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.insights_rounded, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '시장 세부 흐름',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        _buildStatusChip(
                          context: context,
                          label: sessionStatus,
                          color: const Color(0xFF64748B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      summary.marketMessage.isEmpty
                          ? summary.marketStatus
                          : summary.marketMessage,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.66),
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (marketOverview != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildIndexTile(
                    context: context,
                    label: 'KOSPI',
                    value: marketOverview!.kospiChange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildIndexTile(
                    context: context,
                    label: 'KOSDAQ',
                    value: marketOverview!.kosdaqChange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMarketStatusTile(
                    context: context,
                    label: 'STATUS',
                    value: marketOverview!.marketStatus,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
          if (summary.marketStatus == 'RISK') ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.16),
                ),
              ),
              child: const Text(
                '신규 진입보다 방어 전략을 우선하세요.',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIndexTile({
    required BuildContext context,
    required String label,
    required double value,
  }) {
    final color =
        value >= 0 ? const Color(0xFFEF4444) : const Color(0xFF2563EB);

    return _MiniMarketTile(
      label: label,
      value: '${value.toStringAsFixed(2)}%',
      color: color,
    );
  }

  Widget _buildMarketStatusTile({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
  }) {
    return _MiniMarketTile(
      label: label,
      value: value,
      color: color,
    );
  }

  Widget _buildStatusChip({
    required BuildContext context,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
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

class _MiniMarketTile extends StatelessWidget {
  const _MiniMarketTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: 0.54,
                  ),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
