// File: response_strategy_list_page.dart (오늘의 대응 전략 - 더보기 전체 목록 화면)
// [Added by Claude | 2026-08-10 KST]
// 홈 화면 "오늘의 대응 전략" 카드에서 탭당 3개 초과 종목이 있을 때
// "더보기"로 진입하는 전체 목록 화면.

import 'package:flutter/material.dart';

import '../models/response_strategy.dart';
// [Modified by Claude | 2026-08-27 KST] 최근 종가 표시 공용 유틸
import '../utils/won_format.dart';
// [Added by Codex | 2026-08-28 KST] 관심종목 별을 공통 store 기반 토글 버튼으로 통일
import '../widgets/watchlist_star_button.dart';

// [Modified by Codex | 2026-08-28 KST]
// 부모(savedTickers)를 initState 에서 복사하던 구조 제거.
// 관심종목 상태는 WatchlistStore 하나만 바라보므로 StatefulWidget 이 필요 없다.
class ResponseStrategyListPage extends StatelessWidget {
  const ResponseStrategyListPage({
    super.key,
    required this.title,
    required this.accentColor,
    required this.emptyMessage,
    required this.items,
    required this.onItemTap,
  });

  final String title;
  final Color accentColor;
  final String emptyMessage;
  final List<ResponseStrategyItem> items;
  final Future<void> Function({required String ticker, required String stockName})
      onItemTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  emptyMessage,
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
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                // [Modified by Claude | 2026-08-27 KST] 최근 종가(있을 때만)
                final priceText = formatWonPrice(item.close);
                final subtitleText = priceText == null
                    ? (item.strategyReason ?? item.ticker)
                    : '$priceText · ${item.strategyReason ?? item.ticker}';

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
                      subtitleText,
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
                        // [Modified by Codex | 2026-08-28 KST]
                        // 저장 후 비활성화되던 별을 공통 store 기반 toggle 버튼으로 교체
                        WatchlistStarButton(
                          ticker: item.ticker,
                          stockName: item.stockName,
                        ),
                      ],
                    ),
                    onTap: () => onItemTap(
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
