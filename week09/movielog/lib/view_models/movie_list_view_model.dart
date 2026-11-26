import 'package:flutter/foundation.dart';

import '../core/utils/safe_notify.dart';
import '../data/models/tmdb_genre_dto.dart';
import '../data/services/genre_preference.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_phase.dart';
import 'paged_movies_view_model.dart';

/// 영화 목록 화면의 장르 목록·선택·저장을 담당합니다.
///
/// 5주차에는 이 ViewModel이 Discover를 여러 번 호출해 최대 30개를 모았지만,
/// 9주차부터 영화 목록은 [PagedMoviesViewModel]이 page 단위("더 보기")로 불러옵니다.
/// 장르가 바뀌면 [paged]의 첫 page부터 다시 요청합니다.
class MovieListViewModel extends ChangeNotifier with SafeNotify {
  MovieListViewModel(this._service, this._preference, this.paged);

  final TmdbMovieService _service;
  final GenrePreference _preference;
  final PagedMoviesViewModel paged;

  List<TmdbGenreDto> genres = const [];

  /// 비어 있으면 "전체"입니다.
  List<int> selectedGenreIds = const [];

  bool isLoadingGenres = false;
  String? genreMessage;

  /// 장르 목록을 받은 뒤에만 장르를 바꿀 수 있습니다.
  /// 목록을 불러오는 중이어도 바꿀 수 있고, 이전 장르의 늦은 응답은 [paged]가 무시합니다.
  bool get canChangeGenre => genres.isNotEmpty;

  Future<void> loadInitial() async {
    selectedGenreIds = await _readSavedGenres();
    await _loadGenres();
    if (isDisposed) return;
    await paged.loadInitial(genreIds: selectedGenreIds);
  }

  /// 장르 목록만 다시 불러옵니다. 영화 목록은 그대로 둡니다.
  Future<void> retryGenres() => _loadGenres();

  Future<void> _loadGenres() async {
    if (isLoadingGenres) return;
    isLoadingGenres = true;
    genreMessage = null;
    notifyIfAlive();
    try {
      final loaded = await _service.fetchGenres();
      if (isDisposed) return;
      genres = loaded;
      // 저장된 장르가 더 이상 존재하지 않으면 무시합니다.
      final validIds = genres.map((genre) => genre.id).toSet();
      selectedGenreIds = selectedGenreIds
          .where(validIds.contains)
          .toList(growable: false);
    } catch (_) {
      if (isDisposed) return;
      // 장르를 못 받아도 저장된 조건으로 영화 목록은 보여 줍니다.
      genreMessage = '장르를 불러오지 못했어요.';
    } finally {
      isLoadingGenres = false;
      notifyIfAlive();
    }
  }

  /// 장르 Chip·BottomSheet에서 호출합니다. 선택이 바뀌면 목록을 비우고 page 1부터 다시 요청합니다.
  Future<void> selectGenres(List<int> genreIds) async {
    if (!canChangeGenre) return;
    // 같은 조건을 이미 보여 주는 중이면 다시 요청하지 않습니다. 실패 상태면 다시 요청합니다.
    if (listEquals(genreIds, paged.condition.genreIds) &&
        paged.phase != LoadPhase.error &&
        paged.phase != LoadPhase.idle) {
      return;
    }

    selectedGenreIds = List.unmodifiable(genreIds);
    notifyIfAlive();
    try {
      await _preference.save(selectedGenreIds);
    } catch (error) {
      // 로컬 저장 실패는 목록 조회를 막지 않습니다.
      debugPrint('장르 저장 실패: $error');
    }
    if (isDisposed) return;
    await paged.loadInitial(genreIds: selectedGenreIds);
  }

  Future<List<int>> _readSavedGenres() async {
    try {
      return await _preference.read();
    } catch (error) {
      debugPrint('저장된 장르 읽기 실패: $error');
      return const [];
    }
  }
}
