import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/data/models/favorite_check_dto.dart';
import 'package:movielog/data/models/favorite_response_dto.dart';
import 'package:movielog/data/services/favorite_api_service.dart';
import 'package:movielog/view_models/favorite_detail_view_model.dart';

/// 즐겨찾기 API 가짜. 네트워크·토큰 없이 정해둔 결과를 돌려주고 호출을 기록한다.
class _FakeFavoriteApi extends FavoriteApiService {
  _FakeFavoriteApi() : super(Dio());

  final List<String> calls = [];
  bool serverIsFavorite = false;
  Object? addError;
  Object? deleteError;
  Object? checkError;

  @override
  Future<FavoriteCheckDto> checkFavorite({required int movieId}) async {
    calls.add('GET $movieId');
    final error = checkError;
    if (error != null) throw error;
    return FavoriteCheckDto(movieId: movieId, isFavorite: serverIsFavorite);
  }

  @override
  Future<FavoriteResponseDto> addFavorite({required int movieId}) async {
    calls.add('POST $movieId');
    final error = addError;
    if (error != null) throw error;
    serverIsFavorite = true;
    return FavoriteResponseDto(
      favoriteId: 1,
      movieId: movieId,
      createdAt: DateTime.utc(2026, 9, 6),
    );
  }

  @override
  Future<void> deleteFavorite({required int movieId}) async {
    calls.add('DELETE $movieId');
    final error = deleteError;
    if (error != null) throw error;
    serverIsFavorite = false;
  }
}

/// 공통 오류 형식의 DioException. 요청 헤더는 만들지 않는다.
DioException _apiError(int status, String code) {
  final options = RequestOptions(path: '/v8/favorites');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: options,
      statusCode: status,
      data: {
        'isSuccess': false,
        'code': code,
        'message': '테스트',
        'result': null,
      },
    ),
  );
}

void main() {
  const movieId = 550;
  const email = 'tester@example.com';
  late _FakeFavoriteApi api;
  late SessionGuard guard;
  late FavoriteDetailViewModel vm;

  setUp(() {
    api = _FakeFavoriteApi();
    guard = SessionGuard()..startSession(email);
    vm = FavoriteDetailViewModel(
      movieId: movieId,
      favoriteApi: api,
      sessionGuard: guard,
      accountId: email,
    );
  });

  tearDown(() => vm.dispose());

  test('409(FAVORITE409_1)면 POST를 다시 보내지 않고 GET으로 서버 값(true)에 맞춘다', () async {
    await vm.load();
    expect(vm.isFavorite, isFalse);

    // 다른 기기에서 이미 등록된 상황
    api.serverIsFavorite = true;
    api.addError = _apiError(409, 'FAVORITE409_1');
    await vm.toggle();

    expect(api.calls, ['GET $movieId', 'POST $movieId', 'GET $movieId']);
    expect(vm.isFavorite, isTrue);
    expect(vm.errorMessage, isNull);
    expect(vm.isSaving, isFalse);
  });

  test(
    '404(FAVORITE404_1)면 DELETE를 다시 보내지 않고 GET으로 서버 값(false)에 맞춘다',
    () async {
      api.serverIsFavorite = true;
      await vm.load();
      expect(vm.isFavorite, isTrue);

      // 다른 기기에서 이미 해제된 상황
      api.serverIsFavorite = false;
      api.deleteError = _apiError(404, 'FAVORITE404_1');
      await vm.toggle();

      expect(api.calls, ['GET $movieId', 'DELETE $movieId', 'GET $movieId']);
      expect(vm.isFavorite, isFalse);
      expect(vm.errorMessage, isNull);
    },
  );

  test('409 뒤 동기화 GET까지 실패하면 이전 아이콘 상태를 유지하고 안내한다', () async {
    await vm.load();
    api.addError = _apiError(409, 'FAVORITE409_1');
    api.checkError = DioException(
      requestOptions: RequestOptions(path: '/v8/favorites/$movieId'),
      type: DioExceptionType.connectionTimeout,
    );
    await vm.toggle();

    expect(vm.isFavorite, isFalse);
    expect(vm.errorMessage, FavoriteDetailViewModel.syncFailedMessage);
  });

  test('다른 오류(500)는 GET 동기화 없이 이전 상태를 유지한다', () async {
    await vm.load();
    api.addError = _apiError(500, 'COMMON500');
    await vm.toggle();

    expect(api.calls, ['GET $movieId', 'POST $movieId']);
    expect(vm.isFavorite, isFalse);
    expect(vm.errorMessage, FavoriteDetailViewModel.addFailedMessage);
  });

  test('세션이 바뀐 뒤 도착한 409 동기화 결과는 반영하지 않는다', () async {
    await vm.load();
    api.serverIsFavorite = true;
    api.addError = _apiError(409, 'FAVORITE409_1');
    final toggling = vm.toggle();
    guard.invalidate(); // 로그아웃
    await toggling;

    expect(vm.isFavorite, isFalse);
    expect(api.calls, ['GET $movieId', 'POST $movieId']);
  });
}
