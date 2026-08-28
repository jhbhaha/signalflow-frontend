// File: lib/widgets/watchlist_star_button.dart (관심종목 별 토글 버튼)
// [Added by Codex | 2026-08-28 KST]
// 추천 종목 카드 / 오늘의 대응 전략 카드 / 더보기 목록에서 공통으로 쓰는 별 버튼.
// - 저장 여부는 항상 WatchlistStore.isSaved 기준으로 판단한다.
// - 저장돼도 버튼을 비활성화하지 않는다. (진짜 toggle)
//     빈 별 -> 탭 -> POST 성공 -> 채워진 별
//     채워진 별 -> 탭 -> DELETE 성공 -> 빈 별
// - API 실패 시 store 상태는 그대로 두고 스낵바만 노출한다.

import 'package:flutter/material.dart';

import '../services/watchlist_store.dart';

class WatchlistStarButton extends StatelessWidget {
  const WatchlistStarButton({
    super.key,
    required this.ticker,
    required this.stockName,
    this.iconSize,
  });

  final String ticker;
  final String stockName;
  final double? iconSize;

  static const Color _accent = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final store = WatchlistStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final saved = store.isSaved(ticker);

        return IconButton(
          tooltip: saved ? '관심종목 해제' : '관심종목 추가',
          icon: Icon(
            saved ? Icons.star_rounded : Icons.star_border_rounded,
            color: _accent,
            size: iconSize,
          ),
          onPressed: () => _toggle(context),
        );
      },
    );
  }

  Future<void> _toggle(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final wasSaved = WatchlistStore.instance.isSaved(ticker);

    try {
      await WatchlistStore.instance.toggle(ticker, stockName);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            wasSaved ? '$stockName 관심종목에서 해제했습니다.' : '$stockName 관심종목에 추가했습니다.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            wasSaved ? '관심종목 해제에 실패했습니다. $error' : '관심종목 추가에 실패했습니다. $error',
          ),
        ),
      );
    }
  }
}
