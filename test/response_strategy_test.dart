// File: test/response_strategy_test.dart (오늘의 대응 전략 테스트)
// [Added by Claude | 2026-08-10 KST]
// ResponseStrategy 모델 파싱 및 ResponseStrategyCard 빈 상태 위젯 테스트.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_stock_frontend/models/response_strategy.dart';
import 'package:flutter_stock_frontend/screens/response_strategy_list_page.dart';
import 'package:flutter_stock_frontend/widgets/dashboard/response_strategy_card.dart';

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
              savedTickers: const [],
              onItemTap: ({required ticker, required stockName}) async {},
              onSaveTap: ({required ticker, required stockName}) async {},
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
              savedTickers: const [],
              onItemTap: ({required ticker, required stockName}) async {},
              onSaveTap: ({required ticker, required stockName}) async {},
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
              savedTickers: const [],
              onItemTap: ({required ticker, required stockName}) async {},
              onSaveTap: ({required ticker, required stockName}) async {},
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
              savedTickers: const [],
              onItemTap: ({required ticker, required stockName}) async {
                tappedTicker = ticker;
                tappedName = stockName;
              },
              onSaveTap: ({required ticker, required stockName}) async {},
            ),
          ),
        ),
      );

      await tester.tap(find.textContaining('종목0'));
      await tester.pumpAndSettle();

      expect(tappedTicker, 'A0');
      expect(tappedName, '종목0');
    });

    testWidgets(
        'tapping the save star invokes onSaveTap; already-saved tickers show checkmark',
        (tester) async {
      String? savedTicker;

      final strategy = ResponseStrategy(
        asof: '2026-08-10',
        marketMode: 'ATTACK',
        marketMessage: 'test',
        attackCandidates: _makeItems(2, prefix: 'A'),
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
              // A0은 이미 관심종목에 저장된 상태로 시작
              savedTickers: const ['A0'],
              onItemTap: ({required ticker, required stockName}) async {},
              onSaveTap: ({required ticker, required stockName}) async {
                savedTicker = ticker;
              },
            ),
          ),
        ),
      );

      // 이미 저장된 A0은 체크 아이콘, 저장 콜백은 비활성(onPressed: null)
      final savedButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.check_circle_rounded),
      );
      expect(savedButton.onPressed, isNull);

      // 아직 저장되지 않은 A1의 별 아이콘을 누르면 onSaveTap 호출
      await tester.tap(
        find.widgetWithIcon(IconButton, Icons.star_border_rounded),
      );
      await tester.pumpAndSettle();

      expect(savedTicker, 'A1');
    });

    testWidgets('more button navigates to ResponseStrategyListPage with full list',
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
              savedTickers: const [],
              onItemTap: ({required ticker, required stockName}) async {},
              onSaveTap: ({required ticker, required stockName}) async {},
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
              savedTickers: const [],
              onItemTap: ({required ticker, required stockName}) async {},
              onSaveTap: ({required ticker, required stockName}) async {},
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
              savedTickers: const [],
              onItemTap: ({required ticker, required stockName}) async {},
              onSaveTap: ({required ticker, required stockName}) async {},
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
            savedTickers: const [],
            onItemTap: ({required ticker, required stockName}) async {},
            onSaveTap: ({required ticker, required stockName}) async {},
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
            savedTickers: const [],
            onItemTap: ({required ticker, required stockName}) async {
              tappedTicker = ticker;
            },
            onSaveTap: ({required ticker, required stockName}) async {},
          ),
        ),
      );

      await tester.tap(find.text('종목0'));
      await tester.pumpAndSettle();

      expect(tappedTicker, 'A0');
    });

    testWidgets(
        'saving an item updates its own icon to checkmark immediately',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponseStrategyListPage(
            title: '공격 후보',
            accentColor: const Color(0xFFEF4444),
            emptyMessage: 'empty',
            items: _makeItems(1, prefix: 'A'),
            savedTickers: const [],
            onItemTap: ({required ticker, required stockName}) async {},
            onSaveTap: ({required ticker, required stockName}) async {},
          ),
        ),
      );

      expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

      await tester.tap(find.byIcon(Icons.star_border_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star_border_rounded), findsNothing);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });
  });
}
