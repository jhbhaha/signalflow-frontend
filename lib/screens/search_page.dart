import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import 'stock_detail_page.dart';

class SearchPage extends StatefulWidget {
  final VoidCallback? onGoToWatchlist;

  const SearchPage({super.key, this.onGoToWatchlist});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final ApiService _apiService = ApiService();
  final Map<String, List<dynamic>> _searchCache = {};

  Timer? _debounce;
  List<dynamic> _results = <dynamic>[];
  bool _isLoading = false;
  bool _hasSearched = false;

  final List<String> _popularKeywords = const [
    '\uC0BC\uC131\uC804\uC790',
    'SK\uD558\uC774\uB2C9\uC2A4',
    '\uCE74\uCE74\uC624',
    'NAVER',
    '\uD604\uB300\uCC28',
  ];

  final List<String> _recentKeywords = <String>[];

  Future<void> _searchStocks(String keyword) async {
    final String trimmed = keyword.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _results = <dynamic>[];
        _isLoading = false;
        _hasSearched = false;
      });
      return;
    }

    if (!_recentKeywords.contains(trimmed)) {
      _recentKeywords.insert(0, trimmed);
      if (_recentKeywords.length > 5) {
        _recentKeywords.removeLast();
      }
    }

    if (_searchCache.containsKey(trimmed)) {
      setState(() {
        _results = _searchCache[trimmed]!;
        _isLoading = false;
        _hasSearched = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final Uri uri = Uri.parse(
        '${ApiService.baseUrl}/search/stocks?keyword=${Uri.encodeComponent(trimmed)}',
      );

      final http.Response response = await http.get(uri).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) {
        throw Exception('\uAC80\uC0C9 \uC2E4\uD328: ${response.statusCode}');
      }

      final Map<String, dynamic> data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      if (!mounted) return;

      final List<dynamic> items =
          data['items'] as List<dynamic>? ?? <dynamic>[];
      _searchCache[trimmed] = items;

      setState(() {
        _results = items;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _results = <dynamic>[];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '\uAC80\uC0C9 \uC911 \uC624\uB958\uAC00 \uBC1C\uC0DD\uD588\uC2B5\uB2C8\uB2E4. $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addToWatchlist({
    required String ticker,
    required String stockName,
  }) async {
    try {
      await _apiService.addWatchlistItem(
        ticker: ticker,
        stockName: stockName,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$stockName \uAD00\uC2EC\uC885\uBAA9\uC5D0 \uCD94\uAC00\uD588\uC2B5\uB2C8\uB2E4.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '\uAD00\uC2EC\uC885\uBAA9 \uCD94\uAC00\uC5D0 \uC2E4\uD328\uD588\uC2B5\uB2C8\uB2E4. $error',
          ),
        ),
      );
    }
  }

  void _openStockDetail({
    required String ticker,
    required String stockName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StockDetailPage(
          ticker: ticker,
          stockName: stockName,
          finalStatus: 'WAIT',
          finalScore: '',
        ),
      ),
    );
  }

  void _selectKeyword(String keyword) {
    _controller.text = keyword;
    _controller.selection = TextSelection.collapsed(offset: keyword.length);
    _searchStocks(keyword);
    setState(() {});
  }

  void _clearSearch() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {
      _results = <dynamic>[];
      _isLoading = false;
      _hasSearched = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Widget _buildSearchField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: '\uC885\uBAA9\uBA85 \uB610\uB294 \uD2F0\uCEE4 \uAC80\uC0C9',
          hintStyle: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF2563EB),
          ),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: '\uAC80\uC0C9\uC5B4 \uC9C0\uC6B0\uAE30',
                  icon: Icon(
                    Icons.close_rounded,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  onPressed: _clearSearch,
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
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
      ),
    );
  }

  Widget _buildKeywordSection({
    required String title,
    required List<String> keywords,
    bool showHistoryIcon = false,
  }) {
    if (keywords.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: keywords.map((keyword) {
            return _buildKeywordChip(
              keyword: keyword,
              showHistoryIcon: showHistoryIcon,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildKeywordChip({
    required String keyword,
    required bool showHistoryIcon,
  }) {
    return ActionChip(
      avatar:
          showHistoryIcon ? const Icon(Icons.history_rounded, size: 15) : null,
      label: Text(keyword),
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      shape: StadiumBorder(
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.20),
        ),
      ),
      backgroundColor: Theme.of(context).cardColor,
      onPressed: () => _selectKeyword(keyword),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 14),
          Text(
            '\uC885\uBAA9\uC744 \uCC3E\uB294 \uC911\uC785\uB2C8\uB2E4.',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: _results.length + 1,
      separatorBuilder: (_, index) =>
          index == 0 ? const SizedBox(height: 10) : const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Row(
            children: [
              Text(
                '\uAC80\uC0C9 \uACB0\uACFC',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              _buildCountChip('${_results.length}'),
            ],
          );
        }

        final Map<String, dynamic> item =
            _results[index - 1] as Map<String, dynamic>;
        final String ticker = (item['ticker'] ?? '').toString();
        final String stockName = (item['stock_name'] ?? '').toString();

        return _buildResultCard(
          ticker: ticker,
          stockName: stockName,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildCountChip(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required String ticker,
    required String stockName,
    required bool isDark,
  }) {
    return Material(
      color: isDark ? const Color(0xFF111827) : Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openStockDetail(
          ticker: ticker,
          stockName: stockName,
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: Color(0xFF2563EB),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stockName.isEmpty ? ticker : stockName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ticker,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: '\uAD00\uC2EC\uC885\uBAA9 \uCD94\uAC00',
                icon: const Icon(Icons.star_outline_rounded, size: 20),
                color: const Color(0xFF16A34A),
                onPressed: () async {
                  await _addToWatchlist(
                    ticker: ticker,
                    stockName: stockName,
                  );

                  if (widget.onGoToWatchlist != null) {
                    widget.onGoToWatchlist!();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (!_hasSearched) {
      return _buildEmptyState(
        icon: Icons.manage_search_rounded,
        title: '\uC885\uBAA9\uC744 \uAC80\uC0C9\uD574\uBCF4\uC138\uC694',
        description:
            '\uC885\uBAA9\uBA85 \uB610\uB294 \uD2F0\uCEE4\uB97C \uC785\uB825\uD558\uBA74\n\uBD84\uC11D\uD560 \uC885\uBAA9\uC744 \uBE60\uB974\uAC8C \uCC3E\uC744 \uC218 \uC788\uC2B5\uB2C8\uB2E4.',
      );
    }

    if (_results.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: '\uAC80\uC0C9 \uACB0\uACFC\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4',
        description:
            '\uC885\uBAA9\uBA85\uC774\uB098 \uD2F0\uCEE4\uB97C \uB2E4\uC2DC \uD655\uC778\uD574\uBCF4\uC138\uC694.',
      );
    }

    return _buildResultsList(isDark);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: _buildSearchField(isDark),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKeywordSection(
                title: '\uC778\uAE30 \uAC80\uC0C9',
                keywords: _popularKeywords,
              ),
              if (_recentKeywords.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildKeywordSection(
                  title: '\uCD5C\uADFC \uAC80\uC0C9',
                  keywords: _recentKeywords,
                  showHistoryIcon: true,
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _buildContent(isDark),
        ),
      ],
    );
  }
}
