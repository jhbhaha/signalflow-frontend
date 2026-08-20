// File: response_strategy_list_page.dart (오늘의 대응 전략 - 더보기 전체 목록 화면)
// [Added by Claude | 2026-08-10 KST]
// 홈 화면 "오늘의 대응 전략" 카드에서 탭당 3개 초과 종목이 있을 때
// "더보기"로 진입하는 전체 목록 화면.

import 'package:flutter/material.dart';

import '../models/response_strategy.dart';

class ResponseStrategyListPage extends StatefulWidget {
  const ResponseStrategyListPage({
    super.key,
    required this.title,
    required this.accentColor,
    required this.emptyMessage,
    required this.items,
    required this.savedTickers,
    required this.onItemTap,
    required this.onSaveTap,
  });

  final String title;
  final Color accentColor;
  final String emptyMessage;
  final List<ResponseStrategyItem> items;
  final List<String> savedTickers;
  final Future<void> Function({required String ticker, required String stockName})
      onItemTap;
  final Future<void> Function({required String ticker, required String stockName})
      onSaveTap;

  @override
  State<ResponseStrategyListPage> createState() =>
      _ResponseStrategyListPageState();
}

class _ResponseStrategyListPageState extends State<ResponseStrategyListPage> {
  late List<String> _savedTickers;

  @override
  void initState() {
    super.initState();
    _savedTickers = [...widget.savedTickers];
  }

  Future<void> _handleSaveTap(ResponseStrategyItem item) async {
    await widget.onSaveTap(ticker: item.ticker, stockName: item.stockName);

    if (!mounted) return;

    setState(() {
      _savedTickers.add(item.ticker);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: widget.items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  widget.emptyMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: widget.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSaved = _savedTickers.contains(item.ticker);
                final accentColor = widget.accentColor;

                return Material(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: accentColor.withValues(alpha: 0.18),
                      ),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: accentColor.withValues(alpha: 0.12),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    title: Text(
                      item.stockName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      item.strategyReason ?? item.ticker,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${item.finalScore}점',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        IconButton(
                          tooltip: isSaved ? '저장됨' : '관심종목 저장',
                          icon: Icon(
                            isSaved
                                ? Icons.check_circle_rounded
                                : Icons.star_border_rounded,
                            color: isSaved
                                ? const Color(0xFF64748B)
                                : const Color(0xFFF59E0B),
                          ),
                          onPressed:
                              isSaved ? null : () => _handleSaveTap(item),
                        ),
                      ],
                    ),
                    onTap: () => widget.onItemTap(
                      ticker: item.ticker,
                      stockName: item.stockName,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
