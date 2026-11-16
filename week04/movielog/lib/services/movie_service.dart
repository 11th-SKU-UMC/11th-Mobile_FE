import '../data/movie.dart';

/// 영화 목록을 가져오는 경계(boundary).
///
/// 화면은 이 타입만 알고, 데이터를 Mock에서 가져오는지 실제 서버에서 가져오는지는 모른다.
/// 5주차에는 이 인터페이스를 구현한 실제 API Service를 만들어 [FakeMovieService] 자리에 넣는다.
abstract interface class MovieService {
  /// 완료되면 영화 목록을 돌려주고, 실패하면 [MovieLoadException]으로 끝난다.
  Future<List<Movie>> fetchMovies();
}

/// 영화 목록을 불러오지 못했을 때의 예외.
///
/// [message]는 사용자에게 그대로 보여줘도 되는 문장만 담는다.
/// (StackTrace나 내부 오류 내용은 담지 않는다.)
class MovieLoadException implements Exception {
  const MovieLoadException(this.message);

  final String message;

  @override
  String toString() => 'MovieLoadException: $message';
}

/// [FakeMovieService]가 흉내 낼 응답 종류. Loading·Empty·Error·Success 화면 확인용.
enum MovieLoadMode {
  success('성공'),
  empty('빈 목록'),
  failure('실패'),

  /// 첫 요청은 실패하고, 다시 시도하면 성공한다. '오류 → 재시도 성공' 흐름 확인용.
  flaky('실패 후 재시도 성공'),

  /// 응답이 아주 늦게 온다. 화면의 Timeout 처리 확인용.
  slow('응답 지연(Timeout)');

  const MovieLoadMode(this.label);

  final String label;
}

/// 서버 없이 `Future.delayed`로 네트워크 요청을 흉내 내는 Mock Service.
class FakeMovieService implements MovieService {
  FakeMovieService({
    MovieLoadMode initialMode = MovieLoadMode.success,
    this.delay = defaultDelay,
    this.slowDelay = const Duration(seconds: 8),
  }) : _mode = initialMode;

  /// Loading 화면이 충분히 보이도록 1초 기다린다. (미션 기준: 800ms 이상)
  static const Duration defaultDelay = Duration(seconds: 1);

  /// 일반 응답까지 걸리는 시간. 테스트에서는 짧게 줄여서 넣는다.
  final Duration delay;

  /// [MovieLoadMode.slow]일 때 응답까지 걸리는 시간. 화면의 Timeout보다 길어야 한다.
  final Duration slowDelay;

  /// 화면의 테스트 메뉴에서 바꿀 수 있어서 setter를 따로 둔다. (아래 [mode])
  MovieLoadMode _mode;

  /// [MovieLoadMode.flaky]에서 이미 한 번 실패했는지.
  bool _flakyFailedOnce = false;

  MovieLoadMode get mode => _mode;

  /// 모드를 바꾸면 flaky 상태도 처음부터 다시 시작한다.
  set mode(MovieLoadMode value) {
    _mode = value;
    _flakyFailedOnce = false;
  }

  @override
  Future<List<Movie>> fetchMovies() async {
    await Future<void>.delayed(_mode == MovieLoadMode.slow ? slowDelay : delay);

    switch (_mode) {
      case MovieLoadMode.success:
      case MovieLoadMode.slow:
        return movies;
      case MovieLoadMode.empty:
        return const <Movie>[];
      case MovieLoadMode.failure:
        throw const MovieLoadException('영화를 불러오지 못했어요.');
      case MovieLoadMode.flaky:
        if (_flakyFailedOnce) return movies;
        _flakyFailedOnce = true;
        throw const MovieLoadException('영화를 불러오지 못했어요.');
    }
  }
}
