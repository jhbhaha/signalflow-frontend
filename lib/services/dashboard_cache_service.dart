// File: dashboard_cache_service.dart (대시보드 캐시 서비스)
// [Added by ChatGPT | 2026-05-22 14:20 KST]
// Insert Location: lib/services/dashboard_cache_service.dart 새 파일 생성

import '../models/analysis_response.dart';
import '../models/cached_analysis_item.dart';
import '../models/dashboard_summary.dart';
import '../models/recommendation_item.dart';
import 'api_service.dart';

class DashboardCacheService {
  DashboardCacheService({
    required ApiService apiService,
  }) : _apiService = apiService;

  final ApiService _apiService;

  final Map<String, CachedAnalysisItem> _analysisResultCache = {};

  Future<AnalysisResponse> getAnalysisWithCache({
    required String ticker,
    required String stockName,
  }) async {
    final cache = _analysisResultCache[ticker];

    if (cache != null) {
      final cacheAge = DateTime.now().difference(cache.cachedAt);

      if (cacheAge.inMinutes < 5) {
        return cache.result;
      }
    }

    final AnalysisResponse result = await _apiService
        .analyzeSingle(
      ticker: ticker,
      stockName: stockName,
    )
        .timeout(
      const Duration(seconds: 15),
    );

    _analysisResultCache[ticker] = CachedAnalysisItem(
      result: result,
      cachedAt: DateTime.now(),
    );

    return result;
  }

  Future<void> preloadTopAnalysis({
    required DashboardSummary summary,
    required List<RecommendationItem> recommendations,
  }) async {
    try {
      final List<Future<void>> preloadTasks = [];

      final attackSignals = summary.topSignals
          .where(
            (item) => item.finalStatus.startsWith('ATTACK'),
      )
          .take(3)
          .toList();

      for (final signal in attackSignals) {
        if (_analysisResultCache.containsKey(signal.ticker)) {
          continue;
        }

        preloadTasks.add(
          getAnalysisWithCache(
            ticker: signal.ticker,
            stockName: signal.stockName,
          ).then((_) {}),
        );
      }

      final topRecommendations = recommendations.take(3).toList();

      for (final item in topRecommendations) {
        if (_analysisResultCache.containsKey(item.ticker)) {
          continue;
        }

        preloadTasks.add(
          getAnalysisWithCache(
            ticker: item.ticker,
            stockName: item.stockName,
          ).then((_) {}),
        );
      }

      await Future.wait(preloadTasks);
    } catch (e) {
      // preload 실패는 화면 동작을 막지 않음
      // (Do not block UI when preload fails)
    }
  }
}

