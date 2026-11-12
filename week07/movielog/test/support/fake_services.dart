import 'package:dio/dio.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

/// 네트워크 없이 정해둔 중복 확인·회원가입 결과를 돌려준다. 받은 요청을 기록한다.
class FakeSignUpService extends SignUpService {
  FakeSignUpService({this.nickname, this.email, this.signUpHandler})
    : super(Dio());

  Future<bool> Function(String value)? nickname;
  Future<bool> Function(String value)? email;
  Future<CommonResponse<SignUpResult>> Function(CreateMemberRequest request)?
  signUpHandler;

  final List<String> nicknameCalls = [];
  final List<String> emailCalls = [];
  int signUpCalls = 0;

  @override
  Future<CommonResponse<SignUpResult>> signUp(CreateMemberRequest request) {
    signUpCalls++;
    return signUpHandler?.call(request) ?? Future.value(signUpSuccess(42));
  }

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

  Future<void> Function()? createHandler;
  Future<void> Function()? updateHandler;
  Future<void> Function()? deleteHandler;

  final List<CreateRatingRequest> createCalls = [];
  final List<({int ratingId, int score, String? comment})> updateCalls = [];
  final List<int> deleteCalls = [];

  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) {
    calls++;
    return handler(memberId);
  }

  @override
  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) {
    createCalls.add(request);
    return createHandler?.call() ?? Future.value();
  }

  @override
  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) {
    updateCalls.add((ratingId: ratingId, score: score, comment: comment));
    return updateHandler?.call() ?? Future.value();
  }

  @override
  Future<void> deleteRating({required int memberId, required int ratingId}) {
    deleteCalls.add(ratingId);
    return deleteHandler?.call() ?? Future.value();
  }
}

CommonResponse<SignUpResult> signUpSuccess(int memberId) => CommonResponse(
  isSuccess: true,
  code: 'COMMON201',
  message: '회원가입에 성공했습니다.',
  result: SignUpResult(
    memberId: memberId,
    email: 'movie@example.com',
    nickname: '무비러버',
  ),
);

/// v6 공통 오류 형식 body를 가진 DioException.
DioException commonError(int statusCode, String code, String message) {
  final options = RequestOptions(path: '/');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: options,
      statusCode: statusCode,
      data: {
        'isSuccess': false,
        'code': code,
        'message': message,
        'result': null,
      },
    ),
  );
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
