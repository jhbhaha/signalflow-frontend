// File: attack_page.dart (공격 후보 전용 화면)
// [Modified by ChatGPT | 2026-05-08 19:00 KST]
// SignalFlow 공격 후보 페이지 고급 UI 적용 (Apply SignalFlow advanced attack candidate UI)
// Insert Location: G:\stockmarket_frontend\lib\screens\attack_page.dart 전체 교체

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

  List<AnalysisResponse> _attackItems = [];
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
          .where((e) => (e.finalStatus ?? '').startsWith('ATTACK'))
          .toList();

      attack.sort((a, b) => (b.finalScore ?? 0).compareTo(a.finalScore ?? 0));

      if (!mounted) return;

      setState(() {
        _attackItems = attack;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = '공격 후보를 불러오지 못했습니다. $e';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    if (status.startsWith('ATTACK')) return const Color(0xFF22C55E);
    if (status.startsWith('WATCH')) return const Color(0xFFF59E0B);
    if (status == 'RISK') return const Color(0xFFEF4444);
    return const Color(0xFF64748B);
  }

  Color _rankColor(int index) {
    if (index == 0) return const Color(0xFFF59E0B);
    if (index == 1) return const Color(0xFF94A3B8);
    if (index == 2) return const Color(0xFFB45309);
    return const Color(0xFF3B82F6);
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withValues(alpha: 0.10),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flash_on,
              color: Color(0xFF22C55E),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              '공격 후보는 관심종목 중 ATTACK 상태로 분석된 종목만 표시됩니다.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGauge({
    required int score,
    required Color color,
  }) {
    final double value = (score.clamp(0, 100)) / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Signal Strength',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // [Added by ChatGPT | 2026-05-13 10:15 KST]
// 작은 ETF/상태 Badge 위젯
// (Small ETF/status badge widget)
  Widget _buildMiniBadge({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAttackCard(AnalysisResponse item, int index) {
    final String status = item.finalStatus ?? 'WAIT';
    final int score = item.finalScore ?? 0;
    final Color statusColor = _statusColor(status);
    final Color rankColor = _rankColor(index);

    return TweenAnimationBuilder<double>(
      // [Added by ChatGPT | 2026-05-13 10:35 KST]
      // 공격 후보 카드 등장 애니메이션 추가
      // (Add attack candidate card entrance animation)
      tween: Tween<double>(
        begin: 0.96,
        end: 1.0,
      ),
      duration: Duration(
        milliseconds: 420 + (index * 80),
      ),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.35),
          ),
          gradient: LinearGradient(
            colors: [
              statusColor.withValues(alpha: 0.14),
              const Color(0xFF0F172A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.18),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          // [2026-05-27 14:10 KST]
          // 공격 후보 클릭 시 ticker/stockName만 전달
          // (Pass only ticker and stockName when opening analysis result)
          onTap: () {
            Navigator.pushNamed(
              context,
              '/analysis-result',
              arguments: {
                'ticker': item.ticker,
                'stock_name': item.stockName,
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: rankColor.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: rankColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '#${index + 1}',
                          style: TextStyle(
                            color: rankColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${item.stockName} (${item.ticker})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildGauge(
                  score: score,
                  color: statusColor,
                ),

                // [Added by ChatGPT | 2026-05-13 10:15 KST]
                // 공격 후보 ETF 흐름 Badge 추가
                // (Add ETF flow badges to attack candidate card)
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
                          color: const Color(0xFF3B82F6),
                        ),
                      if (item.etfCorrelation != null)
                        _buildMiniBadge(
                          label: '상관 ${item.etfCorrelation!.toStringAsFixed(2)}',
                          color: const Color(0xFF22C55E),
                        ),
                      if (item.etfUpProb != null)
                        _buildMiniBadge(
                          label:
                          '동반상승 ${(item.etfUpProb! * 100).toStringAsFixed(0)}%',
                          color: const Color(0xFFF59E0B),
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        '관심종목 기반',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$score점',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.white70,
          height: 1.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('공격 후보'),
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
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _buildEmptyCard(_error!)
            else if (_attackItems.isEmpty)
                _buildEmptyCard('현재 공격 후보가 없습니다.\n관심종목이 ATTACK 상태가 되면 이곳에 표시됩니다.')
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