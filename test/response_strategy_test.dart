// File: test/response_strategy_test.dart (오늘의 대응 전략 테스트)
// [Added by Claude | 2026-08-10 KST]
// ResponseStrategy 모델 파싱 및 ResponseStrategyCard 빈 상태 위젯 테스트.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_stock_frontend/models/response_strategy.dart';
import 'package:flutter_stock_frontend/models/watch_item.dart';
import 'package:flutter_stock_frontend/screens/response_strategy_list_page.dart';
import 'package:flutter_stock_frontend/services/api_service.dart';
import 'package:flutter_stock_frontend/services/watchlist_store.dart';
import 'package:flutter_stock_frontend/widgets/dashboard/response_strategy_card.dart';

// [Added by Codex | 2026-08-28 KST]
// 관심종목 별이 이제 공통 WatchlistStore -> ApiService 를 호출하므로,
// 위젯 테스트에서 네트워크 대신 사용할 가짜 ApiService.
class FakeWatchlistApi extends ApiService {
  FakeWatchlistApi({
    this.initial = const <String>[],
    this.failAdd = false,
    this.failDelete = false,
  });

  final List<String> initial;
  final bool failAdd;
  final bool failDelete;

  final List<String> addCalls = <String>[];
  final List<String> deleteCalls = <String>[];

  @override
  Future<List<WatchItem>> fetchWatchlistItems() async {
    return initial.map((t) => WatchItem(ticker: t, stockName: t)).toList();
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

// [Added by Claude | 2026-08-10 KST]
// n개의 더미 ResponseStrategyItem 생성 헬퍼 (탭당 최대 3개 노출 / 더보기 검증용)
List<ResponseStrategyItem> _makeItems(int count, {String prefix = 'T'}) {
  return List.generate(
    count,
    (i) => ResponseStrategyItem(
      ticker: '$prefix$i',
      stockName: '종목$i',
      finalScore: 5 - (i % 5),
      finalStatus: 'ATTACK_STRONG',
      strategyType: 'ATTACK',
      strategyLevel: 'ATTACK_STRONG',
      strategyReason: '테스트 사유 $i',
    ),
  );
}

void main() {
  // [Added by Codex | 2026-08-28 KST]
  // 전역 싱글턴 WatchlistStore 가 테스트 간 상태를 공유하지 않도록 초기화.
  setUp(() {
    WatchlistStore.instance.debugReset();
  });

  group('ResponseStrategy.fromJson', () {
    test('parses full payload with items in every bucket', () {
      final json = {
        'asof': '2026-08-07',
        'market_mode': 'ATTACK',
        'market_message': '관심종목 중 공격 후보가 우세합니다.',
        'attack_candidates': [
          {
            'ticker': '005930',
            'stock_name': '삼성전자',
            'final_score': 95,
            'final_status': 'ATTACK_STRONG',
            'strategy_type': 'ATTACK',
            'strategy_level': 'ATTACK_STRONG',
            'strategy_reason': '강한 공격 조건 충족',
          },
        ],
        'recovery_candidates': <dynamic>[],
        'risk_stocks': <dynamic>[],
      };

      final strategy = ResponseStrategy.fromJson(json);

      expect(strategy.asof, '2026-08-07');
      expect(strategy.marketMode, 'ATTACK');
      expect(strategy.attackCandidates.length, 1);
      expect(strategy.attackCandidates.first.ticker, '005930');
      expect(strategy.attackCandidates.first.strategyLevel, 'ATTACK_STRONG');
      expect(strategy.recoveryCandidates, isEmpty);
      expect(strategy.riskStocks, isEmpty);
    });

    test('missing list fields default to empty lists, not null', () {
      final json = <String, dynamic>{
        'asof': '2026-08-07',
        'market_mode': 'NEUTRAL',
        'market_message': '현재 뚜렷한 공격·회복·위험 신호가 없습니다.',
      };

      final strategy = ResponseStrategy.fromJson(json);

      expect(strategy.attackCandidates, isEmpty);
      expect(strategy.recoveryCandidates, isEmpty);
      expect(strategy.riskStocks, isEmpty);
    });
  });

  group('ResponseStrategyCard empty states', () {
    Future<void> pumpCard(
      WidgetTester tester,
      ResponseStrategy strategy,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponseStrategyCard(
              strategy: strategy,
              isLoading: false,
              hasError: false,
              onItemTap: ({required ticker, required stockName}) async {},
            ),
          ),
        ),
      );
    }

    final emptyStrategy = ResponseStrategy(
      asof: '2026-08-07',
      marketMode: 'NEUTRAL',
      marketMessage: '현재 뚜렷한 공격·회복·위험 신호가 없습니다.',
      attackCandidates: const [],
      recoveryCandidates: const [],
      riskStocks: const [],
    );

    testWidgets('shows attack empty message on the default (attack) tab',
        (tester) async {
      await pumpCard(tester, emptyStrategy);

      expect(
        find.text('현재 공격 조건을 충족한 종목이 없습니다. 기다리는 것도 전략입니다.'),
        findsOneWidget,
      );
    });

    testWidgets('shows recovery empty message after switching tabs',
        (tester) async {
      await pumpCard(tester, emptyStrategy);

      await tester.tap(find.text('회복 후보'));
      await tester.pumpAndSettle();

      expect(
        find.text('아직 뚜렷한 회복 움직임이 확인되지 않았습니다.'),
        findsOneWidget,
      );
    });

    testWidgets('shows risk empty message after switching tabs',
        (tester) async {
      await pumpCard(tester, emptyStrategy);

      await tester.tap(find.text('위험 종목'));
      await tester.pumpAndSettle();

      expect(
        find.text('현재 주요 분석 종목에서 강한 위험 신호가 없습니다.'),
        findsOneWidget,
      );
    });

    testWidgets('renders section title and subtitle', (tester) async {
      await pumpCard(tester, emptyStrategy);

      expect(find.text('오늘의 대응 전략'), findsOneWidget);
      expect(
        find.text('현재 시장에서 공격·회복·위험 신호를 구분해 보여드립니다.'),
        findsOneWidget,
      );
    });
  });

  // [Added by Claude | 2026-08-10 KST]
  // 실제 데이터 검증 후 추가: 탭 전환, 홈 3개 제한, 더보기, 상세 이동,
  // 관심종목 저장, API 오류 상태를 위젯 레벨에서 결정적으로 검증한다.
  group('ResponseStrategyCard populated states', () {
    testWidgets('shows at most 3 tiles even with 5 attack candidates',
        (tester) async {
      final strategy = ResponseStrategy(
        asof: '2026-08-10',
        marketMode: 'ATTACK',
        marketMessage: 'test',
        attackCandidates: _makeItems(5, prefix: 'A'),
        recoveryCandidates: const [],
        riskStocks: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponseStrategyCard(
              strategy: strategy,
              isLoading: false,
              hasError: false,
              onItemTap: ({required ticker, required stockName}) async {},
            ),
          ),
        ),
      );

      // 홈에서는 탭당 최대 3개만 노출
      expect(find.textContaining('종목0'), findsOneWidget);
      expect(find.textContaining('종목1'), findsOneWidget);
      expect(find.textContaining('종목2'), findsOneWidget);
      expect(find.textContaining('종목3'), findsNothing);
      expect(find.textContaining('종목4'), findsNothing);
      // 3개 초과이므로 더보기 버튼이 보여야 함
      expect(find.text('더보기'), findsOneWidget);
    });

    testWidgets('hides the more button when exactly 3 items exist',
        (tester) async {
      final strategy = ResponseStrategy(
        asof: '2026-08-10',
        marketMode: 'ATTACK',
        marketMessage: 'test',
        attackCandidates: _makeItems(3, prefix: 'A'),
        recoveryCandidates: const [],
        riskStocks: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponseStrategyCard(
              strategy: strategy,
              isLoading: false,
              hasError: false,
              onItemTap: ({required ticker, required stockName}) async {},
            ),
          ),
        ),
      );

      expect(find.textContaining('종목2'), findsOneWidget);
      expect(find.text('더보기'), findsNothing);
    });

    testWidgets('tapping a tile invokes onItemTap with correct ticker',
        (tester) async {
      String? tappedTicker;
      String? tappedName;

      final strategy = ResponseStrategy(
        asof: '2026-08-10',
        marketMode: 'ATTACK',
        marketMessage: 'test',
        attackCandidates: _makeItems(1, prefix: 'A'),
        recoveryCandidates: const [],
        riskStocks: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponseStrategyCard(
              strategy: strategy,
              isLoading: false,
              hasError: false,
              onItemTap: ({required ticker, required stockName}) async {
                tappedTicker = ticker;
                tappedName = stockName;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.textContaining('종목0'));
      await tester.pumpAndSettle();

      expect(tappedTicker, 'A0');
      expect(tappedName, '종목0');
    });

    // [Modified by Codex | 2026-08-28 KST]
    // 기존 "저장되면 onPressed=null(비활성)" 스펙을 진짜 toggle 스펙으로 교체.
    testWidgets(
        'star toggles watchlist state: empty star -> add, filled star -> remove',
        (tester) async {
      final api = FakeWatchlistApi();
      WatchlistStore.instance
        ..debugReset()
        ..debugSetApiService(api);

      final strategy = ResponseStrategy(
        asof: '2026-08-10',
        marketMode: 'ATTACK',
        marketMessage: 'test',
        attackCandidates: _makeItems(1, prefix: 'A'),
        recoveryCandidates: const [],
        riskStocks: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponseStrategyCard(
              strategy: strategy,
              isLoading: false,
              hasError: false,
              onItemTap: ({required ticker, required stockName}) async {},
            ),
          ),
        ),
      );

      // 처음에는 빈 별
      expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNothing);

      // 빈 별 클릭 -> add API 호출 -> 저장 true -> 채워진 별
      await tester.tap(find.byIcon(Icons.star_border_rounded));
      await tester.pumpAndSettle();

      expect(api.addCalls, <String>['A0']);
      expect(WatchlistStore.instance.isSaved('A0'), isTrue);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);

      // 채워진 별 클릭 -> delete API 호출 -> 저장 false -> 빈 별
      await tester.tap(find.byIcon(Icons.star_rounded));
      await tester.pumpAndSettle();

      expect(api.deleteCalls, <String>['A0']);
      expect(WatchlistStore.instance.isSaved('A0'), isFalse);
      expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
    });

    testWidgets(
        'already-saved ticker shows a filled star and the button stays enabled',
        (tester) async {
      WatchlistStore.instance
        ..debugReset()
        ..hydrate(const [WatchItem(ticker: 'A0', stockName: '종목0')]);

      final strategy = ResponseStrategy(
        asof: '2026-08-10',
        marketMode: 'ATTACK',
        marketMessage: 'test',
        attackCandidates: _makeItems(1, prefix: 'A'),
        recoveryCandidates: const [],
        riskStocks: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponseStrategyCard(
              strategy: strategy,
              isLoading: false,
              hasError: false,
              onItemTap: ({required ticker, required stockName}) async {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      final starButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.star_rounded),
      );
      expect(starButton.onPressed, isNotNull);
    });

    testWidgets(
        'more button navigates to ResponseStrategyListPage with full list',
        (tester) async {
      final strategy = ResponseStrategy(
        asof: '2026-08-10',
        marketMode: 'ATTACK',
        marketMessage: 'test',
        attackCandidates: _makeItems(5, prefix: 'A'),
        recoveryCandidates: const [],
        riskStocks: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponseStrategyCard(
              strategy: strategy,
              isLoading: false,
              hasError: false,
              onItemTap: ({required ticker, required stockName}) async {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('더보기'));
      await tester.pumpAndSettle();

      // 더보기 화면에서는 5개 전체가 보여야 함 (홈의 3개 제한과 무관)
      expect(find.byType(ResponseStrategyListPage), findsOneWidget);
      expect(find.textContaining('종목0'), findsOneWidget);
      expect(find.textContaining('종목4'), findsOneWidget);
    });
  });

  group('ResponseStrategyCard loading / error states', () {
    testWidgets('shows loading message without throwing when strategy is null',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponseStrategyCard(
              strategy: null,
              isLoading: true,
              hasError: false,
              onItemTap: ({required ticker, required stockName}) async {},
            ),
          ),
        ),
      );

      expect(find.text('전략 분석 중입니다...'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'shows an inline error message without throwing when the API failed',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponseStrategyCard(
              strategy: null,
              isLoading: false,
              hasError: true,
              onItemTap: ({required ticker, required stockName}) async {},
            ),
          ),
        ),
      );

      expect(
        find.text('전략 데이터를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('ResponseStrategyListPage', () {
    testWidgets('shows its own empty message when items is empty',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponseStrategyListPage(
            title: '공격 후보',
            accentColor: const Color(0xFFEF4444),
            emptyMessage: '현재 공격 조건을 충족한 종목이 없습니다. 기다리는 것도 전략입니다.',
            items: const [],
            onItemTap: ({required ticker, required stockName}) async {},
          ),
        ),
      );

      expect(
        find.text('현재 공격 조건을 충족한 종목이 없습니다. 기다리는 것도 전략입니다.'),
        findsOneWidget,
      );
    });

    testWidgets('tapping a row invokes onItemTap with correct ticker',
        (tester) async {
      String? tappedTicker;

      await tester.pumpWidget(
        MaterialApp(
          home: ResponseStrategyListPage(
            title: '공격 후보',
            accentColor: const Color(0xFFEF4444),
            emptyMessage: 'empty',
            items: _makeItems(2, prefix: 'A'),
            onItemTap: ({required ticker, required stockName}) async {
              tappedTicker = ticker;
            },
          ),
        ),
      );

      await tester.tap(find.text('종목0'));
      await tester.pumpAndSettle();

      expect(tappedTicker, 'A0');
    });

    // [Modified by Codex | 2026-08-28 KST]
    // 별을 누르면 즉시 채워진 별로 바뀌고 add API 가 호출되는지 검증(toggle 스펙).
    testWidgets(
        'tapping the star fills it immediately and calls addWatchlistItem',
        (tester) async {
      final api = FakeWatchlistApi();
      WatchlistStore.instance
        ..debugReset()
        ..debugSetApiService(api);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponseStrategyListPage(
            title: '공격 후보',
            accentColor: const Color(0xFFEF4444),
            emptyMessage: 'empty',
            items: _makeItems(1, prefix: 'A'),
            onItemTap: ({required ticker, required stockName}) async {},
          ),
        ),
      );

      expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNothing);

      await tester.tap(find.byIcon(Icons.star_border_rounded));
      await tester.pumpAndSettle();

      expect(api.addCalls, <String>['A0']);
      expect(find.byIcon(Icons.star_border_rounded), findsNothing);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });
  });
}
