# File: app/api/routes_search.py (종목 검색 API)
# [Added by ChatGPT | 2026-04-02 11:20 KST]
# 삽입 위치: 새 파일 생성

from __future__ import annotations

from fastapi import APIRouter, Query

from app.data.stock_master import STOCK_MASTER

router = APIRouter(prefix="/search", tags=["search"])


@router.get("/stocks")
def search_stocks(
    keyword: str = Query(..., min_length=1, description="종목명 또는 종목코드 검색어"),
    limit: int = Query(10, ge=1, le=20),
):
    normalized = keyword.strip().lower()

    results = [
        item
        for item in STOCK_MASTER
        if normalized in item["ticker"].lower() or normalized in item["stock_name"].lower()
    ]

    return {
        "keyword": keyword,
        "count": len(results[:limit]),
        "items": results[:limit],
    }
