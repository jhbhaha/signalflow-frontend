import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../models/analysis_response.dart';
import '../models/signal_history_item.dart';
import '../models/watch_item.dart';
import '../services/api_service.dart';
import 'stock_detail_page.dart';

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  final ApiService _apiService = ApiService();
  final Map<String, List<SignalHistoryItem>> _signalHistoryCache = {};

  List<WatchItem> _watchItems = <WatchItem>[];
  List<AnalysisResponse> _watchResults = <AnalysisResponse>[];

  String _selectedFilter = 'ALL';
  String _selectedSort = 'SCORE';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  Future<void> _loadSignalHistory(String ticker) async {
    if (_signalHistoryCache.containsKey(ticker)) return;

    try {
      final history = await _apiService.fetchSignalHistoryByTicker(
        ticker: ticker,
      );
      if (!mounted) return;

      setState(() {
        _signalHistoryCache[ticker] = history;
      });
    } catch (_) {
      _signalHistoryCache[ticker] = <SignalHistoryItem>[];
    }
  }

  Future<void> _loadWatchlist() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<WatchItem> items = await _apiService.fetchWatchlistItems();
      List<AnalysisResponse> results = <AnalysisResponse>[];

      try {
        results = await _apiService.fetchWatchlistAnalysis();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '\uCD5C\uADFC \uBD84\uC11D \uACB0\uACFC\uB97C \uBD88\uB7EC\uC624\uC9C0 \uBABB\uD588\uC2B5\uB2C8\uB2E4. \uAD00\uC2EC\uC885\uBAA9 \uBAA9\uB85D\uC740 \uD45C\uC2DC\uB429\uB2C8\uB2E4.',
              ),
            ),
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _watchItems = items;
        _watchResults = results;
      });

      for (final item in items) {
        _loadSignalHistory(item.ticker);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            '\uAD00\uC2EC\uC885\uBAA9\uC744 \uBD88\uB7EC\uC624\uC9C0 \uBABB\uD588\uC2B5\uB2C8\uB2E4. $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteWatchItem(String ticker) async {
    try {
      await _apiService.deleteWatchlistItem(ticker);
      if (!mounted) return;

      setState(() {
        _watchItems.removeWhere((item) => item.ticker == ticker);
        _watchResults.removeWhere((item) => item.ticker == ticker);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '\uAD00\uC2EC\uC885\uBAA9\uC774 \uC0AD\uC81C\uB418\uC5C8\uC2B5\uB2C8\uB2E4.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '\uC0AD\uC81C\uC5D0 \uC2E4\uD328\uD588\uC2B5\uB2C8\uB2E4. $error'),
        ),
      );
    }
  }

  Future<void> _reloadAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _apiService.runWatchlistAnalysis();
      await _loadWatchlist();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '\uAD00\uC2EC\uC885\uBAA9 \uBD84\uC11D\uC744 \uC0C8\uB85C \uC2E4\uD589\uD588\uC2B5\uB2C8\uB2E4.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            '\uAD00\uC2EC\uC885\uBAA9 \uBD84\uC11D \uC2E4\uD589\uC5D0 \uC2E4\uD328\uD588\uC2B5\uB2C8\uB2E4. $error';
        _isLoading = false;
      });
    }
  }

  AnalysisResponse _analysisFor(String ticker) {
    return _watchResults.firstWhere(
      (result) => result.ticker == ticker,
      orElse: () => AnalysisResponse.empty(),
    );
  }

  Color _statusColor(String status) {
    if (status.startsWith('ATTACK')) return const Color(0xFFDC2626);
    if (status.startsWith('WATCH')) return const Color(0xFFD97706);
    if (status == 'RISK') return const Color(0xFF2563EB);
    return const Color(0xFF64748B);
  }

  String _statusLabel(String status) {
    if (status.startsWith('ATTACK')) return '\uACF5\uACA9';
    if (status.startsWith('WATCH')) return '\uAD00\uCC30';
    if (status == 'RISK') return '\uC704\uD5D8';
    return '\uB300\uAE30';
  }

  IconData _statusIcon(String status) {
    if (status.startsWith('ATTACK')) return Icons.trending_up_rounded;
    if (status.startsWith('WATCH')) return Icons.visibility_rounded;
    if (status == 'RISK') return Icons.warning_amber_rounded;
    return Icons.hourglass_bottom_rounded;
  }

  int _statusPriority(String status) {
    if (status.startsWith('ATTACK')) return 0;
    if (status.startsWith('WATCH')) return 1;
    if (status == 'RISK') return 2;
    return 3;
  }

  List<WatchItem> get _filteredWatchItems {
    List<WatchItem> items;

    if (_selectedFilter == 'ALL') {
      items = List<WatchItem>.from(_watchItems);
    } else {
      items = _watchItems.where((item) {
        final status = _analysisFor(item.ticker).finalStatus ?? 'WAIT';
        if (_selectedFilter == 'ATTACK') return status.startsWith('ATTACK');
        if (_selectedFilter == 'WATCH') return status.startsWith('WATCH');
        if (_selectedFilter == 'RISK') return status == 'RISK';
        return true;
      }).toList();
    }

    if (_selectedSort == 'SCORE') {
      items.sort((a, b) {
        final aResult = _analysisFor(a.ticker);
        final bResult = _analysisFor(b.ticker);
        final scoreCompare =
            (bResult.finalScore ?? 0).compareTo(aResult.finalScore ?? 0);
        if (scoreCompare != 0) return scoreCompare;
        return _statusPriority(aResult.finalStatus ?? 'WAIT')
            .compareTo(_statusPriority(bResult.finalStatus ?? 'WAIT'));
      });
    } else {
      items.sort((a, b) => a.stockName.compareTo(b.stockName));
    }

    return items;
  }

  int _countByStatus(String target) {
    if (target == 'ALL') return _watchItems.length;
    return _watchItems.where((item) {
      final status = _analysisFor(item.ticker).finalStatus ?? 'WAIT';
      if (target == 'ATTACK') return status.startsWith('ATTACK');
      if (target == 'WATCH') return status.startsWith('WATCH');
      if (target == 'RISK') return status == 'RISK';
      return false;
    }).length;
  }

  double _averageScore() {
    if (_watchItems.isEmpty) return 0;
    final total = _watchItems.fold<int>(
      0,
      (sum, item) => sum + (_analysisFor(item.ticker).finalScore ?? 0),
    );
    return total / _watchItems.length;
  }

  WatchItem? _topItem() {
    if (_watchItems.isEmpty) return null;
    final items = List<WatchItem>.from(_watchItems);
    items.sort((a, b) {
      return (_analysisFor(b.ticker).finalScore ?? 0)
          .compareTo(_analysisFor(a.ticker).finalScore ?? 0);
    });
    return items.first;
  }

  Widget _buildSummaryCard() {
    final topItem = _topItem();
    final topResult = topItem == null ? null : _analysisFor(topItem.ticker);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\uAD00\uC2EC\uC885\uBAA9',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '\uC800\uC7A5\uD55C \uC885\uBAA9\uC758 \uCD5C\uADFC \uBD84\uC11D \uD750\uB984\uC744 \uD655\uC778\uD569\uB2C8\uB2E4.',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '\uC0C8\uB85C\uACE0\uCE68',
                onPressed: _isLoading ? null : _reloadAnalysis,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetricChip(
                label: '\uC804\uCCB4',
                value: '${_watchItems.length}',
                color: const Color(0xFF2563EB),
              ),
              _buildMetricChip(
                label: '\uACF5\uACA9',
                value: '${_countByStatus('ATTACK')}',
                color: const Color(0xFFDC2626),
              ),
              _buildMetricChip(
                label: '\uAD00\uCC30',
                value: '${_countByStatus('WATCH')}',
                color: const Color(0xFFD97706),
              ),
              _buildMetricChip(
                label: '\uD3C9\uADE0',
                value: _averageScore().toStringAsFixed(0),
                color: const Color(0xFF059669),
              ),
            ],
          ),
          if (topItem != null && topResult != null) ...[
            const SizedBox(height: 14),
            _buildTopInlineCard(topItem, topResult),
          ],
        ],
      ),
    );
  }

  Widget _buildTopInlineCard(WatchItem item, AnalysisResponse result) {
    final status = result.finalStatus ?? 'WAIT';
    final statusColor = _statusColor(status);
    final score = result.finalScore ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_rounded, color: statusColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.stockName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$score\uC810',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildSegmentedControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildControlLabel('\uC815\uB82C'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
                'SCORE', '\uC810\uC218\uC21C', const Color(0xFF059669)),
            _buildFilterChip(
                'NAME', '\uC774\uB984\uC21C', const Color(0xFF2563EB)),
          ],
        ),
        const SizedBox(height: 14),
        _buildControlLabel('\uC0C1\uD0DC'),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('ALL', '\uC804\uCCB4', const Color(0xFF64748B)),
              _buildFilterChip(
                  'ATTACK', '\uACF5\uACA9', const Color(0xFFDC2626)),
              _buildFilterChip(
                  'WATCH', '\uAD00\uCC30', const Color(0xFFD97706)),
              _buildFilterChip('RISK', '\uC704\uD5D8', const Color(0xFF2563EB)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, Color color) {
    final isSort = value == 'SCORE' || value == 'NAME';
    final selected = isSort ? _selectedSort == value : _selectedFilter == value;
    final count = isSort ? null : _countByStatus(value);

    return Padding(
      padding: EdgeInsets.only(right: isSort ? 0 : 8),
      child: FilterChip(
        selected: selected,
        showCheckmark: false,
        label: Text(count == null ? label : '$label $count'),
        labelStyle: TextStyle(
          color:
              selected ? color : Theme.of(context).textTheme.bodyMedium?.color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        backgroundColor: Theme.of(context).cardColor,
        selectedColor: color.withValues(alpha: 0.12),
        side: BorderSide(
          color: selected
              ? color.withValues(alpha: 0.45)
              : Theme.of(context).dividerColor.withValues(alpha: 0.18),
        ),
        onSelected: (_) {
          setState(() {
            if (isSort) {
              _selectedSort = value;
            } else {
              _selectedFilter = value;
            }
          });
        },
      ),
    );
  }

  Widget _buildWatchItemCard(WatchItem item) {
    final result = _analysisFor(item.ticker);
    final status = result.finalStatus ?? 'WAIT';
    final statusColor = _statusColor(status);
    final score = result.finalScore ?? 0;
    final close = result.close;
    final ma20 = result.ma20;
    final gap = ma20 > 0 && close > 0 ? ((close - ma20) / ma20) * 100 : null;
    final history = _signalHistoryCache[item.ticker] ?? <SignalHistoryItem>[];
    final latest = history.isEmpty ? null : history.first;

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openDetail(item, result),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: statusColor.withValues(
                  alpha: status.startsWith('ATTACK') ? 0.34 : 0.16),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(_statusIcon(status), color: statusColor, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.stockName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          item.ticker,
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          close > 0
                              ? close.toStringAsFixed(0)
                              : '\uBD84\uC11D \uB300\uAE30',
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (gap != null)
                          Text(
                            'MA20 ${gap >= 0 ? '+' : ''}${gap.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: gap >= 0
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF2563EB),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                    if (latest != null) ...[
                      const SizedBox(height: 7),
                      Text(
                        '${latest.previousStatus ?? 'NONE'} \u2192 ${latest.currentStatus}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: statusColor.withValues(alpha: 0.82),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    tooltip: '\uC0AD\uC81C',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => _deleteWatchItem(item.ticker),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  void _openDetail(WatchItem item, AnalysisResponse result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StockDetailPage(
          ticker: item.ticker,
          stockName: item.stockName,
          finalStatus: result.finalStatus ?? 'WAIT',
          finalScore: (result.finalScore ?? 0).toString(),
        ),
      ),
    );
  }

  Widget _buildSkeletonWatchCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Shimmer.fromColors(
        baseColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE5E7EB),
        highlightColor:
            isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.20),
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color,
          fontSize: 13,
          height: 1.45,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reloadAnalysis,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isLoading && _watchItems.isEmpty)
            Column(
              children: List.generate(5, (_) => _buildSkeletonWatchCard()),
            )
          else if (_errorMessage != null)
            _buildEmptyCard(_errorMessage!)
          else ...[
            _buildSummaryCard(),
            const SizedBox(height: 16),
            _buildSegmentedControls(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '\uC885\uBAA9 \uBAA9\uB85D',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Text(
                  '${_filteredWatchItems.length}\uAC1C',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_watchItems.isEmpty)
              _buildEmptyCard(
                '\uC800\uC7A5\uB41C \uAD00\uC2EC\uC885\uBAA9\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
              )
            else if (_filteredWatchItems.isEmpty)
              _buildEmptyCard(
                '\uC120\uD0DD\uD55C \uC0C1\uD0DC\uC758 \uAD00\uC2EC\uC885\uBAA9\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
              )
            else
              ..._filteredWatchItems.map(_buildWatchItemCard),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _reloadAnalysis,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  '\uC218\uB3D9\uC73C\uB85C \uB2E4\uC2DC \uBD84\uC11D',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
