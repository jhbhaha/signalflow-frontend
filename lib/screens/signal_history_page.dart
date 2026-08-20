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

  Color _statusColor(String status) {
    final upper = status.toUpperCase();
    if (upper.startsWith('ATTACK')) return const Color(0xFFDC2626);
    if (upper.startsWith('WATCH')) return const Color(0xFFD97706);
    if (upper == 'RISK') return const Color(0xFF2563EB);
    return const Color(0xFF64748B);
  }

  String _displayStatusName(String status) {
    final upper = status.toUpperCase();
    if (upper.startsWith('ATTACK')) return '\uACF5\uACA9';
    if (upper.startsWith('WATCH')) return '\uAD00\uCC30';
    if (upper == 'RISK') return '\uC704\uD5D8';
    if (upper == 'WAIT') return '\uB300\uAE30';
    if (upper == 'NONE' || upper == 'NEW') return '\uC2E0\uADDC';
    return status;
  }

  String _displayPreviousStatus(String? status) {
    if (status == null || status.isEmpty) return '\uC2E0\uADDC';
    return _displayStatusName(status);
  }

  String _statusMeaning(String status) {
    final upper = status.toUpperCase();
    if (upper.startsWith('ATTACK')) {
      return '\uACF5\uACA9 \uC2E0\uD638\uAC00 \uAC15\uD574\uC9C4 \uAD6C\uAC04\uC785\uB2C8\uB2E4.';
    }
    if (upper.startsWith('WATCH')) {
      return '\uAD00\uCC30\uC774 \uD544\uC694\uD55C \uC2E0\uD638\uAC00 \uAC10\uC9C0\uB41C \uAD6C\uAC04\uC785\uB2C8\uB2E4.';
    }
    if (upper == 'RISK') {
      return '\uC704\uD5D8 \uC2E0\uD638\uAC00 \uD655\uB300\uB41C \uAD6C\uAC04\uC785\uB2C8\uB2E4.';
    }
    return '\uC0C1\uD0DC \uBCC0\uD654\uAC00 \uAE30\uB85D\uB41C \uAD6C\uAC04\uC785\uB2C8\uB2E4.';
  }

  Widget _buildSummaryCard(List<SignalHistoryItem> items) {
    final latest = items.first;
    final attackCount = items
        .where((item) => item.currentStatus.toUpperCase().startsWith('ATTACK'))
        .length;
    final color = _statusColor(latest.currentStatus);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(Icons.timeline_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\uCD5C\uADFC \uC0C1\uD0DC \uC694\uC57D',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${latest.stockName} (${latest.ticker})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _buildChip(
            label: '\uBCC0\uD654',
            value: '${items.length}',
            color: const Color(0xFF2563EB),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: '\uACF5\uACA9',
            value: '$attackCount',
            color: const Color(0xFFDC2626),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(SignalHistoryItem item) {
    final color = _statusColor(item.currentStatus);

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Container(
                  width: 2,
                  height: 46,
                  margin: const EdgeInsets.only(top: 6),
                  color: color.withValues(alpha: 0.18),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.stockName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.ticker,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    '${_displayPreviousStatus(item.previousStatus)} \u2192 ${_displayStatusName(item.currentStatus)}',
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _statusMeaning(item.currentStatus),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildChip(
                        label: '\uC810\uC218',
                        value: '${item.finalScore}',
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.timestamp,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('신호 히스토리'),
        centerTitle: false,
      ),
      body: FutureBuilder<List<SignalHistoryItem>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildEmptyState(
              '\uD788\uC2A4\uD1A0\uB9AC\uB97C \uBD88\uB7EC\uC624\uC9C0 \uBABB\uD588\uC2B5\uB2C8\uB2E4.\n${snapshot.error}',
            );
          }

          final items = snapshot.data ?? <SignalHistoryItem>[];

          if (items.isEmpty) {
            return _buildEmptyState(
              '\uC544\uC9C1 \uC0C1\uD0DC \uBCC0\uD654 \uD788\uC2A4\uD1A0\uB9AC\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.',
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) return _buildSummaryCard(items);
                return _buildHistoryCard(items[index - 1]);
              },
            ),
          );
        },
      ),
    );
  }
}
