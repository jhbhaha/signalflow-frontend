// File: company_analysis_page.dart
// Last Modified: 2026-06-13 17:45 KST (작성자: ChatGPT)
// Insert Location: G:\stockmarket_frontend\lib\screens\company_analysis_page.dart 전체 교체

import 'package:flutter/material.dart';

import '../models/company_analysis.dart';
import '../services/company_analysis_service.dart';
// [2026-06-15 13:50 KST]
import '../models/company_trend.dart';

class CompanyAnalysisPage extends StatefulWidget {
  final String stockCode;
  final String stockName;

  const CompanyAnalysisPage({
    super.key,
    required this.stockCode,
    required this.stockName,
  });

  @override
  State<CompanyAnalysisPage> createState() => _CompanyAnalysisPageState();
}

class _CompanyAnalysisPageState extends State<CompanyAnalysisPage>
    with SingleTickerProviderStateMixin {
  final CompanyAnalysisService _service = CompanyAnalysisService();

  CompanyAnalysis? _analysis;
  bool _isLoading = true;
  String? _error;
  // [2026-06-15 13:50 KST]
  CompanyTrend? _trend;
  // [2026-06-15 15:05 KST]
  // 실적 탭 진입 시에만 실적추이 API 호출
  TabController? _tabController;
  bool _isTrendLoading = false;
  String? _trendError;

  @override
  void initState() {
    super.initState();

    // [2026-06-15 15:05 KST]
    // 탭 이동 감지용 컨트롤러
    _tabController = TabController(
      length: 6,
      vsync: this,
    );

    _tabController!.addListener(() {
      if (_tabController!.index == 1 && !_tabController!.indexIsChanging) {
        _loadTrendIfNeeded();
      }
    });

    _loadAnalysis();
  }

  @override
  void dispose() {
    // [2026-06-15 15:05 KST]
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadAnalysis() async {
    try {
      // [2026-06-13 17:45 KST]
      // DART 사업보고서는 보통 전년도 기준으로 조회
      final targetYear = (DateTime.now().year - 1).toString();

      // [2026-06-15 15:05 KST]
      // 첫 화면에서는 재무분석 API만 호출하여 초기 로딩 속도 개선
      final result = await _service.fetchCompanyAnalysis(
        stockCode: widget.stockCode,
        year: targetYear,
      );

      if (!mounted) return;

      setState(() {
        _analysis = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // [2026-06-15 15:05 KST]
  // 실적 탭에 처음 진입했을 때만 실적추이 API 호출
  Future<void> _loadTrendIfNeeded() async {
    if (_trend != null || _isTrendLoading) {
      return;
    }

    setState(() {
      _isTrendLoading = true;
      _trendError = null;
    });

    try {
      final trend = await _service.fetchCompanyTrend(
        stockCode: widget.stockCode,
      );

      if (!mounted) return;

      setState(() {
        _trend = trend;
        _isTrendLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _trendError = e.toString();
        _isTrendLoading = false;
      });
    }
  }
  String _formatNumber(num? value) {
    if (value == null) {
      return '-';
    }

    if (value >= 1000000000000) {
      return '${(value / 1000000000000).toStringAsFixed(2)}조';
    }

    if (value >= 100000000) {
      return '${(value / 100000000).toStringAsFixed(2)}억';
    }

    return value.toStringAsFixed(0);
  }

  // [2026-06-15 14:35 KST]
  // 투자지표용 천 단위 쉼표 포맷
  String _formatCommaNumber(num? value) {
    if (value == null) {
      return '-';
    }

    final text = value.toInt().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final positionFromEnd = text.length - i;

      buffer.write(text[i]);

      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }

    return buffer.toString();
  }

  String _formatPercent(num? value) {
    if (value == null) {
      return '-';
    }

    return '${value.toStringAsFixed(2)}%';
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'S':
        return const Color(0xFF8B5CF6);
      case 'A':
        return const Color(0xFF22C55E);
      case 'B':
        return const Color(0xFF3B82F6);
      case 'C':
        return const Color(0xFFF59E0B);
      case 'D':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF991B1B);
    }
  }

  // [2026-06-13 18:00 KST]
  // 수익성 해석 문장 생성
  String _profitabilityOpinion(FinancialSummary summary) {
    final roe = summary.roe;
    final operatingMargin = summary.operatingMargin;
    final netMargin = summary.netMargin;

    if ((roe ?? 0) >= 10 && (operatingMargin ?? 0) >= 10) {
      return 'ROE와 영업이익률이 양호하여 수익성이 좋은 편입니다.';
    }

    if ((roe ?? 0) > 0 && (netMargin ?? 0) > 0) {
      return '흑자를 유지하고 있으나 수익성 지표는 추가 확인이 필요합니다.';
    }

    return '수익성 지표가 약하거나 확인이 어렵습니다.';
  }

  String _stabilityOpinion(FinancialSummary summary) {
    final debtRatio = summary.debtRatio;

    if (debtRatio == null) {
      return '부채비율 데이터를 확인하지 못했습니다.';
    }

    if (debtRatio <= 100) {
      return '부채비율이 낮아 재무 안정성이 좋은 편입니다.';
    }

    if (debtRatio <= 200) {
      return '부채비율은 관리 가능한 수준입니다.';
    }

    if (debtRatio <= 300) {
      return '부채비율이 다소 높은 편입니다.';
    }

    return '부채비율이 매우 높아 재무 안정성 확인이 필요합니다.';
  }

  String _performanceOpinion(FinancialSummary summary) {
    final revenue = summary.revenue;
    final operatingIncome = summary.operatingIncome;
    final netIncome = summary.netIncome;

    if ((revenue ?? 0) > 0 &&
        (operatingIncome ?? 0) > 0 &&
        (netIncome ?? 0) > 0) {
      return '매출, 영업이익, 순이익이 모두 확인되며 흑자 구조입니다.';
    }

    if ((revenue ?? 0) > 0 && (operatingIncome ?? 0) > 0) {
      return '매출과 영업이익은 확인되지만 순이익까지 함께 확인해야 합니다.';
    }

    return '실적 데이터가 부족하거나 손익 확인이 필요합니다.';
  }

  String _questionAnswer({
    required String question,
    required FinancialSummary summary,
    required FinancialAnalysis analysis,
  }) {
    if (question == '최근 실적은 좋은가요?') {
      return '${_performanceOpinion(summary)} '
          '매출액은 ${_formatNumber(summary.revenue)}, '
          '영업이익은 ${_formatNumber(summary.operatingIncome)}, '
          '순이익은 ${_formatNumber(summary.netIncome)}입니다.';
    }

    if (question == '부채비율은 위험한가요?') {
      return '${_stabilityOpinion(summary)} '
          '현재 부채비율은 ${_formatPercent(summary.debtRatio)}입니다.';
    }

    if (question == '수익성은 좋은가요?') {
      return '${_profitabilityOpinion(summary)} '
          'ROE는 ${_formatPercent(summary.roe)}, '
          '영업이익률은 ${_formatPercent(summary.operatingMargin)}, '
          '순이익률은 ${_formatPercent(summary.netMargin)}입니다.';
    }

    if (question == '재무등급이 높은 이유는?') {
      return '재무등급은 ${analysis.financialGrade}, '
          '재무점수는 ${analysis.financialScore}점입니다. '
          '${analysis.financialOpinion}';
    }

    return '투자 판단 시 실적, 부채비율, 수익성, 주가 흐름을 함께 확인해야 합니다. '
        '현재 재무등급은 ${analysis.financialGrade}이며, '
        '부채비율은 ${_formatPercent(summary.debtRatio)}, '
        'ROE는 ${_formatPercent(summary.roe)}입니다.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('${widget.stockName} 재무분석'),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: [
              Tab(text: '요약'),
              Tab(text: '실적'),
              Tab(text: '안정성'),
              Tab(text: '수익성'),
              Tab(text: '투자지표'),
              Tab(text: '질문'),
            ],
          ),
        ),
        body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(_error!),
        ),
      );
    }

    if (_analysis == null) {
      return const Center(
        child: Text('데이터가 없습니다.'),
      );
    }

    final summary = _analysis!.summary;
    final analysis = _analysis!.analysis;

    return TabBarView(
      controller: _tabController,
      children: [
        _buildSummaryTab(summary, analysis),
        _buildPerformanceTab(summary, _trend),
        _buildStabilityTab(summary),
        _buildProfitabilityTab(summary),

        // [2026-06-15 12:00 KST]
        _buildInvestmentTab(summary),

        _buildQuestionTab(summary, analysis),
      ],
    );
  }

  Widget _buildSummaryTab(
      FinancialSummary summary,
      FinancialAnalysis analysis,
      ) {
    final gradeColor = _gradeColor(analysis.financialGrade);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Text(
                  analysis.financialGrade,
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: gradeColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '재무점수 ${analysis.financialScore}점',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildOpinionCard(
          title: '종합 의견',
          content: analysis.financialOpinion,
          icon: Icons.psychology,
          color: gradeColor,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: '매출액',
          value: _formatNumber(summary.revenue),
        ),
        _buildMetricCard(
          title: '영업이익',
          value: _formatNumber(summary.operatingIncome),
        ),
        _buildMetricCard(
          title: '순이익',
          value: _formatNumber(summary.netIncome),
        ),
      ],
    );
  }

  // [2026-06-15 14:10 KST]
  // 실적추이 탭
  Widget _buildPerformanceTab(
      FinancialSummary summary,
      CompanyTrend? trend,
      ) {
    // [2026-06-15 15:05 KST]
    // 실적 탭 진입 전에는 API를 호출하지 않음
    if (_isTrendLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_trendError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_trendError!),
        ),
      );
    }

    if (trend == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _loadTrendIfNeeded,
            child: const Text('실적추이 불러오기'),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildOpinionCard(
          title: '실적 해석',
          content: _performanceOpinion(summary),
          icon: Icons.bar_chart,
          color: const Color(0xFF3B82F6),
        ),

        const SizedBox(height: 12),

        ...trend.items.map(
              (item) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.year}년',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    '매출액 : ${_formatNumber(item.revenue)}',
                  ),
                  Text(
                    '영업이익 : ${_formatNumber(item.operatingIncome)}',
                  ),
                  Text(
                    '순이익 : ${_formatNumber(item.netIncome)}',
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        _buildMetricCard(
          title: '매출 성장률',
          value:
          '${trend.growth.revenueGrowthRate?.toStringAsFixed(2) ?? '-'}%',
        ),

        _buildMetricCard(
          title: '영업이익 성장률',
          value:
          '${trend.growth.operatingIncomeGrowthRate?.toStringAsFixed(2) ?? '-'}%',
        ),

        _buildMetricCard(
          title: '순이익 성장률',
          value:
          '${trend.growth.netIncomeGrowthRate?.toStringAsFixed(2) ?? '-'}%',
        ),
      ],
    );
  }

  Widget _buildStabilityTab(FinancialSummary summary) {
    final debtRatio = summary.debtRatio ?? 0;
    final isRisk = debtRatio > 300;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildOpinionCard(
          title: '안정성 해석',
          content: _stabilityOpinion(summary),
          icon: Icons.health_and_safety,
          color: isRisk
              ? const Color(0xFFEF4444)
              : const Color(0xFF22C55E),
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: '총자산',
          value: _formatNumber(summary.totalAssets),
        ),
        _buildMetricCard(
          title: '총부채',
          value: _formatNumber(summary.totalLiabilities),
        ),
        _buildMetricCard(
          title: '총자본',
          value: _formatNumber(summary.totalEquity),
        ),
        _buildMetricCard(
          title: '부채비율',
          value: _formatPercent(summary.debtRatio),
        ),
      ],
    );
  }

  Widget _buildProfitabilityTab(FinancialSummary summary) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildOpinionCard(
          title: '수익성 해석',
          content: _profitabilityOpinion(summary),
          icon: Icons.trending_up,
          color: const Color(0xFF8B5CF6),
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: 'ROE',
          value: _formatPercent(summary.roe),
        ),
        _buildMetricCard(
          title: '영업이익률',
          value: _formatPercent(summary.operatingMargin),
        ),
        _buildMetricCard(
          title: '순이익률',
          value: _formatPercent(summary.netMargin),
        ),
      ],
    );
  }

  // [2026-06-15 12:00 KST]
  // 투자지표 탭
  Widget _buildInvestmentTab(FinancialSummary summary) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMetricCard(
          title: '현재가',
          value: _formatCommaNumber(summary.currentPrice),
        ),
        _buildMetricCard(
          title: '발행주식수',
          value: _formatCommaNumber(summary.sharesOutstanding),
        ),
        _buildMetricCard(
          title: 'EPS',
          value: _formatCommaNumber(summary.eps),
        ),
        _buildMetricCard(
          title: 'BPS',
          value: _formatCommaNumber(summary.bps),
        ),
        _buildMetricCard(
          title: 'PER',
          value: summary.per?.toStringAsFixed(2) ?? '-',
        ),
        _buildMetricCard(
          title: 'PBR',
          value: summary.pbr?.toStringAsFixed(2) ?? '-',
        ),
      ],
    );
  }

  Widget _buildQuestionTab(
      FinancialSummary summary,
      FinancialAnalysis analysis,
      ) {
    final questions = [
      '최근 실적은 좋은가요?',
      '부채비율은 위험한가요?',
      '수익성은 좋은가요?',
      '재무등급이 높은 이유는?',
      '투자 시 주의할 점은?',
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: questions.map((question) {
        return Card(
          child: ExpansionTile(
            title: Text(
              question,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _questionAnswer(
                      question: question,
                      summary: summary,
                      analysis: analysis,
                    ),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOpinionCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
  }) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}