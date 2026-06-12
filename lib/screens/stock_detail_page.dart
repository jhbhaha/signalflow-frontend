// File: stock_detail_page.dart (종목 상세 화면)
// Last Modified: 2026-05-12 13:50 KST (작성자: ChatGPT)
// Insert Location: G:\stockmarket_frontend\lib\screens\stock_detail_page.dart 전체 교체

import 'package:flutter/material.dart';

import '../models/analysis_response.dart';
import '../services/api_service.dart';
import '../models/signal_history_item.dart';
import '../models/attack_statistics.dart';
// [2026-05-13 14:05 KST]
// 상태 변화 점수 차트 패키지 추가
// (Add signal score chart package)
import 'package:fl_chart/fl_chart.dart';
// [2026-05-24 00:05 KST]
// Skeleton 로딩 UI 패키지 추가
// (Add skeleton loading UI package)
import 'package:shimmer/shimmer.dart';

// [2026-06-12 23:59 KST]
// 종목별 AI 분석 결과 임시 캐시
class _CachedStockAnalysis {
  _CachedStockAnalysis({
    required this.analysis,
    required this.updatedAt,
  });

  final AnalysisResponse analysis;
  final DateTime updatedAt;
}

class StockDetailPage extends StatefulWidget {
  final String ticker;
  final String stockName;
  final String finalStatus;
  final String finalScore;

  const StockDetailPage({
    super.key,
    required this.ticker,
    required this.stockName,
    required this.finalStatus,
    required this.finalScore,
  });

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> {
  // [2026-06-12 23:59 KST]
  // 앱 실행 중 종목별 최근 AI 분석 결과 캐시
  static final Map<String, _CachedStockAnalysis> _analysisCache = {};

  DateTime? _analysisUpdatedAt;

  final ApiService _apiService = ApiService();
  // [2026-06-08 12:35 KST]
  // 분석 설명 카드 위치 추적용 Key (Key for analysis description section)

  AnalysisResponse? _analysis;
  // [2026-05-12 16:45 KST]
  // ATTACK 성공률 통계 데이터 추가 (Add ATTACK success statistics data)
  AttackStatistics? _attackStatistics;
  List<SignalHistoryItem> _timelineItems = [];
  bool _isLoading = true;
  String? _error;
  // [2026-05-22 20:10 KST]
  // 분석 API 백그라운드 로딩 상태 (Background analysis API loading state)
  bool _isAnalysisLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAnalysisOnly();
    });
  }

  // [2026-05-22 20:05 KST]
  // 종목 상세 진입 후 분석만 백그라운드로 실행 (Run analysis in background after stock detail page is shown)
  Future<void> _runAnalysisOnly() async {
    if (_isAnalysisLoading) return;

    final cached = _analysisCache[widget.ticker];
    final now = DateTime.now();

    if (cached != null) {
      setState(() {
        _analysis = cached.analysis;
        _analysisUpdatedAt = cached.updatedAt;
      });

      final bool isFresh =
          now.difference(cached.updatedAt).inMinutes < 5;

      if (isFresh) {
        return;
      }
    }

    setState(() {
      _isAnalysisLoading = true;
    });

    try {
      final result = await _apiService
          .analyzeSingle(
        ticker: widget.ticker,
        stockName: widget.stockName,
      )
          .timeout(
        const Duration(seconds: 45),
      );

      if (!mounted) return;

      final DateTime updatedAt = DateTime.now();

      _analysisCache[widget.ticker] = _CachedStockAnalysis(
        analysis: result,
        updatedAt: updatedAt,
      );

      setState(() {
        _analysis = result;
        _analysisUpdatedAt = updatedAt;
        _isAnalysisLoading = false;
      });
    } catch (e) {
      debugPrint('STOCK DETAIL ANALYSIS ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isAnalysisLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('분석 시간이 지연되고 있습니다. 잠시 후 다시 시도해 주세요.'),
        ),
      );
    }
  }

  // [2026-05-22 19:45 KST]
  // 종목 상세 진입 시 분석 API timeout으로 전체 화면이 막히지 않도록 수정 (Prevent full detail page failure when analysis API times out)
  Future<void> _loadAnalysis() async {
    debugPrint(
      'STOCK DETAIL LOAD: '
          'ticker=${widget.ticker}, '
          'stockName=${widget.stockName}',
    );

    try {
      final historyItems = await _apiService.fetchSignalHistory();

      final filteredTimeline = historyItems
          .where((item) => item.ticker == widget.ticker)
          .toList();

      // [2026-05-22 19:55 KST]
      // ATTACK 통계 API timeout 문제로 초기 로딩에서는 제외 (Exclude ATTACK statistics from initial loading due to API timeout)
      AttackStatistics? attackStatistics;

      if (!mounted) return;

      setState(() {
        _timelineItems = filteredTimeline;
        _attackStatistics = attackStatistics;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('STOCK DETAIL LOAD ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = null;
      });
    }
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    Color? color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color ?? Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [2026-06-12 22:50 KST]
  // 분석중 Skeleton의 무한 width 오류 방지 및 라이트/다크 모드 색상 적용
  Widget _buildAnalysisSkeleton() {
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    final Color baseColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE5E7EB);

    final Color highlightColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFF8FAFC);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double safeWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width - 72;

        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 18,
                width: safeWidth,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 18,
                width: safeWidth * 0.88,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 18,
                width: safeWidth * 0.55,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // [2026-05-13 11:30 KST]
  // 종목 상세 공통 HUD 카드 (Common HUD card for stock detail page)
  Widget _buildHudCard({
    required Widget child,
  }) {
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context)
              .dividerColor
              .withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.24 : 0.08,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }

  // [2026-05-13 12:10 KST]
  // ATTACK 통계 HUD 박스 (ATTACK statistics HUD box)
  Widget _buildStatBox({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }

  // [2026-05-13 12:20 KST]
  // 종목 상세 핵심 수치 HUD 타일 (Stock detail key metric HUD tile)
  Widget _buildMetricTile({
    required String title,
    required String value,
    Color? color,
  }) {
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Theme.of(context)
              .dividerColor
              .withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color ?? Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // [2026-05-13 14:15 KST]
  // 상태 변화 점수 추이 차트 (Signal score trend chart)
  Widget _buildSignalTrendChart() {
    if (_timelineItems.isEmpty) {
      return _buildHudCard(
        child: const Text(
          '상태 변화 데이터가 없습니다.',
          style: TextStyle(
            color: Color(0xFF94A3B8),
          ),
        ),
      );
    }

    final spots = _timelineItems
        .asMap()
        .entries
        .map(
          (entry) => FlSpot(
        entry.key.toDouble(),
        entry.value.finalScore.toDouble(),
      ),
    )
        .toList();

    return _buildHudCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Signal Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,

                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (_) {
                    return FlLine(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.20),
                      strokeWidth: 1,
                    );
                  },
                ),

                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),

                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (_, __) {
                        return const SizedBox.shrink();
                      },
                    ),
                  ),

                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                ),

                borderData: FlBorderData(
                  show: false,
                ),

                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF22C55E),
                    barWidth: 4,
                    dotData: FlDotData(
                      show: true,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF22C55E)
                          .withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // [2026-06-11 16:20 KST]
  // SignalFlow AI 분석 보기 클릭 시 페이지 내부 스크롤이 아니라 기존 분석 상세 화면으로 이동 (Navigate to the existing analysis result page)
  void _openAiAnalysisPage() {
    Navigator.pushNamed(
      context,
      '/analysis-result',
      arguments: {
        'ticker': widget.ticker,
        'stock_name': widget.stockName,
      },
    );
  }

  // [2026-05-13 11:20 KST]
  // SignalFlow 전체 상태 색상 규칙 통일 (Unify SignalFlow status color rules)
  Color _statusColor(String status) {
    if (status == 'ANALYZING') {
      return const Color(0xFF3B82F6);
    }

    if (status.startsWith('ATTACK')) {
      return const Color(0xFF22C55E);
    }

    if (status.startsWith('WATCH')) {
      return const Color(0xFFF59E0B);
    }

    if (status == 'RISK') {
      return const Color(0xFFEF4444);
    }

    return const Color(0xFF64748B);
  }

  // [2026-06-12 23:59 KST]
  // 최근 AI 분석 시각 표시
  String _analysisTimeText(DateTime time) {
    final diff = DateTime.now().difference(time);

    if (diff.inMinutes < 1) {
      return '방금 전';
    }

    if (diff.inHours < 1) {
      return '${diff.inMinutes}분 전';
    }

    return '${diff.inHours}시간 전';
  }

  // [2026-06-08 12:20 KST]
  // 스크롤 컨트롤러 해제 (Dispose scroll controller)
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    final String displayName =
    widget.stockName.isEmpty ? widget.ticker : widget.stockName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('종목 상세'),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _error != null
          ? Center(
        child: Text(
          '분석 데이터를 불러오지 못했습니다.\n$_error',
          textAlign: TextAlign.center,
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadAnalysis,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // [2026-05-13 11:10 KST]
            // 종목 상세 Hero HUD 카드 추가 (Add stock detail hero HUD card)

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    _statusColor(
                      _isAnalysisLoading
                          ? 'ANALYZING'
                          : (_analysis?.finalStatus ?? widget.finalStatus),
                    ).withValues(alpha: 0.18),

                    isDark
                        ? const Color(0xFF0F172A)
                        : Theme.of(context).cardColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: _statusColor(
                    _isAnalysisLoading
                        ? 'ANALYZING'
                        : (_analysis?.finalStatus ?? widget.finalStatus),
                  ).withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _statusColor(
                      _isAnalysisLoading
                          ? 'ANALYZING'
                          : (_analysis?.finalStatus ?? widget.finalStatus),
                    ).withValues(alpha: 0.18),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.ticker,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(
                            _isAnalysisLoading
                                ? 'ANALYZING'
                                : (_analysis?.finalStatus ?? widget.finalStatus),
                          ).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: _statusColor(
                              _isAnalysisLoading
                                  ? 'ANALYZING'
                                  : (_analysis?.finalStatus ?? widget.finalStatus),
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          _isAnalysisLoading
                              ? '분석중'
                              : (_analysis?.finalStatus ?? widget.finalStatus),
                          style: TextStyle(
                            color: _statusColor(
                              _isAnalysisLoading
                                  ? 'ANALYZING'
                                  : (_analysis?.finalStatus ?? widget.finalStatus),
                            ),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  FilledButton.icon(
                    onPressed: _openAiAnalysisPage,
                    icon: const Icon(Icons.smart_toy),
                    label: const Text('SignalFlow AI 분석 보기'),
                  ),

                  if (_analysisUpdatedAt != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      '최근 분석: ${_analysisTimeText(_analysisUpdatedAt!)}',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Signal Strength',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value:
                                ((_analysis?.finalScore ?? 0).clamp(0, 100)) / 100,
                                minHeight: 10,
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.08),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _statusColor(
                                    _analysis?.finalStatus ?? widget.finalStatus,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 18),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '점수',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isAnalysisLoading
                                ? '0'
                                : '${_analysis?.finalScore ?? widget.finalScore}',
                            style: TextStyle(
                              color: _statusColor(
                                _analysis?.finalStatus ?? widget.finalStatus,
                              ),
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  if ((_analysis?.etfReason ?? '').isNotEmpty) ...[
                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF3B82F6)
                              .withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.hub,
                            color: Color(0xFF3B82F6),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _analysis?.etfReason ?? '',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // [2026-05-13 12:20 KST]
            // 핵심 수치 영역 HUD Grid 스타일 적용 (Apply HUD grid style to key metrics area)
            _buildHudCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '핵심 수치',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.8,
                    children: [
                      _buildMetricTile(
                        title: '현재 상태',
                        value: _analysis?.finalStatus ?? widget.finalStatus,
                        color: _statusColor(
                          _analysis?.finalStatus ?? widget.finalStatus,
                        ),
                      ),
                      _buildMetricTile(
                        title: '최종 점수',
                        value: '${_analysis?.finalScore ?? widget.finalScore}',
                        color: const Color(0xFF3B82F6),
                      ),
                      _buildMetricTile(
                        title: '종가',
                        value: '${_analysis?.close ?? '-'}',
                      ),
                      _buildMetricTile(
                        title: 'MA5',
                        value: '${_analysis?.ma5 ?? '-'}',
                      ),
                      _buildMetricTile(
                        title: 'MA20',
                        value: '${_analysis?.ma20 ?? '-'}',
                      ),
                      _buildMetricTile(
                        title: 'MA60',
                        value: '${_analysis?.ma60 ?? '-'}',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

      // [Modified by ChatGPT | 2026-06-12 23:10 KST]
// 분석 설명 카드 레이아웃 괄호 정리
      _buildHudCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '분석 설명',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_isAnalysisLoading) ...[
              _buildAnalysisSkeleton(),
              const SizedBox(height: 16),
              Text(
                'AI가 종목 데이터, 가격 흐름, ETF 연동 정보를 분석중입니다...',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else
              Text(
                _analysis?.message ?? '분석 메시지가 없습니다.',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  height: 1.45,
                ),
              ),
          ],
        ),
      ),

            // [2026-05-12 15:00 KST]
            // 분석 근거 목록 표시 추가 (Add analysis reasons list display)
            const SizedBox(height: 24),

            // [2026-06-12 23:58 KST]
            // 분석 이유 영역도 AI 분석중 Skeleton 표시
            _buildHudCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '분석 이유',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_isAnalysisLoading) ...[
                    _buildAnalysisSkeleton(),
                    const SizedBox(height: 16),
                    Text(
                      '매수/관찰/위험 판단 근거를 계산중입니다...',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else if ((_analysis?.reasons ?? []).isEmpty)
                    const Text(
                      '분석 근거가 없습니다.',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                      ),
                    )
                  else
                    ...(_analysis?.reasons ?? []).map(
                          (reason) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.check_circle,
                                size: 18,
                                color: Color(0xFF22C55E),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                reason,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // [2026-05-12 15:20 KST]
            // ETF 연동 분석 카드 추가 (Add ETF correlation analysis card)

            const SizedBox(height: 24),

            // [2026-05-13 11:50 KST]
            // ETF 연동 분석 HUD 스타일 적용 (Apply HUD style to ETF correlation analysis card)
            _buildHudCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ETF 연동 분석',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_isAnalysisLoading) ...[
                    _buildAnalysisSkeleton(),
                    const SizedBox(height: 16),
                    Text(
                      'ETF 상관관계와 동반 상승 확률을 계산중입니다...',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6)
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF3B82F6)
                            .withValues(alpha: 0.18),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildInfoCard(
                          title: 'ETF 보정 사유',
                          value: _analysis?.etfReason ?? '정보 없음',
                        ),

                        _buildInfoCard(
                          title: '상관계수',
                          value: _analysis?.etfCorrelation != null
                              ? _analysis!.etfCorrelation!
                              .toStringAsFixed(2)
                              : '-',
                          color: const Color(0xFF22C55E),
                        ),

                        _buildInfoCard(
                          title: '동반 상승 확률',
                          value: _analysis?.etfUpProb != null
                              ? '${(_analysis!.etfUpProb! * 100).toStringAsFixed(1)}%'
                              : '-',
                          color: const Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                  ),

                  if ((_analysis?.etfRecommendations ?? []).isNotEmpty) ...[
                    const SizedBox(height: 18),

                    const Text(
                      '추천 ETF',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 10),

                    ..._analysis!.etfRecommendations.map(
                          (etf) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : Theme.of(context)
                                .dividerColor
                                .withValues(alpha: 0.20),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.show_chart,
                              color: Color(0xFF22C55E),
                              size: 18,
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                '${etf.etfName} (${etf.etfCode})',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            Text(
                              etf.correlation.toStringAsFixed(2),
                              style: const TextStyle(
                                color: Color(0xFF22C55E),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // [2026-05-12 15:45 KST]
            // 해당 종목 상태 변화 타임라인 카드 추가 (Add stock status change timeline card)

            const SizedBox(height: 24),

            const SizedBox(height: 20),

            _buildSignalTrendChart(),

            const SizedBox(height: 20),

            // [2026-05-13 12:00 KST]
            // 상태 변화 타임라인 HUD 스타일 적용 (Apply HUD style to signal timeline card)
            _buildHudCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '상태 변화 타임라인',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 18),

                  if (_timelineItems.isEmpty)
                    const Text(
                      '아직 이 종목의 상태 변화 기록이 없습니다.',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                      ),
                    ),

                  ..._timelineItems.map(
                        (item) => Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _statusColor(item.currentStatus)
                              .withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: _statusColor(item.currentStatus),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _statusColor(item.currentStatus)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 6),

                              Container(
                                width: 2,
                                height: 42,
                                color: Theme.of(context)
                                    .dividerColor
                                    .withValues(alpha: 0.25),
                              ),
                            ],
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.previousStatus ?? 'NEW'} → ${item.currentStatus}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _statusColor(item.currentStatus),
                                    fontSize: 15,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  'Signal Score ${item.finalScore}',
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                    fontSize: 13,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  item.timestamp,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // [2026-05-12 16:45 KST]
            // ATTACK 성공률 통계 카드 추가 (Add ATTACK success statistics card)

            const SizedBox(height: 24),

            // [2026-05-13 12:10 KST]
            // ATTACK 성공률 통계 HUD 스타일 적용 (Apply HUD style to ATTACK statistics card)
            _buildHudCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '공격 성공률 통계',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 18),

                  if (_isAnalysisLoading) ...[
                    _buildAnalysisSkeleton(),
                    const SizedBox(height: 16),
                    Text(
                      '과거 ATTACK 성공률과 평균 수익률을 계산중입니다...',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatBox(
                            title: 'ATTACK',
                            value: '${_attackStatistics?.attackCount ?? 0}',
                            color: const Color(0xFF22C55E),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatBox(
                            title: '성공',
                            value: '${_attackStatistics?.successCount ?? 0}',
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatBox(
                            title: '성공률',
                            value: '${(_attackStatistics?.successRate ?? 0).toStringAsFixed(1)}%',
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatBox(
                            title: '평균수익',
                            value: '${(_attackStatistics?.avgReturn ?? 0).toStringAsFixed(2)}%',
                            color: (_attackStatistics?.avgReturn ?? 0) >= 0
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        '기준: ATTACK 발생 후 5거래일 내 +3% 이상 상승',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}