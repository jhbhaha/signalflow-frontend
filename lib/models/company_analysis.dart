// File: company_analysis.dart
// Last Modified: 2026-06-15 11:45 KST
// Insert Location: G:\stockmarket_frontend\lib\models\company_analysis.dart 전체 교체

class CompanyAnalysis {
  final String stockCode;
  final String year;
  final FinancialSummary summary;
  final FinancialAnalysis analysis;

  CompanyAnalysis({
    required this.stockCode,
    required this.year,
    required this.summary,
    required this.analysis,
  });

  factory CompanyAnalysis.fromJson(Map<String, dynamic> json) {
    return CompanyAnalysis(
      stockCode: json['stock_code'] ?? '',
      year: json['year'] ?? '',
      summary: FinancialSummary.fromJson(json['summary'] ?? {}),
      analysis: FinancialAnalysis.fromJson(json['analysis'] ?? {}),
    );
  }
}

class FinancialSummary {
  final num? revenue;
  final num? operatingIncome;
  final num? netIncome;
  final num? totalAssets;
  final num? totalLiabilities;
  final num? totalEquity;
  final num? debtRatio;
  final num? roe;
  final num? operatingMargin;
  final num? netMargin;
  final num? currentPrice;
  final num? sharesOutstanding;
  final num? eps;
  final num? bps;
  final num? per;
  final num? pbr;
  final int financialScore;
  final String financialGrade;

  FinancialSummary({
    required this.revenue,
    required this.operatingIncome,
    required this.netIncome,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.totalEquity,
    required this.debtRatio,
    required this.roe,
    required this.operatingMargin,
    required this.netMargin,
    required this.currentPrice,
    required this.sharesOutstanding,
    required this.eps,
    required this.bps,
    required this.per,
    required this.pbr,
    required this.financialScore,
    required this.financialGrade,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      revenue: json['revenue'],
      operatingIncome: json['operating_income'],
      netIncome: json['net_income'],
      totalAssets: json['total_assets'],
      totalLiabilities: json['total_liabilities'],
      totalEquity: json['total_equity'],
      debtRatio: json['debt_ratio'],
      roe: json['roe'],
      operatingMargin: json['operating_margin'],
      netMargin: json['net_margin'],
      currentPrice: json['current_price'],
      sharesOutstanding: json['shares_outstanding'],
      eps: json['eps'],
      bps: json['bps'],
      per: json['per'],
      pbr: json['pbr'],

      financialScore: json['financial_score'] ?? 0,
      financialGrade: json['financial_grade'] ?? 'F',
    );
  }
}

class FinancialAnalysis {
  final int financialScore;
  final String financialGrade;
  final String financialOpinion;

  FinancialAnalysis({
    required this.financialScore,
    required this.financialGrade,
    required this.financialOpinion,
  });

  factory FinancialAnalysis.fromJson(Map<String, dynamic> json) {
    return FinancialAnalysis(
      financialScore: json['financial_score'] ?? 0,
      financialGrade: json['financial_grade'] ?? 'F',
      financialOpinion: json['financial_opinion'] ?? '',
    );
  }
}