import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/movie_sort.dart';
import 'package:movielog/screens/movie_list_screen.dart';
import 'package:movielog/services/movie_service.dart';
import 'package:movielog/storage/movie_list_preferences.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/widgets/movie_grid.dart';
import 'package:movielog/widgets/movie_list_empty.dart';
import 'package:movielog/widgets/movie_list_error.dart';
import 'package:movielog/widgets/movie_list_loading.dart';

const _loadDelay = Duration(milliseconds: 100);

/// 기기 저장소 대신 메모리에 저장하는 가짜 설정 저장소.
class _MemoryPreferences implements MovieListPreferences {
  _MemoryPreferences({
    this.savedGenres = const [],
    this.savedSort = MovieSort.latest,
    this.readDelay = Duration.zero,
  });

  List<String> savedGenres;
  MovieSort savedSort;
  final Duration readDelay;

  @override
  Future<List<String>> readGenres() async {
    await Future<void>.delayed(readDelay);
    return savedGenres;
  }

  @override
  Future<void> saveGenres(List<String> genres) async {
    savedGenres = List.of(genres);
  }

  @override
  Future<MovieSort> readSort() async {
    await Future<void>.delayed(readDelay);
    return savedSort;
  }

  @override
  Future<void> saveSort(MovieSort sort) async {
    savedSort = sort;
  }

  @override
  Future<void> clear() async {
    savedGenres = const [];
    savedSort = MovieSort.latest;
  }
}

Future<void> _pumpMovieList(
  WidgetTester tester, {
  required FakeMovieService service,
  required _MemoryPreferences preferences,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/movies',
    routes: [
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) =>
            Scaffold(body: Text('상세 ${state.pathParameters['movieId']}')),
      ),
      GoRoute(
        path: '/movies',
        builder: (context, state) => MovieListScreen(
          selectedGenres: state.uri.queryParametersAll['genre'] ?? const [],
          movieService: service,
          preferences: preferences,
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
}

/// Mock 응답 시간이 지나고 화면이 안정될 때까지 진행한다.
Future<void> _finishLoading(WidgetTester tester) async {
  await tester.pump(_loadDelay + const Duration(milliseconds: 50));
  await tester.pumpAndSettle();
}

List<String> _visibleTitles(WidgetTester tester) => tester
    .widget<MovieGrid>(find.byType(MovieGrid))
    .movies
    .map((movie) => movie.title)
    .toList();

void main() {
  FakeMovieService service(MovieLoadMode mode) =>
      FakeMovieService(initialMode: mode, delay: _loadDelay);

  testWidgets('처음에는 Loading을 보여주고, 응답이 오면 영화 Grid를 보여준다', (tester) async {
    await _pumpMovieList(
      tester,
      service: service(MovieLoadMode.success),
      preferences: _MemoryPreferences(),
    );
    await tester.pump();

    expect(find.byType(MovieListLoading), findsOneWidget);
    expect(find.byType(MovieGrid), findsNothing);

    await _finishLoading(tester);

    expect(find.byType(MovieListLoading), findsNothing);
    expect(find.byType(MovieGrid), findsOneWidget);
    expect(find.text('별빛 아래 우리'), findsOneWidget);
  });

  testWidgets('빈 목록이 오면 빈 Grid 대신 Empty 안내를 보여준다', (tester) async {
    await _pumpMovieList(
      tester,
      service: service(MovieLoadMode.empty),
      preferences: _MemoryPreferences(),
    );
    await _finishLoading(tester);

    expect(find.byType(MovieListEmpty), findsOneWidget);
    expect(find.text('아직 등록된 영화가 없어요.'), findsOneWidget);
    expect(find.byType(MovieGrid), findsNothing);
  });

  testWidgets('실패하면 Error 화면을 보여주고 내부 예외 내용은 노출하지 않는다', (tester) async {
    await _pumpMovieList(
      tester,
      service: service(MovieLoadMode.failure),
      preferences: _MemoryPreferences(),
    );
    await _finishLoading(tester);

    expect(find.byType(MovieListError), findsOneWidget);
    expect(find.textContaining('영화를 불러오지 못했어요'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('다시 시도를 누르면 Loading부터 다시 시작해서 성공 화면을 보여준다', (tester) async {
    await _pumpMovieList(
      tester,
      service: service(MovieLoadMode.flaky),
      preferences: _MemoryPreferences(),
    );
    await _finishLoading(tester);
    expect(find.byType(MovieListError), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    await tester.pump();

    expect(find.byType(MovieListLoading), findsOneWidget);
    expect(find.byType(MovieListError), findsNothing);

    await _finishLoading(tester);

    expect(find.byType(MovieGrid), findsOneWidget);
  });

  testWidgets('계속 실패하면 재시도 후에도 다시 Error 화면을 보여준다', (tester) async {
    await _pumpMovieList(
      tester,
      service: service(MovieLoadMode.failure),
      preferences: _MemoryPreferences(),
    );
    await _finishLoading(tester);

    await tester.tap(find.text('다시 시도'));
    // 탭 직후 한 프레임을 그려야 새 FutureBuilder가 새 Future를 구독한다.
    // 이 pump 없이 시간을 먼저 넘기면, 구독 전에 실패가 끝나서 처리되지 않은 예외로 잡힌다.
    await tester.pump();
    expect(find.byType(MovieListLoading), findsOneWidget);

    await _finishLoading(tester);

    expect(find.byType(MovieListError), findsOneWidget);
  });

  testWidgets('응답이 5초 안에 오지 않으면 Timeout 안내를 보여준다', (tester) async {
    await _pumpMovieList(
      tester,
      service: FakeMovieService(
        initialMode: MovieLoadMode.slow,
        slowDelay: const Duration(seconds: 10),
      ),
      preferences: _MemoryPreferences(),
    );

    await tester.pump(const Duration(seconds: 4));
    expect(find.byType(MovieListLoading), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.byType(MovieListError), findsOneWidget);
    expect(find.textContaining('응답이 늦어지고 있어요'), findsOneWidget);

    // 늦게 도착하는 Mock 응답 타이머까지 끝내서 테스트가 깨끗하게 끝나게 한다.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('저장된 장르와 정렬이 있으면 앱을 다시 켰을 때 그대로 복원한다', (tester) async {
    final preferences = _MemoryPreferences(
      savedGenres: ['드라마'],
      savedSort: MovieSort.rating,
    );
    await _pumpMovieList(
      tester,
      service: service(MovieLoadMode.success),
      preferences: preferences,
    );
    await _finishLoading(tester);

    // 드라마 장르만, 평점 높은 순서로 보인다.
    expect(_visibleTitles(tester), ['별빛 아래 우리', '네 번째 오후']);
  });

  testWidgets('장르 칩을 누르면 목록이 바뀌고 선택값이 저장된다', (tester) async {
    final preferences = _MemoryPreferences();
    await _pumpMovieList(
      tester,
      service: service(MovieLoadMode.success),
      preferences: preferences,
    );
    await _finishLoading(tester);

    await tester.tap(find.text('SF'));
    await tester.pumpAndSettle();

    expect(_visibleTitles(tester), ['우주의 끝에서']);
    expect(preferences.savedGenres, ['SF']);

    await tester.tap(find.text('전체'));
    await tester.pumpAndSettle();

    expect(_visibleTitles(tester), hasLength(6));
    expect(preferences.savedGenres, isEmpty);
  });

  testWidgets('저장된 장르가 지금 Mock 데이터에 없는 장르면 무시한다', (tester) async {
    await _pumpMovieList(
      tester,
      service: service(MovieLoadMode.success),
      preferences: _MemoryPreferences(savedGenres: ['없는 장르']),
    );
    await _finishLoading(tester);

    expect(find.byType(MovieGrid), findsOneWidget);
    expect(_visibleTitles(tester), hasLength(6));
  });

  testWidgets('불러오는 도중 화면이 사라져도 setState 오류가 나지 않는다', (tester) async {
    await _pumpMovieList(
      tester,
      service: service(MovieLoadMode.success),
      preferences: _MemoryPreferences(
        savedGenres: ['SF'],
        readDelay: const Duration(milliseconds: 300),
      ),
    );
    await tester.pump();

    // 영화 목록과 저장값을 기다리는 중에 화면을 없앤다.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });
}
