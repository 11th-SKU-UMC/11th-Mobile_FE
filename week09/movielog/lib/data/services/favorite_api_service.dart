import 'package:dio/dio.dart';

import '../models/favorite_check_dto.dart';
import '../models/favorite_response_dto.dart';
import 'api_error.dart';

class FavoriteApiService {
  FavoriteApiService(this._authDio);

  final Dio _authDio;
  static const _path = '/v8/favorites';

  Future<FavoriteResponseDto> add(int movieId) async {
    final response = await _authDio.post(_path, data: {'movieId': movieId});
    return requireResult(response, 201, FavoriteResponseDto.fromJson);
  }

  Future<List<FavoriteResponseDto>> fetchMine() async {
    final response = await _authDio.get(_path);
    final result = requireWriteResponse(response, 200);
    if (result is! List) {
      throw const ApiException('즐겨찾기 목록 응답 형식이 올바르지 않습니다.');
    }
    return [
      for (final item in result)
        FavoriteResponseDto.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<FavoriteCheckDto> check(int movieId) async {
    final response = await _authDio.get('$_path/$movieId');
    return requireResult(
      response,
      200,
      (json) => FavoriteCheckDto.fromJson(json, movieId: movieId),
    );
  }

  Future<void> remove(int movieId) async {
    final response = await _authDio.delete('$_path/$movieId');
    if (requireWriteResponse(response, 200) != null) {
      throw const ApiException('즐겨찾기 해제 응답 형식이 올바르지 않습니다.');
    }
  }
}
