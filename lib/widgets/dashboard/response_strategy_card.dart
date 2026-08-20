// File: response_strategy_card.dart (오늘의 대응 전략 카드)
// [Added by Claude | 2026-08-10 KST]
// 홈 화면의 기존 "오늘의 추천 종목" 영역을 대체하는 "오늘의 대응 전략" 카드.
// 공격 후보 / 회복 후보 / 위험 종목 탭으로 구분해서 보여주고,
// 탭당 홈에서는 최대 3개까지만 노출하며 나머지는 "더보기"로 이동한다.

import 'package:flutter/material.dart';

import '../../models/response_strategy.dart';
import '../../screens/response_strategy_list_page.dart';

typedef ResponseStrategyTapCallback = Future<void> Function({
  required String ticker,
  required String stockName,
});

class _StrategyTabInfo {
  const _StrategyTabInfo({
    required this.type,
    required this.label,
    required this.color,
    required this.emptyMessage,
  });

  final String type;
  final String label;
  final Color color;
  final String emptyMessage;
}

const List<_StrategyTabInfo> _kStrategyTabs = [
  _StrategyTabInfo(
    type: 'ATTACK',
    label: '공격 후보',
    // 기존 공격 상태 색상(빨강 계열) 재사용
    color: Color(0xFFEF4444),
    emptyMessage: '현재 공격 조건을 충족한 종목이 없습니다. 기다리는 것도 전략입니다.',
  ),
  _StrategyTabInfo(
    type: 'RECOVERY',
    label: '회복 후보',
    // 노랑 계열(기존 WATCH 상태 색상 재사용)
    color: Color(0xFFF59E0B),
    emptyMessage: '아직 뚜렷한 회복 움직임이 확인되지 않았습니다.',
  ),
  _StrategyTabInfo(
    type: 'RISK',
    label: '위험 종목',
    // 파랑 계열(기존 RISK 상태 색상 재사용)
    color: Color(0xFF3B82F6),
    emptyMessage: '현재 주요 분석 종목에서 강한 위험 신호가 없습니다.',
  ),
];

const int _kHomeVisibleLimit = 3;

class ResponseStrategyCard extends StatefulWidget {
  const ResponseStrategyCard({
    super.key,
    required this.strategy,
    required this.isLoading,
    required this.hasError,
    required this.savedTickers,
    required this.onItemTap,
    required this.onSaveTap,
  });

  final ResponseStrategy? strategy;
  final bool isLoading;
  final bool hasError;
  final List<String> savedTickers;
  final ResponseStrategyTapCallback onItemTap;
  final ResponseStrategyTapCallback onSaveTap;

  @override
  State<ResponseStrategyCard> createState() => _ResponseStrategyCardState();
}

class _ResponseStrategyCardState extends State<ResponseStrategyCard> {
  int _selectedTabIndex = 0;

  List<ResponseStrategyItem> _itemsForType(String type) {
    final strategy = widget.strategy;

    if (strategy == null) {
      return const <ResponseStrategyItem>[];
    }

    switch (type) {
      case 'ATTACK':
        return strategy.attackCandidates;
      case 'RECOVERY':
        return strategy.recoveryCandidates;
      case 'RISK':
      default:
        return strategy.riskStocks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedTab = _kStrategyTabs[_selectedTabIndex];
    final items = _itemsForType(selectedTab.type);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : theme.dividerColor.withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '오늘의 대응 전략',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '현재 시장에서 공격·회복·위험 신호를 구분해 보여드립니다.',
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 14),
            _buildTabRow(),
            const SizedBox(height: 14),
            if (widget.isLoading && widget.strategy == null)
              _buildStatusMessage('전략 분석 중입니다...')
            else if (widget.hasError && widget.strategy == null)
              _buildStatusMessage('전략 데이터를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.')
            else if (items.isEmpty)
              _buildStatusMessage(selectedTab.emptyMessage)
            else
              _buildItemList(items, selectedTab),
          ],
        ),
      ),
    );
  }

  Widget _buildTabRow() {
    return Row(
      children: List.generate(_kStrategyTabs.length, (index) {
        final tab = _kStrategyTabs[index];
        final isSelected = index == _selectedTabIndex;
        final count = _itemsForType(tab.type).length;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == _kStrategyTabs.length - 1 ? 0 : 8,
            ),
            child: Material(
              color: isSelected
                  ? tab.color.withValues(alpha: 0.14)
                  : Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? tab.color.withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        tab.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? tab.color
                              : Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count개',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? tab.color
                              : Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatusMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildItemList(
    List<ResponseStrategyItem> items,
    _StrategyTabInfo tab,
  ) {
    final visibleItems = items.take(_kHomeVisibleLimit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...visibleItems.map((item) {
          final isSaved = widget.savedTickers.contains(item.ticker);

          return _ResponseStrategyTile(
            item: item,
            color: tab.color,
            isSaved: isSaved,
            onTap: () => widget.onItemTap(
              ticker: item.ticker,
              stockName: item.stockName,
            ),
            onSaveTap: isSaved
                ? null
                : () => widget.onSaveTap(
                      ticker: item.ticker,
                      stockName: item.stockName,
                    ),
          );
        }),
        if (items.length > _kHomeVisibleLimit)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResponseStrategyListPage(
                      title: tab.label,
                      accentColor: tab.color,
                      emptyMessage: tab.emptyMessage,
                      items: items,
                      savedTickers: widget.savedTickers,
                      onItemTap: widget.onItemTap,
                      onSaveTap: widget.onSaveTap,
                    ),
                  ),
                );
              },
              child: const Text('더보기'),
            ),
          ),
      ],
    );
  }
}

class _ResponseStrategyTile extends StatelessWidget {
  const _ResponseStrategyTile({
    required this.item,
    required this.color,
    required this.isSaved,
    required this.onTap,
    required this.onSaveTap,
  });

  final ResponseStrategyItem item;
  final Color color;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback? onSaveTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.stockName} (${item.ticker})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: isSaved ? '저장됨' : '관심종목 저장',
                    icon: Icon(
                      isSaved
                          ? Icons.check_circle_rounded
                          : Icons.star_border_rounded,
                      color: isSaved
                          ? const Color(0xFF64748B)
                          : const Color(0xFFF59E0B),
                    ),
                    onPressed: onSaveTap,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.strategyReason ?? item.finalStatus,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${item.finalScore}점',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
