import 'package:dio/dio.dart';

import '../models/movie_record_request.dart';
import '../models/movie_record_response_dto.dart';
import 'api_error.dart';

class MovieRecordApiService {
  MovieRecordApiService(this._authDio);

  final Dio _authDio;

  Future<MovieRecordResponseDto> create(MovieRecordRequest request) async {
    final response = await _authDio.post(
      '/v8/movie-records',
      data: request.toJson(),
    );
    return requireResult(response, 201, MovieRecordResponseDto.fromJson);
  }
}
