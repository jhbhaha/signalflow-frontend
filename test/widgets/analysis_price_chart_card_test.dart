// File: analysis_price_chart_card_test.dart
// Verifies that the Y-axis of AnalysisPriceChartCard no longer renders the
// raw axis min/max edge labels that used to collide with the nearby rounded
// interval tick (see analysis_price_chart_card.dart for details).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
