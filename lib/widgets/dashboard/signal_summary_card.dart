// File: signal_summary_card.dart (시그널 요약 카드)
// [Added by ChatGPT | 2026-05-22 13:25 KST]
// Insert Location: lib/widgets/dashboard/signal_summary_card.dart 새 파일 생성

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/dashboard_summary.dart';

class SignalSummaryCard extends StatelessWidget {
  const SignalSummaryCard({
    super.key,
    required this.summary,
  });

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return _buildSignalFlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '오늘의 시그널',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusBadge(
                label: 'WATCHLIST ${summary.watchlistCount}',
                color: const Color(0xFF3B82F6),
              ),
              _buildStatusBadge(
                label: 'ATTACK ${summary.attackCount}',
                color: const Color(0xFFEF4444),
              ),
              _buildStatusBadge(
                label: 'WATCH ${summary.watchCount}',
                color: const Color(0xFFF59E0B),
              ),
              _buildStatusBadge(
                label: 'RISK ${summary.riskCount}',
                color: const Color(0xFF3B82F6),
              ),
              _buildStatusBadge(
                label: 'WAIT ${summary.waitCount}',
                color: const Color(0xFF64748B),
              ),
              const SizedBox(height: 18),
              _buildStatusDonutChart(summary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignalFlowCard({
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _buildStatusBadge({
    required String label,
    required Color color,
  }) {
    final bool isAttackBadge = label.startsWith('ATTACK');

    return AnimatedScale(
      scale: isAttackBadge ? 1.03 : 1.0,
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isAttackBadge ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: color.withValues(alpha: isAttackBadge ? 0.75 : 0.55),
          ),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: isAttackBadge ? 0.28 : 0.22),
              color.withValues(alpha: isAttackBadge ? 0.12 : 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isAttackBadge ? 0.28 : 0.18),
              blurRadius: isAttackBadge ? 24 : 18,
              spreadRadius: isAttackBadge ? 3 : 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDonutChart(DashboardSummary summary) {
    final int attack = summary.attackCount;
    final int watch = summary.watchCount;
    final int risk = summary.riskCount;
    final int wait = summary.waitCount;
    final int total = attack + watch + risk + wait;

    return Row(
      children: [
        SizedBox(
          width: 110,
          height: 110,
          child: CustomPaint(
            painter: _StatusDonutPainter(
              attack: attack,
              watch: watch,
              risk: risk,
              wait: wait,
            ),
            child: Center(
              child: Text(
                total.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem('공격', attack, const Color(0xFFEF4444), total),
              const SizedBox(height: 8),
              _buildLegendItem('관찰', watch, const Color(0xFFF59E0B), total),
              const SizedBox(height: 8),
              _buildLegendItem('위험', risk, const Color(0xFF3B82F6), total),
              const SizedBox(height: 8),
              _buildLegendItem('대기', wait, const Color(0xFF64748B), total),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(
      String label,
      int count,
      Color color,
      int total,
      ) {
    final int percent = total == 0 ? 0 : ((count / total) * 100).round();

    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          '$percent%',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _StatusDonutPainter extends CustomPainter {
  _StatusDonutPainter({
    required this.attack,
    required this.watch,
    required this.risk,
    required this.wait,
  });

  final int attack;
  final int watch;
  final int risk;
  final int wait;

  @override
  void paint(Canvas canvas, Size size) {
    final int total = attack + watch + risk + wait;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 8, backgroundPaint);

    if (total == 0) {
      return;
    }

    final List<_DonutSegment> segments = [
      _DonutSegment(attack, const Color(0xFFEF4444)),
      _DonutSegment(watch, const Color(0xFFF59E0B)),
      _DonutSegment(risk, const Color(0xFF3B82F6)),
      _DonutSegment(wait, const Color(0xFF64748B)),
    ];

    double startAngle = -math.pi / 2;

    for (final segment in segments) {
      if (segment.value <= 0) continue;

      final double sweepAngle = (segment.value / total) * math.pi * 2;

      final Paint paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect.deflate(8),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _StatusDonutPainter oldDelegate) {
    return attack != oldDelegate.attack ||
        watch != oldDelegate.watch ||
        risk != oldDelegate.risk ||
        wait != oldDelegate.wait;
  }
}

class _DonutSegment {
  _DonutSegment(this.value, this.color);

  final int value;
  final Color color;
}