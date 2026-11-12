import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/check_result.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page_dto.dart';
import 'package:movielog/data/services/fake_movie_service.dart';

void main() {
  group('4주차 FakeMovieService', () {
    const service = FakeMovieService(delay: Duration(milliseconds: 10));

    test('success 모드는 Mock 영화 목록을 반환한다', () async {
      final movies = await service.fetchMovies();
      expect(movies, isNotEmpty);
      expect(movies.first.title, '별빛 아래 우리');
    });

    test('장르를 지정하면 해당 장르만 반환한다', () async {
      final movies = await service.fetchMovies(genre: 'SF');
      expect(movies.every((movie) => movie.genre == 'SF'), isTrue);
    });

    test('empty 모드는 빈 목록을 반환한다', () async {
      expect(await service.fetchMovies(mode: MovieLoadMode.empty), isEmpty);
    });

    test('failure 모드는 MovieLoadException을 던진다', () {
      expect(
        service.fetchMovies(mode: MovieLoadMode.failure),
        throwsA(isA<MovieLoadException>()),
      );
    });
  });

  group('5주차 TMDB DTO', () {
    test('snake_case·null·num 값을 변환한다', () {
      final movie = TmdbMovieDto.fromJson({
        'id': 550,
        'title': null,
        'overview': null,
        'poster_path': null,
        'release_date': null,
        'genre_ids': [18, 53],
        'vote_average': 8,
        'popularity': 12.5,
      });

      expect(movie.title, '제목 없음');
      expect(movie.overview, '');
      expect(movie.posterPath, isNull);
      expect(movie.releaseYear, isNull);
      expect(movie.genreIds, [18, 53]);
      expect(movie.voteAverage, 8.0);
      expect(movie.fiveStarAverage, 4.0);
    });

    test('상세 응답의 genres 배열에서 장르 id와 이름을 읽는다', () {
      final movie = TmdbMovieDto.fromJson({
        'id': 13,
        'title': '포레스트 검프',
        'release_date': '1994-06-23',
        'genres': [
          {'id': 35, 'name': '코미디'},
          {'id': 18, 'name': '드라마'},
        ],
      });

      expect(movie.genreIds, [35, 18]);
      expect(movie.genreNames, ['코미디', '드라마']);
      expect(movie.releaseYear, '1994');
    });

    test('페이지 응답을 TmdbMoviePageDto로 변환한다', () {
      final page = TmdbMoviePageDto.fromJson({
        'page': 1,
        'results': [
          {'id': 1, 'title': 'A'},
        ],
        'total_pages': 10,
        'total_results': 200,
      });

      expect(page.results.single.id, 1);
      expect(page.totalPages, 10);
    });
  });

  group('6주차 자체 API 모델', () {
    test('CheckResult는 Wrapper 없이 available을 읽는다', () {
      expect(CheckResult.fromJson({'available': false}).available, isFalse);
    });

    test('RatingDto는 comment가 null이어도 파싱한다', () {
      final rating = RatingDto.fromJson({
        'ratingId': 3,
        'movieId': 13,
        'score': 3,
        'comment': null,
        'createdAt': '2026-11-07T19:00:16.676Z',
        'updatedAt': '2026-11-07T19:00:16.676Z',
      });

      expect(rating.comment, isNull);
      expect(rating.movieId, 13);
      expect(rating.createdAt.isUtc, isTrue);
    });
  });

  group('7주차 v6 요청·응답 모델', () {
    test('CommonResponse는 회원가입 result를 SignUpResult로 한 번만 파싱한다', () {
      final response = CommonResponse<SignUpResult>.fromJson({
        'isSuccess': true,
        'code': 'COMMON201',
        'message': '성공',
        'result': {'memberId': 7, 'email': 'a@umc.com', 'nickname': '무비'},
      }, (value) => SignUpResult.fromJson(value as Map<String, dynamic>));

      expect(response.isSuccess, isTrue);
      expect(response.result?.memberId, 7);
    });

    test('CommonResponse는 result가 null이면 파싱 함수를 호출하지 않는다', () {
      final response = CommonResponse<SignUpResult>.fromJson({
        'isSuccess': true,
        'code': 'COMMON200',
        'message': '성공',
        'result': null,
      }, (value) => throw StateError('호출되면 안 됩니다.'));
      expect(response.result, isNull);
    });

    test('CreateMemberRequest는 이메일·닉네임만 trim하고 비밀번호는 그대로 둔다', () {
      const request = CreateMemberRequest(
        email: ' a@umc.com ',
        password: ' Pass12!x',
        nickname: ' 무비 ',
      );
      expect(request.toJson(), {
        'email': 'a@umc.com',
        'password': ' Pass12!x',
        'nickname': '무비',
      });
    });

    test('CreateRatingRequest는 빈 comment를 생략한다', () {
      expect(
        const CreateRatingRequest(
          movieId: 550,
          score: 4,
          comment: '   ',
        ).toJson(),
        {'movieId': 550, 'score': 4},
      );
    });

    test('validateServerScore는 1~5 정수만 허용한다', () {
      expect(validateServerScore(3.0), 3);
      expect(() => validateServerScore(3.5), throwsArgumentError);
      expect(() => validateServerScore(0), throwsArgumentError);
      expect(() => validateServerScore(6), throwsArgumentError);
    });
  });
}
