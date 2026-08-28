// File: test/widgets/dashboard_price_display_test.dart
// [Added by Claude | 2026-08-27 KST]
// 홈 대시보드의 종목 카드(관심종목 변화 / 공격 후보 랭킹 / 오늘의 대응 전략)가
// 최근 종가를 84,500원 형식으로 표시하고, close 가 없으면 가격 영역을 숨기는지 검증.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_stock_frontend/models/dashboard_summary.dart';
import 'package:flutter_stock_frontend/models/response_strategy.dart';
import 'package:flutter_stock_frontend/models/signal_history_item.dart';
import 'package:flutter_stock_frontend/widgets/dashboard/attack_top5_card.dart';
import 'package:flutter_stock_frontend/widgets/dashboard/response_strategy_card.dart';
import 'package:flutter_stock_frontend/widgets/dashboard/top_signals_card.dart';

Widget _app(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

DashboardSummary _summaryWith(List<TopSignal> signals) => DashboardSummary(
      watchlistCount: signals.length,
      attackCount: signals.where((s) => s.finalStatus.startsWith('ATTACK')).length,
      watchCount: 0,
      riskCount: 0,
      waitCount: 0,
      marketStatus: 'ATTACK',
      marketMessage: 'test',
      topSignals: signals,
      etfSectors: const [],
    );

Color _statusColor(String status) => const Color(0xFFEF4444);

void main() {
  testWidgets('TopSignalsCard shows formatted close, hides it when null',
      (tester) async {
    final summary = _summaryWith([
      TopSignal(
        ticker: '005930',
        stockName: '삼성전자',
        finalStatus: 'ATTACK_STRONG',
        finalScore: 5,
        etfReason: null,
        close: 84500,
        asofDate: '2026-08-26',
      ),
      TopSignal(
        ticker: '000660',
        stockName: 'SK하이닉스',
        finalStatus: 'WATCH_NORMAL',
        finalScore: 3,
        etfReason: null,
      ),
    ]);

    await tester.pumpWidget(
      _app(
        TopSignalsCard(
          summary: summary,
          recentAttackTicker: null,
          signalHistoryCache: const <String, List<SignalHistoryItem>>{},
          statusColor: _statusColor,
          onSignalTap: ({required ticker, required stockName}) {},
        ),
      ),
    );

    expect(find.text('84,500원'), findsOneWidget);
    // 두 번째 종목은 close 가 없으므로 어떤 '원' 표기도 없어야 한다
    expect(find.textContaining('원'), findsOneWidget);
  });

  testWidgets('AttackTop5Card shows formatted close for attack signals',
      (tester) async {
    final summary = _summaryWith([
      TopSignal(
        ticker: '005930',
        stockName: '삼성전자',
        finalStatus: 'ATTACK_STRONG',
        finalScore: 5,
        etfReason: null,
        close: 84500,
      ),
    ]);

    await tester.pumpWidget(
      _app(
        AttackTop5Card(
          summary: summary,
          recentAttackTicker: null,
          onAttackTap: ({required ticker, required stockName}) async {},
        ),
      ),
    );

    expect(find.text('84,500원'), findsOneWidget);
  });

  testWidgets('ResponseStrategyCard shows close when provided, hides when null',
      (tester) async {
    ResponseStrategyItem item({double? close}) => ResponseStrategyItem(
          ticker: '005930',
          stockName: '삼성전자',
          finalScore: 5,
          finalStatus: 'ATTACK_STRONG',
          strategyType: 'ATTACK',
          strategyLevel: 'ATTACK_STRONG',
          strategyReason: '강한 공격 조건 충족',
          close: close,
        );

    ResponseStrategy strategyWith(ResponseStrategyItem i) => ResponseStrategy(
          asof: '2026-08-26',
          marketMode: 'ATTACK',
          marketMessage: 'test',
          attackCandidates: [i],
          recoveryCandidates: const [],
          riskStocks: const [],
        );

    await tester.pumpWidget(
      _app(
        ResponseStrategyCard(
          strategy: strategyWith(item(close: 84500)),
          isLoading: false,
          hasError: false,
          onItemTap: ({required ticker, required stockName}) async {},
        ),
      ),
    );
    expect(find.text('84,500원'), findsOneWidget);

    await tester.pumpWidget(
      _app(
        ResponseStrategyCard(
          strategy: strategyWith(item()),
          isLoading: false,
          hasError: false,
          onItemTap: ({required ticker, required stockName}) async {},
        ),
      ),
    );
    expect(find.textContaining('원'), findsNothing);
  });
}
