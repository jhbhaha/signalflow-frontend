// File: search_page.dart (검색 화면)
// Last Modified: 2026-04-15 20:05 KST (작성자: ChatGPT)
// Insert Location: G:\stockmarket_frontend\lib\screens\search_page.dart 전체 교체

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
// [2026-05-24 02:05 KST]
// 종목상세 화면 연결
// (Connect stock detail page)
import 'stock_detail_page.dart';
// debounce timer 추가
// (Add debounce timer)
import 'dart:async';

class SearchPage extends StatefulWidget {
  final VoidCallback? onGoToWatchlist;

  const SearchPage({super.key, this.onGoToWatchlist});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // 검색 입력 제어용 컨트롤러
  final TextEditingController _controller = TextEditingController();

  // 관심종목 저장용 API 서비스
  final ApiService _apiService = ApiService();
  // 검색 debounce timer
  // (Search debounce timer)
  Timer? _debounce;

  // 검색 결과 및 로딩 상태
  List<dynamic> _results = <dynamic>[];
  // 검색 결과 메모리 캐시
  // (Search result memory cache)
  final Map<String, List<dynamic>>
  _searchCache = {};
  bool _isLoading = false;
  // 검색 실행 여부
  // (Track whether search was executed)
  bool _hasSearched = false;
  // 인기 검색 및 최근 검색 (Popular & recent searches)
  final List<String> _popularKeywords = [
    '삼성전자',
    'SK하이닉스',
    '카카오',
    'NAVER',
    '현대차',
  ];

  final List<String> _recentKeywords = <String>[];

  // 종목 검색 API 호출
  Future<void> _searchStocks(String keyword) async {
    final String trimmed = keyword.trim();
    // 검색 캐시 조회
    // (Search cache lookup)
    if (_searchCache.containsKey(trimmed)) {
      setState(() {
        _results = _searchCache[trimmed]!;
        _isLoading = false;
      });

      return;
    }

    if (trimmed.isEmpty) {
      setState(() {
        _results = <dynamic>[];
        _isLoading = false;
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

      final http.Response response =
      await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        throw Exception('검색 실패: ${response.statusCode}');
      }

      final Map<String, dynamic> data =
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      if (!mounted) {
        return;
      }

      final items =
      (data['items'] as List<dynamic>? ?? <dynamic>[]);
      // 검색 캐시 저장
      // (Store search cache)
      _searchCache[trimmed] = items;

      setState(() {
        _results = items;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _results = <dynamic>[];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('검색 중 오류가 발생했습니다. $error')),
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  // [Added by ChatGPT | 2026-04-15 20:05 KST] 검색 결과 항목을 관심종목에 저장
  Future<void> _addToWatchlist({
    required String ticker,
    required String stockName,
  }) async {
    try {
      await _apiService.addWatchlistItem(
        ticker: ticker,
        stockName: stockName,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$stockName 관심종목이 추가되었습니다.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('관심종목 추가에 실패했습니다. $error')),
      );
    }
  }

  // [2026-05-24 02:10 KST]
  // 검색 결과 클릭 시 종목상세 화면으로 이동
  // (Navigate to stock detail page when tapping search result)

  void _moveToAnalysisResult({
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

  // controller + debounce timer 정리
  // (Dispose controller and debounce timer)
  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: <Widget>[
        // SignalFlow 스타일 검색창 적용 (Apply SignalFlow search box style)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF111827)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context)
                    .dividerColor
                    .withValues(alpha: 0.20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDark ? 0.22 : 0.08,
                  ),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: TextField(
              controller: _controller,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: '종목명 또는 티커 검색',
                hintStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Color(0xFF3B82F6),
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  onPressed: () {
                    _controller.clear();

                    setState(() {
                      _results = [];
                    });
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                ),
              ),
              // [Modified by ChatGPT | 2026-05-14 18:30 KST]
// debounce 적용 검색 입력
// (Debounced stock search)
              onChanged: (value) {
                setState(() {});

                if (value.trim().isNotEmpty &&
                    !_recentKeywords.contains(value.trim())) {
                  _recentKeywords.insert(0, value.trim());

                  if (_recentKeywords.length > 5) {
                    _recentKeywords.removeLast();
                  }
                }

                _debounce?.cancel();

                _debounce = Timer(
                  const Duration(milliseconds: 400),
                      () {
                    _searchStocks(value);
                  },
                );
              },
            ),
          ),
        ),
        // [Added by ChatGPT | 2026-05-08 19:20 KST]
// 인기 검색 영역 (Popular search section)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '인기 검색',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _popularKeywords.map((keyword) {
                  return GestureDetector(
                    onTap: () {
                      _controller.text = keyword;
                      _searchStocks(keyword);

                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Theme.of(context)
                              .dividerColor
                              .withValues(alpha: 0.20),
                        ),
                      ),
                      child: Text(
                        keyword,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              if (_recentKeywords.isNotEmpty) ...[
                const SizedBox(height: 18),

                Text(
                  '최근 검색',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _recentKeywords.map((keyword) {
                    return GestureDetector(
                      onTap: () {
                        _controller.text = keyword;
                        _searchStocks(keyword);

                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF111827)
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.history,
                              size: 14,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              keyword,
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : !_hasSearched
              ? Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF111827)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Theme.of(context)
                      .dividerColor
                      .withValues(alpha: 0.20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.manage_search,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    size: 48,
                  ),

                  SizedBox(height: 14),

                  Text(
                    '종목을 검색해보세요',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    '종목명 또는 티커를 입력하면\n실시간 분석 종목을 찾을 수 있습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          )
              : _results.isEmpty
              ? Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF111827)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Theme.of(context)
                      .dividerColor
                      .withValues(alpha: 0.20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    size: 48,
                  ),

                  SizedBox(height: 14),

                  Text(
                    '검색 결과가 없습니다.',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    '종목명 또는 티커를 다시 입력해보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          )
              : ListView.builder(
            itemCount: _results.length,
            itemBuilder: (BuildContext context, int index) {
              final Map<String, dynamic> item =
              _results[index] as Map<String, dynamic>;

              final String ticker =
              (item['ticker'] ?? '').toString();
              final String stockName =
              (item['stock_name'] ?? '').toString();

              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF111827)
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _moveToAnalysisResult(
                    ticker: ticker,
                    stockName: stockName,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6)
                                .withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.show_chart,
                            color: Color(0xFF3B82F6),
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stockName,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .dividerColor
                                      .withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  ticker,
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        GestureDetector(
                          onTap: () async {
                            await _addToWatchlist(
                              ticker: ticker,
                              stockName: stockName,
                            );

                            if (widget.onGoToWatchlist != null) {
                              widget.onGoToWatchlist!();
                            }
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E)
                                  .withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF22C55E)
                                    .withValues(alpha: 0.35),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF22C55E)
                                      .withValues(alpha: 0.18),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.star_outline,
                              color: Color(0xFF22C55E),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}