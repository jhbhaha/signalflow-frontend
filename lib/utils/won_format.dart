// File: lib/utils/won_format.dart (원화 가격 표시 유틸)
// [Added by Claude | 2026-08-27 KST]
// 모든 종목 카드/리스트/타일에서 "최근 종가"를 동일한 형식으로 표시하기 위한 공용 함수.
// - 실시간 시세가 아니라 "가장 최근 거래일 close" 값을 그대로 표시한다.
// - 새 패키지(intl 등)는 추가하지 않고 순수 문자열 처리로 3자리 콤마를 만든다.

/// 종목 가격(close)을 `84,500원` 형태의 문자열로 변환한다.
///
/// - `84500` / `84500.0` 모두 `84,500원`으로 표시한다.
/// - 소수점 이하는 반올림한다(한국 주식 호가 단위 특성상 정수 표시).
/// - 값이 없거나(`null`) 0 이하이면 `null`을 반환한다.
///   호출부는 반환값이 `null`이면 가격 영역 자체를 숨겨야 한다(`-` 표시 금지).
String? formatWonPrice(num? value) {
  if (value == null) return null;

  final double doubleValue = value.toDouble();
  if (!doubleValue.isFinite || doubleValue <= 0) return null;

  final String digits = doubleValue.round().toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      );

  return '$digits원';
}
