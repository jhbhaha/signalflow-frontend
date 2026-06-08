// File: main.dart (앱 시작 파일)
// Last Modified: 2026-05-12 12:25 KST (작성자: ChatGPT)
// Insert Location: G:\stockmarket_frontend\lib\main.dart 전체 교체

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'screens/home_page.dart';
import 'services/notification_local_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'services/api_service.dart';
import 'screens/stock_detail_page.dart';
// [2026-05-23 22:40 KST]
// 분석 결과 화면 import 추가
// (Add analysis result page import)

import 'screens/analysis_result_page.dart';

// [2026-05-12 12:25 KST]
// Push 클릭 시 화면 이동에 사용할 전역 Navigator Key 추가
// (Add global Navigator Key for push click navigation)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// [Modified by ChatGPT | 2026-05-12 13:30 KST]
// Push 클릭 시 종목 상세 화면으로 자동 이동
// (Navigate to stock detail page when push notification is clicked)
void handleFcmMessageClick(RemoteMessage message) {
  final Map<String, dynamic> data = message.data;

  final String ticker = data['ticker']?.toString() ?? '';
  final String stockName = data['stock_name']?.toString() ?? '';
  final String finalStatus =
      data['final_status']?.toString() ?? data['current_status']?.toString() ?? '';
  final String finalScore = data['final_score']?.toString() ?? '';

  print('FCM CLICK DATA: $data');

  if (ticker.isEmpty) {
    return;
  }

  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => StockDetailPage(
        ticker: ticker,
        stockName: stockName,
        finalStatus: finalStatus,
        finalScore: finalScore,
      ),
    ),
  );
}

// [2026-05-22 18:30 KST]
// 로컬 알림 클릭 시 종목 상세 화면으로 이동
// (Navigate to stock detail page when local notification is tapped)
void handleLocalNotificationClick(String? payload) {
  if (payload == null || payload.isEmpty) {
    return;
  }

  print('LOCAL PAYLOAD: $payload');

  try {
    final Map<String, dynamic> data = jsonDecode(payload);

    final String ticker = data['ticker']?.toString() ?? '';
    final String stockName = data['stock_name']?.toString() ?? '';
    final String finalStatus = data['final_status']?.toString() ?? '';
    final String finalScore = data['final_score']?.toString() ?? '';

    if (ticker.isEmpty) {
      return;
    }

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => StockDetailPage(
          ticker: ticker,
          stockName: stockName,
          finalStatus: finalStatus,
          finalScore: finalScore,
        ),
      ),
    );
  } catch (error) {
    print('LOCAL NOTIFICATION CLICK ERROR: $error');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  // [2026-06-05 00:00 KST]
  // Google Mobile Ads SDK 초기화 (Initialize Google Mobile Ads SDK)
  await MobileAds.instance.initialize();

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  final String? fcmToken = await FirebaseMessaging.instance.getToken();
  print('FCM TOKEN: $fcmToken');

  if (fcmToken != null) {
    try {
      await ApiService().registerFcmToken(fcmToken);
    } catch (error) {
      print('FCM token registration failed: $error');
    }
  }

  // [Added by ChatGPT | 2026-05-12 12:25 KST]
  // 앱이 백그라운드 상태일 때 Push 클릭 처리
  // (Handle push click when app is in background)
  FirebaseMessaging.onMessageOpenedApp.listen(handleFcmMessageClick);

  // [Added by ChatGPT | 2026-05-12 12:25 KST]
  // 앱이 완전히 종료된 상태에서 Push 클릭으로 실행된 경우 처리
  // (Handle push click when app is launched from terminated state)
  final RemoteMessage? initialMessage =
  await FirebaseMessaging.instance.getInitialMessage();

  await NotificationLocalService.init(
    onNotificationTap: handleLocalNotificationClick,
  );

  runApp(const StockAnalysisApp());

  if (initialMessage != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      handleFcmMessageClick(initialMessage);
    });
  }
}

class StockAnalysisApp extends StatelessWidget {
  const StockAnalysisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Stock Analysis',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF22C55E),
          surface: Color(0xFF1E293B),
          error: Color(0xFFEF4444),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF111827),
          indicatorColor: const Color(0xFF3B82F6).withValues(alpha: 0.25),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      initialRoute: '/',
      // [2026-05-23 22:40 KST]
      // 분석 결과 화면 라우트 추가
      // (Add analysis result page route)

      routes: {
        '/': (context) => const HomePage(),

        // [2026-05-27 14:10 KST]
        // ticker 기반 상세 분석 화면 호출
        // (Open analysis result page using ticker-based analysis)
        '/analysis-result': (context) {
          final args =
          ModalRoute.of(context)!.settings.arguments
          as Map<String, dynamic>;

          return AnalysisResultPage(
            ticker: args['ticker'].toString(),
            stockName: args['stock_name'].toString(),
          );
        },
      },
    );
  }
}