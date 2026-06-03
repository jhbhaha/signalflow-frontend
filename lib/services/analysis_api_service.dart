// File: analysis_api_service.dart (분석 API 서비스)
// [Modified by ChatGPT | 2026-04-25 23:25 KST]
// Insert Location: G:\stockmarket_frontend\lib\services\analysis_api_service.dart 전체 교체

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/analysis_response.dart';

class AnalysisApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<AnalysisResponse> runOneAnalysis({
    required String ticker,
    required String stockName,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/analysis/run-one'
          '?ticker=${Uri.encodeComponent(ticker)}'
          '&stock_name=${Uri.encodeComponent(stockName)}',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        '분석 요청 실패: ${response.statusCode} / ${response.body}',
      );
    }

    final Map<String, dynamic> jsonMap =
    json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    return AnalysisResponse.fromJson(jsonMap);
  }
}