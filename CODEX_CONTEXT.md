# SignalFlow - Codex Context

## Project Overview

SignalFlow is a Korean stock market analysis application.

Goal:

* Analyze KOSPI/KOSDAQ stocks
* Provide attack/watch/wait signals
* ETF sector flow analysis
* AI-based stock analysis
* DART financial statement analysis
* User watchlist management
* Notification system
* AdMob monetization

Current stage:

* Closed/Internal testing
* Preparing production release
* Focus on stability and user retention

---

# Technology Stack

## Frontend

* Flutter
* Material 3
* Provider
* SharedPreferences
* Google Mobile Ads

Repository Structure

lib/

* models/
* services/
* screens/
* widgets/

Main Pages

* DashboardPage
* SearchPage
* WatchlistPage
* AttackPage
* NotificationPage
* StockDetailPage
* AnalysisResultPage
* SignalHistoryPage

## Backend

* FastAPI
* SQLAlchemy
* SQLite
* APScheduler
* FinanceDataReader
* Pandas
* Render Deployment

Repository Structure

app/

* server.py
* routes/
* services/
* models/
* database/

---

# Current Signal System

Status Types

1. ATTACK_STRONG
2. ATTACK_NORMAL
3. WATCH_STRONG
4. WATCH_NORMAL
5. WAIT

Signal calculations include:

* Moving averages
* Momentum
* ETF sector trend
* Risk score
* AI score

ETF influence is already integrated.

---

# Completed Features

## Dashboard

Completed

Includes:

* Market Status
* Risk Gauge
* ETF Sector Flow
* Watchlist Summary
* Recommended Stocks
* Attack Candidates

## Search

Completed

* Korean stock search
* Watchlist registration

## Watchlist

Completed

* Add/Delete
* Refresh analysis

## Attack Candidates

Completed

* Signal filtering

## Notification Center

Completed

* Read/Unread handling
* Mark all as read

## Signal History

Completed

* Signal change history

## AI Analysis

Completed

Includes:

* AI Score
* AI Trend
* Price Chart
* Status Summary

## DART Financial Analysis

Completed Backend

API:

/api/company-analysis/{stock_code}

Provides:

* Revenue
* Operating Income
* Net Income
* Assets
* Liabilities
* Equity
* Debt Ratio
* ROE
* Operating Margin
* Net Margin
* Financial Grade
* Financial Score

---

# Current Deployment

Backend

Render

Production API:

Check current Render deployment before changing API URLs.

Frontend

Google Play Internal Testing

Version pattern:

Production:

1.0.xx

Internal:

1.0.xx_inner

---

# AdMob Strategy

Current decision:

Dashboard

Place advertisement:

ETF Sector Flow
↓

Advertisement

↓

Today's Recommended Stocks

Analysis Page

Place advertisement:

Status Summary

↓

Advertisement

↓

AI Analysis

Ads must not interrupt core analysis flow.

---

# Coding Rules

Important

When modifying code:

1. Keep existing architecture.

2. Do not rewrite entire screens unless necessary.

3. Prefer minimal changes.

4. Preserve API compatibility.

5. Preserve existing theme support.

6. Preserve dark/light mode support.

7. Avoid breaking watchlist functionality.

8. Avoid breaking DART analysis functionality.

9. Avoid changing backend endpoint contracts unless required.

---

# Current Priority

Priority 1

Production Stability

* Fix remaining UI bugs
* Reduce loading issues
* Improve error handling

Priority 2

DART Analysis UI Improvement

* Better layout
* Better readability
* Financial score visualization

Priority 3

User Retention

* Improve dashboard usefulness
* Improve signal explanations

Priority 4

Monetization

* AdMob integration
* Ad placement optimization

---

# Things To Avoid

Do NOT:

* Rewrite database structure
* Rewrite signal engine
* Replace FastAPI
* Replace Flutter architecture
* Remove ETF integration
* Remove AI analysis
* Remove DART analysis

Focus on incremental improvements.

---

# Owner Notes

Project owner prefers:

* Practical solutions
* Minimal refactoring
* Stable releases
* Clear code comments
* Production-first decisions

When providing code:

Always specify:

* File name
* Exact insertion location
* Existing code
* New code
* Final result

Include modification timestamp comments.
