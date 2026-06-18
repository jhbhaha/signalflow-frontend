// File: home_page.dart (홈 화면)
// Last Modified: 2026-05-12 12:10 KST
// Insert Location: G:\stockmarket_frontend\lib\screens\home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dashboard_page.dart';
import 'search_page.dart';
import 'watchlist_page.dart';
import 'attack_page.dart';
// [2026-05-12 12:10 KST]
// 상태 변화 히스토리 화면 추가 (Add signal history page)
import 'signal_history_page.dart';
import 'notification_center_page.dart';
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  // [2026-06-18 08:00 KST]
  // 뒤로가기 두 번 입력 시 앱 종료 처리용 시간 저장
  DateTime? _lastBackPressedAt;
  // [2026-05-12 14:30 KST]
  // 읽지 않은 알림 개수 상태 추가 (Add unread notification count state)
  final ApiService _apiService = ApiService();
  int _unreadNotificationCount = 0;

  // [2026-05-12 12:10 KST]
  // 히스토리 탭 index 4 추가 (Add history tab index 4)
  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return const DashboardPage();
      case 1:
        return const SearchPage();
      case 2:
        return const WatchlistPage();
      case 3:
        return const AttackPage();
      case 4:
        return const SignalHistoryPage();
      default:
        return const DashboardPage();
    }
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isActive = _currentIndex == index;
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;
    final Color activeColor = const Color(0xFF3B82F6);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          boxShadow: isActive
              ? [
            BoxShadow(
              color: activeColor.withValues(alpha: 0.25),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive
                  ? activeColor
                  : Theme.of(context).textTheme.bodyMedium?.color,
              size: 22,
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? const Color(0xFFBFDBFE) : activeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // File: home_page.dart
// Insert Location: lib/screens/home_page.dart 안의 기존 build() 메서드 전체 교체

  @override
  Widget build(BuildContext context) {
    // [2026-06-18 08:00 KST]
    // 하단 탭에서는 뒤로가기 시 대시보드로 이동하고,
    // 대시보드에서 한 번 더 누르면 앱 종료
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return;
        }

        final now = DateTime.now();
        final shouldExit = _lastBackPressedAt != null &&
            now.difference(_lastBackPressedAt!) <= const Duration(seconds: 2);

        if (shouldExit) {
          SystemNavigator.pop();
          return;
        }

        _lastBackPressedAt = now;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('한 번 더 누르면 앱이 종료됩니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Scaffold(
        // [2026-05-12 14:20 KST]
        // 알림 센터 이동 버튼 추가 (Add notification center navigation button)

        // [2026-05-12 14:30 KST]
        // 읽지 않은 알림 Badge 표시 추가 (Add unread notification badge)
        appBar: AppBar(
          title: const Text('SignalFlow'),
          actions: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationCenterPage(),
                      ),
                    );

                    await _loadUnreadNotificationCount();
                  },
                ),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        _unreadNotificationCount > 99
                            ? '99+'
                            : _unreadNotificationCount.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: _buildCurrentPage(),
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Theme.of(context)
                    .dividerColor
                    .withValues(alpha: 0.20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.35
                        : 0.10,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: '대시보드',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.search,
                  activeIcon: Icons.search,
                  label: '검색',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.star_outline,
                  activeIcon: Icons.star,
                  label: '관심',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.flash_on_outlined,
                  activeIcon: Icons.flash_on,
                  label: '공격',
                ),
                // [2026-05-12 12:10 KST]
                // 상태 변화 히스토리 탭 추가 (Add signal history tab)
                _buildNavItem(
                  index: 4,
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history,
                  label: '히스토리',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // [2026-05-12 14:30 KST]
  // 홈 진입 시 읽지 않은 알림 개수 조회 (Fetch unread notification count when home page starts)
  @override
  void initState() {
    super.initState();
    _loadUnreadNotificationCount();
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count = await _apiService.fetchUnreadNotificationCount();

      if (!mounted) {
        return;
      }

      setState(() {
        _unreadNotificationCount = count;
      });
    } catch (error) {
      print('Unread notification count load failed: $error');
    }
  }

}