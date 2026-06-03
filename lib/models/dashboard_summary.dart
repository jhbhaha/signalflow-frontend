// File: dashboard_summary.dart (대시보드 요약 모델)
// [Added by ChatGPT | 2026-04-25 19:00 KST]
// Insert Location: G:\stockmarket_frontend\lib\models\dashboard_summary.dart 새 파일 생성

class TopSignal {
  final String ticker;
  final String stockName;
  final String finalStatus;
  final int finalScore;
  final String? etfReason;

  TopSignal({
    required this.ticker,
    required this.stockName,
    required this.finalStatus,
    required this.finalScore,
    required this.etfReason,
  });

  factory TopSignal.fromJson(Map<String, dynamic> json) {
    return TopSignal(
      ticker: json['ticker'] ?? '',
      stockName: json['stock_name'] ?? '',
      finalStatus: json['final_status'] ?? '',
      finalScore: json['final_score'] ?? 0,
      etfReason: json['etf_reason'],
    );
  }
}

// [Added by ChatGPT | 2026-05-12 18:35 KST]
// ETF 섹터 흐름 모델 추가
// (Add ETF sector flow model)

class EtfSectorFlow {
  final String sector;
  final int count;
  final double avgCorrelation;
  final double avgUpProbability;
  final String trend;

  const EtfSectorFlow({
    required this.sector,
    required this.count,
    required this.avgCorrelation,
    required this.avgUpProbability,
    required this.trend,
  });

  factory EtfSectorFlow.fromJson(
      Map<String, dynamic> json,
      ) {
    return EtfSectorFlow(
      sector: json['sector'] ?? '',
      count: json['count'] ?? 0,
      avgCorrelation:
      (json['avg_correlation'] ?? 0).toDouble(),
      avgUpProbability:
      (json['avg_up_probability'] ?? 0).toDouble(),
      trend: json['trend'] ?? 'NEUTRAL',
    );
  }
}

class DashboardSummary {
  final int watchlistCount;
  final int attackCount;
  final int watchCount;
  final int riskCount;
  final int waitCount;
  final String marketStatus;
  final String marketMessage;
  final List<TopSignal> topSignals;
  // [Added by ChatGPT | 2026-05-12 18:35 KST]
  // ETF 섹터 흐름 목록 추가
  // (Add ETF sector flow list)
  final List<EtfSectorFlow> etfSectors;

  DashboardSummary({
    required this.watchlistCount,
    required this.attackCount,
    required this.watchCount,
    required this.riskCount,
    required this.waitCount,
    required this.marketStatus,
    required this.marketMessage,
    required this.topSignals,
    required this.etfSectors,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      watchlistCount: json['watchlist_count'] ?? 0,
      attackCount: json['attack_count'] ?? 0,
      watchCount: json['watch_count'] ?? 0,
      riskCount: json['risk_count'] ?? 0,
      waitCount: json['wait_count'] ?? 0,
      marketStatus: json['market_status'] ?? '',
      marketMessage: json['market_message'] ?? '',
      topSignals: (json['top_signals'] as List<dynamic>? ?? [])
          .map((item) => TopSignal.fromJson(item as Map<String, dynamic>))
          .toList(),
      etfSectors:
      (json['etf_sectors'] as List<dynamic>? ?? [])
          .map(
            (item) => EtfSectorFlow.fromJson(
          item as Map<String, dynamic>,
        ),
      )
          .toList(),
    );
  }
}