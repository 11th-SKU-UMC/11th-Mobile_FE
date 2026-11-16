# MovieLog · Week07

회원가입과 영화 평점 CRUD를 MovieLog v6에 연결한 Flutter 앱입니다. 필수 미션과 챌린지(회원가입 이탈 방지, 평점 다중 삭제)를 구현했습니다.

## 실행

검증 환경: Flutter 3.47.5 / Dart 3.13.4.

```powershell
cd week07/movielog
Copy-Item .env.example .env
# .env의 TMDB_ACCESS_TOKEN을 본인 TMDB Read Access Token으로 설정
flutter pub get
flutter run -d chrome --no-pub
```

MovieLog는 `https://workbook.devnoco.com`을 사용합니다. TMDB와 별도 Dio 인스턴스를 사용하며, MovieLog 요청에는 TMDB Authorization 헤더를 추가하지 않습니다.

이 Windows 환경에서는 의존성 다운로드 후 데스크톱 플러그인 심볼릭 링크 권한 오류가 발생했습니다. 생성된 패키지 설정을 사용해 분석·테스트·웹 빌드는 `--no-pub`로 검증했습니다.

## 사용 흐름

1. 시작 화면에서 회원가입: 닉네임·이메일 중복 확인 후 가입합니다.
2. 가입 응답의 memberId를 메모리 세션에 보관하고 영화 목록으로 이동합니다.
3. 영화 상세의 '평점 남기기'에서 정수 별점과 선택 코멘트를 저장합니다.
4. 마이페이지 → '내가 등록한 평점'에서 수정·삭제합니다.
5. '편집'을 누르면 다중 선택 후 삭제할 수 있습니다.

세션은 인증 기능이 아니며 앱을 재시작하면 사라집니다. 회원가입 전에는 평점 등록을 막고 회원가입으로 안내합니다. 수정은 마이페이지에서 진행합니다.

## 검증

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter build web --no-pub
# UI 테스트에서 화면 증빙도 다시 생성
flutter test --no-pub --dart-define=UPDATE_EVIDENCE=true
```

실제 API를 다시 검증하려면 다음 명령을 별도로 실행합니다. 실행할 때마다 학습용 계정 2개가 만들어지며, 생성한 평점은 검증 후 삭제합니다. 비밀번호는 실행 중 메모리에서만 생성합니다. 일반 테스트에서는 실제 API에 요청하지 않습니다.

```powershell
dart run tool/verify_live_api.dart
```

체크리스트, 실제 서버 응답, 화면 증빙과 미검증 항목은 [미션 기록](docs/MISSION_REPORT.md)에 있습니다.
