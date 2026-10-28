import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// 영화 목록 상단의 가로 장르 칩 목록. '전체' 칩이 맨 앞에 온다.
///
/// 선택 상태는 부모가 [selectedGenres]로 넘겨주고,
/// 칩을 누르면 [onSelected]로 새 선택값을 알려준다. ('전체'는 빈 목록)
class GenreFilterChips extends StatelessWidget {
  const GenreFilterChips({
    super.key,
    required this.genres,
    required this.selectedGenres,
    required this.onSelected,
  });

  static const String allLabel = '전체';

  final List<String> genres;
  final Set<String> selectedGenres;
  final ValueChanged<List<String>> onSelected;

  @override
  Widget build(BuildContext context) {
    final labels = [allLabel, ...genres];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: labels.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final label = labels[index];
          final isAll = label == allLabel;
          final isSelected =
              isAll ? selectedGenres.isEmpty : selectedGenres.contains(label);

          return _GenrePill(
            label: label,
            selected: isSelected,
            onTap: () => onSelected(isAll ? const [] : [label]),
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
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        button: true,
        selected: selected,
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
    );
  }
}
