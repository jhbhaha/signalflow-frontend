import 'package:flutter/material.dart';

import '../models/dashboard_summary.dart';

class AttackListPage extends StatelessWidget {
  final List<TopSignal> signals;

  const AttackListPage({super.key, required this.signals});

  Color _statusColor(String status) {
    if (status.startsWith('ATTACK')) return const Color(0xFFDC2626);
    if (status.startsWith('WATCH')) return const Color(0xFFD97706);
    if (status == 'RISK') return const Color(0xFF2563EB);
    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    final attackSignals = signals
        .where((item) => item.finalStatus.startsWith('ATTACK'))
        .toList()
      ..sort((a, b) => b.finalScore.compareTo(a.finalScore));

    return Scaffold(
      appBar: AppBar(title: const Text('\uACF5\uACA9 \uD6C4\uBCF4')),
      body: attackSignals.isEmpty
          ? Center(
              child: Text(
                '\uACF5\uACA9 \uD6C4\uBCF4\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: attackSignals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = attackSignals[index];
                final color = _statusColor(item.finalStatus);

                return Material(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: color.withValues(alpha: 0.18)),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.12),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    title: Text(
                      item.stockName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(item.ticker),
                    trailing: Text(
                      '${item.finalScore}\uC810',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/analysis-result',
                        arguments: {
                          'ticker': item.ticker,
                          'stockName': item.stockName,
                        },
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
