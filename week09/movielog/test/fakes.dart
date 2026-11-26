import 'dart:async';

import 'package:dio/dio.dart';
import 'package:movielog/core/storage/token_storage.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/favorite_check_dto.dart';
import 'package:movielog/data/models/favorite_response_dto.dart';
import 'package:movielog/data/models/login_models.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/models/movie_record_models.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page_dto.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/email_preference.dart';
import 'package:movielog/data/services/favorite_api_service.dart';
import 'package:movielog/data/services/genre_preference.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/movie_record_api_service.dart';
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
    Set<int> missingMovieIds = const {},
  }) : missingMovieIds = missingMovieIds.toSet();

  final int pageSize;
  int totalPages;
  bool failDiscover;
  bool failSearch = false;

  /// 이 page들만 Discover가 실패합니다. 같은 page 재시도를 확인할 때 씁니다.
  final failDiscoverPages = <int>{};

  /// TMDB 상세가 404인 영화입니다.
  final Set<int> missingMovieIds;

  /// TMDB 상세가 500인 영화입니다.
  final failingDetailIds = <int>{};

  /// key('discover:{장르}:{page}', 'search:{검색어}:{page}', 'detail')에 해당하는
  /// 요청이 Completer가 끝날 때까지 기다립니다. 늦게 도착한 응답을 흉내 냅니다.
  final gates = <String, Completer<void>>{};

  final discoverCalls = <({int page, List<int> genreIds})>[];
  final searchCalls = <({int page, String query})>[];
  final detailCalls = <int>[];
  int activeDetailCalls = 0;
  int maxActiveDetailCalls = 0;

  Future<void> _wait(String key) async => gates[key]?.future;

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
    await _wait('discover:${genreIds.join(',')}:$page');
    if (failDiscover || failDiscoverPages.contains(page)) {
      throw dioError(500, '/discover/movie');
    }
    // 장르마다 다른 id 대역을 써서 이전 장르 결과가 섞였는지 확인할 수 있게 합니다.
    final base = genreIds.isEmpty ? 0 : genreIds.first * 1000;
    // 페이지마다 앞 5개는 이전 페이지와 겹치도록 만들어 중복 제거를 확인합니다.
    final start = base + (page - 1) * (pageSize - 5) + 1;
    return TmdbMoviePageDto(
      page: page,
      results: [for (var i = 0; i < pageSize; i++) movieDto(start + i)],
      totalPages: totalPages,
      totalResults: totalPages * pageSize,
    );
  }

  /// '없는영화'는 결과 0건, 그 외 검색어는 2 page짜리 결과를 돌려줍니다.
  @override
  Future<TmdbMoviePageDto> searchMovies({
    required int page,
    required String query,
  }) async {
    searchCalls.add((page: page, query: query));
    await _wait('search:$query:$page');
    if (failSearch) throw dioError(500, '/search/movie');
    if (query == '없는영화') {
      return TmdbMoviePageDto(
        page: page,
        results: const [],
        totalPages: 0,
        totalResults: 0,
      );
    }
    final base = 5000 + query.hashCode.abs() % 1000 * 10 + (page - 1) * 4;
    return TmdbMoviePageDto(
      page: page,
      results: [
        for (var i = 0; i < 4; i++)
          movieDto(base + i, title: '$query 결과 ${(page - 1) * 4 + i + 1}'),
      ],
      totalPages: 2,
      totalResults: 8,
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
    activeDetailCalls++;
    if (activeDetailCalls > maxActiveDetailCalls) {
      maxActiveDetailCalls = activeDetailCalls;
    }
    try {
      await _wait('detail');
      if (missingMovieIds.contains(movieId)) {
        throw dioError(404, '/movie/$movieId');
      }
      if (failingDetailIds.contains(movieId)) {
        throw dioError(500, '/movie/$movieId');
      }
      return movieDto(movieId, title: 'TMDB 영화 $movieId');
    } finally {
      activeDetailCalls--;
    }
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
    if (fail) throw dioError(500, '/v8/members/nickname');
    return !takenNicknames.contains(nickname);
  }

  @override
  Future<bool> checkEmail(String email) async {
    emailCalls++;
    if (fail) throw dioError(500, '/v8/members/email');
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

/// 메모리 안에서 v8 토큰 기반 평점 등록·수정·삭제를 흉내 냅니다.
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
        '/v8/auth/login',
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

/// 토큰(= 계정)별로 즐겨찾기를 보관합니다. 실제 서버처럼 JWT로 사용자를 구분하는 흉내입니다.
class FakeFavoriteApiService implements FavoriteApiService {
  FakeFavoriteApiService(this.storage);

  /// 현재 저장된 토큰으로 "누구의 요청인지" 판단합니다.
  final FakeTokenStorage storage;

  final _byToken = <String, List<FavoriteResponseDto>>{};
  int _nextId = 1;

  DioException? listError;
  DioException? checkError;
  DioException? addError;
  DioException? deleteError;

  /// 설정하면 해당 호출이 Completer가 끝날 때까지 기다립니다.
  Completer<void>? listGate;
  Completer<void>? checkGate;
  Completer<void>? addGate;

  int listCalls = 0;
  final checkCalls = <int>[];
  final addCalls = <int>[];
  final deleteCalls = <int>[];

  List<FavoriteResponseDto> _mine([String? token]) =>
      _byToken.putIfAbsent(token ?? storage.token ?? '', () => []);

  /// [token] 계정에 즐겨찾기를 미리 넣어 둡니다.
  void seed(String token, List<int> movieIds) {
    for (final movieId in movieIds) {
      _mine(token).add(
        FavoriteResponseDto(
          favoriteId: _nextId++,
          movieId: movieId,
          createdAt: DateTime.utc(2026, 11, 20),
        ),
      );
    }
  }

  List<int> movieIdsOf(String token) =>
      _mine(token).map((f) => f.movieId).toList();

  @override
  Future<List<FavoriteResponseDto>> fetchMyFavorites() async {
    listCalls++;
    final token = storage.token;
    await listGate?.future;
    final error = listError;
    if (error != null) throw error;
    return _mine(token).toList();
  }

  @override
  Future<FavoriteCheckDto> checkFavorite({required int movieId}) async {
    checkCalls.add(movieId);
    final token = storage.token;
    await checkGate?.future;
    final error = checkError;
    if (error != null) throw error;
    return FavoriteCheckDto(
      movieId: movieId,
      isFavorite: _mine(token).any((f) => f.movieId == movieId),
    );
  }

  @override
  Future<FavoriteResponseDto> addFavorite({required int movieId}) async {
    addCalls.add(movieId);
    final token = storage.token;
    await addGate?.future;
    final error = addError;
    if (error != null) throw error;
    if (_mine(token).any((f) => f.movieId == movieId)) {
      throw dioError(409, '/v8/favorites', code: 'FAVORITE409_1');
    }
    final created = FavoriteResponseDto(
      favoriteId: _nextId++,
      movieId: movieId,
      createdAt: DateTime.utc(2026, 11, 26),
    );
    _mine(token).insert(0, created);
    return created;
  }

  @override
  Future<void> deleteFavorite({required int movieId}) async {
    deleteCalls.add(movieId);
    final error = deleteError;
    if (error != null) throw error;
    final list = _mine();
    if (!list.any((f) => f.movieId == movieId)) {
      throw dioError(404, '/v8/favorites/$movieId', code: 'FAVORITE404_1');
    }
    list.removeWhere((f) => f.movieId == movieId);
  }
}

/// `POST /v8/movie-records`를 흉내 냅니다. addToFavorites면 [favorites]에도 넣습니다.
class FakeMovieRecordApiService implements MovieRecordApiService {
  FakeMovieRecordApiService({this.favorites});

  final FakeFavoriteApiService? favorites;
  DioException? error;
  int _nextId = 300;
  final calls = <CreateMovieRecordRequest>[];

  @override
  Future<MovieRecordResponseDto> createMovieRecord(
    CreateMovieRecordRequest request,
  ) async {
    calls.add(request);
    final e = error;
    if (e != null) throw e;
    final favorite = request.addToFavorites
        ? await favorites?.addFavorite(movieId: request.movieId)
        : null;
    return MovieRecordResponseDto(
      rating: RatingDto(
        ratingId: _nextId++,
        movieId: request.movieId,
        score: request.score,
        comment: request.comment,
        createdAt: DateTime.utc(2026, 11, 26),
      ),
      favorite: favorite,
    );
  }
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
