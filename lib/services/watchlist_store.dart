// File: lib/services/watchlist_store.dart (관심종목 공통 상태 저장소)
// [Added by Codex | 2026-08-28 KST]
// 여러 화면에 흩어져 있던 관심종목 상태(_savedTickers / _isSavedToWatchlist /
// _watchItems 등)를 하나로 모으는 앱 전역 ChangeNotifier.
//
// 원칙:
//  1. 서버 API(add/delete/fetch) 호출이 성공한 뒤에만 로컬 Set 을 변경한다.
//     -> API 실패 시 프론트 상태가 잘못 바뀌지 않는다.
//  2. 상태가 바뀌면 즉시 notifyListeners() 로 모든 화면(별 버튼 / 관심종목 화면)에
//     동일한 기준(WatchlistStore.isSaved)을 반영한다.
//  3. 백엔드 API 계약은 그대로 사용한다. (엔드포인트 변경 없음)

import 'package:flutter/foundation.dart';

import '../models/watch_item.dart';
import 'api_service.dart';

class WatchlistStore extends ChangeNotifier {
  WatchlistStore._();

  // 앱 전역에서 공유되는 단일 인스턴스
  static final WatchlistStore instance = WatchlistStore._();

  ApiService _api = ApiService();

  final Set<String> _savedTickers = <String>{};
  bool _loaded = false;
  Future<void>? _inflightRefresh;

  /// 현재 관심종목 ticker 집합 (읽기 전용 사본)
  Set<String> get savedTickers => Set<String>.unmodifiable(_savedTickers);

  /// 서버 목록을 한 번이라도 반영했는지 여부
  bool get isLoaded => _loaded;

  /// 특정 종목이 관심종목인지 여부
  bool isSaved(String ticker) => _savedTickers.contains(ticker);

  /// 이미 조회한 관심종목 목록(WatchItem)으로 상태를 채운다. (추가 API 호출 없음)
  /// 관심종목 화면이 자체 조회한 목록을 store 와 동기화할 때 사용한다.
  void hydrate(Iterable<WatchItem> items) {
    final next =
        items.map((e) => e.ticker.trim()).where((t) => t.isNotEmpty).toSet();

    _loaded = true;

    if (setEquals(_savedTickers, next)) {
      return;
    }

    _savedTickers
      ..clear()
      ..addAll(next);
    notifyListeners();
  }

  /// 최초 1회만 서버에서 관심종목 목록을 조회한다.
  Future<void> ensureLoaded() {
    if (_loaded) {
      return Future<void>.value();
    }
    return refresh();
  }

  /// 서버 관심종목 목록으로 상태를 강제 동기화한다.
  /// 동시에 여러 화면에서 호출해도 실제 요청은 1건만 나간다.
  Future<void> refresh() {
    final inflight = _inflightRefresh;
    if (inflight != null) {
      return inflight;
    }

    final future = _refresh();
    _inflightRefresh = future;
    return future.whenComplete(() {
      _inflightRefresh = null;
    });
  }

  Future<void> _refresh() async {
    final items = await _api.fetchWatchlistItems();
    hydrate(items);
  }

  /// 관심종목 추가: API 성공 후에만 로컬 상태 변경
  Future<void> add(String ticker, String stockName) async {
    final trimmed = ticker.trim();
    if (trimmed.isEmpty || _savedTickers.contains(trimmed)) {
      return;
    }

    await _api.addWatchlistItem(ticker: trimmed, stockName: stockName);

    _savedTickers.add(trimmed);
    _loaded = true;
    notifyListeners();
  }

  /// 관심종목 해제: API 성공 후에만 로컬 상태 변경
  Future<void> remove(String ticker) async {
    final trimmed = ticker.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await _api.deleteWatchlistItem(trimmed);

    final removed = _savedTickers.remove(trimmed);
    _loaded = true;
    if (removed) {
      notifyListeners();
    }
  }

  /// 현재 저장 여부에 따라 add / remove 를 수행하는 toggle
  Future<void> toggle(String ticker, String stockName) {
    return isSaved(ticker) ? remove(ticker) : add(ticker, stockName);
  }

  // ---------------------------------------------------------------------------
  // 테스트 전용 진입점
  // ---------------------------------------------------------------------------

  @visibleForTesting
  void debugSetApiService(ApiService api) {
    _api = api;
  }

  @visibleForTesting
  void debugReset() {
    _api = ApiService();
    _savedTickers.clear();
    _loaded = false;
    _inflightRefresh = null;
  }
}
