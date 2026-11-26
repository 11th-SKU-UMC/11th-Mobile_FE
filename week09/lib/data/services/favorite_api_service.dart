import 'package:dio/dio.dart';

import '../models/favorite_check_dto.dart';
import '../models/favorite_response_dto.dart';

class FavoriteApiService {
  FavoriteApiService(this._dio);

  final Dio _dio;

  Future<FavoriteResponseDto> createFavorite({
    required int movieId,
  }) async {
    final response = await _dio.post(
      '/v8/favorites',
      data: {
        'movieId': movieId,
      },
    );

    final result = _extractResult(response.data);

    return FavoriteResponseDto.fromJson(result);
  }

  Future<List<FavoriteResponseDto>> getFavorites() async {
    final response = await _dio.get(
      '/v8/favorites',
    );

    final result = _extractResult(response.data);

    if (result is! List) {
      throw const FormatException(
        'Favorites result must be a list.',
      );
    }

    return result
        .map(
          (item) => FavoriteResponseDto.fromJson(item),
        )
        .toList();
  }

  Future<FavoriteCheckDto> checkFavorite({
    required int movieId,
  }) async {
    final response = await _dio.get(
      '/v8/favorites/$movieId',
    );

    final result = _extractResult(response.data);

    return FavoriteCheckDto.fromJson(
      result,
      movieId: movieId,
    );
  }

  Future<void> deleteFavorite({
    required int movieId,
  }) async {
    await _dio.delete(
      '/v8/favorites/$movieId',
    );
  }

  Object? _extractResult(Object? data) {
    if (data is! Map<String, Object?>) {
      throw const FormatException(
        'Response must be a JSON object.',
      );
    }

    return data['result'];
  }
}