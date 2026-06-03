// File: analysis_screen.dart (분석 화면)
// [Added by ChatGPT | 2026-04-13 19:05 KST]
// Insert Location: lib/screens/analysis_screen.dart 새 파일 전체 생성

import 'package:flutter/material.dart';

import '../models/analysis_response.dart';
import '../services/analysis_api_service.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final TextEditingController _tickerController =
  TextEditingController(text: '071050');
  final TextEditingController _stockNameController =
  TextEditingController(text: '한국금융지주');

  AnalysisResponse? _result;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _tickerController.dispose();
    _stockNameController.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await AnalysisApiService.runOneAnalysis(
        ticker: _tickerController.text.trim(),
        stockName: _stockNameController.text.trim(),
      );

      setState(() {
        _result = result;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _result = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    if (status.contains('RISK')) return Colors.red;
    if (status.contains('ATTACK')) return Colors.green;
    if (status.contains('WATCH')) return Colors.orange;
    return Colors.blueGrey;
  }

  Widget _buildInfoCard({
    required String title,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildBulletList(List<String> items) {
    if (items.isEmpty) {
      return const Text('없음');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text('• $item'),
        ),
      )
          .toList(),
    );
  }

  Widget _buildResultView(AnalysisResponse result) {
    final Color statusColor = _statusColor(result.finalStatus ?? result.status);

    return Column(
      children: [
        _buildInfoCard(
          title: '기본 정보',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('종목명: ${result.stockName}'),
              Text('종목코드: ${result.ticker}'),
              Text('기준일: ${result.asofDate}'),
              Text('종가: ${result.close.toStringAsFixed(0)}'),
            ],
          ),
        ),
        _buildInfoCard(
          title: '상태 요약',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '기본 상태: ${result.status} (${result.statusLabelKo})',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('기본 점수: ${result.statusScore}'),
                    Text('최종 상태: ${result.finalStatus ?? result.status}'),
                    Text('최종 점수: ${result.finalScore ?? result.statusScore}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text('한 줄 요약: ${result.summary}'),
              const SizedBox(height: 8),
              Text('행동 가이드: ${result.actionGuide}'),
              if (result.etfReason != null) ...[
                const SizedBox(height: 8),
                Text('ETF 반영 사유: ${result.etfReason}'),
              ],
            ],
          ),
        ),
        _buildInfoCard(
          title: '판단 근거',
          child: _buildBulletList(result.reasons),
        ),
        _buildInfoCard(
          title: '위험 요소',
          child: _buildBulletList(result.riskFlags),
        ),
        _buildInfoCard(
          title: 'ETF 추천 결과',
          child: result.etfRecommendations.isEmpty
              ? const Text('ETF 추천 결과 없음')
              : Column(
            children: result.etfRecommendations.map((etf) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ETF 코드: ${etf.etfCode}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('상관계수: ${etf.correlation.toStringAsFixed(3)}'),
                    Text(
                      '상승 동조 확률: ${(etf.upProbability * 100).toStringAsFixed(1)}%',
                    ),
                    Text(
                      '하락 동조 확률: ${(etf.downProbability * 100).toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        _buildInfoCard(
          title: '알림',
          child: result.alerts.isEmpty
              ? const Text('발생한 알림 없음')
              : Column(
            children: result.alerts.map((alert) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.subject,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(alert.body),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        _buildInfoCard(
          title: '원본 메시지',
          child: Text(result.message),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주식 분석'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _tickerController,
                decoration: const InputDecoration(
                  labelText: '종목 코드',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _stockNameController,
                decoration: const InputDecoration(
                  labelText: '종목명',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _runAnalysis,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('분석 실행'),
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Expanded(
                child: _result == null
                    ? const Center(
                  child: Text('종목 코드와 종목명을 입력한 뒤 분석 실행을 누르세요.'),
                )
                    : SingleChildScrollView(
                  child: _buildResultView(_result!),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}