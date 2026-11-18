import 'package:flutter/foundation.dart';

import '../data/models/rating_dto.dart';
import '../data/models/rating_with_movie.dart';
import '../data/services/api_error.dart';
import 'session_ratings.dart';

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._session) : _version = _session.version {
    _session.addListener(_onRatingsChanged);
  }

  final SessionRatings _session;
  final int _version;
  final Set<int> _selectedRatingIds = {};
  bool _disposed = false;
  bool isWriting = false;
  bool isDeletingSelected = false;
  bool isEditing = false;
  String? writeMessage;

  List<RatingWithMovie> get ratings => _session.entries;
  Set<int> get selectedRatingIds => Set.unmodifiable(_selectedRatingIds);
  int get selectedCount => _selectedRatingIds.length;
  bool get _active => !_disposed && _session.isCurrent(_version);

  void _onRatingsChanged() {
    _selectedRatingIds.retainAll(ratings.map((entry) => entry.rating.ratingId));
    if (ratings.isEmpty) isEditing = false;
    notifyListeners();
  }

  void toggleEditing() {
    if (isWriting) return;
    isEditing = !isEditing;
    _selectedRatingIds.clear();
    notifyListeners();
  }

  void toggleSelected(int ratingId) {
    if (!isEditing || isWriting) return;
    if (!_selectedRatingIds.add(ratingId)) _selectedRatingIds.remove(ratingId);
    notifyListeners();
  }

  Future<void> _write(Future<void> Function() action) async {
    if (!_active) return;
    if (isWriting) throw const ApiException('이미 처리 중입니다.');
    isWriting = true;
    notifyListeners();
    try {
      await action();
    } finally {
      if (_active) {
        isWriting = false;
        notifyListeners();
      }
    }
  }

  Future<void> updateRating(RatingDto rating, int score, String? comment) =>
      _write(() => _session.update(_version, rating, score, comment));

  Future<void> deleteRating(RatingDto rating) =>
      _write(() => _session.delete(_version, rating));

  Future<void> deleteSelectedRatings() => _write(() async {
    final selected = ratings
        .where((entry) => _selectedRatingIds.contains(entry.rating.ratingId))
        .toList();
    if (selected.isEmpty) return;
    isDeletingSelected = true;
    notifyListeners();
    final errors = <String>{};
    try {
      for (final entry in selected) {
        if (!_active) return;
        try {
          await _session.delete(_version, entry.rating);
        } catch (error) {
          if (_active) errors.add(ratingErrorMessage(error));
        }
      }
      if (!_active) return;
      writeMessage = errors.isEmpty ? '선택한 평점을 삭제했습니다.' : errors.join('\n');
      if (_selectedRatingIds.isEmpty) isEditing = false;
    } finally {
      if (_active) isDeletingSelected = false;
    }
  });

  @override
  void dispose() {
    _disposed = true;
    _session.removeListener(_onRatingsChanged);
    super.dispose();
  }
}
