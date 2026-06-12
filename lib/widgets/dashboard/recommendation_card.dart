// File: recommendation_card.dart (추천 종목 카드)
// [Added by ChatGPT | 2026-05-21 19:05 KST]
// Insert Location: lib/widgets/dashboard/recommendation_card.dart 새 파일 생성

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
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: color.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (finalStatus.startsWith('ATTACK')) {
      addTag('ATTACK', const Color(0xFFEF4444));
    } else if (finalStatus.startsWith('WATCH')) {
      addTag('WATCH', const Color(0xFFF59E0B));
    } else if (finalStatus == 'RISK') {
      addTag('RISK', const Color(0xFF3B82F6));
    }

    if (finalScore >= 85) {
      addTag('상위점수', const Color(0xFF22C55E));
    }

    if (etfReason != null && etfReason.isNotEmpty) {
      addTag('ETF 흐름', const Color(0xFF8B5CF6));
    }

    return tags;
  }

  @override
  Widget build(BuildContext context) {
    return _buildSignalFlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '오늘의 추천 종목',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (recommendations.isEmpty)
            const Text('추천 종목이 없습니다.')
          else
            ...recommendations.map(
                  (item) {
                final Color statusColor = _statusColor(item.finalStatus);
                final bool isSaved = savedTickers.contains(item.ticker);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.28),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withValues(alpha: 0.10),
                        Theme.of(context).cardColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.12),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      onItemTap(
                        ticker: item.ticker,
                        stockName: item.stockName,
                      );
                    },
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  isSaved
                                      ? Icons.check_circle
                                      : Icons.star_border,
                                  color: isSaved
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFFF59E0B),
                                ),
                                onPressed: isSaved
                                    ? null
                                    : () {
                                  onSaveTap(item);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
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
                              const SizedBox(width: 8),
                              Text(
                                '${item.finalScore}점',
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
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
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            children: _buildReasonTags(
                              finalStatus: item.finalStatus,
                              finalScore: item.finalScore,
                              etfReason: item.etfReason,
                            ),
                          ),
                        ],
                      ),
                    ),
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
    return Builder(
      builder: (context) {
        final bool isDark =
            Theme.of(context).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Theme.of(context)
                  .dividerColor
                  .withValues(alpha: 0.20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark ? 0.25 : 0.08,
                ),
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
      },
    );
  }
}