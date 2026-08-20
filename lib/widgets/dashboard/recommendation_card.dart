import 'package:flutter/material.dart';

import '../../models/recommendation_item.dart';

class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
    super.key,
    required this.recommendations,
    required this.savedTickers,
    required this.onItemTap,
    required this.onSaveTap,
  });

  final List<RecommendationItem> recommendations;
  final List<String> savedTickers;
  final Future<void> Function({
    required String ticker,
    required String stockName,
  }) onItemTap;
  final Future<void> Function(RecommendationItem item) onSaveTap;

  Color _statusColor(String status) {
    if (status.startsWith('ATTACK')) return const Color(0xFFEF4444);
    if (status.startsWith('WATCH')) return const Color(0xFFF59E0B);
    if (status == 'RISK') return const Color(0xFF2563EB);
    return const Color(0xFF64748B);
  }

  List<Widget> _buildReasonTags({
    required String finalStatus,
    required int finalScore,
    String? etfReason,
  }) {
    final tags = <Widget>[];

    void addTag(String text, Color color) {
      tags.add(
        Container(
          margin: const EdgeInsets.only(right: 6, bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.30)),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    if (finalStatus.startsWith('ATTACK')) {
      addTag('공격', const Color(0xFFEF4444));
    } else if (finalStatus.startsWith('WATCH')) {
      addTag('관찰', const Color(0xFFF59E0B));
    } else if (finalStatus == 'RISK') {
      addTag('위험', const Color(0xFF2563EB));
    }

    if (finalScore >= 85) {
      addTag('상위 점수', const Color(0xFF16A34A));
    }

    if (etfReason != null && etfReason.isNotEmpty) {
      addTag('ETF 흐름', const Color(0xFF7C3AED));
    }

    return tags;
  }

  @override
  Widget build(BuildContext context) {
    return _buildSignalFlowCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '오늘의 추천 종목',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              Text(
                '${recommendations.length}개',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recommendations.isEmpty)
            Text(
              '추천 종목이 없습니다.',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            )
          else
            ...recommendations.map((item) {
              final statusColor = _statusColor(item.finalStatus);
              final isSaved = savedTickers.contains(item.ticker);

              return _RecommendationTile(
                item: item,
                statusColor: statusColor,
                isSaved: isSaved,
                tags: _buildReasonTags(
                  finalStatus: item.finalStatus,
                  finalScore: item.finalScore,
                  etfReason: item.etfReason,
                ),
                onTap: () {
                  onItemTap(ticker: item.ticker, stockName: item.stockName);
                },
                onSaveTap: isSaved ? null : () => onSaveTap(item),
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

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({
    required this.item,
    required this.statusColor,
    required this.isSaved,
    required this.tags,
    required this.onTap,
    required this.onSaveTap,
  });

  final RecommendationItem item;
  final Color statusColor;
  final bool isSaved;
  final List<Widget> tags;
  final VoidCallback onTap;
  final VoidCallback? onSaveTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.24)),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.stockName} (${item.ticker})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: isSaved ? '저장됨' : '관심종목 저장',
                    icon: Icon(
                      isSaved ? Icons.check_circle_rounded : Icons.star_border_rounded,
                      color: isSaved ? const Color(0xFF64748B) : const Color(0xFFF59E0B),
                    ),
                    onPressed: onSaveTap,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.etfReason ?? 'ETF 영향 없음',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${item.finalScore}점',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.finalStatus,
                style: TextStyle(
                  fontSize: 11,
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(children: tags),
            ],
          ),
        ),
      ),
    );
  }
}