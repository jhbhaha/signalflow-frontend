// File: watchlist_page.dart (관심종목 화면)
// [Modified by ChatGPT | 2026-05-08 18:40 KST]
// SignalFlow 관심종목 페이지 UI 적용 (Apply SignalFlow watchlist page UI)
// Insert Location: G:\stockmarket_frontend\lib\screens\watchlist_page.dart 전체 교체

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/analysis_response.dart';
import '../models/watch_item.dart';
import '../services/api_service.dart';
import '../models/signal_history_item.dart';
import 'stock_detail_page.dart';

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  final ApiService _apiService = ApiService();

  List<WatchItem> _watchItems = <WatchItem>[];
  List<AnalysisResponse> _watchResults = <AnalysisResponse>[];
  // 종목별 상태 변화 이력 캐시
  // (Signal history cache by ticker)
  final Map<String, List<SignalHistoryItem>> _signalHistoryCache = {};

  // 상태 필터 탭 (Status filter tab)
  String _selectedFilter = 'ALL';

  // 관심종목 정렬 방식
  // (Watchlist sort mode)
  String _selectedSort = 'SCORE';

  bool _isLoading = false;
  String? _errorMessage;

  // [2026-06-03 21:35 KST]
  // 관심종목 화면 첫 진입 시 목록을 먼저 표시하고, 분석은 뒤에서 실행 (Show saved watchlist first, then run analysis in background)
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await _loadData();

      try {
        await _apiService.runWatchlistAnalysis();

        if (mounted) {
          await _loadData();
        }
      } catch (error) {
        debugPrint('watchlist background analysis failed: $error');
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 종목별 상태 변화 이력 미리 불러오기
  // (Preload signal history by ticker)
  Future<void> _loadSignalHistory(String ticker) async {
    if (_signalHistoryCache.containsKey(ticker)) {
      return;
    }

    try {
      final items = await _apiService.fetchSignalHistoryByTicker(
        ticker: ticker,
      );

      _signalHistoryCache[ticker] = items;
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // [Modified by ChatGPT | 2026-05-09 09:40 KST]
// 관심종목 목록은 반드시 먼저 표시하고, 분석 실패는 별도로 처리 (Show watchlist even if analysis fails)
      final List<WatchItem> items = await _apiService.fetchWatchlistItems();

      List<AnalysisResponse> results = <AnalysisResponse>[];

      try {
        results = await _apiService.fetchWatchlistAnalysis();
      } catch (analysisError) {
        debugPrint('watchlist analysis load failed: $analysisError');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('최근 분석 결과를 불러오지 못했습니다. 관심종목 목록은 표시됩니다.'),
            ),
          );
        }
      }

      await Future.wait(
        items.map((item) => _loadSignalHistory(item.ticker)),
      );

      if (!mounted) return;

      setState(() {
        _watchItems = items;
        _watchResults = results;

        _watchItems.sort((a, b) {
          final aResult = _watchResults.firstWhere(
                (r) => r.ticker == a.ticker,
            orElse: () => AnalysisResponse.empty(),
          );
          final bResult = _watchResults.firstWhere(
                (r) => r.ticker == b.ticker,
            orElse: () => AnalysisResponse.empty(),
          );

          return _statusPriority(aResult.finalStatus ?? 'WAIT').compareTo(
            _statusPriority(bResult.finalStatus ?? 'WAIT'),
          );
        });
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = '관심종목을 불러오지 못했습니다. $error';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteWatchItem(String ticker) async {
    try {
      await _apiService.deleteWatchlistItem(ticker);
      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('관심종목이 삭제되었습니다.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제에 실패했습니다. $error')),
      );
    }
  }

  // [Modified by ChatGPT | 2026-05-11 09:30 KST]
// 수동 다시 분석 버튼이 캐시 조회가 아니라 실제 분석 실행 후 최신 캐시를 다시 읽도록 수정
// (Run watchlist analysis first, then reload the latest cached results)
  Future<void> _reloadAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _apiService.runWatchlistAnalysis();
      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('관심종목 분석을 새로 실행했습니다.')),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = '관심종목 분석 실행에 실패했습니다. $error';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  int _statusPriority(String status) {
    if (status.startsWith('ATTACK')) return 0;
    if (status.startsWith('WATCH')) return 1;
    if (status == 'RISK') return 2;
    return 3;
  }

  // 한국 주식 시장 기준 상태 색상 적용
  // 상승=빨강 / 위험=파랑
  Color _statusColor(String status) {
    if (status.startsWith('ATTACK')) return const Color(0xFFEF4444);
    if (status.startsWith('WATCH')) return const Color(0xFFF59E0B);
    if (status == 'RISK') return const Color(0xFF3B82F6);
    return const Color(0xFF64748B);
  }

  List<WatchItem> get _filteredWatchItems {
    List<WatchItem> items;

    if (_selectedFilter == 'ALL') {
      items = List<WatchItem>.from(_watchItems);
    } else {
      items = _watchItems.where((item) {
        final result = _watchResults.firstWhere(
              (r) => r.ticker == item.ticker,
          orElse: () => AnalysisResponse.empty(),
        );

        final status = result.finalStatus ?? 'WAIT';

        if (_selectedFilter == 'ATTACK') {
          return status.startsWith('ATTACK');
        }

        if (_selectedFilter == 'WATCH') {
          return status.startsWith('WATCH');
        }

        if (_selectedFilter == 'RISK') {
          return status == 'RISK';
        }

        return true;
      }).toList();
    }

    // 점수순 정렬
    // (Sort by final score)
    if (_selectedSort == 'SCORE') {
      items.sort((a, b) {
        final aResult = _watchResults.firstWhere(
              (r) => r.ticker == a.ticker,
          orElse: () => AnalysisResponse.empty(),
        );

        final bResult = _watchResults.firstWhere(
              (r) => r.ticker == b.ticker,
          orElse: () => AnalysisResponse.empty(),
        );

        return (bResult.finalScore ?? 0)
            .compareTo(aResult.finalScore ?? 0);
      });
    }

    // 이름순 정렬
    // (Sort by stock name)
    if (_selectedSort == 'NAME') {
      items.sort(
            (a, b) => a.stockName.compareTo(b.stockName),
      );
    }

    return items;
  }

  Widget _buildFilterChip(
      String value,
      String label,
      Color color,
      ) {
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;
    final bool selected =
    value == 'SCORE' || value == 'NAME'
        ? _selectedSort == value
        : _selectedFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (value == 'SCORE' || value == 'NAME') {
              _selectedSort = value;
            } else {
              _selectedFilter = value;
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.16)
                : isDark
                ? const Color(0xFF1E293B)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.6)
                  : Theme.of(context)
                  .dividerColor
                  .withValues(alpha: 0.20),
            ),
            boxShadow: selected
                ? [
              BoxShadow(
                color: color.withValues(alpha: 0.22),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? color
                  : Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context)
              .dividerColor
              .withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Color(0xFF3B82F6).withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_graph,
              color: Color(0xFF3B82F6),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '관심종목은 최근 분석 캐시를 빠르게 표시합니다. 최신 분석은 아래 버튼으로 수동 실행할 수 있습니다.',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }


  // 관심종목 카드 HUD 리스트 스타일로 전체 교체
  // (Replace watch item card with HUD list style)
  Widget _buildWatchItemCard(WatchItem item) {
    final result = _watchResults.firstWhere(
          (r) => r.ticker == item.ticker,
      orElse: () => AnalysisResponse.empty(),
    );

    final String status = result.finalStatus ?? 'WAIT';
    final Color statusColor = _statusColor(status);
    final int score = result.finalScore ?? 0;
    // ATTACK 상태 카드 강조
    // (Highlight ATTACK status card)
    final bool isAttack = status.startsWith('ATTACK');
    final double close = result.close;
    // MA20 대비 현재가 위치 계산
    // (Calculate current price position against MA20)
    final double ma20 = result.ma20;
    final double ma20GapPercent =
    close > 0 && ma20 > 0
        ? ((close - ma20) / ma20) * 100
        : 0;

    // 최근 상태 변화 이력 조회
    // (Load recent signal history)
    final history =
        _signalHistoryCache[item.ticker] ?? <SignalHistoryItem>[];

    SignalHistoryItem? latestHistory;

    if (history.isNotEmpty) {
      latestHistory = history.last;
    }

    String statusLabel(String value) {
      if (value == 'ATTACK_STRONG') {
        return '강한 공격';
      }

      if (value == 'ATTACK_NORMAL') {
        return '공격';
      }

      if (value == 'WATCH_STRONG') {
        return '강한 관찰';
      }

      if (value.startsWith('WATCH')) {
        return '관찰';
      }

      if (value == 'RISK') {
        return '위험';
      }

      return '대기';
    }

    IconData statusIcon(String value) {
      if (value.startsWith('ATTACK')) return Icons.trending_up;
      if (value.startsWith('WATCH')) return Icons.visibility;
      if (value == 'RISK') return Icons.warning_amber_rounded;
      return Icons.hourglass_bottom;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAttack
              ? const Color(0xFFEF4444).withValues(alpha: 0.45)
              : Theme.of(context)
              .dividerColor
              .withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: isAttack
                ? const Color(0xFFEF4444).withValues(alpha: 0.30)
                : statusColor.withValues(alpha: 0.10),
            blurRadius: isAttack ? 24 : 14,
            spreadRadius: isAttack ? 3 : 1,
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          try {
            AnalysisResponse selectedResult = _watchResults.firstWhere(
                  (r) => r.ticker == item.ticker,
              orElse: () => AnalysisResponse.empty(),
            );

            if (selectedResult.ticker.isEmpty) {
              selectedResult = await _apiService.analyzeSingle(
                ticker: item.ticker,
                stockName: item.stockName,
              );
            }

            if (!mounted) return;

            // [2026-06-12 23:55 KST]
            // 관심종목 선택 시 분석 결과 페이지가 아니라 종목 상세 페이지로 이동
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StockDetailPage(
                  ticker: item.ticker,
                  stockName: item.stockName,
                  finalStatus: status,
                  finalScore: score.toString(),
                ),
              ),
            );
          } catch (error) {
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('분석 결과를 열 수 없습니다. $error')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  statusIcon(status),
                  color: statusColor,
                  size: 18,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.stockName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.ticker,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 11,
                      ),
                    ),

                    if (latestHistory != null) ...[
                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Icon(
                            Icons.history,
                            size: 11,
                            color: statusColor.withValues(alpha: 0.70),
                          ),

                          const SizedBox(width: 4),

                          Expanded(
                            child: Text(
                              '${latestHistory.previousStatus ?? 'NONE'} → '
                                  '${latestHistory.currentStatus}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: statusColor.withValues(alpha: 0.78),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    close > 0 ? close.toStringAsFixed(0) : '-',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      ma20 > 0
                          ? '${ma20GapPercent >= 0 ? '+' : ''}${ma20GapPercent.toStringAsFixed(1)}%'
                          : '$score점',
                      key: ValueKey('${item.ticker}_${score}_${ma20GapPercent.toStringAsFixed(1)}'),
                      style: TextStyle(
                        color: ma20GapPercent >= 0
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF3B82F6),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 10),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  statusLabel(status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).disabledColor,
                ),
                onPressed: () => _deleteWatchItem(item.ticker),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 관심종목 Skeleton 카드
  // (Watchlist skeleton card)
  Widget _buildSkeletonWatchCard() {
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Shimmer.fromColors(
        baseColor: isDark
            ? const Color(0xFF1E293B)
            : Theme.of(context).cardColor,
        highlightColor: isDark
            ? const Color(0xFF334155)
            : const Color(0xFFF8FAFC),
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface,
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        width: 80,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 52,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context)
              .dividerColor
              .withValues(alpha: 0.20),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      // 화면 당겨서 새로고침할 때도 실제 분석 실행 후 캐시를 다시 읽도록 수정
      // (Run analysis when pull-to-refresh is triggered)
      onRefresh: _reloadAnalysis,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (_isLoading && _watchItems.isEmpty)
            Column(
              children: List.generate(
                5,
                    (index) => _buildSkeletonWatchCard(),
              ),
            )
          else if (_errorMessage != null)
            _buildEmptyCard(_errorMessage!)
          else ...<Widget>[
              _buildInfoCard(),
              const SizedBox(height: 16),

              const SizedBox(height: 18),

              Text(
                '관심종목',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  _buildFilterChip(
                    'SCORE',
                    '점수순',
                    const Color(0xFF22C55E),
                  ),

                  _buildFilterChip(
                    'NAME',
                    '이름순',
                    const Color(0xFF3B82F6),
                  ),
                ],
              ),

              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip('ALL', '전체', Colors.blueGrey),
                    _buildFilterChip('ATTACK', '공격', const Color(0xFFEF4444)),
                    _buildFilterChip('WATCH', '관찰', const Color(0xFFF59E0B)),
                    _buildFilterChip('RISK', '위험', const Color(0xFF3B82F6)),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              if (_watchItems.isEmpty)
                _buildEmptyCard('저장된 관심종목이 없습니다.')
              else if (_filteredWatchItems.isEmpty)
                _buildEmptyCard('선택한 상태의 관심종목이 없습니다.')
              else
                ..._filteredWatchItems.map(_buildWatchItemCard),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _reloadAnalysis,
                  icon: Icon(Icons.refresh),
                  label: const Text('수동으로 다시 분석'),
                ),
              ),
            ],
        ],
      ),
    );
  }
}