// File: test/services/watchlist_store_test.dart
// [Added by Codex | 2026-08-28 KST]
// 관심종목 공통 상태 저장소(WatchlistStore) 단위 테스트.
//  - 미저장 종목 add -> addWatchlistItem 호출 + isSaved true
//  - 저장 종목 remove -> deleteWatchlistItem 호출 + isSaved false
//  - add API 실패 -> 상태가 잘못 true 가 되지 않음
//  - delete API 실패 -> 기존 저장 상태 유지
//  - add / remove 시 listeners 통지

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_stock_frontend/models/watch_item.dart';
import 'package:flutter_stock_frontend/services/api_service.dart';
import 'package:flutter_stock_frontend/services/watchlist_store.dart';

class _FakeApi extends ApiService {
  _FakeApi({
    this.initial = const <String>[],
    this.failAdd = false,
    this.failDelete = false,
  });

  final List<String> initial;
  final bool failAdd;
  final bool failDelete;

  final List<String> addCalls = <String>[];
  final List<String> deleteCalls = <String>[];
  int fetchCount = 0;

  @override
  Future<List<WatchItem>> fetchWatchlistItems() async {
    fetchCount++;
    return initial
        .map((t) => WatchItem(ticker: t, stockName: '$t name'))
        .toList();
  }

  @override
  Future<void> addWatchlistItem({
    required String ticker,
    required String stockName,
  }) async {
    addCalls.add(ticker);
    if (failAdd) {
      throw Exception('add failed');
    }
  }

  @override
  Future<void> deleteWatchlistItem(String ticker) async {
    deleteCalls.add(ticker);
    if (failDelete) {
      throw Exception('delete failed');
    }
  }
}

void main() {
  final store = WatchlistStore.instance;

  setUp(() {
    store.debugReset();
  });

  test('ensureLoaded fetches the list once and populates savedTickers',
      () async {
    final api = _FakeApi(initial: const ['005930', '000660']);
    store.debugSetApiService(api);

    await store.ensureLoaded();
    await store.ensureLoaded();

    expect(api.fetchCount, 1);
    expect(store.isSaved('005930'), isTrue);
    expect(store.isSaved('000660'), isTrue);
    expect(store.isSaved('035720'), isFalse);
  });

  test('add: unsaved ticker calls addWatchlistItem and flips isSaved true',
      () async {
    final api = _FakeApi();
    store.debugSetApiService(api);

    var notified = 0;
    store.addListener(() => notified++);

    await store.add('005930', '삼성전자');

    expect(api.addCalls, ['005930']);
    expect(store.isSaved('005930'), isTrue);
    expect(notified, 1);
  });

  test('remove: saved ticker calls deleteWatchlistItem and flips isSaved false',
      () async {
    final api = _FakeApi(initial: const ['005930']);
    store.debugSetApiService(api);
    await store.ensureLoaded();

    var notified = 0;
    store.addListener(() => notified++);

    await store.remove('005930');

    expect(api.deleteCalls, ['005930']);
    expect(store.isSaved('005930'), isFalse);
    expect(notified, 1);
  });

  test('toggle flips between add and remove', () async {
    final api = _FakeApi();
    store.debugSetApiService(api);

    await store.toggle('005930', '삼성전자');
    expect(store.isSaved('005930'), isTrue);
    expect(api.addCalls, ['005930']);

    await store.toggle('005930', '삼성전자');
    expect(store.isSaved('005930'), isFalse);
    expect(api.deleteCalls, ['005930']);
  });

  test('add API failure does not mark the ticker as saved', () async {
    final api = _FakeApi(failAdd: true);
    store.debugSetApiService(api);

    var notified = 0;
    store.addListener(() => notified++);

    await expectLater(
      store.add('005930', '삼성전자'),
      throwsA(isA<Exception>()),
    );

    expect(store.isSaved('005930'), isFalse);
    expect(notified, 0);
  });

  test('delete API failure keeps the existing saved state', () async {
    final api = _FakeApi(initial: const ['005930'], failDelete: true);
    store.debugSetApiService(api);
    await store.ensureLoaded();

    var notified = 0;
    store.addListener(() => notified++);

    await expectLater(
      store.remove('005930'),
      throwsA(isA<Exception>()),
    );

    expect(store.isSaved('005930'), isTrue);
    expect(notified, 0);
  });

  test('hydrate replaces the set without hitting the API', () async {
    final api = _FakeApi();
    store.debugSetApiService(api);

    store.hydrate(const [
      WatchItem(ticker: '005930', stockName: '삼성전자'),
      WatchItem(ticker: '000660', stockName: 'SK하이닉스'),
    ]);

    expect(api.fetchCount, 0);
    expect(store.savedTickers, {'005930', '000660'});

    store.hydrate(const [WatchItem(ticker: '005930', stockName: '삼성전자')]);
    expect(store.savedTickers, {'005930'});
  });
}
