// File: attack_list_page.dart (공격 후보 리스트 화면)
// [Added by ChatGPT | 2026-04-25 21:10 KST]

import 'package:flutter/material.dart';
import '../models/dashboard_summary.dart';

class AttackListPage extends StatelessWidget {
  final List<TopSignal> signals;

  const AttackListPage({super.key, required this.signals});

  @override
  Widget build(BuildContext context) {
    final attackSignals =
    signals.where((e) => e.finalStatus.startsWith('ATTACK')).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('공격 후보')),
      body: attackSignals.isEmpty
          ? const Center(child: Text('공격 후보 없음'))
          : ListView.builder(
        itemCount: attackSignals.length,
        itemBuilder: (context, index) {
          final s = attackSignals[index];
          return ListTile(
            title: Text('${s.stockName} (${s.ticker})'),
            subtitle: Text(s.etfReason ?? ''),
            trailing: Text('${s.finalScore}점'),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/analysis-result',
                arguments: {
                  'ticker': s.ticker,
                  'stock_name': s.stockName,
                },
              );
            },
          );
        },
      ),
    );
  }
}