// File: company_trend.dart
// Last Modified: 2026-06-15 13:30 KST (작성자: ChatGPT)
// Insert Location: G:\stockmarket_frontend\lib\models\company_trend.dart 새 파일 생성

class CompanyTrend {
  final String stockCode;
  final String startYear;
  final String endYear;
  final List<TrendItem> items;
  final TrendGrowth growth;

  CompanyTrend({
    required this.stockCode,
    required this.startYear,
    required this.endYear,
    required this.items,
    required this.growth,
  });

  factory CompanyTrend.fromJson(Map<String, dynamic> json) {
    return CompanyTrend(
      stockCode: json['stock_code'] ?? '',
      startYear: json['start_year'] ?? '',
      endYear: json['end_year'] ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => TrendItem.fromJson(e))
          .toList(),
      growth: TrendGrowth.fromJson(json['growth'] ?? {}),
    );
  }
}

class TrendItem {
  final String year;
  final num? revenue;
  final num? operatingIncome;
  final num? netIncome;

  TrendItem({
    required this.year,
    required this.revenue,
    required this.operatingIncome,
    required this.netIncome,
  });

  factory TrendItem.fromJson(Map<String, dynamic> json) {
    return TrendItem(
      year: json['year'] ?? '',
      revenue: json['revenue'],
      operatingIncome: json['operating_income'],
      netIncome: json['net_income'],
    );
  }
}

class TrendGrowth {
  final num? revenueGrowthRate;
  final num? operatingIncomeGrowthRate;
  final num? netIncomeGrowthRate;

  TrendGrowth({
    required this.revenueGrowthRate,
    required this.operatingIncomeGrowthRate,
    required this.netIncomeGrowthRate,
  });

  factory TrendGrowth.fromJson(Map<String, dynamic> json) {
    return TrendGrowth(
      revenueGrowthRate: json['revenue_growth_rate'],
      operatingIncomeGrowthRate:
      json['operating_income_growth_rate'],
      netIncomeGrowthRate:
      json['net_income_growth_rate'],
    );
  }
}