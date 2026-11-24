import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/favorite_check_dto.dart';
import '../models/favorite_response_dto.dart';

// MovieLog 즐겨찾기 API(/v8/favorites)를 호출합니다.
// 보호용 MovieLog Dio(JWT Interceptor 포함)를 주입받아 사용합니다.
class FavoriteApiService {
  FavoriteApiService(this._dio);

  final Dio _dio;

  // 즐겨찾기 등록: 201, result에 FavoriteResponseDto가 담깁니다.
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

  // 내 즐겨찾기 조회: 200, result가 배열입니다. 없으면 빈 배열입니다.
  Future<List<FavoriteResponseDto>> fetchMyFavorites() async {
    final response = await _dio.get('/v8/favorites');
    final body = CommonResponse<List<FavoriteResponseDto>>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => (value as List<dynamic>)
          .map(FavoriteResponseDto.fromJson)
          .toList(),
    );
    return body.result ?? const [];
  }

  // 특정 영화의 즐겨찾기 여부 조회: 응답에 movieId가 없어서 요청한 값을 함께 넘깁니다.
  Future<FavoriteCheckDto> checkFavorite({required int movieId}) async {
    final response = await _dio.get('/v8/favorites/$movieId');
    final body = CommonResponse<FavoriteCheckDto>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => FavoriteCheckDto.fromJson(value, movieId: movieId),
    );
    return body.result!;
  }

  // 즐겨찾기 해제: 200, result는 null입니다. 평점 삭제의 204와 다릅니다.
  // 응답 body를 파싱하지 않고, DioException이 없으면 성공입니다.
  Future<void> deleteFavorite({required int movieId}) async {
    await _dio.delete('/v8/favorites/$movieId');
  }
}
