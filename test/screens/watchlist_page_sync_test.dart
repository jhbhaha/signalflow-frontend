// File: test/screens/watchlist_page_sync_test.dart
// [Added by Codex | 2026-08-28 KST]
// 관심종목 화면이 공통 WatchlistStore 변경을 즉시 반영하는지 검증.
//  7. 다른 화면에서 해제(store.remove) -> 관심종목 목록에서 즉시 사라짐
//  8. 관심종목 화면의 X 삭제 -> deleteWatchlistItem 호출 + store 에서도 제거 + 목록 즉시 제거

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_stock_frontend/models/analysis_response.dart';
import 'package:flutter_stock_frontend/models/signal_history_item.dart';
import 'package:flutter_stock_frontend/models/watch_item.dart';
import 'package:flutter_stock_frontend/services/api_service.dart';
import 'package:flutter_stock_frontend/services/watchlist_store.dart';
import 'package:flutter_stock_frontend/screens/watchlist_page.dart';

class _FakeApi extends ApiService {
  _FakeApi(this._tickers);

  final List<String> _tickers;
  final List<String> deleteCalls = <String>[];

  @override
  Future<List<WatchItem>> fetchWatchlistItems() async {
    return _tickers
        .map((t) => WatchItem(ticker: t, stockName: '$t종목'))
        .toList();
  }

  @override
  Future<List<AnalysisResponse>> fetchWatchlistAnalysis() async {
    return <AnalysisResponse>[];
  }

  @override
  Future<List<SignalHistoryItem>> fetchSignalHistoryByTicker({
    required String ticker,
  }) async {
    return <SignalHistoryItem>[];
  }

  @override
  Future<void> deleteWatchlistItem(String ticker) async {
    deleteCalls.add(ticker);
    _tickers.remove(ticker);
  }
}

void main() {
  setUp(() => WatchlistStore.instance.debugReset());

  testWidgets(
      'removing a ticker elsewhere removes it from the watchlist screen',
      (tester) async {
    final api = _FakeApi(['AAA', 'BBB']);
    WatchlistStore.instance.debugSetApiService(api);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: WatchlistPage(apiService: api))),
    );
    await tester.pumpAndSettle();

    expect(find.text('AAA종목'), findsWidgets);
    expect(find.text('BBB종목'), findsWidgets);

    // 다른 화면에서 해제한 것과 동일한 경로
    await WatchlistStore.instance.remove('AAA');
    await tester.pumpAndSettle();

    expect(find.text('AAA종목'), findsNothing);
    expect(find.text('BBB종목'), findsWidgets);
  });

  testWidgets('X delete routes through the store and drops the row immediately',
      (tester) async {
    final api = _FakeApi(['AAA']);
    WatchlistStore.instance.debugSetApiService(api);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: WatchlistPage(apiService: api))),
    );
    await tester.pumpAndSettle();

    expect(find.text('AAA종목'), findsWidgets);
    expect(WatchlistStore.instance.isSaved('AAA'), isTrue);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();

    expect(api.deleteCalls, ['AAA']);
    expect(WatchlistStore.instance.isSaved('AAA'), isFalse);
    expect(find.text('AAA종목'), findsNothing);
  });
}
