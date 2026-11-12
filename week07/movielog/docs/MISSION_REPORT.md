# 7주차 미션 수행 기록

검증일: 2026-11-12 (Asia/Seoul)

PR: [[Week07] 감자/이상훈 미션 제출 #45](https://github.com/11th-SKU-UMC/11th-Mobile_FE/pull/45) · Draft

사용자 포크의 `week07` → 원본 저장소의 `GAMJA`입니다. 선행 6주차 PR #42가 아직 열려 있어 이력에 포함됩니다. [7주차 변경만 비교](https://github.com/benhoon/11th-Mobile_FE/compare/week06...week07)

## 구현 범위

기존 `week06/movielog`를 기반으로 `week07/movielog`에 구현했습니다. 회원가입·등록은 `SignUpViewModel`·`MovieDetailViewModel`, 조회·수정·삭제는 `MyRatingsViewModel`이 담당합니다.

### Guided A · 회원가입

- [x] v6 닉네임·이메일 중복 확인, `SignUpService.signUp` 연결
- [x] `CommonResponse<T>`, `CreateMemberRequest`, `SignUpResult` 작성
- [x] 닉네임 2~12자·이메일 형식·비밀번호 형식 검증
- [x] 현재 입력값의 중복 확인 2개가 통과해야 가입 버튼 활성화
- [x] 입력 변경 시 이전 확인 결과·서버 제출 오류 초기화, 늦은 응답 무시
- [x] idle/submitting/success/error 상태, 중복 제출 방지
- [x] 201의 result.memberId 확인 → 메모리 세션 저장 → `/movies` 이동
- [x] 비밀번호 오류로 확인된 400만 입력칸에 표시, 다른 400·409는 Snackbar
- [x] 로컬 validator를 다시 실행해도 서버의 비밀번호 오류 유지

### Guided B · 상세 평점 등록

- [x] URL movieId와 `state.extra`의 DTO ID 확인, 상세 GET 및 직접 진입 지원
- [x] 선택한 `TmdbMovieDto.id`를 등록 body의 movieId로 전달
- [x] 별점을 선택해야 확인 활성화, 1~5 정수만 허용
- [x] 선택 코멘트 최대 500자, 등록 시 공백 코멘트 생략
- [x] Dialog 내부 서버 저장, 성공 후 true 반환 및 상세 화면 성공 Snackbar
- [x] 저장 실패 시 Dialog·별점·코멘트 유지, 서버 오류 표시·재시도 가능
- [x] 등록·수정 중 입력·중복 탭·뒤로가기·바깥 탭 차단

### Required · 마이페이지 수정·삭제

- [x] 가입 결과 memberId로 조회, 로딩·오류·빈 목록·성공 상태
- [x] root Navigator의 `/my/ratings`에 뒤로가기·중앙 제목, 하단 탭 숨김
- [x] 회원별 조회 결과에만 수정·삭제 버튼 표시
- [x] TMDB 제목·포스터를 movieId로 연결, TMDB 실패 시 평점·placeholder 유지
- [x] 수정 Dialog의 기존 별점·코멘트 초기값, 기존 ratingId로 PATCH
- [x] score 필수 전송, comment 유지·변경·null 삭제를 명시적으로 전송
- [x] 단일 삭제 확인 Dialog 유지, 취소 시 DELETE 없음
- [x] DELETE 204 본문 파싱 없음, 마지막 삭제 후 Empty UI
- [x] 수정·삭제 성공 후 GET 재조회
- [x] 쓰기 실패는 Dialog에서 처리, 쓰기 성공 후 GET 실패는 조회 전용 재시도
- [x] 400/403/404/409 안내 구분, 수정·삭제 403·404 후 목록 재조회
- [x] dispose 이후 응답·쓰기 이전 GET 결과 무시, 컨트롤러 dispose

### Challenge

- [x] 회원가입 제출 중 화면 이탈 방지
- [x] 편집·취소, 체크박스·선택 개수, 1개 이상 선택 시 삭제 활성화
- [x] 다중 삭제는 확인 Dialog를 닫은 뒤 요청 시작
- [x] 화면 위 어두운 ModalBarrier·흰색 인디케이터, 이탈 방지
- [x] 선택 ID의 복사본 순회, 성공 항목만 제거·실패 항목 선택 유지
- [x] 일부 실패 Snackbar, 요청 후 GET 재조회, 예외에도 로딩 해제

## 검증 결과

| 검증 | 결과 |
|---|---|
| `flutter analyze --no-pub` | [No issues found](evidence/flutter-analyze.txt) |
| `flutter test --no-pub` | [전체 53개 테스트 통과](evidence/flutter-test.txt) |
| `flutter build web --no-pub` | [웹 release 빌드 성공](evidence/flutter-build.txt) |
| `dart run tool/verify_live_api.dart` | 실제 v6 API 15개 확인 통과 |

일반 단위·위젯 테스트는 제어된 HTTP 응답을 사용합니다. 실제 서버 검증은 별도 스크립트로 실행했습니다. 아래 이미지는 실제 Flutter 위젯을 렌더링한 자동화 테스트 증빙이며 수동 브라우저 캡처·영상은 아닙니다.

### 실제 API 검증

명세: [MovieLog v6 Swagger JSON](https://workbook.devnoco.com/docs/v6-json). 직접 객체·배열/공통 wrapper/204를 각각 처리합니다. 평점 등록 result는 숫자/null 어느 쪽도 강제 캐스팅하지 않습니다.

비밀번호를 제외한 응답 기록: [live-api.json](evidence/live-api.json)

- 본인 검증용 회원: memberId **6**, nickname `w7453510396`, email `week07.1794453510396@example.com`
- 권한 검증용으로 직접 생성한 두 번째 회원: memberId **7**
- 실제 TMDB 인기 목록에서 선택한 영화: **687163 / 프로젝트 헤일메리**
- TMDB id 687163 → MovieLog movieId 687163 → 생성 ratingId 6 확인
- 가입 201, 최종 중복 409, 비밀번호 400 확인
- 평점 등록 201 → GET 확인 → 중복 등록 409 확인
- 다른 본인 테스트 계정의 path로 수정·삭제해 403 확인
- PATCH 200 후 코멘트 유지, 명시적 null 전송 후 삭제 확인
- DELETE 204 후 GET 빈 배열, 이미 삭제한 평점 DELETE 404 확인

이 실행에서 만든 평점은 정리했습니다. 타인의 평점 ID를 조회하거나 수정·삭제하지 않았습니다. 비밀번호·TMDB 토큰은 증빙에 포함하지 않았습니다.

### 화면 증빙

| 상황 | 화면 |
|---|---|
| 별점·코멘트 입력 | [01-rating-comment.png](evidence/01-rating-comment.png) |
| 저장 실패 후 입력 유지 | [02-save-failure-preserves-input.png](evidence/02-save-failure-preserves-input.png) |
| 현재 회원 평점 목록·수정·삭제 | [03-my-ratings.png](evidence/03-my-ratings.png) |
| 기존 값이 채워진 수정 Dialog | [04-edit-prefilled.png](evidence/04-edit-prefilled.png) |
| 저장 성공 후 GET 실패·조회 재시도 | [05-write-success-refresh-failure.png](evidence/05-write-success-refresh-failure.png) |
| 단일 삭제 확인 | [06-delete-confirmation.png](evidence/06-delete-confirmation.png) |
| 마지막 삭제 후 빈 목록 | [07-empty-after-delete.png](evidence/07-empty-after-delete.png) |
| 다중 선택 | [08-multi-selection.png](evidence/08-multi-selection.png) |
| 다중 삭제 오버레이 | [09-bulk-delete-overlay.png](evidence/09-bulk-delete-overlay.png) |
| 다중 삭제 부분 실패·선택 유지 | [10-bulk-partial-failure.png](evidence/10-bulk-partial-failure.png) |
| 회원가입 서버 비밀번호 400 | [signup-400.png](evidence/signup-400.png) |
| 중복 확인 후 최종 가입 409 | [signup-409.png](evidence/signup-409.png) |

## 트러블슈팅

1. **쓰기 후 조회 실패**: 쓰기 부분만 예외를 다시 던지고, `_refreshAfterWrite`는 GET 실패를 `refreshWarning`에 기록했습니다. GET 재시도 후에도 PATCH가 1회만 호출되는지 테스트했습니다.
2. **PATCH 코멘트 삭제**: 유지할 때도 score와 기존 comment를 함께 보내며, 비우면 명시적 null을 보냅니다. 실제 API로 유지·삭제를 검증했습니다.
3. **204 파싱**: DELETE는 상태 코드만 확인하고 본문을 읽지 않습니다. 빈 응답 단위 테스트와 실제 서버 검증을 수행했습니다.
4. **다중 삭제 Set 변경**: `toList()` 복사본을 순회해 성공 ID만 제거했습니다. 일부 실패 시 체크박스 선택 유지까지 테스트했습니다.
5. **비동기 테스트·증빙 출력**: 파일 출력·초기 데이터 준비는 `tester.runAsync`에서 처리하고, 요청 시작 전후 이벤트를 진행해 검증했습니다. 글꼴을 로드해 한국어·아이콘을 표시했습니다.
6. **Windows 심볼릭 링크 권한**: `flutter pub get`은 의존성 다운로드 후 데스크톱 플러그인 심볼릭 링크 단계에서 종료 코드 1을 반환했습니다. 생성된 package config로 `--no-pub` 분석·테스트·웹 빌드는 성공했습니다.

## 미검증·남은 제출 작업

- 브라우저 도구가 Windows의 현재 URL을 신뢰할 수 있게 판별하지 못해 실제 브라우저 UI 조작이 중단되었습니다. 수동 Guided/Required 검증과 스터디 인증 녹화 영상은 아직 없습니다.
- Android/iOS 실기기·뒤로 스와이프는 미검증입니다. 위젯 테스트에서는 저장 중 pop 차단을 확인했습니다.
- Notion 개인 미션 페이지 작성과 `https://umc.ai.kr/` 제출은 아직 수행하지 않았습니다. 이 문서를 미션 기록으로 옮기고 수동 영상을 추가할 수 있습니다.
- 학습용 memberId는 인증 수단이 아니며 다음 JWT 주차에서 변경할 대상입니다.
