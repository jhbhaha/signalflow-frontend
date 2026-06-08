// File: dashboard_page.dart (대시보드 화면)
// Insert Location: G:\stockmarket_frontend\lib\screens\dashboard_page.dart 새 파일 생성

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../models/dashboard_summary.dart';
import '../services/api_service.dart';
import 'attack_list_page.dart';
import '../models/recommendation_item.dart';
import 'dart:async';
import '../services/notification_local_service.dart';
// 시장 흐름 모델 추가
// (Add market overview model)
import '../models/market_overview.dart';
// signal history 모델 추가
// (Add signal history model)
import '../models/signal_history_item.dart';
// 상태 설명 페이지 연결 추가 (Add status help page navigation)
import 'status_help_page.dart';
import '../widgets/dashboard/attack_top5_card.dart';
import '../widgets/dashboard/recommendation_card.dart';
import '../widgets/dashboard/market_card.dart';
import '../widgets/dashboard/signal_summary_card.dart';
import '../widgets/dashboard/top_signals_card.dart';
import '../widgets/dashboard/etf_sector_flow_card.dart';
import '../widgets/dashboard/market_risk_gauge_card.dart';
import '../services/dashboard_cache_service.dart';
import 'analysis_result_page.dart';
import '../widgets/admob_banner_ad_widget.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  // 대시보드 자동 새로고침 타이머
  // (Dashboard auto refresh timer)
  Timer? _autoRefreshTimer;
  List<String> _savedTickers = [];
  final ApiService _apiService = ApiService();

  late final DashboardCacheService _dashboardCacheService;

  // Dashboard 메모리 캐시
  // (Dashboard memory cache)
  static DashboardSummary? _cachedSummary;
  static MarketOverview? _cachedMarketOverview;
  static List<RecommendationItem> _cachedRecommendations = <RecommendationItem>[];

  DashboardSummary? _summary;
  // [2026-05-29 18:40 KST]
  // 분석 화면 중복 열림 방지 플래그 (Prevent duplicate analysis page opening)
  bool _isOpeningAnalysis = false;
  // 시장 전체 흐름 데이터
  // (Market overview data)
  MarketOverview? _marketOverview;
  bool _isLoading = false;
  // 네트워크 연결 상태
  // (Network connection status)
  bool _isOfflineMode = false;
  String? _errorMessage;
  // 대시보드 마지막 업데이트 시간
  // (Dashboard last update time)
  DateTime? _lastUpdatedAt;
  List<RecommendationItem> _recommendations = <RecommendationItem>[];
  Timer? _notificationTimer;
  // LIVE pulse animation controller
  // (LIVE pulse animation controller)
  late AnimationController _livePulseController;

  String? _lastShownNotificationId;
  // 이전 ATTACK 종목 저장
  // (Store previous ATTACK tickers)
  Set<String> _previousAttackTickers = {};
  // 최근 새 ATTACK ticker 저장
  // (Store latest detected ATTACK ticker)
  String? _recentAttackTicker;
  // 종목별 signal history 캐시
  // (Signal history cache by ticker)
  final Map<String, List<SignalHistoryItem>>
  _signalHistoryCache = {};

  @override
  void initState() {
    super.initState();

    _dashboardCacheService = DashboardCacheService(
      apiService: _apiService,
    );

    _livePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // 캐시가 있으면 먼저 즉시 표시하고, 뒤에서 최신 데이터 갱신
    // (Show cached dashboard first, then refresh in background)
    if (_cachedSummary != null) {
      _summary = _cachedSummary;
      _marketOverview = _cachedMarketOverview;
      _recommendations = _cachedRecommendations;
    }

    _loadSummary();
    _loadSavedTickers();
    // 60초마다 Dashboard 자동 새로고침
    // (Auto refresh dashboard every 60 seconds)
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) {
        if (mounted) {
          _loadSummary();
        }
      },
    );
    // 앱 실행 시 읽지 않은 알림 개수와 최신 알림 확인
    // (Load unread notification count and check latest notification on app start)
    _checkAndShowUnreadNotification();

    // 30초마다 읽지 않은 상태 변화 알림 확인
    // (Check unread signal notifications every 30 seconds)
    _notificationTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) {
        if (mounted) {
          _checkAndShowUnreadNotification();
        }
      },
    );
  }

  // 화면 종료 시 타이머 정리 (Dispose timer when page is removed)
  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _notificationTimer?.cancel();
    _livePulseController.dispose();
    super.dispose();
  }

  // Dashboard API 병렬 처리 최적화
  // (Optimize dashboard loading with parallel API requests)
  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = _summary == null;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _apiService.fetchDashboardSummary(),
        _apiService.fetchMarketOverview(),
        _apiService.fetchTopRecommendations(),
      ]);

      final DashboardSummary summary =
      results[0] as DashboardSummary;

      final MarketOverview marketOverview =
      results[1] as MarketOverview;

      final List<RecommendationItem> recommendations =
      results[2] as List<RecommendationItem>;

      // [2026-05-21 15:30 KST]
      // 추천 종목 점수 기준 정렬
      // (Sort recommendations by final score)

      recommendations.sort(
            (a, b) => b.finalScore.compareTo(a.finalScore),
      );

      if (!mounted) return;

      _detectNewAttackSignals(summary);

      _dashboardCacheService.preloadTopAnalysis(
        summary: summary,
        recommendations: recommendations,
      );

      // signal history 병렬 preload
      // (Parallel preload for signal history)
      await Future.wait(
        summary.topSignals.map(
              (signal) => _loadSignalHistory(signal.ticker),
        ),
      );

      if (!mounted) return;

      setState(() {
        _summary = summary;
        _marketOverview = marketOverview;
        _recommendations = recommendations;
        _lastUpdatedAt = DateTime.now();
        _isOfflineMode = false;

        _cachedSummary = summary;
        _cachedMarketOverview = marketOverview;
        _cachedRecommendations = recommendations;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isOfflineMode = true;

        // 기존 cache 데이터가 있으면 에러 화면 대신 유지
        // (Keep previous cache data instead of error screen)
        if (_summary == null) {
          _errorMessage =
          '서버 연결이 불안정합니다. 잠시 후 다시 시도해 주세요.';
        }
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // 새 ATTACK 종목 감지
  // (Detect newly appeared ATTACK signals)
  void _detectNewAttackSignals(
      DashboardSummary summary,
      ) {
    final currentAttackTickers = summary.topSignals
        .where(
          (item) => item.finalStatus.startsWith('ATTACK'),
    )
        .map((e) => e.ticker)
        .toSet();

    final newAttackTickers = currentAttackTickers.difference(
      _previousAttackTickers,
    );

    if (newAttackTickers.isNotEmpty && mounted) {
      final newTicker = newAttackTickers.first;

      _recentAttackTicker = newTicker;

      final signal = summary.topSignals.firstWhere(
            (e) => e.ticker == newTicker,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          content: Text(
            '새 ATTACK 포착: ${signal.stockName}',
          ),
        ),
      );
    }

    _previousAttackTickers = currentAttackTickers;
  }

  // 저장된 관심종목 ticker 목록 불러오기
  Future<void> _loadSavedTickers() async {
    try {
      final items = await _apiService.fetchWatchlistItems();

      if (!mounted) return;

      setState(() {
        _savedTickers = items.map((e) => e.ticker).toList();
      });
    } catch (e) {
      debugPrint('watchlist load error: $e');
    }
  }

  // 읽지 않은 알림 이벤트가 있으면 로컬 알림 표시 (Show local notification when unread event exists)
  Future<void> _checkAndShowUnreadNotification() async {
    try {
      final events = await _apiService.fetchNotifications();
      final unreadEvents = events.where((event) => !event.read).toList();

      if (unreadEvents.isEmpty) {
        return;
      }

      final latestEvent = unreadEvents.first;

      if (_lastShownNotificationId == latestEvent.id) {
        return;
      }

      _lastShownNotificationId = latestEvent.id;

      await NotificationLocalService.showEventNotification(latestEvent);

      if (!mounted) return;

    } catch (e) {
      debugPrint('notification count load error: $e');
    }
  }


  // 한국 주식 시장 기준 상태 색상 적용
  // 상승=빨강 / 위험=파랑
  Color _statusColor(String status) {
    if (status.startsWith('ATTACK')) {
      return const Color(0xFFEF4444);
    }

    if (status.startsWith('WATCH')) {
      return const Color(0xFFF59E0B);
    }

    if (status == 'RISK') {
      return const Color(0xFF3B82F6);
    }

    return const Color(0xFF64748B);
  }

  // 종목별 signal history 미리 로드
  // (Preload signal history by ticker)
  Future<void> _loadSignalHistory(
      String ticker,
      ) async {
    if (_signalHistoryCache.containsKey(ticker)) {
      return;
    }

    try {
      final items =
      await _apiService.fetchSignalHistoryByTicker(
        ticker: ticker,
      );

      _signalHistoryCache[ticker] = items;
    } catch (_) {}
  }

  // [2026-05-21 19:05 KST]
  // 추천 종목을 관심종목에 저장
  // (Save recommendation item to watchlist)
  Future<void> _saveRecommendationToWatchlist(
      RecommendationItem item,
      ) async {
    try {
      await _apiService.addWatchlistItem(
        ticker: item.ticker,
        stockName: item.stockName,
      );

      if (!mounted) return;

      setState(() {
        _savedTickers.add(item.ticker);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.stockName} 저장 완료'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 실패: $e'),
        ),
      );
    }
  }

  // [2026-05-22 13:10 KST]
  // 최고 점수 종목 분석 열기
  // (Open analysis for highest scored signal)
  Future<void> _openBestSignalAnalysis(
      DashboardSummary summary,
      ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '종목 분석 중...',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final sortedSignals = [...summary.topSignals];

      sortedSignals.sort(
            (a, b) => b.finalScore.compareTo(a.finalScore),
      );

      final first = sortedSignals.first;

      if (!mounted) return;

      Navigator.pop(context);

      _openAnalysisWithCache(
        ticker: first.ticker,
        stockName: first.stockName,
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('종목 분석 실패: $e'),
        ),
      );
    }
  }

  // [2026-05-29 18:50 KST]
  // 대시보드 터치 시 즉시 분석 결과 화면으로 이동 (Navigate immediately and load analysis inside AnalysisResultPage)
  Future<void> _openAnalysisWithCache({
    required String ticker,
    required String stockName,
  }) async {
    if (_isOpeningAnalysis) {
      return;
    }

    setState(() {
      _isOpeningAnalysis = true;
    });

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AnalysisResultPage(
                ticker: ticker,
                stockName: stockName,
              ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningAnalysis = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('대시보드'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSkeletonCard(height: 180),
            const SizedBox(height: 12),

            _buildSkeletonCard(height: 120),
            const SizedBox(height: 12),

            _buildSkeletonCard(height: 220),
            const SizedBox(height: 12),

            _buildSkeletonCard(height: 260),
            const SizedBox(height: 12),

            _buildSkeletonCard(height: 180),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    final summary = _summary;

    if (summary == null) {
      return const Center(child: Text('대시보드 데이터가 없습니다.'));
    }

    // Scaffold 안에 RefreshIndicator를 body로 연결 (Connect RefreshIndicator as Scaffold body)
    return Scaffold(
      appBar: AppBar(
        title: const Text('대시보드'),
        actions: [
          // 상태 설명 페이지 이동 버튼 추가 (Add status help page button)
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: '상태 설명',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StatusHelpPage(),
                ),
              );
            },
          ),

          // [Modified by ChatGPT | 2026-05-19 15:35 KST]
// 새 ATTACK 발생 시 실시간 시그널 아이콘에 dot 표시
// (Show dot on live signal icon when new ATTACK appears)
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFFF59E0B),
                ),
                tooltip: '공격 후보',
                onPressed: () {
                  setState(() {
                    _recentAttackTicker = null;
                  });

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttackListPage(
                        signals: summary.topSignals,
                      ),
                    ),
                  );
                },
              ),

              if (_recentAttackTicker != null)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildLiveUpdateBar(),
            const SizedBox(height: 12),
            MarketCard(
              summary: summary,
              marketOverview: _marketOverview,
              statusColor: _statusColor,
              onWatchNowTap: () => _openBestSignalAnalysis(summary),
              onAttackListTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AttackListPage(
                      signals: summary.topSignals,
                    ),
                  ),
                );
              },
            ),
            // 시장 위험도 Gauge 카드 추가
            // (Add market risk gauge card)
            const SizedBox(height: 12),
            MarketRiskGaugeCard(
              summary: summary,
            ),
            const SizedBox(height: 12),
            SignalSummaryCard(
              summary: summary,
            ),
            const SizedBox(height: 12),
            TopSignalsCard(
              summary: summary,
              recentAttackTicker: _recentAttackTicker,
              signalHistoryCache: _signalHistoryCache,
              statusColor: _statusColor,
              onSignalTap: _openAnalysisWithCache,
            ),
            // 실시간 ATTACK TOP5 카드 추가
            // (Add realtime ATTACK TOP5 card)
            const SizedBox(height: 12),
            AttackTop5Card(
              summary: summary,
              recentAttackTicker: _recentAttackTicker,
              onAttackTap: _openAnalysisWithCache,
            ),
            const SizedBox(height: 12),
            EtfSectorFlowCard(
              summary: summary,
            ),
            const SizedBox(height: 12),
            RecommendationCard(
              recommendations: _recommendations,
              savedTickers: _savedTickers,
              onItemTap: _openAnalysisWithCache,
              onSaveTap: _saveRecommendationToWatchlist,
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF59E0B)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFFF59E0B)
                      .withValues(alpha: 0.25),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '본 앱의 분석 결과는 투자 참고용이며, 투자 손실에 대한 책임은 사용자 본인에게 있습니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // [2026-06-05 00:00 KST]
            // Dashboard 하단 AdMob 배너 광고 (Dashboard bottom AdMob banner ad)
            const SizedBox(height: 16),
            const AdMobBannerAdWidget(
              realAdUnitId: 'ca-app-pub-5880993243034417/8072752082',
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Dashboard Skeleton 카드
  // (Dashboard skeleton loading card)
  Widget _buildSkeletonCard({
    required double height,
  }) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E293B),
      highlightColor: const Color(0xFF334155),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
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
  // Dashboard LIVE / 마지막 업데이트 표시
  // (Dashboard live and last update indicator)
  Widget _buildLiveUpdateBar() {
    final String timeText = _lastUpdatedAt == null
        ? '--:--:--'
        : '${_lastUpdatedAt!.hour.toString().padLeft(2, '0')}:'
        '${_lastUpdatedAt!.minute.toString().padLeft(2, '0')}:'
        '${_lastUpdatedAt!.second.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _livePulseController,
            builder: (context, child) {
              final scale = 0.85 + (_livePulseController.value * 0.35);

              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _isOfflineMode
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF22C55E),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isOfflineMode
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF22C55E))
                        .withValues(alpha: 0.45),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isOfflineMode ? 'OFFLINE CACHE' : 'LIVE',
            style: TextStyle(
              color: _isOfflineMode
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF22C55E),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Last Update $timeText',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}