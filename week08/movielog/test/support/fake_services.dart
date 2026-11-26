import 'package:dio/dio.dart';
import 'package:movielog/core/storage/token_storage.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/login_models.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';

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

/// v7 평점 API 가짜. 받은 요청을 기록하고, 기본으로는 성공 응답 Rating을 돌려준다.
///
/// 사용자 식별은 토큰으로 하므로 어떤 메서드에도 memberId 인자가 없다.
class FakeRatingApiService extends RatingApiService {
  FakeRatingApiService() : super(Dio(), Dio());

  Future<RatingDto> Function(CreateRatingRequest request)? createHandler;
  Future<RatingDto> Function(int ratingId, int score, String? comment)?
  updateHandler;
  Future<void> Function(int ratingId)? deleteHandler;

  final List<CreateRatingRequest> createCalls = [];
  final List<({int ratingId, int score, String? comment})> updateCalls = [];
  final List<int> deleteCalls = [];

  @override
  Future<RatingDto> createRating(CreateRatingRequest request) {
    createCalls.add(request);
    return createHandler?.call(request) ??
        Future.value(
          rating(
            ratingId: 100 + createCalls.length,
            movieId: request.movieId,
            score: request.score,
            comment: request.comment,
          ),
        );
  }

  @override
  Future<RatingDto> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) {
    updateCalls.add((ratingId: ratingId, score: score, comment: comment));
    return updateHandler?.call(ratingId, score, comment) ??
        Future.value(
          rating(ratingId: ratingId, score: score, comment: comment),
        );
  }

  @override
  Future<void> deleteRating(int ratingId) {
    deleteCalls.add(ratingId);
    return deleteHandler?.call(ratingId) ?? Future.value();
  }
}

/// 메모리 토큰 저장소. 토큰 값은 테스트용 더미 문자열만 쓰고 출력하지 않는다.
class MemoryTokenStorage implements TokenStorage {
  MemoryTokenStorage({this.token});

  String? token;
  Object? readError;
  Object? deleteError;
  int saveCalls = 0;
  int deleteCalls = 0;

  @override
  Future<void> saveAccessToken(String value) async {
    saveCalls++;
    token = value;
  }

  @override
  Future<String?> readAccessToken() async {
    final error = readError;
    if (error != null) throw error;
    return token;
  }

  @override
  Future<void> deleteAccessToken() async {
    deleteCalls++;
    final error = deleteError;
    if (error != null) throw error;
    token = null;
  }
}

/// 테스트용 더미 토큰. 실제 JWT가 아니다.
const String testToken = 'test-token';

class FakeAuthApiService extends AuthApiService {
  FakeAuthApiService({this.handler}) : super(Dio());

  Future<LoginResult> Function(LoginRequest request)? handler;
  int calls = 0;

  @override
  Future<LoginResult> login(LoginRequest request) {
    calls++;
    return handler?.call(request) ??
        Future.value(
          const LoginResult(nickname: '무비러버', accessToken: testToken),
        );
  }
}

class FakeMemberApiService extends MemberApiService {
  FakeMemberApiService({this.fetchHandler, this.updateHandler}) : super(Dio());

  Future<MemberInfo> Function()? fetchHandler;
  Future<MemberInfo> Function(String nickname)? updateHandler;
  int fetchCalls = 0;

  @override
  Future<MemberInfo> fetchMe() {
    fetchCalls++;
    return fetchHandler?.call() ?? Future.value(member());
  }

  @override
  Future<MemberInfo> updateNickname(String nickname) {
    return updateHandler?.call(nickname) ??
        Future.value(member(nickname: nickname));
  }
}

MemberInfo member({String nickname = '무비러버'}) => MemberInfo(
  email: 'movie@example.com',
  nickname: nickname,
  createdAt: DateTime.utc(2026, 10, 10, 3),
);

/// 로그인까지 마친 AuthViewModel. (토큰 저장 → signedIn)
Future<AuthViewModel> signedInAuth({
  MemoryTokenStorage? storage,
  FakeMemberApiService? members,
}) async {
  final auth = AuthViewModel(
    FakeAuthApiService(),
    members ?? FakeMemberApiService(),
    storage ?? MemoryTokenStorage(),
  );
  await auth.login('movie@example.com', 'movie1234');
  return auth;
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

/// 공통 오류 형식 body를 가진 DioException. (v6·v7 모두 `{isSuccess, code, message, result}`)
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
