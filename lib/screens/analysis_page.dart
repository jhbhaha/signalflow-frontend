// File: analysis_page.dart (분석 화면)
// Last Modified: 2026-06-28 17:35 KST (작성자: ChatGPT)
// Insert Location: lib/screens/analysis_page.dart 전체 교체

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/recommendation_item.dart';
import '../services/api_service.dart';
import '../widgets/dashboard/recommendation_card.dart';
import 'analysis_result_page.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;
  int _searchRequestId = 0;

  bool _isLoading = true;
  bool _isSearching = false;
  bool _hasSearched = false;

  String? _errorMessage;

  List<dynamic> _searchResults = <dynamic>[];
  List<RecommendationItem> _recommendations = <RecommendationItem>[];
  List<String> _savedTickers = <String>[];

  @override
  void initState() {
    super.initState();
    _loadAnalysisPageData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalysisPageData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _apiService.fetchTopRecommendations(),
        _apiService.fetchWatchlistItems(),
      ]);

      final recommendations = results[0] as List<RecommendationItem>;
      final watchlistItems = results[1] as List<dynamic>;

      recommendations.sort(
        (a, b) => b.finalScore.compareTo(a.finalScore),
      );

      if (!mounted) return;

      setState(() {
        _recommendations = recommendations;
        _savedTickers = watchlistItems.map((item) {
          return item.ticker.toString();
        }).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = '오늘의 추천 종목을 불러오지 못했습니다.';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchStocks(String keyword) async {
    final trimmed = keyword.trim();
    final requestId = ++_searchRequestId;

    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = <dynamic>[];
        _isSearching = false;
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final uri = Uri.parse(
        '${ApiService.baseUrl}/search/stocks?keyword=${Uri.encodeComponent(trimmed)}',
      );

      final response = await http.get(uri).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) {
        throw Exception('검색 실패: ${response.statusCode}');
      }

      final data = jsonDecode(
        utf8.decode(response.bodyBytes),
      ) as Map<String, dynamic>;

      final items = data['items'] as List<dynamic>? ?? <dynamic>[];

      if (!mounted || requestId != _searchRequestId) return;

      setState(() {
        _searchResults = items;
      });
    } catch (_) {
      if (!mounted || requestId != _searchRequestId) return;

      setState(() {
        _searchResults = <dynamic>[];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('검색하지 못했습니다. 네트워크 연결을 확인해 주세요.'),
        ),
      );
    } finally {
      if (mounted && requestId == _searchRequestId) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchRequestId++;
    _searchController.clear();

    setState(() {
      _searchResults = <dynamic>[];
      _isSearching = false;
      _hasSearched = false;
    });
  }

  Future<void> _openAnalysis({
    required String ticker,
    required String stockName,
  }) async {
    FocusScope.of(context).unfocus();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalysisResultPage(
          ticker: ticker,
          stockName: stockName,
        ),
      ),
    );
  }

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
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 실패: $error'),
        ),
      );
    }
  }

  Widget _buildSearchBox() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        hintText: '종목명 또는 티커 검색',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: '검색어 지우기',
                icon: const Icon(Icons.close_rounded),
                onPressed: _clearSearch,
              ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onSubmitted: _searchStocks,
      onChanged: (value) {
        setState(() {});
        _debounce?.cancel();
        _debounce = Timer(
          const Duration(milliseconds: 400),
          () => _searchStocks(value),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_hasSearched) {
      return const SizedBox.shrink();
    }

    if (_searchResults.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.20),
          ),
        ),
        child: const Column(
          children: [
            Icon(Icons.search_off_rounded, size: 28),
            SizedBox(height: 8),
            Text('일치하는 종목이 없습니다.'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _searchResults.map((item) {
        final ticker = (item['ticker'] ?? '').toString();
        final stockName = (item['stock_name'] ?? '').toString();

        return Card(
          child: ListTile(
            leading: const Icon(Icons.show_chart_rounded),
            title: Text(stockName.isEmpty ? ticker : stockName),
            subtitle: Text(ticker),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              _openAnalysis(
                ticker: ticker,
                stockName: stockName,
              );
            },
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return RefreshIndicator(
        onRefresh: _loadAnalysisPageData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 64),
            Icon(
              Icons.cloud_off_rounded,
              size: 44,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '네트워크 연결을 확인한 후 다시 시도해 주세요.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Center(
              child: FilledButton.icon(
                onPressed: _loadAnalysisPageData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('다시 시도'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnalysisPageData,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_graph_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI 종목 분석',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '종목을 검색하거나 오늘의 추천 신호를 확인하세요.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSearchBox(),
          if (_hasSearched) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '검색 결과',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (!_isSearching)
                  Text(
                    '${_searchResults.length}개',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _buildSearchResults(),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  '오늘의 추천 종목',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                '${_recommendations.length}개',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          RecommendationCard(
            recommendations: _recommendations,
            savedTickers: _savedTickers,
            onItemTap: _openAnalysis,
            onSaveTap: _saveRecommendationToWatchlist,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
