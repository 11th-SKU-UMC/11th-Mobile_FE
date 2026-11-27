/// 평점 Dialog의 onSubmit이 던지면 Dialog가 오류 문구 없이 닫힌다.
///
/// 세션 만료(AUTH401_2/3/4)·RATING403_1·RATING409_1·RATING404_1처럼 Dialog 밖에서
/// 안내할 실패에 쓴다. 안내 문구는 ViewModel이 보관하고, Dialog를 띄운 화면이
/// 닫힌 뒤 Snackbar로 보여준다. 세션 만료는 로그인 화면이 안내한다.
class RatingDialogDismissed implements Exception {
  const RatingDialogDismissed();
}
