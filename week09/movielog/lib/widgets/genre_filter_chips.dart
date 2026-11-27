import 'package:flutter/material.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../theme/app_spacing.dart';

/// 영화 목록 상단의 가로 장르 칩 목록. '전체' 칩이 맨 앞에 온다.
///
/// 칩 이름과 id는 TMDB Genre API 결과를 그대로 쓴다.
/// 선택 상태는 부모가 [selectedGenreId]로 넘겨주고(null이면 '전체'),
/// 칩을 누르면 [onSelected]로 새 장르 id를 알려준다.
/// [enabled]가 false면(목록 Loading 중) 칩을 눌러도 아무 일도 없다.
class GenreFilterChips extends StatelessWidget {
  const GenreFilterChips({
    super.key,
    required this.genres,
    required this.selectedGenreId,
    required this.onSelected,
    this.enabled = true,
  });

  static const String allLabel = '전체';

  final List<TmdbGenreDto> genres;
  final int? selectedGenreId;
  final ValueChanged<int?> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // '전체'는 genreId null로 요청해서 with_genres를 보내지 않는다.
    final items = <(int?, String)>[
      (null, allLabel),
      for (final genre in genres) (genre.id, genre.name),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: items.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final (id, label) = items[index];

          return _GenrePill(
            label: label,
            selected: id == selectedGenreId,
            onTap: enabled ? () => onSelected(id) : null,
          );
        },
      ),
    );
  }
}

class _GenrePill extends StatelessWidget {
  const _GenrePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;

  /// null이면 비활성화.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final enabled = onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        button: true,
        enabled: enabled,
        selected: selected,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1 : 0.5,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md + 4),
            decoration: BoxDecoration(
              color: selected ? colors.primary : colors.secondaryContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                color: selected ? colors.onPrimary : colors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
