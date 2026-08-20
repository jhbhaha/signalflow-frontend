import 'package:flutter/material.dart';

import '../models/analysis_response.dart';
import '../services/api_service.dart';

class AttackPage extends StatefulWidget {
  const AttackPage({super.key});

  @override
  State<AttackPage> createState() => _AttackPageState();
}

class _AttackPageState extends State<AttackPage> {
  final ApiService _apiService = ApiService();

  List<AnalysisResponse> _attackItems = <AnalysisResponse>[];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAttackItems();
  }

  Future<void> _loadAttackItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _apiService.fetchWatchlistAnalysis();
      final attack = results
          .where((item) => (item.finalStatus ?? '').startsWith('ATTACK'))
          .toList()
        ..sort((a, b) => (b.finalScore ?? 0).compareTo(a.finalScore ?? 0));

      if (!mounted) return;
      setState(() {
        _attackItems = attack;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error =
            '\uACF5\uACA9 \uD6C4\uBCF4\uB97C \uBD88\uB7EC\uC624\uC9C0 \uBABB\uD588\uC2B5\uB2C8\uB2E4. $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _statusColor(String status) {
    if (status.startsWith('ATTACK')) return const Color(0xFFDC2626);
    if (status.startsWith('WATCH')) return const Color(0xFFD97706);
    if (status == 'RISK') return const Color(0xFF2563EB);
    return const Color(0xFF64748B);
  }

  String _statusLabel(String status) {
    if (status.startsWith('ATTACK')) return '\uACF5\uACA9';
    if (status.startsWith('WATCH')) return '\uAD00\uCC30';
    if (status == 'RISK') return '\uC704\uD5D8';
    return '\uB300\uAE30';
  }

  double _averageScore() {
    if (_attackItems.isEmpty) return 0;
    final total = _attackItems.fold<int>(
      0,
      (sum, item) => sum + (item.finalScore ?? 0),
    );
    return total / _attackItems.length;
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\uACF5\uACA9 \uD6C4\uBCF4',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '\uAD00\uC2EC\uC885\uBAA9 \uC911 ATTACK \uC0C1\uD0DC\uB85C \uBD84\uC11D\uB41C \uC885\uBAA9\uB9CC \uD45C\uC2DC\uD569\uB2C8\uB2E4.',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '\uC0C8\uB85C\uACE0\uCE68',
                onPressed: _isLoading ? null : _loadAttackItems,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetricChip(
                label: '\uD6C4\uBCF4',
                value: '${_attackItems.length}',
                color: const Color(0xFFDC2626),
              ),
              _buildMetricChip(
                label: '\uD3C9\uADE0',
                value: _averageScore().toStringAsFixed(0),
                color: const Color(0xFF059669),
              ),
              if (_attackItems.isNotEmpty)
                _buildMetricChip(
                  label: 'TOP',
                  value: '${_attackItems.first.finalScore ?? 0}',
                  color: const Color(0xFF2563EB),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildGauge({
    required int score,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Signal Strength',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '$score\uC810',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: score.clamp(0, 100) / 100,
            minHeight: 9,
            backgroundColor:
                Theme.of(context).dividerColor.withValues(alpha: 0.14),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBadge({
    required String label,
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
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildAttackCard(AnalysisResponse item, int index) {
    final status = item.finalStatus ?? 'WAIT';
    final score = item.finalScore ?? 0;
    final statusColor = _statusColor(status);

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
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
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: statusColor.withValues(alpha: 0.26)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildMiniBadge(
                    label: _statusLabel(status),
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildGauge(score: score, color: statusColor),
              if ((item.etfReason ?? '').isNotEmpty ||
                  item.etfCorrelation != null ||
                  item.etfUpProb != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if ((item.etfReason ?? '').isNotEmpty)
                      _buildMiniBadge(
                        label: item.etfReason!,
                        color: const Color(0xFF2563EB),
                      ),
                    if (item.etfCorrelation != null)
                      _buildMiniBadge(
                        label:
                            '\uC0C1\uAD00 ${item.etfCorrelation!.toStringAsFixed(2)}',
                        color: const Color(0xFF059669),
                      ),
                    if (item.etfUpProb != null)
                      _buildMiniBadge(
                        label:
                            '\uB3D9\uBC18\uC0C1\uC2B9 ${(item.etfUpProb! * 100).toStringAsFixed(0)}%',
                        color: const Color(0xFFD97706),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.20),
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color,
          fontSize: 13,
          height: 1.45,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('\uACF5\uACA9 \uD6C4\uBCF4'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAttackItems,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _buildEmptyCard(_error!)
            else if (_attackItems.isEmpty)
              _buildEmptyCard(
                '\uD604\uC7AC \uACF5\uACA9 \uD6C4\uBCF4\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.\n\uAD00\uC2EC\uC885\uBAA9\uC774 ATTACK \uC0C1\uD0DC\uAC00 \uB418\uBA74 \uC774\uACF3\uC5D0 \uD45C\uC2DC\uB429\uB2C8\uB2E4.',
              )
            else
              ..._attackItems.asMap().entries.map(
                    (entry) => _buildAttackCard(entry.value, entry.key),
                  ),
          ],
        ),
      ),
    );
  }
}
