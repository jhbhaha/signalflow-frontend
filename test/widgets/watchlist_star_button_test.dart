// File: test/widgets/watchlist_star_button_test.dart
// [Added by Codex | 2026-08-28 KST]
// 공통 별 토글 버튼(WatchlistStarButton) 위젯 테스트.
//  1. 미저장 종목 별 클릭 -> addWatchlistItem 호출 -> 채워진 별
//  2. 저장 종목 별 클릭 -> deleteWatchlistItem 호출 -> 빈 별
//  3. add API 실패 -> 별이 채워진 상태로 잘못 남지 않음

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_stock_frontend/models/watch_item.dart';
import 'package:flutter_stock_frontend/services/api_service.dart';
import 'package:flutter_stock_frontend/services/watchlist_store.dart';
import 'package:flutter_stock_frontend/widgets/watchlist_star_button.dart';

class _FakeApi extends ApiService {
  _FakeApi({this.failAdd = false});

  final bool failAdd;
  final List<String> addCalls = <String>[];
  final List<String> deleteCalls = <String>[];

  @override
  Future<void> addWatchlistItem({
    required String ticker,
    required String stockName,
  }) async {
    addCalls.add(ticker);
    if (failAdd) throw Exception('add failed');
  }

  @override
  Future<void> deleteWatchlistItem(String ticker) async {
    deleteCalls.add(ticker);
  }
}

Widget _host() => const MaterialApp(
      home: Scaffold(
        body: Center(
          child: WatchlistStarButton(ticker: '005930', stockName: '삼성전자'),
        ),
      ),
    );

void main() {
  setUp(() => WatchlistStore.instance.debugReset());

  testWidgets('unsaved -> tap -> addWatchlistItem called, star becomes filled',
      (tester) async {
    final api = _FakeApi();
    WatchlistStore.instance.debugSetApiService(api);

    await tester.pumpWidget(_host());

    expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.star_border_rounded));
    await tester.pumpAndSettle();

    expect(api.addCalls, ['005930']);
    expect(WatchlistStore.instance.isSaved('005930'), isTrue);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });

  testWidgets('saved -> tap -> deleteWatchlistItem called, star becomes empty',
      (tester) async {
    final api = _FakeApi();
    WatchlistStore.instance
      ..debugSetApiService(api)
      ..hydrate(const [WatchItem(ticker: '005930', stockName: '삼성전자')]);

    await tester.pumpWidget(_host());

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.star_rounded));
    await tester.pumpAndSettle();

    expect(api.deleteCalls, ['005930']);
    expect(WatchlistStore.instance.isSaved('005930'), isFalse);
    expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
  });

  testWidgets('add API failure leaves the star empty (no false-positive save)',
      (tester) async {
    final api = _FakeApi(failAdd: true);
    WatchlistStore.instance.debugSetApiService(api);

    await tester.pumpWidget(_host());

    await tester.tap(find.byIcon(Icons.star_border_rounded));
    await tester.pumpAndSettle();

    expect(api.addCalls, ['005930']);
    expect(WatchlistStore.instance.isSaved('005930'), isFalse);
    expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
  });
}
