import 'dart:async';

import 'package:dio/dio.dart';
import 'package:movielog/core/storage/token_storage.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/login_models.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page_dto.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/email_preference.dart';
import 'package:movielog/data/services/genre_preference.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';

TmdbMovieDto movieDto(int id, {String? title, String? posterPath = '/p.jpg'}) {
  return TmdbMovieDto.fromJson({
    'id': id,
    'title': title ?? '영화 $id',
    'overview': '',
    'poster_path': posterPath,
    'release_date': '2024-01-01',
    'genre_ids': [18],
    'vote_average': 8.0,
    'popularity': 1.0,
  });
}

/// [code]·[message]를 주면 v6 공통 오류 응답 body를 함께 담습니다.
DioException dioError(
  int statusCode,
  String path, {
  String? code,
  String? message,
}) {
  final options = RequestOptions(path: path);
  return DioException(
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: statusCode,
      data: code == null
          ? null
          : {
              'isSuccess': false,
              'code': code,
              'message': message ?? '',
              'result': null,
            },
    ),
    type: DioExceptionType.badResponse,
  );
}

class FakeTmdbMovieService implements TmdbMovieService {
  FakeTmdbMovieService({
    this.pageSize = 20,
    this.totalPages = 5,
    this.failDiscover = false,
    this.missingMovieIds = const {},
  });

  final int pageSize;
  final int totalPages;
  bool failDiscover;
  final Set<int> missingMovieIds;

  final discoverCalls = <({int page, List<int> genreIds})>[];
  final detailCalls = <int>[];

  @override
  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) async {
    return TmdbMoviePageDto(
      page: 1,
      results: [for (var i = 1; i <= 3; i++) movieDto(i, title: '인기 영화 $i')],
      totalPages: 1,
      totalResults: 3,
    );
  }

  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int> genreIds = const [],
  }) async {
    discoverCalls.add((page: page, genreIds: genreIds));
    if (failDiscover) throw dioError(500, '/discover/movie');
    // 페이지마다 앞 5개는 이전 페이지와 겹치도록 만들어 중복 제거를 확인합니다.
    final start = (page - 1) * (pageSize - 5) + 1;
    return TmdbMoviePageDto(
      page: page,
      results: [for (var i = 0; i < pageSize; i++) movieDto(start + i)],
      totalPages: totalPages,
      totalResults: totalPages * pageSize,
    );
  }

  @override
  Future<List<TmdbGenreDto>> fetchGenres() async => const [
    TmdbGenreDto(id: 28, name: '액션'),
    TmdbGenreDto(id: 18, name: '드라마'),
  ];

  @override
  Future<TmdbMovieDto> fetchMovieDetail(int movieId) async {
    detailCalls.add(movieId);
    if (missingMovieIds.contains(movieId)) {
      throw dioError(404, '/movie/$movieId');
    }
    return movieDto(movieId, title: 'TMDB 영화 $movieId');
  }

  @override
  Future<TmdbMovieDto?> findMovieById(int movieId) async {
    try {
      return await fetchMovieDetail(movieId);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}

class FakeSignUpService implements SignUpService {
  FakeSignUpService({
    this.takenNicknames = const {'영화광'},
    this.takenEmails = const {'movie@umc.com'},
    this.createdMemberId = 42,
  });

  final Set<String> takenNicknames;
  final Set<String> takenEmails;
  final int createdMemberId;
  bool fail = false;
  int nicknameCalls = 0;
  int emailCalls = 0;

  /// 설정하면 signUp이 이 오류를 던집니다.
  DioException? signUpError;

  /// 설정하면 signUp이 이 Completer가 끝날 때까지 기다립니다.
  Completer<void>? signUpGate;
  final signUpRequests = <CreateMemberRequest>[];

  @override
  Future<bool> checkNickname(String nickname) async {
    nicknameCalls++;
    if (fail) throw dioError(500, '/v7/members/nickname');
    return !takenNicknames.contains(nickname);
  }

  @override
  Future<bool> checkEmail(String email) async {
    emailCalls++;
    if (fail) throw dioError(500, '/v7/members/email');
    return !takenEmails.contains(email);
  }

  @override
  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    signUpRequests.add(request);
    await signUpGate?.future;
    final error = signUpError;
    if (error != null) throw error;
    return CommonResponse<SignUpResult>(
      isSuccess: true,
      code: 'COMMON201',
      message: '회원가입 성공',
      result: SignUpResult(
        memberId: createdMemberId,
        email: request.email.trim(),
        nickname: request.nickname.trim(),
      ),
    );
  }
}

/// 메모리 안에서 v7 토큰 기반 평점 등록·수정·삭제를 흉내 냅니다.
class FakeRatingApiService implements RatingApiService {
  FakeRatingApiService({List<RatingDto> publicRatings = const []})
    : publicRatings = publicRatings.toList();

  /// 공개 유저별 조회가 돌려줄 목록입니다.
  List<RatingDto> publicRatings;

  int _nextId = 100;

  DioException? createError;
  DioException? updateError;

  /// ratingId → 삭제 시 던질 오류입니다.
  final deleteErrors = <int, DioException>{};

  /// 설정하면 해당 호출이 이 Completer가 끝날 때까지 기다립니다.
  Completer<void>? createGate;
  Completer<void>? updateGate;

  final createCalls = <CreateRatingRequest>[];
  final updateCalls = <({int ratingId, int score, String? comment})>[];
  final deleteCalls = <int>[];

  @override
  Future<List<RatingDto>> fetchMemberRatings(int memberId) async =>
      publicRatings.toList();

  @override
  Future<RatingDto> createRating(CreateRatingRequest request) async {
    createCalls.add(request);
    await createGate?.future;
    final error = createError;
    if (error != null) throw error;
    return RatingDto(
      ratingId: _nextId++,
      movieId: request.movieId,
      score: request.score,
      comment: request.comment,
      createdAt: DateTime.utc(2026, 11, 19),
    );
  }

  @override
  Future<RatingDto> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    updateCalls.add((ratingId: ratingId, score: score, comment: comment));
    await updateGate?.future;
    final error = updateError;
    if (error != null) throw error;
    return RatingDto(
      ratingId: ratingId,
      movieId: 0, // 화면은 기존 카드의 movie를 유지하므로 값은 중요하지 않습니다.
      score: score,
      comment: comment,
      createdAt: DateTime.utc(2026, 11, 19),
    );
  }

  @override
  Future<void> deleteRating(int ratingId) async {
    deleteCalls.add(ratingId);
    final error = deleteErrors[ratingId];
    if (error != null) throw error;
  }
}

class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage([this.token]);

  String? token;
  bool failRead = false;
  bool failDelete = false;
  int saveCalls = 0;
  int deleteCalls = 0;

  @override
  Future<void> saveAccessToken(String value) async {
    saveCalls++;
    token = value;
  }

  @override
  Future<String?> readAccessToken() async {
    if (failRead) throw StateError('storage');
    return token;
  }

  @override
  Future<void> deleteAccessToken() async {
    deleteCalls++;
    if (failDelete) throw StateError('storage');
    token = null;
  }
}

/// 이메일·비밀번호 쌍을 accounts로 검사하고, 성공하면 'token-{email}'을 돌려줍니다.
class FakeAuthApiService implements AuthApiService {
  FakeAuthApiService({this.accounts = const {'movie@umc.com': 'Umc1234!'}});

  final Map<String, String> accounts;
  DioException? error;
  Completer<void>? gate;
  final loginCalls = <String>[];

  @override
  Future<LoginResult> login(LoginRequest request) async {
    loginCalls.add(request.email);
    await gate?.future;
    final e = error;
    if (e != null) throw e;
    if (accounts[request.email.trim()] != request.password) {
      throw dioError(
        401,
        '/v7/auth/login',
        code: 'AUTH401_1',
        message: '이메일 또는 비밀번호가 올바르지 않습니다.',
      );
    }
    return LoginResult(
      nickname: '무비러버',
      accessToken: 'token-${request.email.trim()}',
    );
  }
}

class FakeMemberApiService implements MemberApiService {
  FakeMemberApiService({MemberInfo? member})
    : member =
          member ??
          MemberInfo(
            email: 'movie@umc.com',
            nickname: '무비러버',
            createdAt: DateTime.utc(2026, 10, 10, 3),
          );

  MemberInfo member;
  DioException? fetchError;
  DioException? updateError;
  Completer<void>? fetchGate;
  int fetchCalls = 0;
  final updateCalls = <String>[];

  @override
  Future<MemberInfo> fetchMe() async {
    fetchCalls++;
    await fetchGate?.future;
    final e = fetchError;
    if (e != null) throw e;
    return member;
  }

  @override
  Future<MemberInfo> updateNickname(String nickname) async {
    updateCalls.add(nickname);
    final e = updateError;
    if (e != null) throw e;
    member = MemberInfo(
      email: member.email,
      nickname: nickname,
      createdAt: member.createdAt,
    );
    return member;
  }
}

class FakeEmailPreference implements EmailPreference {
  FakeEmailPreference([this.saved]);

  String? saved;

  @override
  Future<String?> read() async => saved;

  @override
  Future<void> save(String email) async => saved = email.trim();

  @override
  Future<void> clear() async => saved = null;
}

DioException expiredError(String path, {String code = 'AUTH401_4'}) =>
    dioError(401, path, code: code, message: '토큰이 만료되었습니다. 다시 로그인해주세요.');

/// 실제 AuthViewModel을 fake 서비스로 만들고, 필요하면 로그인 상태까지 만듭니다.
Future<AuthViewModel> signedInAuth({
  FakeAuthApiService? authApi,
  FakeMemberApiService? memberApi,
  FakeTokenStorage? storage,
}) async {
  final auth = AuthViewModel(
    authApi ?? FakeAuthApiService(),
    memberApi ?? FakeMemberApiService(),
    storage ?? FakeTokenStorage(),
  );
  await auth.login('movie@umc.com', 'Umc1234!');
  return auth;
}

class FakeGenrePreference implements GenrePreference {
  FakeGenrePreference([List<int> saved = const []]) : saved = saved.toList();

  List<int> saved;

  @override
  Future<List<int>> read() async => saved;

  @override
  Future<void> save(List<int> genreIds) async => saved = genreIds.toList();

  @override
  Future<void> clear() async => saved = [];
}
