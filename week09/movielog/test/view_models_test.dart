import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/view_models/load_phase.dart';
import 'package:movielog/view_models/load_status.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';

import 'fakes.dart';

void main() {
  group('MovieHomeViewModel', () {
    test('인기 영화가 5개보다 적어도 범위 오류 없이 표시한다', () async {
      final viewModel = MovieHomeViewModel(FakeTmdbMovieService());
      await viewModel.loadPopular();

      expect(viewModel.status, LoadStatus.success);
      expect(viewModel.popularMovies.length, 3);
    });
  });

  group('MovieListViewModel (장르) + PagedMoviesViewModel', () {
    (MovieListViewModel, PagedMoviesViewModel) create(
      FakeTmdbMovieService service, [
      FakeGenrePreference? preference,
    ]) {
      final paged = PagedMoviesViewModel(tmdbApi: service);
      return (
        MovieListViewModel(service, preference ?? FakeGenrePreference(), paged),
        paged,
      );
    }

    test('영화 목록은 첫 page만 불러온다(30개 수집 방식 대체)', () async {
      final service = FakeTmdbMovieService();
      final (viewModel, paged) = create(service);
      await viewModel.loadInitial();

      expect(paged.phase, LoadPhase.ready);
      expect(paged.movies.length, 20);
      expect(service.discoverCalls.map((call) => call.page), [1]);
    });

    test('장르를 선택하면 저장하고 page 1부터 with_genres로 다시 요청한다', () async {
      final service = FakeTmdbMovieService();
      final preference = FakeGenrePreference();
      final (viewModel, paged) = create(service, preference);
      await viewModel.loadInitial();
      await paged.loadNextPage();
      service.discoverCalls.clear();

      await viewModel.selectGenres([28, 18]);

      expect(preference.saved, [28, 18]);
      expect(service.discoverCalls.single.page, 1);
      expect(service.discoverCalls.single.genreIds, [28, 18]);
      expect(paged.nextPage, 2);
    });

    test('저장된 장르를 앱 재시작 시 복원한다', () async {
      final service = FakeTmdbMovieService();
      final (viewModel, _) = create(service, FakeGenrePreference([18]));
      await viewModel.loadInitial();

      expect(viewModel.selectedGenreIds, [18]);
      expect(service.discoverCalls.first.genreIds, [18]);
    });

    test('첫 page 실패는 Error 상태가 되고 재시도할 수 있다', () async {
      final service = FakeTmdbMovieService(failDiscover: true);
      final (viewModel, paged) = create(service);
      await viewModel.loadInitial();
      expect(paged.phase, LoadPhase.error);

      service.failDiscover = false;
      await paged.refresh();
      expect(paged.phase, LoadPhase.ready);
    });
  });

  group('SignUpViewModel', () {
    test('사용 가능한 닉네임은 available 상태가 된다', () async {
      final viewModel = SignUpViewModel(FakeSignUpService());
      viewModel.onNicknameChanged('무비러버');
      await viewModel.checkNickname('무비러버');

      expect(viewModel.nicknameCheckStatus, CheckStatus.available);
      expect(viewModel.nicknameErrorText, isNull);
    });

    test('중복이면 에러 문구를 표시하고 확인 버튼을 비활성화한다', () async {
      final viewModel = SignUpViewModel(FakeSignUpService());
      viewModel.onNicknameChanged('영화광');
      await viewModel.checkNickname('영화광');

      expect(viewModel.nicknameCheckStatus, CheckStatus.duplicated);
      expect(viewModel.nicknameErrorText, '이미 사용 중인 닉네임입니다.');
      expect(viewModel.canCheckNickname, isFalse);
    });

    test('입력을 바꾸면 이전 결과가 무효화되고, 중복이던 값을 다시 입력하면 재요청 없이 에러가 된다', () async {
      final service = FakeSignUpService();
      final viewModel = SignUpViewModel(service);
      viewModel.onNicknameChanged('영화광');
      await viewModel.checkNickname('영화광');

      viewModel.onNicknameChanged('영화광2');
      expect(viewModel.nicknameCheckStatus, CheckStatus.idle);
      expect(viewModel.nicknameErrorText, isNull);
      expect(viewModel.canCheckNickname, isTrue);

      viewModel.onNicknameChanged(' 영화광 ');
      expect(viewModel.nicknameCheckStatus, CheckStatus.duplicated);
      expect(viewModel.canCheckNickname, isFalse);
      expect(service.nicknameCalls, 1);
    });

    test('통신 실패와 정상 중복 응답을 다른 문구로 구분한다', () async {
      final service = FakeSignUpService()..fail = true;
      final viewModel = SignUpViewModel(service);
      viewModel.onEmailChanged('a@umc.com');
      await viewModel.checkEmail('a@umc.com');

      expect(viewModel.emailCheckStatus, CheckStatus.error);
      expect(viewModel.emailErrorText, '중복 확인에 실패했습니다. 다시 시도해 주세요.');
      expect(viewModel.canCheckEmail, isTrue);
    });

    test('응답 전에 입력이 바뀌면 늦게 도착한 응답을 무시한다', () async {
      final viewModel = SignUpViewModel(FakeSignUpService());
      viewModel.onEmailChanged('movie@umc.com');
      final pending = viewModel.checkEmail('movie@umc.com');
      viewModel.onEmailChanged('new@umc.com');
      await pending;

      expect(viewModel.emailCheckStatus, CheckStatus.idle);
      expect(viewModel.emailErrorText, isNull);
    });

    test('닉네임과 이메일 상태는 서로 영향을 주지 않는다', () async {
      final viewModel = SignUpViewModel(FakeSignUpService());
      viewModel.onNicknameChanged('영화광');
      await viewModel.checkNickname('영화광');
      viewModel.onEmailChanged('a@umc.com');
      await viewModel.checkEmail('a@umc.com');

      expect(viewModel.nicknameCheckStatus, CheckStatus.duplicated);
      expect(viewModel.emailCheckStatus, CheckStatus.available);
      expect(viewModel.isAllChecked, isFalse);
    });
  });
}
