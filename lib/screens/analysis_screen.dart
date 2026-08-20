import 'package:flutter/material.dart';

import '../models/analysis_response.dart';
import '../services/analysis_api_service.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final TextEditingController _tickerController =
      TextEditingController(text: '071050');
  final TextEditingController _stockNameController =
      TextEditingController(text: '\uD55C\uAD6D\uAE08\uC735\uC9C0\uC8FC');

  AnalysisResponse? _result;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _tickerController.dispose();
    _stockNameController.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await AnalysisApiService.runOneAnalysis(
        ticker: _tickerController.text.trim(),
        stockName: _stockNameController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _result = result;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _result = null;
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
    if (status.contains('RISK')) return const Color(0xFF2563EB);
    if (status.contains('ATTACK')) return const Color(0xFFDC2626);
    if (status.contains('WATCH')) return const Color(0xFFD97706);
    return const Color(0xFF64748B);
  }

  String _statusLabel(String status) {
    if (status.contains('ATTACK')) return '\uACF5\uACA9';
    if (status.contains('WATCH')) return '\uAD00\uCC30';
    if (status.contains('RISK')) return '\uC704\uD5D8';
    return '\uB300\uAE30';
  }

  Widget _buildInputCard() {
    return Container(
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
          Text(
            '\uC218\uB3D9 \uC885\uBAA9 \uBD84\uC11D',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\uC885\uBAA9 \uCF54\uB4DC\uC640 \uC885\uBAA9\uBA85\uC744 \uC785\uB825\uD574 SignalFlow \uBD84\uC11D\uC744 \uC2E4\uD589\uD569\uB2C8\uB2E4.',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tickerController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: '\uC885\uBAA9 \uCF54\uB4DC',
              prefixIcon: const Icon(Icons.tag_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stockNameController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!_isLoading) _runAnalysis();
            },
            decoration: InputDecoration(
              labelText: '\uC885\uBAA9\uBA85',
              prefixIcon: const Icon(Icons.business_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _runAnalysis,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.analytics_rounded),
              label: Text(
                _isLoading
                    ? '\uBD84\uC11D \uC911'
                    : '\uBD84\uC11D \uC2E4\uD589',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletList(List<String> items) {
    if (items.isEmpty) {
      return _buildEmptyText(
          '\uD45C\uC2DC\uD560 \uD56D\uBAA9\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.');
    }

    return Column(
      children: items.asMap().entries.map((entry) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.key + 1}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.value,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyText(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildResultHero(AnalysisResponse result) {
    final status = result.finalStatus ?? result.status;
    final statusColor = _statusColor(status);
    final score = result.finalScore ?? result.statusScore;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(
              Icons.show_chart_rounded,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.stockName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.ticker,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _statusLabel(status),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$score',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(AnalysisResponse result) {
    final status = result.finalStatus ?? result.status;
    final statusColor = _statusColor(status);

    return Column(
      children: [
        _buildResultHero(result),
        _buildInfoCard(
          title: '\uAE30\uBCF8 \uC815\uBCF4',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('\uC885\uBAA9\uBA85', result.stockName),
              _buildInfoRow('\uC885\uBAA9\uCF54\uB4DC', result.ticker),
              _buildInfoRow('\uAE30\uC900\uC77C', result.asofDate),
              _buildInfoRow('\uC885\uAC00', result.close.toStringAsFixed(0)),
            ],
          ),
        ),
        _buildInfoCard(
          title: '\uC0C1\uD0DC \uC694\uC57D',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                '\uAE30\uBCF8 \uC0C1\uD0DC',
                '${_statusLabel(result.status)} (${result.statusLabelKo})',
                valueColor: statusColor,
              ),
              _buildInfoRow(
                  '\uAE30\uBCF8 \uC810\uC218', '${result.statusScore}'),
              _buildInfoRow(
                '\uCD5C\uC885 \uC0C1\uD0DC',
                _statusLabel(status),
                valueColor: statusColor,
              ),
              _buildInfoRow(
                '\uCD5C\uC885 \uC810\uC218',
                '${result.finalScore ?? result.statusScore}',
                valueColor: statusColor,
              ),
              const SizedBox(height: 6),
              _buildInfoRow('\uC694\uC57D', result.summary),
              _buildInfoRow('\uAC00\uC774\uB4DC', result.actionGuide),
              if (result.etfReason != null)
                _buildInfoRow('ETF', result.etfReason!),
            ],
          ),
        ),
        _buildInfoCard(
          title: '\uD310\uB2E8 \uADFC\uAC70',
          child: _buildBulletList(result.reasons),
        ),
        _buildInfoCard(
          title: '\uC704\uD5D8 \uC694\uC18C',
          child: _buildBulletList(result.riskFlags),
        ),
        _buildInfoCard(
          title: 'ETF \uCD94\uCC9C \uACB0\uACFC',
          child: result.etfRecommendations.isEmpty
              ? _buildEmptyText(
                  'ETF \uCD94\uCC9C \uACB0\uACFC\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.')
              : Column(
                  children: result.etfRecommendations.map((etf) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              const Color(0xFF2563EB).withValues(alpha: 0.18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            etf.etfCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            '\uC0C1\uAD00',
                            etf.correlation.toStringAsFixed(3),
                          ),
                          _buildInfoRow(
                            '\uC0C1\uC2B9',
                            '${(etf.upProbability * 100).toStringAsFixed(1)}%',
                          ),
                          _buildInfoRow(
                            '\uD558\uB77D',
                            '${(etf.downProbability * 100).toStringAsFixed(1)}%',
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        _buildInfoCard(
          title: '\uC54C\uB9BC',
          child: result.alerts.isEmpty
              ? _buildEmptyText(
                  '\uBC1C\uC0DD\uD55C \uC54C\uB9BC\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.')
              : Column(
                  children: result.alerts.map((alert) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.subject,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(alert.body),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        _buildInfoCard(
          title: '\uC6D0\uBCF8 \uBA54\uC2DC\uC9C0',
          child: Text(
            result.message,
            style: const TextStyle(height: 1.45),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDC2626)),
      ),
      child: Text(
        _error!,
        style: const TextStyle(
          color: Color(0xFFDC2626),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildIdleState() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.manage_search_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(
              '\uC885\uBAA9\uC744 \uC785\uB825\uD574 \uBD84\uC11D\uD574\uBCF4\uC138\uC694',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\uC885\uBAA9 \uCF54\uB4DC\uC640 \uC885\uBAA9\uBA85\uC744 \uC785\uB825\uD55C \uB4A4 \uBD84\uC11D\uC744 \uC2E4\uD589\uD558\uC138\uC694.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('\uC8FC\uC2DD \uBD84\uC11D'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInputCard(),
            const SizedBox(height: 16),
            if (_error != null) _buildErrorCard(),
            if (_result == null)
              _buildIdleState()
            else
              _buildResultView(_result!),
          ],
        ),
      ),
    );
  }
}
