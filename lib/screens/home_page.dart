import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/api_service.dart';
import 'attack_page.dart';
import 'analysis_page.dart';
import 'dashboard_page.dart';
import 'notification_center_page.dart';
import 'signal_history_page.dart';
import 'watchlist_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();

  int _currentIndex = 0;
  int _unreadNotificationCount = 0;
  DateTime? _lastBackPressedAt;

  static const List<Widget> _pages = [
    DashboardPage(),
    AnalysisPage(),
    WatchlistPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUnreadNotificationCount();
  }

  @override
  Widget build(BuildContext context) {
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
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/images/signalflow_logo.svg',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'SignalFlow',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          centerTitle: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Badge(
                isLabelVisible: _unreadNotificationCount > 0,
                label: Text(
                  _unreadNotificationCount > 99
                      ? '99+'
                      : _unreadNotificationCount.toString(),
                ),
                child: IconButton(
                  tooltip: '알림',
                  icon: const Icon(Icons.notifications_none_rounded),
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
              ),
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex > 2 ? 0 : _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              height: 68,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (index) {
                if (index == 3) {
                  _showMoreMenu();
                  return;
                }

                setState(() {
                  _currentIndex = index;
                });
              },

              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: '대시보드',
                ),
                NavigationDestination(
                  icon: Icon(Icons.analytics_outlined),
                  selectedIcon: Icon(Icons.analytics_rounded),
                  label: '분석',
                ),
                NavigationDestination(
                  icon: Icon(Icons.star_outline_rounded),
                  selectedIcon: Icon(Icons.star_rounded),
                  label: '관심종목',
                ),
                NavigationDestination(
                  icon: Icon(Icons.more_horiz_rounded),
                  selectedIcon: Icon(Icons.more_rounded),
                  label: '더보기',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.flash_on_rounded,
                    color: Color(0xFFF59E0B),
                  ),
                  title: const Text('공격 후보'),
                  subtitle: const Text('강한 신호가 나온 종목을 확인합니다.'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AttackPage(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.history_rounded),
                  title: const Text('히스토리'),
                  subtitle: const Text('신호 변화 이력을 확인합니다.'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SignalHistoryPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
      debugPrint('Unread notification count load failed: $error');
    }
  }
}
