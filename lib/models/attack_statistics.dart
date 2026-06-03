// File: attack_statistics.dart (공격 성공률 통계 모델)
// Last Modified: 2026-05-12 16:35 KST (작성자: ChatGPT)
// Insert Location: G:\stockmarket_frontend\lib\models\attack_statistics.dart 새 파일 생성

class AttackStatistics {
  final String ticker;
  final int attackCount;
  final int successCount;
  final double successRate;
  final double avgReturn;

  const AttackStatistics({
    required this.ticker,
    required this.attackCount,
    required this.successCount,
    required this.successRate,
    required this.avgReturn,
  });

  factory AttackStatistics.fromJson(Map<String, dynamic> json) {
    return AttackStatistics(
      ticker: json['ticker']?.toString() ?? '',
      attackCount: json['attack_count'] ?? 0,
      successCount: json['success_count'] ?? 0,
      successRate: (json['success_rate'] ?? 0).toDouble(),
      avgReturn: (json['avg_return'] ?? 0).toDouble(),
    );
  }
}