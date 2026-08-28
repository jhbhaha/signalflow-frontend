// File: analysis_price_chart_card_test.dart
// Verifies that the Y-axis of AnalysisPriceChartCard no longer renders the
// raw axis min/max edge labels that used to collide with the nearby rounded
// interval tick (see analysis_price_chart_card.dart for details).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:flutter_stock_frontend/models/price_chart_point.dart';
import 'package:flutter_stock_frontend/widgets/analysis_price_chart_card.dart';

String _formatPrice(double value) {
  return value
      .round()
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
}

List<PriceChartPoint> _buildItems(List<double> closes) {
  return [
    for (var i = 0; i < closes.length; i++)
      PriceChartPoint(
        date: '2026-08-${(i % 28 + 1).toString().padLeft(2, '0')}',
        close: closes[i],
      ),
  ];
}

// [Modified by Claude | 2026-08-28 KST] close + ma5/ma20/ma60 를 모두 채워
// 실제로 4개 라인이 생성되는 데이터.
List<PriceChartPoint> _buildItemsWithMa() {
  return [
    for (var i = 0; i < 6; i++)
      PriceChartPoint(
        date: '2026-08-${(i + 1).toString().padLeft(2, '0')}',
        close: 84000 + i * 100,
        ma5: 83000 + i * 100,
        ma20: 82000 + i * 100,
        ma60: 79000 + i * 100,
      ),
  ];
}

// 지정한 barIndex 라인의 터치 툴팁 항목을 계산한다.
// barIndex: 0=종가, 1=MA5, 2=MA20, 3=MA60
Future<LineTooltipItem> _tooltipItemFor(
  WidgetTester tester,
  int barIndex,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AnalysisPriceChartCard(items: _buildItemsWithMa()),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final chart = tester.widget<LineChart>(find.byType(LineChart));
  final bars = chart.data.lineBarsData;
  expect(bars.length, 4, reason: '종가 + MA5/MA20/MA60 = 4개 라인이 있어야 함');

  final bar = bars[barIndex];
  final spot = LineBarSpot(bar, barIndex, bar.spots.last);
  final items =
      chart.data.lineTouchData.touchTooltipData.getTooltipItems([spot]);
  return items.single!;
}

Future<void> _expectNoEdgeLabelCollision(
  WidgetTester tester,
  List<double> closes,
) async {
  final items = _buildItems(closes);
  final minPrice = closes.reduce((a, b) => a < b ? a : b);
  final maxPrice = closes.reduce((a, b) => a > b ? a : b);
  final minY = minPrice * 0.98;
  final maxY = maxPrice * 1.02;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AnalysisPriceChartCard(items: items),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // The raw axis min/max (e.g. 196,xxx / 369,750-style values) must not be
  // rendered as separate labels anymore.
  expect(find.text(_formatPrice(minY)), findsNothing);
  expect(find.text(_formatPrice(maxY)), findsNothing);
}

void main() {
  // [Modified by Codex | 2026-08-27 15:51 KST] 마지막 종가 고정 tooltip 회귀 테스트 추가
  testWidgets('keeps the latest close spot as a fixed tooltip indicator',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnalysisPriceChartCard(
            items: _buildItems([83000, 84000, 84500]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final indicator = chart.data.showingTooltipIndicators.single;
    final latestSpot = indicator.showingSpots.single;

    expect(latestSpot.x, 2);
    expect(latestSpot.y, 84500);
    expect(chart.data.lineTouchData.handleBuiltInTouches, isTrue);
  });

  // [Modified by Claude | 2026-08-28 KST]
  // 터치 툴팁에서 각 값이 어느 이동평균선인지 라벨 + 색으로 구분되는지 회귀 검증.
  testWidgets('MA5 tooltip is labeled "MA5" and uses the MA5 line color',
      (tester) async {
    final item = await _tooltipItemFor(tester, 1);
    expect(item.text, contains('MA5'));
    expect(item.textStyle.color, const Color(0xFFEF4444));
  });

  testWidgets('MA20 tooltip is labeled "MA20" and uses the MA20 line color',
      (tester) async {
    final item = await _tooltipItemFor(tester, 2);
    expect(item.text, contains('MA20'));
    expect(item.textStyle.color, const Color(0xFFF59E0B));
  });

  testWidgets('MA60 tooltip is labeled "MA60" and uses the MA60 line color',
      (tester) async {
    final item = await _tooltipItemFor(tester, 3);
    expect(item.text, contains('MA60'));
    expect(item.textStyle.color, const Color(0xFF3B82F6));
  });

  testWidgets('close tooltip is labeled "종가" and stays white',
      (tester) async {
    final item = await _tooltipItemFor(tester, 0);
    expect(item.text, contains('종가'));
    expect(item.textStyle.color, Colors.white);
  });

  testWidgets('hides duplicated edge labels for a low price range (~10k)',
      (tester) async {
    await _expectNoEdgeLabelCollision(
      tester,
      [10500, 10800, 10200, 11000, 10650, 10950, 10400],
    );
  });

  testWidgets('hides duplicated edge labels for a mid price range (~50k)',
      (tester) async {
    await _expectNoEdgeLabelCollision(
      tester,
      [50200, 51800, 49500, 52300, 50900, 51200, 49800],
    );
  });

  testWidgets('hides duplicated edge labels for a high price range (~100k)',
      (tester) async {
    await _expectNoEdgeLabelCollision(
      tester,
      [102000, 108500, 99500, 110200, 105300, 107100, 101800],
    );
  });

  testWidgets(
      'hides duplicated edge labels for a wide-range stock (~300k, like Samsung Electronics example)',
      (tester) async {
    await _expectNoEdgeLabelCollision(
      tester,
      [200884, 250000, 300000, 350000, 362500, 210000, 280000],
    );
  });
}
