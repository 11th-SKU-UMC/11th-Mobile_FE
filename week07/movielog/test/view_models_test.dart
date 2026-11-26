import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/view_models/load_status.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';

import 'fakes.dart';

RatingDto rating(int id, int movieId, {String? comment}) => RatingDto(
  ratingId: id,
  movieId: movieId,
  score: 4,
  comment: comment,
  createdAt: DateTime.utc(2026, 11, 7),
);

void main() {
  group('MovieHomeViewModel', () {
    test('인기 영화가 5개보다 적어도 범위 오류 없이 표시한다', () async {
      final viewModel = MovieHomeViewModel(FakeTmdbMovieService());
      await viewModel.loadPopular();

      expect(viewModel.status, LoadStatus.success);
      expect(viewModel.popularMovies.length, 3);
    });
  });

  group('MovieListViewModel', () {
    test('Discover를 여러 페이지 요청해 중복 없는 최대 30개를 만든다', () async {
      final service = FakeTmdbMovieService();
      final viewModel = MovieListViewModel(service, FakeGenrePreference());
      await viewModel.loadInitial();

      expect(viewModel.status, LoadStatus.success);
      expect(viewModel.movies.length, 30);
      expect(viewModel.movies.map((movie) => movie.id).toSet().length, 30);
      expect(service.discoverCalls.map((call) => call.page), [1, 2]);
    });

    test('결과가 30개보다 적으면 있는 만큼만 보여준다', () async {
      final service = FakeTmdbMovieService(pageSize: 10, totalPages: 1);
      final viewModel = MovieListViewModel(service, FakeGenrePreference());
      await viewModel.loadInitial();

      expect(viewModel.movies.length, 10);
      expect(service.discoverCalls.length, 1);
    });

    test('장르를 선택하면 저장하고 page 1부터 with_genres로 다시 요청한다', () async {
      final service = FakeTmdbMovieService();
      final preference = FakeGenrePreference();
      final viewModel = MovieListViewModel(service, preference);
      await viewModel.loadInitial();
      service.discoverCalls.clear();

      await viewModel.selectGenres([28, 18]);

      expect(preference.saved, [28, 18]);
      expect(service.discoverCalls.first.page, 1);
      expect(service.discoverCalls.first.genreIds, [28, 18]);
    });

    test('저장된 장르를 앱 재시작 시 복원한다', () async {
      final service = FakeTmdbMovieService();
      final viewModel = MovieListViewModel(service, FakeGenrePreference([18]));
      await viewModel.loadInitial();

      expect(viewModel.selectedGenreIds, [18]);
      expect(service.discoverCalls.first.genreIds, [18]);
    });

    test('요청 중에는 장르를 바꿀 수 없다', () async {
      final service = FakeTmdbMovieService();
      final viewModel = MovieListViewModel(service, FakeGenrePreference());
      final loading = viewModel.loadInitial();

      expect(viewModel.canChangeGenre, isFalse);
      await viewModel.selectGenres([28]);
      await loading;

      expect(viewModel.selectedGenreIds, isEmpty);
    });

    test('Discover 실패는 Error 상태가 되고 재시도할 수 있다', () async {
      final service = FakeTmdbMovieService(failDiscover: true);
      final viewModel = MovieListViewModel(service, FakeGenrePreference());
      await viewModel.loadInitial();
      expect(viewModel.status, LoadStatus.error);

      service.failDiscover = false;
      await viewModel.reload();
      expect(viewModel.status, LoadStatus.success);
    });

    test('새로고침이 실패해도 최근 목록을 유지한다', () async {
      final service = FakeTmdbMovieService();
      final viewModel = MovieListViewModel(service, FakeGenrePreference());
      await viewModel.loadInitial();

      service.failDiscover = true;
      final success = await viewModel.refresh();

      expect(success, isFalse);
      expect(viewModel.status, LoadStatus.success);
      expect(viewModel.movies.length, 30);
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

  group('MyRatingsViewModel', () {
    test('평점의 movieId로 TMDB 영화를 붙이고 같은 movieId는 한 번만 조회한다', () async {
      final movies = FakeTmdbMovieService();
      final viewModel = MyRatingsViewModel(
        FakeRatingApiService(ratings: [rating(2, 550), rating(1, 550)]),
        movies,
        1,
      );
      await viewModel.load();

      expect(viewModel.status, LoadStatus.success);
      expect(viewModel.ratings.first.movie?.title, 'TMDB 영화 550');
      expect(movies.detailCalls, [550]);
    });

    test('TMDB에서 영화를 찾지 못해도 평점은 남기고 안내 문구를 표시한다', () async {
      final viewModel = MyRatingsViewModel(
        FakeRatingApiService(ratings: [rating(1, 999)]),
        FakeTmdbMovieService(missingMovieIds: {999}),
        1,
      );
      await viewModel.load();

      expect(viewModel.status, LoadStatus.success);
      expect(viewModel.ratings.single.movie, isNull);
      expect(viewModel.message, isNotNull);
    });

    test('빈 배열은 Empty, 404는 Error로 구분한다', () async {
      final empty = MyRatingsViewModel(
        FakeRatingApiService(),
        FakeTmdbMovieService(),
        1,
      );
      await empty.load();
      expect(empty.status, LoadStatus.empty);

      final notFound = MyRatingsViewModel(
        FakeRatingApiService(errorStatus: 404),
        FakeTmdbMovieService(),
        99999,
      );
      await notFound.load();
      expect(notFound.status, LoadStatus.error);
      expect(notFound.message, '존재하지 않는 회원입니다.');
    });
  });
}
