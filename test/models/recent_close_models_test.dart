// [Modified by Codex | 2026-08-27 15:51 KST] 최근 종가 nullable/숫자 타입 파싱 회귀 테스트 추가
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_stock_frontend/models/dashboard_summary.dart';
import 'package:flutter_stock_frontend/models/recommendation_item.dart';

void main() {
  test('TopSignal parses int and legacy missing close safely', () {
    final priced = TopSignal.fromJson({
      'ticker': '005930',
      'stock_name': '삼성전자',
      'final_status': 'ATTACK_STRONG',
      'final_score': 5,
      'close': 84500,
      'asof_date': '2026-08-26',
    });
    final legacy = TopSignal.fromJson({
      'ticker': '005930',
      'stock_name': '삼성전자',
    });

    expect(priced.close, 84500.0);
    expect(priced.asofDate, '2026-08-26');
    expect(legacy.close, isNull);
    expect(legacy.asofDate, isNull);
  });

  test('RecommendationItem parses double and legacy missing close safely', () {
    final priced = RecommendationItem.fromJson({
      'ticker': '005930',
      'stock_name': '삼성전자',
      'final_score': 5,
      'final_status': 'ATTACK_STRONG',
      'close': 84500.0,
      'asof_date': '2026-08-26',
    });
    final legacy = RecommendationItem.fromJson({
      'ticker': '005930',
      'stock_name': '삼성전자',
    });

    expect(priced.close, 84500.0);
    expect(priced.asofDate, '2026-08-26');
    expect(legacy.close, isNull);
    expect(legacy.asofDate, isNull);
  });
}
