// File: main.dart (앱 시작 파일)
// Last Modified: 2026-05-12 12:25 KST

import 'dart:convert';
import 'package:flutter/foundation.dart';
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

// [2026-05-12 13:30 KST]
// Push 클릭 시 종목 상세 화면으로 자동 이동 (Navigate to stock detail page when push notification is clicked)
void handleFcmMessageClick(RemoteMessage message) {
  final Map<String, dynamic> data = message.data;

  final String ticker = data['ticker']?.toString() ?? '';
  final String stockName = data['stock_name']?.toString() ?? '';
  final String finalStatus =
      data['final_status']?.toString() ?? data['current_status']?.toString() ?? '';
  final String finalScore = data['final_score']?.toString() ?? '';

  if (kDebugMode) {
    debugPrint('FCM CLICK DATA: $data');
  }

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

  if (kDebugMode) {
    debugPrint('LOCAL PAYLOAD: $payload');
  }

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
    debugPrint('LOCAL NOTIFICATION CLICK ERROR: $error');
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
  if (kDebugMode) {
    debugPrint('FCM TOKEN: $fcmToken');
  }

  if (fcmToken != null) {
    try {
      await ApiService().registerFcmToken(fcmToken);
    } catch (error) {
      debugPrint('FCM token registration failed: $error');
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
      title: 'SignalFlow',
      // [2026-06-10 00:00 KST]
      // 휴대폰 시스템 설정에 따라 라이트/다크 테마 자동 적용 (Apply light/dark theme automatically based on phone system setting)
      themeMode: ThemeMode.system,

      theme: _buildLightTheme(),

      darkTheme: _buildDarkTheme(),
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

ThemeData _buildLightTheme() {
  const primary = Color(0xFF2563EB);
  const positive = Color(0xFF16A34A);
  const background = Color(0xFFF6F8FB);
  const surface = Colors.white;
  const textPrimary = Color(0xFF111827);
  const textSecondary = Color(0xFF64748B);
  const border = Color(0xFFE5E7EB);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: positive,
      surface: surface,
      error: Color(0xFFDC2626),
      onPrimary: Colors.white,
      onSurface: textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: true,
      foregroundColor: textPrimary,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: primary.withValues(alpha: 0.12),
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          color: selected ? primary : textSecondary,
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? primary : textSecondary,
          size: 23,
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: textPrimary,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textPrimary),
      bodyMedium: TextStyle(color: textSecondary),
      titleLarge: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

ThemeData _buildDarkTheme() {
  const primary = Color(0xFF60A5FA);
  const positive = Color(0xFF34D399);
  const background = Color(0xFF0B1120);
  const surface = Color(0xFF111827);
  const textPrimary = Color(0xFFF8FAFC);
  const textSecondary = Color(0xFF94A3B8);
  const border = Color(0xFF1F2937);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: positive,
      surface: surface,
      error: Color(0xFFF87171),
      onPrimary: Color(0xFF0B1120),
      onSurface: textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: true,
      foregroundColor: textPrimary,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: primary.withValues(alpha: 0.18),
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          color: selected ? primary : textSecondary,
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? primary : textSecondary,
          size: 23,
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFFE5E7EB),
      contentTextStyle: const TextStyle(color: Color(0xFF111827)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textPrimary),
      bodyMedium: TextStyle(color: textSecondary),
      titleLarge: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
