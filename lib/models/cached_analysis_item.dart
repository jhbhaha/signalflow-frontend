// File: cached_analysis_item.dart (분석 캐시 모델)
// [2026-05-21 18:00 KST]

import 'analysis_response.dart';

class CachedAnalysisItem {

  final AnalysisResponse result;

  final DateTime cachedAt;

  CachedAnalysisItem({
    required this.result,
    required this.cachedAt,
  });
}