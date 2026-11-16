import 'package:dio/dio.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

/// 네트워크 없이 정해둔 중복 확인 결과를 돌려준다. 받은 요청을 기록한다.
class FakeMemberCheckService extends MemberCheckService {
  FakeMemberCheckService({this.nickname, this.email}) : super(Dio());

  Future<bool> Function(String value)? nickname;
  Future<bool> Function(String value)? email;

  final List<String> nicknameCalls = [];
  final List<String> emailCalls = [];

  @override
  Future<bool> checkNickname(String value) {
    nicknameCalls.add(value);
    return nickname?.call(value) ?? Future.value(true);
  }

  @override
  Future<bool> checkEmail(String value) {
    emailCalls.add(value);
    return email?.call(value) ?? Future.value(true);
  }
}

class FakeRatingApiService extends RatingApiService {
  FakeRatingApiService(this.handler) : super(Dio());

  Future<List<RatingDto>> Function(int memberId) handler;
  int calls = 0;

  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) {
    calls++;
    return handler(memberId);
  }
}

/// findMovieById만 바꾼 TMDB Service.
class FakeMovieDetailService extends TmdbMovieService {
  FakeMovieDetailService(this.handler) : super(Dio());

  Future<TmdbMovieDto?> Function(int movieId) handler;
  final List<int> calls = [];

  @override
  Future<TmdbMovieDto?> findMovieById(int movieId) {
    calls.add(movieId);
    return handler(movieId);
  }
}

DioException dioError({int? statusCode, String path = '/'}) {
  final options = RequestOptions(path: path);
  return DioException(
    requestOptions: options,
    type: statusCode == null
        ? DioExceptionType.connectionError
        : DioExceptionType.badResponse,
    response: statusCode == null
        ? null
        : Response(requestOptions: options, statusCode: statusCode),
  );
}

RatingDto rating({
  int ratingId = 1,
  int movieId = 550,
  int score = 5,
  String? comment = '최고의 영화!',
}) => RatingDto(
  ratingId: ratingId,
  movieId: movieId,
  score: score,
  comment: comment,
  createdAt: DateTime.utc(2026, 9, 6, 12),
);

TmdbMovieDto movie(int id, {String? title}) => TmdbMovieDto(
  id: id,
  title: title ?? '영화 $id',
  overview: '',
  posterPath: null,
  backdropPath: null,
  releaseDate: '2024-01-01',
  genreIds: const [],
  voteAverage: 7,
  popularity: 1,
);
