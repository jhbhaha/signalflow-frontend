// File: test/models/close_field_parsing_test.dart
// [Added by Claude | 2026-08-27 KST]
// 목록/이벤트 모델들이 백엔드의 close(최근 종가) 필드를 안전하게 파싱하는지 검증.
// - 값이 있으면 double 로 파싱
// - 값이 없으면(구형 캐시/미지원 API) null, 앱은 가격 UI를 숨겨야 한다

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_stock_frontend/models/notification_event.dart';
import 'package:flutter_stock_frontend/models/response_strategy.dart';
import 'package:flutter_stock_frontend/models/signal_history_item.dart';
import 'package:flutter_stock_frontend/models/stock_search_item.dart';

void main() {
  test('ResponseStrategyItem parses close/asof_date, legacy payload -> null', () {
    final priced = ResponseStrategyItem.fromJson({
      'ticker': '005930',
      'stock_name': '삼성전자',
      'final_score': 5,
      'final_status': 'ATTACK_STRONG',
      'strategy_type': 'ATTACK',
      'close': 84500,
      'asof_date': '2026-08-26',
    });
    final legacy = ResponseStrategyItem.fromJson({
      'ticker': '005930',
      'stock_name': '삼성전자',
      'final_score': 5,
      'final_status': 'ATTACK_STRONG',
      'strategy_type': 'ATTACK',
    });

    expect(priced.close, 84500.0);
    expect(priced.asofDate, '2026-08-26');
    expect(legacy.close, isNull);
    expect(legacy.asofDate, isNull);
  });

  test('StockSearchItem parses close, legacy payload -> null', () {
    final priced = StockSearchItem.fromJson({
      'ticker': '005930',
      'stock_name': '삼성전자',
      'close': 84500.0,
    });
    final legacy = StockSearchItem.fromJson({
      'ticker': '005930',
      'stock_name': '삼성전자',
    });

    expect(priced.close, 84500.0);
    expect(legacy.close, isNull);
  });

  test('SignalHistoryItem parses close, legacy payload -> null', () {
    final priced = SignalHistoryItem.fromJson({
      'timestamp': '2026-08-26 15:40',
      'ticker': '005930',
      'stock_name': '삼성전자',
      'current_status': 'ATTACK_STRONG',
      'final_score': 5,
      'close': 84500,
    });
    final legacy = SignalHistoryItem.fromJson({
      'timestamp': '2026-08-26 15:40',
      'ticker': '005930',
      'stock_name': '삼성전자',
      'current_status': 'ATTACK_STRONG',
      'final_score': 5,
    });

    expect(priced.close, 84500.0);
    expect(legacy.close, isNull);
  });

  test('NotificationEvent parses close, legacy payload -> null', () {
    final base = {
      'id': 'e1',
      'ticker': '005930',
      'stock_name': '삼성전자',
      'prev_status': 'WATCH_NORMAL',
      'current_status': 'ATTACK_STRONG',
      'final_score': 5,
      'message': '상태가 변경되었습니다.',
      'created_at': '2026-08-26 15:40',
      'read': false,
    };

    final priced = NotificationEvent.fromJson({...base, 'close': 84500});
    final legacy = NotificationEvent.fromJson(base);

    expect(priced.close, 84500.0);
    expect(legacy.close, isNull);
  });
}
