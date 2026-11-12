import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/movie.dart';
import '../data/movie_sort.dart';
import '../router/app_router.dart';
import '../services/movie_service.dart';
import '../storage/movie_list_preferences.dart';
import '../theme/app_spacing.dart';
import '../widgets/genre_filter_chips.dart';
import '../widgets/genre_filter_sheet.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_empty.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/movie_list_loading.dart';
import '../widgets/tab_app_bar.dart';

/// 영화 목록 탭.
///
/// - 영화 목록은 [MovieService]가 돌려주는 Future로 비동기로 불러오고,
///   Loading·Empty·Error·Success 네 상태를 각각 다른 Widget으로 보여준다.
/// - 선택한 장르는 3주차처럼 URL의 Query Parameter(`/movies?genre=SF`)가 기준이다.
///   URL이 바뀔 때마다 로컬에 저장하고, 앱을 다시 켜면 저장된 장르를 URL로 되돌린다.
class MovieListScreen extends StatefulWidget {
  const MovieListScreen({
    super.key,
    required this.selectedGenres,
    this.movieService,
    this.preferences,
  });

  final List<String> selectedGenres;

  /// 테스트에서 가짜 Service를 넣기 위한 자리. null이면 기본 Service를 쓴다.
  final MovieService? movieService;

  /// 테스트에서 가짜 저장소를 넣기 위한 자리. null이면 기기 저장소를 쓴다.
  final MovieListPreferences? preferences;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  /// 이 시간 안에 응답이 없으면 Timeout 오류 화면을 보여준다.
  static const Duration _loadTimeout = Duration(seconds: 5);

  // TODO(5주차 유저별 평점 조회 API): FakeMovieService를 Swagger의 실제 API Service로 교체한다.
  // 화면은 MovieService 인터페이스만 알기 때문에 이 한 줄만 바꾸면 된다.
  late final MovieService _movieService =
      widget.movieService ?? FakeMovieService();

  late final MovieListPreferences _preferences =
      widget.preferences ?? MovieListPreferences();

  /// FutureBuilder가 관찰하는 Future. build가 아니라 initState·재시도·새로고침에서만 새로 만든다.
  late Future<List<Movie>> _moviesFuture;

  /// 재시도할 때 올려서 FutureBuilder를 새로 만든다.
  /// (같은 FutureBuilder에 새 Future만 주면 이전 결과가 남아 있어서 Loading 화면이 안 보일 수 있다.)
  int _loadGeneration = 0;

  MovieSort _sort = MovieSort.latest;

  /// 저장값 복원이 끝나기 전에 사용자가 직접 필터·정렬을 바꿨는지.
  /// 바꿨다면 늦게 도착한 저장값으로 덮어쓰지 않는다.
  bool _userChangedSettings = false;

  @override
  void initState() {
    super.initState();
    _moviesFuture = _fetchMovies();
    // 영화 목록과 저장된 설정은 서로 기다릴 필요가 없으므로 동시에 시작한다.
    unawaited(_restoreSettings());
  }

  @override
  void didUpdateWidget(covariant MovieListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Query Parameter만 바뀌면 go_router는 이 State를 그대로 두고 새 장르 목록만 넘겨준다.
    // 칩·BottomSheet·홈의 '전체보기' 등 어디서 바꿨든 여기서 한 번에 저장한다.
    if (!listEquals(oldWidget.selectedGenres, widget.selectedGenres)) {
      unawaited(_saveSafely(() => _preferences.saveGenres(widget.selectedGenres)));
    }
  }

  Future<List<Movie>> _fetchMovies() async {
    try {
      return await _movieService.fetchMovies().timeout(_loadTimeout);
    } catch (error, stackTrace) {
      // 개발자용 기록만 남기고 다시 던진다. 화면에는 FutureBuilder가 오류 상태로 보여준다.
      debugPrint('영화 목록 로드 실패: $error');
      debugPrintStack(stackTrace: stackTrace, maxFrames: 5);
      rethrow;
    }
  }

  /// 마지막으로 선택한 장르와 정렬을 불러와 적용한다.
  Future<void> _restoreSettings() async {
    try {
      // 두 값은 서로 의존하지 않으므로 Future.wait처럼 동시에 읽는다.
      // (Record의 .wait는 결과 타입을 그대로 유지해 줘서 형변환이 필요 없다.)
      final (savedGenres, savedSort) = await (
        _preferences.readGenres(),
        _preferences.readSort(),
      ).wait;

      // await 하는 사이에 화면이 사라졌다면 setState·context를 쓰면 안 된다.
      if (!mounted) return;
      if (_userChangedSettings) return;

      setState(() => _sort = savedSort);

      // URL에 이미 장르가 있으면(직접 연 링크 등) URL을 우선한다.
      final genres = savedGenres.where(movieGenres.contains).toList();
      if (widget.selectedGenres.isNotEmpty || genres.isEmpty) return;
      context.go(AppRoutes.moviesWithGenres(genres));
    } catch (error, stackTrace) {
      // 저장값을 못 읽어도 기본값(전체·최신순)으로 보여주면 되므로 화면에는 알리지 않는다.
      debugPrint('영화 목록 설정 복원 실패: $error');
      debugPrintStack(stackTrace: stackTrace, maxFrames: 5);
    }
  }

  Future<void> _saveSafely(Future<void> Function() save) async {
    try {
      await save();
    } catch (error) {
      // 저장 실패는 다음 실행 때 기본값으로 보일 뿐이라 화면을 막지 않는다.
      debugPrint('영화 목록 설정 저장 실패: $error');
    }
  }

  /// 오류 화면의 '다시 시도'와 테스트용 모드 변경. Loading 화면부터 다시 보여준다.
  void _reload() {
    setState(() {
      _loadGeneration++;
      _moviesFuture = _fetchMovies();
    });
  }

  /// 당겨서 새로고침. 새 결과가 올 때까지 지금 목록을 그대로 보여준다.
  Future<void> _refresh() async {
    final future = _fetchMovies();
    setState(() => _moviesFuture = future);
    try {
      await future;
    } catch (_) {
      // 오류 화면은 FutureBuilder가 보여준다. 여기서는 새로고침 표시만 끝낸다.
    }
  }

  void _applyGenres(List<String> genres) {
    _userChangedSettings = true;
    // go: 같은 탭 안에서 Query Parameter만 바꾼다. (저장은 didUpdateWidget에서)
    context.go(AppRoutes.moviesWithGenres(genres));
  }

  void _changeSort(MovieSort sort) {
    _userChangedSettings = true;
    setState(() => _sort = sort);
    unawaited(_saveSafely(() => _preferences.saveSort(sort)));
  }

  void _changeLoadMode(FakeMovieService service, MovieLoadMode mode) {
    service.mode = mode;
    _reload();
  }

  Future<void> _openFilterSheet() async {
    final result = await GenreFilterSheet.show(
      context,
      genres: movieGenres,
      initialSelection: widget.selectedGenres.toSet(),
    );
    // 바깥을 눌러 닫았거나(null) 그사이 화면이 사라졌으면 아무것도 하지 않는다.
    if (result == null || !mounted) return;

    _applyGenres(result);
    // BottomSheet가 닫힌 뒤에 Snackbar를 띄워야 Sheet 뒤에 가려지지 않는다.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.isEmpty
                ? '전체 영화를 보여드려요.'
                : '${result.join(', ')} 장르만 보여드려요.',
          ),
        ),
      );
  }

  /// 사용자에게 보여줄 문장으로 바꾼다. Exception 이름이나 StackTrace는 보여주지 않는다.
  String _errorMessage(Object? error) {
    return switch (error) {
      TimeoutException() => '응답이 늦어지고 있어요.\n잠시 후 다시 시도해주세요.',
      MovieLoadException(:final message) => '$message\n잠시 후 다시 시도해주세요.',
      _ => '영화를 불러오지 못했어요.\n잠시 후 다시 시도해주세요.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final movieService = _movieService;

    return Scaffold(
      appBar: TabAppBar(
        title: '영화',
        actions: [
          // 개발 중에만 보이는 메뉴. Loading·Empty·Error 화면을 직접 확인할 때 쓴다.
          if (kDebugMode && movieService is FakeMovieService)
            _LoadModeMenu(
              current: movieService.mode,
              onSelected: (mode) => _changeLoadMode(movieService, mode),
            ),
          _SortMenu(current: _sort, onSelected: _changeSort),
          IconButton(
            tooltip: '장르 필터',
            onPressed: _openFilterSheet,
            icon: Badge(
              isLabelVisible: widget.selectedGenres.isNotEmpty,
              label: Text('${widget.selectedGenres.length}'),
              child: const Icon(Icons.filter_list),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          GenreFilterChips(
            genres: movieGenres,
            selectedGenres: widget.selectedGenres.toSet(),
            onSelected: _applyGenres,
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: FutureBuilder<List<Movie>>(
              key: ValueKey(_loadGeneration),
              future: _moviesFuture,
              builder: _buildContent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AsyncSnapshot<List<Movie>> snapshot,
  ) {
    final isDone = snapshot.connectionState == ConnectionState.done;

    // 1) Loading: 처음 불러오는 중이거나 재시도 중.
    //    당겨서 새로고침 중에는 이전 목록(snapshot.data)이 남아 있으므로 목록을 계속 보여준다.
    if (!isDone && !snapshot.hasData) {
      return const MovieListLoading();
    }

    // 2) Error: done이어도 데이터가 있다는 뜻은 아니므로 오류를 먼저 확인한다.
    if (isDone && snapshot.hasError) {
      return MovieListError(
        message: _errorMessage(snapshot.error),
        onRetry: _reload,
      );
    }

    final loaded = snapshot.data ?? const <Movie>[];
    final visible = sortMovies(
      filterMoviesByGenres(widget.selectedGenres, from: loaded),
      _sort,
    );

    // 3) Empty: 받아온 목록이 비었거나, 선택한 장르에 맞는 영화가 없음.
    if (visible.isEmpty) {
      final filtered = loaded.isNotEmpty;
      return RefreshIndicator(
        onRefresh: _refresh,
        child: MovieListEmpty(
          message: filtered ? '조건에 맞는 영화가 없어요.' : '아직 등록된 영화가 없어요.',
          actionLabel: filtered ? '전체 영화 보기' : null,
          onAction: filtered ? () => _applyGenres(const []) : null,
        ),
      );
    }

    // 4) Success
    return RefreshIndicator(
      onRefresh: _refresh,
      child: MovieGrid(
        movies: visible,
        // push: 목록을 Stack에 남겨서 상세에서 뒤로 가면 같은 필터의 목록으로 돌아온다.
        onMovieTap: (movie) => context.push(AppRoutes.movieDetail(movie.id)),
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.current, required this.onSelected});

  final MovieSort current;
  final ValueChanged<MovieSort> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MovieSort>(
      tooltip: '정렬: ${current.label}',
      icon: const Icon(Icons.sort),
      initialValue: current,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final sort in MovieSort.values)
          CheckedPopupMenuItem(
            value: sort,
            checked: sort == current,
            child: Text(sort.label),
          ),
      ],
    );
  }
}

class _LoadModeMenu extends StatelessWidget {
  const _LoadModeMenu({required this.current, required this.onSelected});

  final MovieLoadMode current;
  final ValueChanged<MovieLoadMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MovieLoadMode>(
      tooltip: '로딩 상태 테스트',
      icon: const Icon(Icons.science_outlined),
      initialValue: current,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final mode in MovieLoadMode.values)
          CheckedPopupMenuItem(
            value: mode,
            checked: mode == current,
            child: Text(mode.label),
          ),
      ],
    );
  }
}
