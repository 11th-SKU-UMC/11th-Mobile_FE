import 'dart:async';

import 'package:dio/dio.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page_dto.dart';
import 'package:movielog/data/services/genre_preference.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

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
    if (fail) throw dioError(500, '/v6/members/nickname');
    return !takenNicknames.contains(nickname);
  }

  @override
  Future<bool> checkEmail(String email) async {
    emailCalls++;
    if (fail) throw dioError(500, '/v6/members/email');
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

/// 메모리 안에서 v6 평점 CRUD를 흉내 냅니다.
class FakeRatingApiService implements RatingApiService {
  FakeRatingApiService({List<RatingDto> ratings = const [], this.errorStatus})
    : ratings = ratings.toList();

  List<RatingDto> ratings;

  /// 설정하면 GET이 이 상태 코드로 실패합니다.
  int? errorStatus;

  /// ratingId → 삭제 시 던질 오류입니다.
  final deleteErrors = <int, DioException>{};
  DioException? createError;
  DioException? updateError;

  final createCalls = <({int memberId, CreateRatingRequest request})>[];
  final updateCalls =
      <({int memberId, int ratingId, int score, String? comment})>[];
  final deleteCalls = <({int memberId, int ratingId})>[];
  int fetchCalls = 0;

  @override
  Future<List<RatingDto>> fetchMemberRatings(int memberId) async {
    fetchCalls++;
    if (errorStatus != null) {
      throw dioError(errorStatus!, '/v6/members/$memberId/ratings');
    }
    return ratings.toList();
  }

  @override
  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    createCalls.add((memberId: memberId, request: request));
    final error = createError;
    if (error != null) throw error;
    final nextId =
        ratings.fold(0, (max, r) => r.ratingId > max ? r.ratingId : max) + 1;
    ratings = [
      RatingDto(
        ratingId: nextId,
        movieId: request.movieId,
        score: request.score,
        comment: request.comment,
        createdAt: DateTime.utc(2026, 11, 12),
      ),
      ...ratings,
    ];
  }

  @override
  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    updateCalls.add((
      memberId: memberId,
      ratingId: ratingId,
      score: score,
      comment: comment,
    ));
    final error = updateError;
    if (error != null) throw error;
    ratings = [
      for (final r in ratings)
        if (r.ratingId == ratingId)
          RatingDto(
            ratingId: r.ratingId,
            movieId: r.movieId,
            score: score,
            comment: comment,
            createdAt: r.createdAt,
          )
        else
          r,
    ];
  }

  @override
  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    deleteCalls.add((memberId: memberId, ratingId: ratingId));
    final error = deleteErrors[ratingId];
    if (error != null) throw error;
    ratings = ratings.where((r) => r.ratingId != ratingId).toList();
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
