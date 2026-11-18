# MovieLog · Week08

MovieLog v7 로그인과 보안 저장소를 연결한 Flutter 앱입니다. 앱을 열면 저장된 토큰으로 `GET /v7/members/me`를 호출해 세션을 확인합니다. 처음 로그인할 때는 토큰을 저장한 뒤 홈으로 이동하고, 메인 화면에서 내 정보를 불러옵니다.

## 실행

Flutter 3.47.5와 Dart 3.13.4에서 검증했습니다. 저장소 루트에서 아래 명령을 실행한 뒤 `.env`에 TMDB Read Access Token을 설정해 주세요.

```powershell
cd week08/movielog
Copy-Item .env.example .env
flutter pub get
flutter run
```

## 평점 API

| 동작 | v7 경로 | 성공 응답 |
| --- | --- | --- |
| 회원별 공개 조회 | `GET /v7/members/{memberId}/ratings` | 200, 평점 배열 |
| 등록 | `POST /v7/ratings` | 201, `result` 평점 객체 |
| 수정 | `PATCH /v7/ratings/{ratingId}` | 200, `result` 평점 객체 |
| 삭제 | `DELETE /v7/ratings/{ratingId}` | 200, `result: null` |

MovieLog JWT는 MovieLog의 내 정보 및 평점 쓰기 요청에 사용합니다. TMDB 영화 조회는 별도 클라이언트의 TMDB 토큰을 사용합니다. 평점의 `movieId`에 맞는 영화 제목과 포스터를 표시하며, 영화 정보가 없으면 `영화 #{movieId}`로 표시합니다.

v7에는 토큰으로 기존 내 평점 전체를 조회하는 경로가 없습니다. 마이페이지의 평점 목록은 이번 세션에서 등록한 평점만 표시합니다. 로그아웃과 앱 재시작 뒤에는 이 목록이 새로 시작합니다. 로그인과 내 정보 응답은 `memberId`를 제공하지 않습니다.

## 검증

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
```

- Android 16 Pixel 10 에뮬레이터에서 실제 로그인과 내 정보 조회, 강제 종료 후 세션 복원, 닉네임 변경, TMDB 영화에 연결된 평점 등록·수정·삭제, 로그아웃 후 강제 종료 및 재실행을 확인했습니다. iOS 기기 검증은 남아 있습니다.
- 실제 v7 서버에서 로그인 401, 무효 토큰 401, 평점 권한 부족 403, 닉네임·평점 중복 409, 삭제한 평점 404 및 공개 평점 배열을 확인했습니다.
- 회귀 테스트에서 일시적인 네트워크 장애 뒤 세션 재확인, 동시 만료 처리, 계정 변경 후 이전 응답 무시, 보호 경로 접근 차단을 확인했습니다.
- 만료 및 무효 토큰은 세션을 정리하고 로그인 화면에 안내를 한 번 표시합니다. 로그인 입력 오류, 직접 로그아웃, 평점 권한 부족과 중복, 닉네임 중복의 동작을 각각 다르게 처리합니다.
- 챌린지에서는 이메일 저장, 내 정보 로딩과 재시도, 가입일 표시, 프로필 수정 중 뒤로가기 확인을 구현했습니다. 일반 환경설정에는 선택한 이메일만 저장합니다.

[MovieLog v7 Swagger](https://workbook.devnoco.com/docs/v7)
