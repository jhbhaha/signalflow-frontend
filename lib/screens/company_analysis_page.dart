// File: company_analysis_page.dart
// Last Modified: 2026-06-12 17:20 KST (작성자: ChatGPT)
// Insert Location: G:\stockmarket_frontend\lib\screens\company_analysis_page.dart 새 파일 생성

import 'package:flutter/material.dart';

import '../models/company_analysis.dart';
import '../services/company_analysis_service.dart';

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

class _CompanyAnalysisPageState extends State<CompanyAnalysisPage> {
  final CompanyAnalysisService _service = CompanyAnalysisService();

  CompanyAnalysis? _analysis;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    try {
      // [2026-06-13 16:15 KST]
      // DART 사업보고서는 보통 전년도 기준으로 조회
      final targetYear = (DateTime.now().year - 1).toString();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.stockName} 재무분석'),
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
        child: Text(_error!),
      );
    }

    if (_analysis == null) {
      return const Center(
        child: Text('데이터가 없습니다.'),
      );
    }

    final summary = _analysis!.summary;
    final analysis = _analysis!.analysis;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    analysis.financialGrade,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '재무점수 ${analysis.financialScore}점',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                analysis.financialOpinion,
                style: const TextStyle(fontSize: 16),
              ),
            ),
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

          _buildMetricCard(
            title: 'ROE',
            value: '${summary.roe ?? '-'}%',
          ),

          _buildMetricCard(
            title: '부채비율',
            value: '${summary.debtRatio ?? '-'}%',
          ),

          _buildMetricCard(
            title: '영업이익률',
            value: '${summary.operatingMargin ?? '-'}%',
          ),

          _buildMetricCard(
            title: '순이익률',
            value: '${summary.netMargin ?? '-'}%',
          ),
        ],
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