// File: company_analysis_service.dart
// Last Modified: 2026-06-15 13:40 KST (작성자: ChatGPT)
// Insert Location: G:\stockmarket_frontend\lib\services\company_analysis_service.dart 전체 교체

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/company_analysis.dart';
import '../models/company_trend.dart';
import 'package:flutter/foundation.dart';

class CompanyAnalysisService {
  static const String baseUrl =
      'https://stockmarket-backend-nwkm.onrender.com';

  Future<CompanyAnalysis> fetchCompanyAnalysis({
    required String stockCode,
    required String year,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/company-analysis/$stockCode?year=$year',
    );

    // [2026-06-18 08:20 KST]
    // 기업분석 API 호출 URL/응답 앞부분 로그 출력
    debugPrint('[CompanyAnalysis] GET $uri');

    final response = await http.get(uri);

    debugPrint('[CompanyAnalysis] status=${response.statusCode}');
    debugPrint(
      '[CompanyAnalysis] body=${utf8.decode(response.bodyBytes).substring(0, utf8.decode(response.bodyBytes).length > 500 ? 500 : utf8.decode(response.bodyBytes).length)}',
    );

    if (response.statusCode != 200) {
      throw Exception('기업분석 조회 실패: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return CompanyAnalysis.fromJson(data);
  }

  // [Added by ChatGPT | 2026-06-15 13:40 KST]
  // 실적추이 API 조회
  Future<CompanyTrend> fetchCompanyTrend({
    required String stockCode,
    int startYear = 2022,
    int endYear = 2024,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/company-analysis/trend/$stockCode'
          '?start_year=$startYear'
          '&end_year=$endYear',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('실적추이 조회 실패: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return CompanyTrend.fromJson(data);
  }
}