# Flutter Stock Frontend

FastAPI 기반 주식 분석 서버와 연결되는 Flutter 앱입니다.

## 실행 방법

```bash
flutter pub get
flutter run
```

## 백엔드 주소 설정

`lib/services/api_service.dart` 파일에서 `baseUrl` 값을 수정하세요.

- Android Emulator: `http://10.0.2.2:8000`
- iOS Simulator / macOS / Windows / Chrome: `http://127.0.0.1:8000`
- 실기기: `http://PC의로컬IP:8000`

## 사용 API

- `GET /analysis/default`
- `GET /analysis/run-one`
- `GET /analysis/watchlist`
- `GET /analysis/watchlist/items`
- `POST /analysis/watchlist/items`
- `DELETE /analysis/watchlist/items/{ticker}`
