// File: lib/widgets/analysis_result_card.dart (분석 결과 카드 위젯)
// Last Modified: 2026-04-15 22:25 KST (작성자: ChatGPT)
// Insert Location: G:\stockmarket_frontend\lib\widgets\analysis_result_card.dart 전체 교체

import 'package:flutter/material.dart';

import '../models/analysis_response.dart';

// 한국 주식 시장 기준 상태 색상 적용
// 상승=빨강 / 위험=파랑
Color _getStatusColor(String? status) {
  if (status == null) {
    return const Color(0xFF64748B);
  }

  if (status.startsWith('ATTACK')) {
    return const Color(0xFFEF4444);
  }

  if (status.startsWith('WATCH')) {
    return const Color(0xFFF59E0B);
  }

  if (status == 'WAIT') {
    return const Color(0xFF64748B);
  }

  if (status == 'RISK') {
    return const Color(0xFF3B82F6);
  }

  return const Color(0xFF64748B);
}

class AnalysisResultCard extends StatefulWidget {
  const AnalysisResultCard({
    super.key,
    required this.result,
  });

  final AnalysisResponse result;

  @override
  State<AnalysisResultCard> createState() => _AnalysisResultCardState();
}

class _AnalysisResultCardState extends State<AnalysisResultCard> {
  // 카드 눌림 애니메이션 상태값
  bool _isPressed = false;
  // 카드 펼침 상태
  bool _isExpanded = false;

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }

    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AnalysisResponse result = widget.result;

    return AnimatedScale(
      scale: _isPressed ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: GestureDetector(
        // 눌림 + 펼침 자연스럽게 통합
        onTapDown: (_) => _setPressed(true),
        // 카드 전체 클릭 시 눌림 효과 후 상세 펼침/접힘 처리
        onTapUp: (_) {
          _setPressed(false);
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        onTapCancel: () => _setPressed(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: _isPressed ? 1 : 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // [Added by ChatGPT | 2026-04-15 21:50 KST] 상단 상태 컬러 바
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: _getStatusColor(result.finalStatus ?? result.status),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '${result.stockName} (${result.ticker})',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 6),
                                // [Modified by ChatGPT | 2026-04-15 22:25 KST] 상태 텍스트 색상 강조 유지
                                Text(
                                  '[상태] ${result.statusLabelKo}',
                                  style: TextStyle(
                                    color: _getStatusColor(
                                      result.finalStatus ?? result.status,
                                    ),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (result.shouldNotify)
                            Chip(
                              label: const Text('알림'),
                              avatar: const Icon(
                                Icons.notifications_active_outlined,
                                size: 18,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          // [Modified by ChatGPT | 2026-04-24 21:55 KST] 카드 전체 클릭 방식으로 변경하여 아이콘은 상태 표시만 담당
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(
                              Icons.expand_more,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // [Modified by ChatGPT | 2026-04-24 18:30 KST] 한눈에 판단 가능한 압축 요약 UI로 변경
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: <Widget>[
                          _buildCompactChip(
                            label: '최종',
                            value: result.finalStatus ?? result.status,
                            color: _getStatusColor(result.finalStatus ?? result.status),
                          ),
                          _buildCompactChip(
                            label: '점수',
                            value: '${result.finalScore ?? result.statusScore}',
                            color: _getStatusColor(result.finalStatus ?? result.status),
                          ),
                          // [Fixed by ChatGPT | 2026-04-24 19:20 KST] ETF Chip 구조 오류 수정
                          _buildCompactChip(
                            label: 'ETF',
                            value: result.etfRecommendations.isNotEmpty
                                ? result.etfRecommendations.first.etfName
                                : '없음',
                            color: _getStatusColor(result.finalStatus ?? result.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        result.summary,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        result.actionGuide,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // [Modified by ChatGPT | 2026-04-24 19:40 KST] 펼침 UI 적용
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 200),
                        crossFadeState: _isExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: const SizedBox.shrink(),
                        secondChild: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildListSection(context, '근거', result.reasons),
                            _buildListSection(context, '위험', result.riskFlags),
                            if (result.alerts.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 16),
                              Text('알림 메시지', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              ...result.alerts.map((alert) => Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(alert.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text(alert.body),
                                  ],
                                ),
                              )),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // 핵심 판단 정보를 Chip 형태로 압축 표시
  Widget _buildCompactChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Chip(
      label: Text('$label $value'),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      backgroundColor: color.withValues(alpha: 0.08),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildListSection(
      BuildContext context,
      String title,
      List<String> items,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          if (items.isEmpty)
            const Text('-')
          else
            ...items.map(
                  (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('- $item'),
              ),
            ),
        ],
      ),
    );
  }
}