// File: lib/screens/analysis_result_page.dart (분석 결과 화면)
// Insert Location: G:\stockmarket_frontend\lib\screens\analysis_result_page.dart 전체 교체

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
// 분석 결과 화면에서 관심종목 저장 API 사용
import '../services/api_service.dart';
// [2026-05-27 10:55 KST]
// 상태 설명 페이지 import (Import status help page)
import 'status_help_page.dart';
// [2026-06-02 13:40 KST]
// 종목 상태 이력 화면
import 'signal_detail_history_page.dart';
// [2026-05-28 20:15 KST]
// 분석 가격 차트 카드 추가 (Add analysis price chart card)
import '../widgets/analysis_price_chart_card.dart';
// [2026-06-05 00:20 KST]
// AdMob 배너 광고 위젯 (AdMob banner ad widget)
import '../widgets/admob_banner_ad_widget.dart';
// 가격 차트 모델 추가 (Add price chart model)
import '../models/price_chart_point.dart';

// [2026-05-27 14:10 KST]
// ticker 기반 상세 분석 구조로 변경(Change to ticker-based detailed analysis structure)
class AnalysisResultPage extends StatefulWidget {

  final String ticker;
  final String stockName;

  const AnalysisResultPage({
    super.key,
    required this.ticker,
    required this.stockName,
  });

  @override
  State<AnalysisResultPage> createState() => _AnalysisResultPageState();
}

class _AnalysisResultPageState extends State<AnalysisResultPage> {
  bool _isLoading = true;
  // [2026-05-27 10:10 KST]
  // 상태요약 카드 중복 터치 방지용 플래그 (Navigation duplicate tap guard)
  bool _isOpeningStatusSummary = false;
  String? _error;
  Map<String, dynamic>? _result;
  // [2026-05-28 20:15 KST]
  // 가격 차트 데이터(Price chart data)
  List<PriceChartPoint> _chartItems = [];
  // 관심종목 저장용 API 서비스
  final ApiService _apiService = ApiService();
  // KST] 이미 관심종목에 저장된 종목인지 확인하기 위한 상태값 추가
  bool _isSavedToWatchlist = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    if (!_isLoading) return;

    try {
      final analysis = await _apiService.analyzeSingle(
        ticker: widget.ticker,
        stockName: widget.stockName,
      );

      // [2026-05-28 20:15 KST]
      // 가격 차트 데이터 조회 (Fetch price chart data)
      final chartItems =
      await _apiService.fetchPriceChart(
        ticker: widget.ticker,
      );

      if (!mounted) return;

      setState(() {
        _result = {
          'ticker': analysis.ticker,
          'stock_name': analysis.stockName,
          'asof_date': analysis.asofDate,
          'close': analysis.close,
          'status': analysis.status,
          'status_score': analysis.statusScore,
          'status_label_ko': analysis.statusLabelKo,
          'final_status': analysis.finalStatus,
          'final_score': analysis.finalScore,
          'etf_reason': analysis.etfReason,
          'summary': analysis.summary,
          'action_guide': analysis.actionGuide,
          'message': analysis.message,
          'reasons': analysis.reasons,
          'risk_flags': analysis.riskFlags,

          // [2026-06-02 13:00 KST]
          // 서버에서 내려준 실제 상태 변화 정보 보관 (Keep real status change information from backend)
          'status_change': analysis.statusChange == null
              ? null
              : {
            'changed': analysis.statusChange!.changed,
            'prev_status': analysis.statusChange!.prevStatus,
            'current_status': analysis.statusChange!.currentStatus,
            'message': analysis.statusChange!.message,
          },
          'should_notify': analysis.shouldNotify,
          'change_alert': analysis.changeAlert,

          'alerts': analysis.alerts
              .map((e) =>
          {
            'subject': e.subject,
            'body': e.body,
          })
              .toList(),

          'etf_recommendations':
          analysis.etfRecommendations
              .map((e) =>
          {
            'etf_code': e.etfCode,
            'correlation': e.correlation,
            'up_probability': e.upProbability,
            'down_probability': e.downProbability,
          })
              .toList(),

          'etf_correlation': analysis.etfCorrelation,
          'etf_up_prob': analysis.etfUpProb,

          // [2026-06-03 15:00 KST]
          // AI 분석 결과 저장 (Store AI analysis result)
          'ai_score': analysis.aiScore,
          'ai_grade': analysis.aiGrade,
          'ai_status': analysis.aiStatus,
          'ai_summary': analysis.aiSummary,
          'ai_detail': analysis.aiDetail,
          // [2026-06-08 21:10 KST]
          // AI 추세 분석 결과 저장
          'ai_trend': analysis.aiTrend,
          'ai_trend_label': analysis.aiTrendLabel,
          'ai_trend_summary': analysis.aiTrendSummary,
          'ai_score_history': analysis.aiScoreHistory,
        };

        _chartItems = chartItems;
        _isLoading = false;
      });

      // [2026-05-28 22:15 KST]
      // 관심종목 저장 여부 확인 (Check watchlist saved state)
      await _checkAlreadySaved();

    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = '분석 데이터를 불러오지 못했습니다. $e';
        _isLoading = false;
      });
    }
  }

  // [2026-04-27 17:30 KST] 현재 종목이 이미 관심종목에 저장되어 있는지 확인
  Future<void> _checkAlreadySaved() async {
    final result = _result;

    if (result == null) {
      return;
    }

    final ticker = (result['ticker'] ?? '').toString();

    if (ticker.isEmpty) {
      return;
    }

    try {
      final items = await _apiService.fetchWatchlistItems();

      if (!mounted) return;

      setState(() {
        _isSavedToWatchlist = items.any((item) => item.ticker == ticker);
      });
    } catch (_) {
      // 저장 여부 확인 실패는 화면 표시를 막지 않음
    }
  }

  // [Added by ChatGPT | 2026-04-26 00:45 KST] 현재 분석 종목을 관심종목에 저장
  Future<void> _saveToWatchlist() async {
    final result = _result;

    if (result == null) {
      return;
    }

    final ticker = (result['ticker'] ?? '').toString();
    final stockName = (result['stock_name'] ?? '').toString();

    if (ticker.isEmpty || stockName.isEmpty) {
      return;
    }

    try {
      await _apiService.addWatchlistItem(
        ticker: ticker,
        stockName: stockName,
      );

      if (!mounted) return;

      setState(() {
        _isSavedToWatchlist = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$stockName 관심종목에 저장했습니다.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('관심종목 저장 실패: $e')),
      );
    }
  }

  // 한국 주식 시장 기준 상태 색상 적용
  // 상승=빨강 / 위험=파랑
  Color _statusColor(String status) {
    if (status.contains('RISK')) {
      return const Color(0xFF3B82F6);
    }

    if (status.contains('ATTACK')) {
      return const Color(0xFFEF4444);
    }

    if (status.contains('WATCH')) {
      return const Color(0xFFF59E0B);
    }

    return const Color(0xFF64748B);
  }

  // [Added by ChatGPT | 2026-06-02 14:30 KST]
// 상태 표시명 변환
// (Convert status code to display label)
  String _statusDisplayName(String status) {
    switch (status) {
      case 'ATTACK_STRONG':
        return '🔥 강한 공격';

      case 'ATTACK_NORMAL':
        return '⚡ 공격';

      case 'WATCH_STRONG':
        return '👀 강한 관찰';

      case 'WATCH':
        return '👀 관찰';

      case 'RISK':
        return '⚠️ 위험';

      default:
        return status;
    }
  }

  // [2026-06-11 22:00 KST]
  // 라이트/다크 모드에 맞는 분석 결과 Skeleton 색상 적용 (Apply theme-aware skeleton colors for analysis result page)
  Widget _buildSkeletonSection({
    required double height,
  }) {
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark
          ? const Color(0xFF1E293B)
          : const Color(0xFFE5E7EB),
      highlightColor: isDark
          ? const Color(0xFF334155)
          : const Color(0xFFF8FAFC),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B)
              : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Card(
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
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStringList(List<String> items) {
    if (items.isEmpty) {
      return const Text('-');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text('- $item'),
        ),
      )
          .toList(),
    );
  }

    Widget _buildEtfList(List<dynamic> etfItems) {
      if (etfItems.isEmpty) {
        return const Text('ETF 추천 결과 없음');
      }
      final bool isDark =
          Theme.of(context).brightness == Brightness.dark;

      return Column(
        children: etfItems.map((item) {
          final etf = item as Map<String, dynamic>;

          final etfCode =
          (etf['etf_code'] ?? '-').toString();

          final correlation =
          ((etf['correlation'] ?? 0) as num)
              .toDouble();

          final upProbability =
          ((etf['up_probability'] ?? 0) as num)
              .toDouble();

          final downProbability =
          ((etf['down_probability'] ?? 0) as num)
              .toDouble();

          final bool isBullish =
              upProbability >= downProbability;

          final Color trendColor =
          isBullish
              ? const Color(0xFFEF4444)
              : const Color(0xFF3B82F6);

          final String trendLabel =
          isBullish
              ? '상승 동조 흐름'
              : '하락 동조 흐름';

          final String probabilityText =
              '${(isBullish ? upProbability : downProbability * 100).toStringAsFixed(1)}%';

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  trendColor.withValues(alpha: 0.16),
                  isDark
                      ? const Color(0xFF0F172A)
                      : Theme.of(context).cardColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: trendColor.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: trendColor,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        etfCode,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Text(
                      probabilityText,
                      style: TextStyle(
                        color: trendColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Text(
                  trendLabel,
                  style: TextStyle(
                    color: trendColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '상관계수 ${correlation.toStringAsFixed(3)}',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),

                const SizedBox(height: 10),

                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: isBullish
                        ? upProbability
                        : downProbability,
                    minHeight: 10,
                    backgroundColor:
                    Colors.white12,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(
                      trendColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

  Widget _buildAlertList(List<dynamic> alerts) {
    if (alerts.isEmpty) {
      return const Text('발생한 알림 없음');
    }

    return Column(
      children: alerts.map((item) {
        final alert = item as Map<String, dynamic>;
        final subject = (alert['subject'] ?? '').toString();
        final body = (alert['body'] ?? '').toString();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF64748B)
                .withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(body),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBody() {
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSkeletonSection(height: 180),
          const SizedBox(height: 12),

          _buildSkeletonSection(height: 240),
          const SizedBox(height: 12),

          _buildSkeletonSection(height: 180),
          const SizedBox(height: 12),

          _buildSkeletonSection(height: 160),
          const SizedBox(height: 12),

          _buildSkeletonSection(height: 220),
        ],
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _error!,
            style: const TextStyle(
              color: Color(0xFFEF4444),
            ),
          ),
        ),
      );
    }

    final result = _result ?? {};

    // [2026-06-02 13:15 KST]
    // 실제 상태 변화 정보 추출
    final statusChange =
    result['status_change'] as Map<String, dynamic>?;

    final bool hasStatusChanged =
        statusChange?['changed'] == true;

    final String prevStatus =
    (statusChange?['prev_status'] ?? '').toString();

    final String currentStatus =
    (statusChange?['current_status'] ?? '').toString();

    final stockName = (result['stock_name'] ?? '-').toString();
    final ticker = (result['ticker'] ?? '-').toString();
    final asofDate = (result['asof_date'] ?? '-').toString();
    final close = ((result['close'] ?? 0) as num).toDouble();

    final status = (result['status'] ?? '-').toString();
    final statusLabel = (result['status_label_ko'] ?? '-').toString();
    final statusScore = (result['status_score'] ?? '-').toString();

    final finalStatus = (result['final_status'] ?? status).toString();
    final finalScore =
    (result['final_score'] ?? result['status_score'] ?? '-').toString();
    final etfReason = (result['etf_reason'] ?? '-').toString();

    final summary = (result['summary'] ?? '-').toString();
    final actionGuide = (result['action_guide'] ?? '-').toString();
    final message = (result['message'] ?? '-').toString();

    final reasons =
    ((result['reasons'] ?? []) as List<dynamic>)
        .map((e) => e.toString())
        .toList();

    final riskFlags =
    ((result['risk_flags'] ?? []) as List<dynamic>)
        .map((e) => e.toString())
        .toList();

    final alerts = result['alerts'] as List<dynamic>? ?? [];
    final etfRecommendations =
        result['etf_recommendations'] as List<dynamic>? ?? [];

    // [2026-06-03 14:40 KST]
    // AI 분석 결과 (AI Analysis Result)
    final aiScore = result['ai_score'];
    final aiGrade = (result['ai_grade'] ?? '-').toString();
    final aiStatus = (result['ai_status'] ?? '-').toString();
    final aiSummary = (result['ai_summary'] ?? '-').toString();
    final aiDetail = (result['ai_detail'] ?? '-').toString();
    // [2026-06-08 21:10 KST]
    // AI 추세 결과
    final aiTrendLabel =
    (result['ai_trend_label'] ?? '-').toString();

    final aiTrendSummary =
    (result['ai_trend_summary'] ?? '-').toString();

    final aiScoreHistory =
    (result['ai_score_history'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    // [2026-06-08 20:00 KST]
    // AI 점수를 기반으로 상승 가능성과 위험도를 계산합니다. (Calculate up probability and risk score from AI score)
    final int aiScoreValue =
    aiScore is num ? aiScore.toInt().clamp(0, 100) : 0;

    final int aiUpProbability = aiScoreValue;
    final int aiRiskScore = 100 - aiScoreValue;

    final etfCorrelation = result['etf_correlation'];
    final etfUpProb = result['etf_up_prob'];

    final Color finalStatusColor = _statusColor(finalStatus);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // [Added by ChatGPT | 2026-05-24 03:55 KST]
// 분석 결과 Hero 상태 카드
// (Analysis result hero status card)

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                finalStatusColor.withValues(alpha: 0.22),

                isDark
                    ? const Color(0xFF0F172A)
                    : Theme.of(context).cardColor,
              ],
            ),
            border: Border.all(
              color: finalStatusColor.withValues(alpha: 0.40),
            ),
            boxShadow: [
              BoxShadow(
                color: finalStatusColor.withValues(alpha: 0.22),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stockName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                ticker,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 22),

              // [Modified by ChatGPT | 2026-06-12 23:35 KST]
// AI 흐름 카드를 Row 밖으로 분리하여 RenderBox 레이아웃 오류 수정
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: finalStatusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: finalStatusColor.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        _statusDisplayName(finalStatus),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: finalStatusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$finalScore점',
                        style: TextStyle(
                          color: finalStatusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 34,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI 흐름',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      aiTrendLabel,
                      style: TextStyle(
                        color: isDark ? Colors.cyanAccent : const Color(0xFF0891B2),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      aiTrendSummary,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      aiScoreHistory.join(' → '),
                      style: TextStyle(
                        color: isDark ? Colors.orangeAccent : const Color(0xFFF59E0B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Text(
                summary,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              // [2026-05-28 22:05 KST]
              // RISK 상태 추가 설명
              // (Additional explanation for RISK status)

              if (finalStatus == 'RISK')
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    '단기 상승 과열 또는 변동성 확대 가능성이 감지되었습니다.',
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // [2026-05-26 13:45 KST]
        // 상태 변화 직관화 카드 추가 (Add intuitive status change card)
        if (hasStatusChanged)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: finalStatusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: finalStatusColor.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.swap_horiz_rounded,
                  color: finalStatusColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '상태 변화 감지',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$prevStatus → $currentStatus',
                        style: TextStyle(
                          color: finalStatusColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        finalStatus.contains('ATTACK')
                            ? '상승 흐름이 강화된 상태입니다.'
                            : finalStatus.contains('RISK')
                            ? '위험 신호가 강해진 상태입니다.'
                            : '관찰이 필요한 흐름입니다.',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // [2026-05-28 20:25 KST]
        // 가격 차트 카드 추가 (Add analysis price chart card)
        AnalysisPriceChartCard(
          items: _chartItems,
        ),

        const SizedBox(height: 12),

        _buildSectionCard(
          title: '기본 정보',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('종목명: $stockName'),
              Text('종목코드: $ticker'),
              Text('기준일: $asofDate'),
              Text('종가: ${close.toStringAsFixed(0)}'),
              const SizedBox(height: 12),
              // [2026-06-02 13:40 KST]
              // 상태 이력 화면 이동 버튼
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.timeline),
                  label: const Text('상태 이력 보기'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SignalDetailHistoryPage(
                          ticker: ticker,
                          stockName: stockName,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),
              // [2026-04-26 00:45 KST] 분석 결과 화면에서 관심종목 저장 버튼 추가
              SizedBox(
                width: double.infinity,
                child: // [Modified by ChatGPT | 2026-04-27 17:30 KST] 이미 저장된 종목이면 버튼 비활성화
                ElevatedButton.icon(
                  onPressed: _isSavedToWatchlist ? null : _saveToWatchlist,
                  icon: Icon(
                    _isSavedToWatchlist ? Icons.check : Icons.star_outline,
                  ),
                  label: Text(
                    _isSavedToWatchlist ? '저장됨' : '관심종목 저장',
                  ),
                ),
              ),
            ],
          ),
        ),


        const SizedBox(height: 12),
        // [2026-05-27 10:45 KST]
        // Insert Location: lib/screens/analysis_result_page.dart 안의 기존 '상태 요약' _buildSectionCard 전체 교체
        // 상태요약 카드 터치 중복 방지 및 로딩 피드백 추가
        // (Add duplicate tap prevention and loading feedback to status summary card)
        _buildSectionCard(
          title: '상태 요약',
          child: InkWell(
            splashColor: finalStatusColor.withValues(alpha: 0.18),
            highlightColor: finalStatusColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            onTap: _isOpeningStatusSummary
                ? null
                : () async {
              if (_isOpeningStatusSummary) return;

              setState(() {
                _isOpeningStatusSummary = true;
              });

              try {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StatusHelpPage(),
                  ),
                );

                // TODO:
                // 나중에 상태 설명 페이지를 연결할 경우 여기에 Navigator.push 추가
                // (Add Navigator.push here when connecting the status help page)
              } finally {
                if (mounted) {
                  setState(() {
                    _isOpeningStatusSummary = false;
                  });
                }
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: finalStatusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: finalStatusColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '기본 상태: $status ($statusLabel)',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text('기본 점수: $statusScore'),
                      const SizedBox(height: 8),
                      Text(
                        '최종 상태: ${_statusDisplayName(finalStatus)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: finalStatusColor,
                        ),
                      ),
                      Text('최종 점수: $finalScore'),
                      const SizedBox(height: 8),
                      Text('ETF 반영 사유: $etfReason'),
                      if (etfCorrelation != null)
                        Text(
                          '대표 ETF 상관계수: ${((etfCorrelation as num).toDouble()).toStringAsFixed(3)}',
                        ),
                      if (etfUpProb != null)
                        Text(
                          '대표 ETF 상승 동조 확률: ${(((etfUpProb as num).toDouble()) * 100).toStringAsFixed(1)}%',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text('요약: $summary'),
                const SizedBox(height: 8),
                Text('가이드: $actionGuide'),

                // [2026-05-27 11:05 KST]
                // 상태요약 상세 설명 진입 힌트
                // (Status summary detail page hint)
                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '터치하여 상태 설명 보기',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),

                // [2026-05-27 10:45 KST]
                // 상태요약 이동 중 로딩 표시
                // (Show loading indicator while opening status summary)
                if (_isOpeningStatusSummary) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(
                    minHeight: 3,
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

// [Added by ChatGPT | 2026-06-03 14:40 KST]
// AI 분석 카드 (AI Analysis Card)
        _buildSectionCard(
          title: '🤖 AI 분석',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI 점수: ${aiScore ?? '-'}점',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

// [Added by ChatGPT | 2026-06-08 20:00 KST]
// AI 상승 가능성 게이지 (AI up probability gauge)
                    Text(
                      '상승 가능성: $aiUpProbability%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: aiUpProbability / 100,
                        minHeight: 10,
                        backgroundColor: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.20),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFEF4444),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 2026-06-08 20:00 KST]
                    // AI 위험도 게이지 (AI risk score gauge)
                    Text(
                      '위험도: $aiRiskScore%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: aiRiskScore / 100,
                        minHeight: 10,
                        backgroundColor: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.20),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF3B82F6),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '등급: $aiGrade',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '판단: $aiStatus',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      aiSummary,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      aiDetail,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: '판단 근거',
          child: _buildStringList(reasons),
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: '위험 요소',
          child: _buildStringList(riskFlags),
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: 'ETF 추천 결과',
          child: _buildEtfList(etfRecommendations),
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: '알림',
          child: _buildAlertList(alerts),
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: '원본 메시지',
          child: Text(message),
        ),

        const SizedBox(height: 16),

        // [2026-06-05 00:20 KST]
        // 분석 결과 화면 하단 AdMob 배너 광고 (Analysis result page bottom AdMob banner ad)
        const AdMobBannerAdWidget(
          realAdUnitId: 'ca-app-pub-5880993243034417/3861514107',
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String stockName = widget.stockName;
    final String ticker = widget.ticker;

    return Scaffold(
      appBar: AppBar(
        title: Text('$stockName ($ticker)'),
      ),
      body: _buildBody(),
    );
  }
}