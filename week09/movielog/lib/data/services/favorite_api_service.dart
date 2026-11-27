import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/favorite_check_dto.dart';
import '../models/favorite_response_dto.dart';

/// MovieLog 즐겨찾기 API(`/v8/favorites`).
///
/// 8주차 보호용 Client(AuthInterceptor 포함)를 주입받는다. memberId는 보내지 않고
/// JWT로 사용자를 구분한다. 오류는 DioException 그대로 던져 apiErrorCode로 구분한다.
class FavoriteApiService {
  FavoriteApiService(this._dio);

  final Dio _dio;

  /// 등록: 201, result에 FavoriteResponseDto.
  Future<FavoriteResponseDto> addFavorite({required int movieId}) async {
    final response = await _dio.post(
      '/v8/favorites',
      data: {'movieId': movieId},
    );
    final body = CommonResponse<FavoriteResponseDto>.fromJson(
      response.data as Map<String, dynamic>,
      FavoriteResponseDto.fromJson,
    );
    return body.result!;
  }

  /// 내 즐겨찾기 목록: 200, result가 배열. 없으면 빈 배열.
  Future<List<FavoriteResponseDto>> fetchMyFavorites() async {
    final response = await _dio.get('/v8/favorites');
    final body = CommonResponse<List<FavoriteResponseDto>>.fromJson(
      response.data as Map<String, dynamic>,
      (value) =>
          (value as List<dynamic>).map(FavoriteResponseDto.fromJson).toList(),
    );
    return body.result ?? const [];
  }

  /// 특정 영화의 즐겨찾기 여부. 응답에 movieId가 없어서 요청한 값을 함께 넘긴다.
  Future<FavoriteCheckDto> checkFavorite({required int movieId}) async {
    final response = await _dio.get('/v8/favorites/$movieId');
    final body = CommonResponse<FavoriteCheckDto>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => FavoriteCheckDto.fromJson(value, movieId: movieId),
    );
    return body.result!;
  }

  /// 해제: 200 + result null. body는 파싱하지 않고 DioException이 없으면 성공이다.
  /// (평점 삭제와 달리 상태 코드 검사도 Dio 기본 validateStatus에 맡긴다)
  Future<void> deleteFavorite({required int movieId}) async {
    await _dio.delete('/v8/favorites/$movieId');
  }
}
