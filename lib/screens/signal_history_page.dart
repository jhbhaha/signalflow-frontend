// File: signal_history_page.dart (상태 변화 히스토리 화면)
// Last Modified: 2026-05-12 12:00 KST (작성자: ChatGPT)
// Insert Location: lib/screens/signal_history_page.dart 새 파일 생성

import 'package:flutter/material.dart';

import '../models/signal_history_item.dart';
import '../services/api_service.dart';

class SignalHistoryPage extends StatefulWidget {
  const SignalHistoryPage({super.key});

  @override
  State<SignalHistoryPage> createState() => _SignalHistoryPageState();
}

class _SignalHistoryPageState extends State<SignalHistoryPage> {
  final ApiService _apiService = ApiService();

  late Future<List<SignalHistoryItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _apiService.fetchSignalHistory();
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = _apiService.fetchSignalHistory();
    });
  }

  // 한국 주식 시장 기준 상태 색상 적용
  // 상승=빨강 / 위험=파랑
  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ATTACK':
        return const Color(0xFFEF4444);

      case 'WATCH':
        return const Color(0xFFF59E0B);

      case 'RISK':
        return const Color(0xFF3B82F6);

      default:
        return const Color(0xFF64748B);
    }
  }

  String _displayPreviousStatus(String? status) {
    if (status == null || status.isEmpty || status == 'None') {
      return 'NEW';
    }
    return status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<SignalHistoryItem>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                '히스토리를 불러오지 못했습니다.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(
              child: Text('아직 상태 변화 히스토리가 없습니다.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      '${item.stockName} (${item.ticker})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_displayPreviousStatus(item.previousStatus)} → ${item.currentStatus}',
                            style: TextStyle(
                              color: _statusColor(item.currentStatus),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('점수: ${item.finalScore}'),
                          const SizedBox(height: 4),
                          Text(
                            item.timestamp,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}