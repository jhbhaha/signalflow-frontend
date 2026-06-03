# File: app/data/stock_master.py (종목 검색 마스터 데이터)
# [Added by ChatGPT | 2026-04-02 11:20 KST]
# 삽입 위치: 새 파일 생성

from __future__ import annotations

from typing import List, Dict

# 실제 운영 전에는 DB 또는 KRX 전체 종목 마스터로 교체
STOCK_MASTER: List[Dict[str, str]] = [
    {"ticker": "005930", "stock_name": "삼성전자"},
    {"ticker": "000660", "stock_name": "SK하이닉스"},
    {"ticker": "035420", "stock_name": "NAVER"},
    {"ticker": "035720", "stock_name": "카카오"},
    {"ticker": "051910", "stock_name": "LG화학"},
    {"ticker": "005380", "stock_name": "현대차"},
    {"ticker": "012330", "stock_name": "현대모비스"},
    {"ticker": "068270", "stock_name": "셀트리온"},
    {"ticker": "207940", "stock_name": "삼성바이오로직스"},
    {"ticker": "323410", "stock_name": "카카오뱅크"},
    {"ticker": "071050", "stock_name": "한국금융지주"},
    {"ticker": "006400", "stock_name": "삼성SDI"},
    {"ticker": "034020", "stock_name": "두산에너빌리티"},
    {"ticker": "105560", "stock_name": "KB금융"},
    {"ticker": "055550", "stock_name": "신한지주"},
]
