// File: analysis_response.dart (분석 응답 모델)
// Last Modified: 2026-04-15 19:40 KST (작성자: ChatGPT)
// Insert Location: G:\stockmarket_frontend\lib\models\analysis_response.dart 전체 교체

class StatusChange {
  final bool changed;
  final String? prevStatus;
  final String currentStatus;

  StatusChange({
    required this.changed,
    required this.prevStatus,
    required this.currentStatus,
  });

  factory StatusChange.fromJson(Map<String, dynamic> json) {
    return StatusChange(
      changed: json['changed'] ?? false,
      prevStatus: json['prev_status'],
      currentStatus: json['current_status'] ?? '',
    );
  }

  // [Added by ChatGPT | 2026-04-15 19:40 KST] 기존 위젯 호환용 상태 변화 메시지 제공
  String? get message {
    if (!changed) return null;
    final prev = (prevStatus == null || prevStatus!.isEmpty) ? '없음' : prevStatus!;
    return '$prev → $currentStatus';
  }
}

class AlertItem {
  final String subject;
  final String body;

  AlertItem({
    required this.subject,
    required this.body,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      subject: json['subject'] ?? '',
      body: json['body'] ?? '',
    );
  }

  // [Added by ChatGPT | 2026-04-15 19:40 KST] 기존 위젯에서 alert.title 사용 중인 부분 호환
  String get title => subject;
}

class EtfRecommendation {
  final String etfCode;
  final double correlation;
  final double upProbability;
  final double downProbability;

  EtfRecommendation({
    required this.etfCode,
    required this.correlation,
    required this.upProbability,
    required this.downProbability,
  });

  factory EtfRecommendation.fromJson(Map<String, dynamic> json) {
    return EtfRecommendation(
      etfCode: json['etf_code'] ?? '',
      correlation: (json['correlation'] ?? 0).toDouble(),
      upProbability: (json['up_probability'] ?? 0).toDouble(),
      downProbability: (json['down_probability'] ?? 0).toDouble(),
    );
  }
  // [Added by ChatGPT | 2026-04-15 22:50 KST] ETF 코드별 표시 이름 반환
  String get etfName {
    switch (etfCode) {
      case '091160':
        return 'KODEX 반도체';
      case '305720':
        return 'TIGER 반도체';
      case '091170':
        return 'KODEX 은행/금융';
      case '139220':
        return 'TIGER 은행/금융';
      case '244580':
        return 'KODEX 바이오';
      case '069500':
        return 'KODEX 200';
      default:
        return etfCode;
    }
  }
}

class AnalysisResponse {
  final String ticker;
  final String stockName;
  final String asofDate;
  final double close;
  final double ma5;
  final double ma20;
  final double ma60;
  final String status;
  final int statusScore;
  final String statusLabelKo;
  final String message;
  final String summary;
  final String actionGuide;
  final List<String> riskFlags;
  final List<String> reasons;
  final List<AlertItem> alerts;
  final List<EtfRecommendation> etfRecommendations;
  final String? finalStatus;
  final int? finalScore;
  final String? etfReason;
  final double? etfCorrelation;
  final double? etfUpProb;
  // [2026-06-03 15:10 KST] AI 분석 결과 필드 (AI analysis result fields)
  final int? aiScore;
  final String? aiGrade;
  final String? aiStatus;
  final String? aiSummary;
  final String? aiDetail;


  // [2026-04-15 19:40 KST] 기존 위젯 호환용 필드 추가
  final bool shouldNotify;
  final StatusChange? statusChange;
  final String? changeAlert;

  AnalysisResponse({
    required this.ticker,
    required this.stockName,
    required this.asofDate,
    required this.close,
    required this.ma5,
    required this.ma20,
    required this.ma60,
    required this.status,
    required this.statusScore,
    required this.statusLabelKo,
    required this.message,
    required this.summary,
    required this.actionGuide,
    required this.riskFlags,
    required this.reasons,
    required this.alerts,
    required this.etfRecommendations,
    required this.finalStatus,
    required this.finalScore,
    required this.etfReason,
    required this.etfCorrelation,
    required this.etfUpProb,

    // [2026-06-03 15:10 KST]
    required this.aiScore,
    required this.aiGrade,
    required this.aiStatus,
    required this.aiSummary,
    required this.aiDetail,

    required this.shouldNotify,
    required this.statusChange,
    required this.changeAlert,
  });

  factory AnalysisResponse.fromJson(Map<String, dynamic> json) {
    return AnalysisResponse(
      ticker: json['ticker'] ?? '',
      stockName: json['stock_name'] ?? '',
      asofDate: json['asof_date'] ?? '',
      close: (json['close'] ?? 0).toDouble(),
      ma5: (json['ma5'] ?? 0).toDouble(),
      ma20: (json['ma20'] ?? 0).toDouble(),
      ma60: (json['ma60'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      statusScore: json['status_score'] ?? 0,
      statusLabelKo: json['status_label_ko'] ?? '',
      message: json['message'] ?? '',
      summary: json['summary'] ?? '',
      actionGuide: json['action_guide'] ?? '',
      riskFlags: List<String>.from(json['risk_flags'] ?? const []),
      reasons: List<String>.from(json['reasons'] ?? const []),
      alerts: (json['alerts'] as List<dynamic>? ?? [])
          .map((item) => AlertItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      etfRecommendations: (json['etf_recommendations'] as List<dynamic>? ?? [])
          .map((item) => EtfRecommendation.fromJson(item as Map<String, dynamic>))
          .toList(),
      finalStatus: json['final_status'],
      finalScore: json['final_score'],
      etfReason: json['etf_reason'],
      etfCorrelation: json['etf_correlation'] != null
          ? (json['etf_correlation'] as num).toDouble()
          : null,
      etfUpProb: json['etf_up_prob'] != null
          ? (json['etf_up_prob'] as num).toDouble()
          : null,
      // [2026-06-03 15:10 KST]
      // AI 분석 결과 파싱 (Parse AI analysis result)
      aiScore: json['ai_score'],
      aiGrade: json['ai_grade'],
      aiStatus: json['ai_status'],
      aiSummary: json['ai_summary'],
      aiDetail: json['ai_detail'],
      shouldNotify: json['should_notify'] ?? false,
      statusChange: json['status_change'] != null
          ? StatusChange.fromJson(json['status_change'] as Map<String, dynamic>)
          : null,
      changeAlert: json['change_alert'],
    );
  }
  // [Added by ChatGPT | 2026-04-27 20:00 KST] 안전한 기본값 생성 (필수 필드 모두 채움)
  factory AnalysisResponse.empty() {
    return AnalysisResponse(
      ticker: '',
      stockName: '',
      asofDate: '',
      close: 0,
      ma5: 0,
      ma20: 0,
      ma60: 0,
      status: '',
      statusScore: 0,
      statusLabelKo: '',
      message: '',
      summary: '',
      actionGuide: '',
      riskFlags: const [],
      reasons: const [],
      alerts: const [],
      etfRecommendations: const [],
      finalStatus: 'WAIT',
      finalScore: 0,
      etfReason: null,
      etfCorrelation: null,
      etfUpProb: null,

      // [2026-06-03 15:10 KST]
      aiScore: null,
      aiGrade: null,
      aiStatus: null,
      aiSummary: null,
      aiDetail: null,

      shouldNotify: false,
      statusChange: null,
      changeAlert: null,
    );
  }
}

