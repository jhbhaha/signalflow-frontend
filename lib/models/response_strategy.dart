// File: response_strategy.dart (오늘의 대응 전략 응답 모델)
// [Added by Claude | 2026-08-10 KST]
// 홈 화면 "오늘의 대응 전략" 섹션(공격 후보 / 회복 후보 / 위험 종목)을 위한 모델.
// 백엔드 GET /dashboard/response-strategy 응답 구조와 1:1로 대응한다.

class ResponseStrategyItem {
  final String ticker;
  final String stockName;
  final int finalScore;
  final String finalStatus;
  final String strategyType;
  final String? strategyLevel;
  final String? strategyReason;

  ResponseStrategyItem({
    required this.ticker,
    required this.stockName,
    required this.finalScore,
    required this.finalStatus,
    required this.strategyType,
    required this.strategyLevel,
    required this.strategyReason,
  });

  factory ResponseStrategyItem.fromJson(Map<String, dynamic> json) {
    return ResponseStrategyItem(
      ticker: json['ticker'] ?? '',
      stockName: json['stock_name'] ?? '',
      finalScore: json['final_score'] ?? 0,
      finalStatus: json['final_status'] ?? '',
      strategyType: json['strategy_type'] ?? '',
      strategyLevel: json['strategy_level'],
      strategyReason: json['strategy_reason'],
    );
  }
}

class ResponseStrategy {
  final String asof;
  final String marketMode;
  final String marketMessage;
  final List<ResponseStrategyItem> attackCandidates;
  final List<ResponseStrategyItem> recoveryCandidates;
  final List<ResponseStrategyItem> riskStocks;

  ResponseStrategy({
    required this.asof,
    required this.marketMode,
    required this.marketMessage,
    required this.attackCandidates,
    required this.recoveryCandidates,
    required this.riskStocks,
  });

  factory ResponseStrategy.fromJson(Map<String, dynamic> json) {
    List<ResponseStrategyItem> parseItems(String key) {
      final List<dynamic> raw = json[key] as List<dynamic>? ?? <dynamic>[];
      return raw
          .map(
            (dynamic item) =>
                ResponseStrategyItem.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    return ResponseStrategy(
      asof: json['asof'] ?? '',
      marketMode: json['market_mode'] ?? 'NEUTRAL',
      marketMessage: json['market_message'] ?? '',
      attackCandidates: parseItems('attack_candidates'),
      recoveryCandidates: parseItems('recovery_candidates'),
      riskStocks: parseItems('risk_stocks'),
    );
  }
}
