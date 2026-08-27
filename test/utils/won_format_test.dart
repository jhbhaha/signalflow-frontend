// File: test/utils/won_format_test.dart
// [Added by Claude | 2026-08-27 KST] 최근 종가 원화 포맷 유틸 회귀 테스트

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_stock_frontend/utils/won_format.dart';

void main() {
  group('formatWonPrice', () {
    test('formats integer close with thousands separators', () {
      expect(formatWonPrice(84500), '84,500원');
      expect(formatWonPrice(350000), '350,000원');
      expect(formatWonPrice(1250000), '1,250,000원');
    });

    test('formats double close (rounds to won)', () {
      expect(formatWonPrice(84500.0), '84,500원');
      expect(formatWonPrice(84499.6), '84,500원');
    });

    test('small prices (< 1,000) are left without a separator', () {
      expect(formatWonPrice(940), '940원');
    });

    test('returns null for missing / non-positive / non-finite values', () {
      expect(formatWonPrice(null), isNull);
      expect(formatWonPrice(0), isNull);
      expect(formatWonPrice(-100), isNull);
      expect(formatWonPrice(double.nan), isNull);
      expect(formatWonPrice(double.infinity), isNull);
    });
  });
}
