import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/movie_record_models.dart';

/// Challenge: 평점과 즐겨찾기를 한 트랜잭션으로 저장하는 `POST /v8/movie-records`를 호출합니다.
///
/// 서버는 둘 중 하나라도 실패하면 모두 저장하지 않습니다.
/// 이미 즐겨찾기한 영화에 addToFavorites=true를 보내면 평점도 저장되지 않습니다.
class MovieRecordApiService {
  MovieRecordApiService(this._authDio);

  final Dio _authDio;

  Future<MovieRecordResponseDto> createMovieRecord(
    CreateMovieRecordRequest request,
  ) async {
    final response = await _authDio.post(
      '/v8/movie-records',
      data: request.toJson(),
    );
    final body = CommonResponse<MovieRecordResponseDto>.fromJson(
      response.data as Map<String, dynamic>,
      MovieRecordResponseDto.fromJson,
    );
    final result = body.result;
    if (result == null) throw const FormatException('영화 기록 result가 없습니다.');
    return result;
  }
}
