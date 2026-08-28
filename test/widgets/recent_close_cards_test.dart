// [Modified by Codex | 2026-08-27 15:51 KST] 홈/분석 추천 카드 최근 종가 표시 회귀 테스트 추가
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_stock_frontend/models/dashboard_summary.dart';
import 'package:flutter_stock_frontend/models/recommendation_item.dart';
import 'package:flutter_stock_frontend/widgets/dashboard/recommendation_card.dart';
import 'package:flutter_stock_frontend/widgets/dashboard/today_market_brief_card.dart';

Widget _app(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  testWidgets('home top signal displays formatted recent close', (
    tester,
  ) async {
    final summary = DashboardSummary(
      watchlistCount: 1,
      attackCount: 1,
      watchCount: 0,
      riskCount: 0,
      waitCount: 0,
      marketStatus: 'ATTACK',
      marketMessage: '공격 후보가 있습니다.',
      topSignals: [
        TopSignal(
          ticker: '005930',
          stockName: '삼성전자',
          finalStatus: 'ATTACK_STRONG',
          finalScore: 5,
          etfReason: null,
          close: 84500,
          asofDate: '2026-08-26',
        ),
      ],
      etfSectors: const [],
    );

    await tester.pumpWidget(
      _app(
        TodayMarketBriefCard(
          summary: summary,
          recommendations: const [],
          onBestTap: () {},
          onSignalTap: ({required ticker, required stockName}) {},
        ),
      ),
    );

    expect(find.text('84,500원'), findsOneWidget);
  });

  testWidgets('analysis recommendation displays formatted recent close', (
    tester,
  ) async {
    final item = RecommendationItem(
      ticker: '005930',
      stockName: '삼성전자',
      finalScore: 5,
      finalStatus: 'ATTACK_STRONG',
      etfReason: null,
      close: 84500,
      asofDate: '2026-08-26',
    );

    await tester.pumpWidget(
      _app(
        RecommendationCard(
          recommendations: [item],
          onItemTap: ({required ticker, required stockName}) async {},
        ),
      ),
    );

    expect(find.text('84,500원'), findsOneWidget);
  });

  testWidgets('legacy cards hide the missing price area', (tester) async {
    final item = RecommendationItem(
      ticker: '005930',
      stockName: '삼성전자',
      finalScore: 5,
      finalStatus: 'ATTACK_STRONG',
      etfReason: null,
    );

    await tester.pumpWidget(
      _app(
        RecommendationCard(
          recommendations: [item],
          onItemTap: ({required ticker, required stockName}) async {},
        ),
      ),
    );

    expect(find.textContaining('원'), findsNothing);
  });
}
