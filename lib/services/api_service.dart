// File: lib/services/api_service.dart (API 통신 서비스)
// Last Modified: 2026-04-04 22:20 KST (작성자: ChatGPT)
// Insert Location: G:\stockmarket_frontend\lib\services\api_service.dart 전체 교체

import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

import '../models/dashboard_summary.dart';
import '../models/analysis_response.dart';
import '../models/stock_search_item.dart';
import '../models/watch_item.dart';
import '../models/recommendation_item.dart';
// 알림 이벤트 모델 추가 (Notification event model)
import '../models/notification_event.dart';
import '../models/signal_history_item.dart';
import '../models/attack_statistics.dart';
// [2026-05-13 14:50 KST]
// 시장 흐름 모델 추가
// (Add market overview model)
import '../models/market_overview.dart';
// [2026-05-28 20:00 KST]
// 가격 차트 모델 추가 (Add price chart model)
import '../models/price_chart_point.dart';

class ApiService {
  // API timeout / retry 설정
  // (API timeout and retry settings)
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const int _maxRetryCount = 2;
  // 운영 서버 주소 기본값 지정
  // (Set production API server as default)
  static const String _devBaseUrl =
      'https://stockmarket-backend-nwkm.onrender.com';

  static const String _prodBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://stockmarket-backend-nwkm.onrender.com',
  );

  static const bool _useProductionApi = true;

  static String get baseUrl {
    if (_useProductionApi && _prodBaseUrl.isNotEmpty) {
      return _prodBaseUrl;
    }

    return _devBaseUrl;
  }

// 일시적 네트워크 실패 시 재시도 처리
// (Retry once on temporary network failure)
  Future<http.Response> _sendWithRetry(
      Future<http.Response> Function() request,
      ) async {
    int attempt = 0;

    while (true) {
      try {
        return await request().timeout(_requestTimeout);
      } on TimeoutException {
        if (attempt >= _maxRetryCount) {
          throw Exception(
            '서버 응답 시간이 초과되었습니다. 잠시 후 다시 시도해 주세요.',
          );
        }
      } catch (e) {
        if (attempt >= _maxRetryCount) {
          throw Exception(
            '네트워크 연결이 불안정합니다. 잠시 후 다시 시도해 주세요. $e',
          );
        }
      }

      attempt += 1;

      await Future<void>.delayed(
        const Duration(milliseconds: 350),
      );
    }
  }

  // 단일 종목 분석 API 호출
  Future<AnalysisResponse> analyzeSingle({
    required String ticker,
    required String stockName,
  }) async {
    final String encodedStockName = Uri.encodeQueryComponent(stockName);

    final dynamic decoded = await _getJson(
      '/analysis/run-one?ticker=$ticker&stock_name=$encodedStockName',
    );

    return AnalysisResponse.fromJson(decoded as Map<String, dynamic>);
  }

  // [Added by ChatGPT | 2026-04-25 22:45 KST] 추천 종목 TOP API 호출
  Future<List<RecommendationItem>> fetchTopRecommendations() async {
    // [Modified by ChatGPT | 2026-05-10 19:25 KST]
// 추천 종목 캐시 조회 (Fetch cached top recommendations)
    final dynamic decoded = await _getJson('/recommend/top/latest');

    final List<dynamic> items =
    decoded is Map<String, dynamic>
        ? (decoded['top'] as List<dynamic>? ?? <dynamic>[])
        : <dynamic>[];

    return items
        .map((dynamic item) =>
        RecommendationItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // 캐시된 대시보드 요약 조회 (Fetch cached dashboard summary)
  Future<DashboardSummary> fetchDashboardSummary() async {
    final Uri uri = Uri.parse(
      '$baseUrl/dashboard/summary/latest',
    );

    final response = await _sendWithRetry(
          () => http.get(uri),
    );

    if (response.statusCode != 200) {
      throw Exception(
        '대시보드 요약 조회 실패: ${response.statusCode}',
      );
    }

    final Map<String, dynamic> data =
    jsonDecode(utf8.decode(response.bodyBytes))
    as Map<String, dynamic>;

    return DashboardSummary.fromJson(data);
  }

  // 대시보드 분석 수동 실행에 timeout/retry 적용
  // (Apply timeout/retry to dashboard summary run)
  Future<void> runDashboardSummaryAnalysis() async {
    final Uri uri = Uri.parse(
      '$baseUrl/dashboard/summary/run',
    );

    final response = await _sendWithRetry(
          () => http.post(uri),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        '대시보드 분석 실행 실패: ${response.statusCode}',
      );
    }
  }

  // 공통 GET 요청 처리
  Future<dynamic> _getJson(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _sendWithRetry(
          () => http.get(uri),
    );

    if (response.statusCode != 200) {
      String message = '요청 실패: ${response.statusCode}';

      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
          message = decoded['detail'].toString();
        }
      } catch (_) {}

      throw Exception(message);
    }

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  // 공통 POST 요청 처리
  Future<dynamic> _postJson(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _sendWithRetry(
          () => http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('POST 요청 실패: ${response.statusCode} | $path');
    }

    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  // [Added by ChatGPT | 2026-04-04 22:20 KST]
  // 공통 DELETE 요청 처리
  Future<void> _delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _sendWithRetry(
          () => http.delete(uri),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('DELETE 요청 실패: ${response.statusCode} | $path');
    }
  }

  // [Added by ChatGPT | 2026-04-04 22:20 KST]
  // 응답이 List 또는 {items: [...]} 형태 모두 처리
  List<dynamic> _extractList(dynamic decoded, {String key = 'items'}) {
    if (decoded is List<dynamic>) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      final dynamic value = decoded[key];
      if (value is List<dynamic>) {
        return value;
      }
    }

    return <dynamic>[];
  }

  // [Added by ChatGPT | 2026-04-04 22:20 KST]
  // 종목 검색 자동완성 API 호출
  static Future<List<StockSearchItem>> searchStocks(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      return <StockSearchItem>[];
    }

    final uri = Uri.parse('$baseUrl/search/stocks?keyword=$trimmed');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('종목 검색 실패: ${response.statusCode}');
    }

    final Map<String, dynamic> data =
    jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    final List<dynamic> items = (data['items'] as List<dynamic>? ?? <dynamic>[]);

    return items
        .map((dynamic item) => StockSearchItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // [Added by ChatGPT | 2026-04-04 22:20 KST]
  // 관심종목 목록 조회
  Future<List<WatchItem>> fetchWatchlistItems() async {
    final dynamic decoded = await _getJson('/analysis/watchlist/items');
    final List<dynamic> items = _extractList(decoded, key: 'items');

    return items
        .map((dynamic item) => WatchItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // [Modified by ChatGPT | 2026-05-09 10:30 KST]
// 관심종목 최근 캐시 분석 결과 조회 (Fetch cached watchlist analysis results)
  Future<List<AnalysisResponse>> fetchWatchlistAnalysis() async {
    final dynamic decoded =
    await _getJson('/analysis/watchlist/latest');

    List<dynamic> items = _extractList(decoded, key: 'results');

    return items
        .map(
          (dynamic item) => AnalysisResponse.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  // [Added by ChatGPT | 2026-05-09 10:30 KST]
// 관심종목 전체 분석 수동 실행 (Run watchlist analysis manually)
  Future<void> runWatchlistAnalysis() async {
    final Uri uri = Uri.parse(
      '$baseUrl/analysis/watchlist/run',
    );

    final response = await _sendWithRetry(
          () => http.post(uri),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        '관심종목 분석 실행 실패: ${response.statusCode}',
      );
    }
  }

  // 관심종목 추가 API
  Future<void> addWatchlistItem({
    required String ticker,
    required String stockName,
  }) async {
    // 실제 API 경로에 맞게 수정
    final uri = Uri.parse('$baseUrl/analysis/watchlist/items');

    final response = await _sendWithRetry(
          () => http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ticker': ticker,
          'stock_name': stockName,
        }),
      ),
    );

    // 200~299 모두 성공 처리
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('관심종목 저장 실패: ${response.body}');
    }
  }

  // 관심종목 삭제
  Future<void> deleteWatchlistItem(String ticker) async {
    await _delete('/analysis/watchlist/items/$ticker');
  }

  // [Added by ChatGPT | 2026-04-30 14:35 KST]
// 알림 이벤트 목록 조회 (Fetch notification events)
  Future<List<NotificationEvent>> fetchNotifications() async {
    final dynamic decoded = await _getJson('/notifications/events');

    final List<dynamic> list = decoded['events'] ?? <dynamic>[];

    return list
        .map((dynamic e) => NotificationEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // [Added by ChatGPT | 2026-04-30 14:20 KST]
// 읽지 않은 알림 개수 조회 (Fetch unread notification count)
  Future<int> fetchUnreadNotificationCount() async {
    final dynamic decoded = await _getJson('/notifications/events');

    return decoded['unread_count'] ?? 0;
  }

// [Added by ChatGPT | 2026-04-30 14:20 KST]
// 모든 알림 읽음 처리 (Mark all notifications as read)
  Future<void> markNotificationsAsRead() async {
    await _postJson('/notifications/events/read', <String, dynamic>{});
  }

  // [Added by ChatGPT | 2026-05-11 11:00 KST]
// FCM 토큰 서버 등록 (Register FCM token to backend)

  Future<void> registerFcmToken(String token) async {
    final response = await _sendWithRetry(
          () => http.post(
        Uri.parse('$baseUrl/notifications/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
        }),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('FCM token registration failed');
    }
  }

// signal-history 응답이 List 또는 Map 형태여도 처리되도록 수정
// (Handle signal-history response as either List or Map)
  Future<List<SignalHistoryItem>> fetchSignalHistory() async {
    final uri = Uri.parse('$baseUrl/signal-history/');

    final response = await _sendWithRetry(
          () => http.get(uri),
    );

    if (response.statusCode != 200) {
      throw Exception('상태 변화 히스토리를 불러오지 못했습니다.');
    }

    final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

    List<dynamic> data;

    if (decoded is List<dynamic>) {
      data = decoded;
    } else if (decoded is Map<String, dynamic>) {
      data = decoded['items'] as List<dynamic>? ??
          decoded['history'] as List<dynamic>? ??
          decoded['events'] as List<dynamic>? ??
          <dynamic>[];
    } else {
      data = <dynamic>[];
    }

    return data
        .map((item) => SignalHistoryItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // 종목별 상태 변화 히스토리 조회
  // (Fetch signal history by ticker)
  Future<List<SignalHistoryItem>> fetchSignalHistoryByTicker({
    required String ticker,
  }) async {
    final dynamic decoded = await _getJson(
      '/signal-history/$ticker',
    );

    final List<dynamic> items =
    decoded is Map<String, dynamic>
        ? decoded['items'] as List<dynamic>? ?? <dynamic>[]
        : <dynamic>[];

    return items
        .map(
          (item) => SignalHistoryItem.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  // ATTACK 성공률 통계 조회 API 추가
  // (Add ATTACK success statistics fetch API)
  Future<AttackStatistics> fetchAttackStatistics({
    required String ticker,
  }) async {
    final dynamic decoded = await _getJson(
      '/analysis/statistics/attack?ticker=$ticker',
    );

    return AttackStatistics.fromJson(
      decoded as Map<String, dynamic>,
    );
  }

  // 시장 전체 흐름 조회
  // (Fetch market overview data)
  Future<MarketOverview> fetchMarketOverview() async {
    final dynamic decoded = await _getJson(
      '/dashboard/market-overview',
    );

    return MarketOverview.fromJson(
      decoded as Map<String, dynamic>,
    );
  }

  // [2026-05-28 20:00 KST]
  // 종목 가격 차트 데이터 조회 (Fetch price chart data)
  Future<List<PriceChartPoint>> fetchPriceChart({
    required String ticker,
  }) async {

    final dynamic decoded = await _getJson(
      '/analysis/chart?ticker=$ticker',
    );

    final List<dynamic> items =
    decoded is Map<String, dynamic>
        ? decoded['items'] as List<dynamic>? ?? <dynamic>[]
        : <dynamic>[];

    return items
        .map(
          (item) => PriceChartPoint.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();
  }

}
