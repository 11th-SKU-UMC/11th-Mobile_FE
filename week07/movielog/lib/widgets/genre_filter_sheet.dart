import 'package:flutter/material.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../theme/app_text_styles.dart';
import 'movielog_button.dart';

/// 드래그로 높이를 조절할 수 있는 장르 다중 선택 BottomSheet입니다.
/// Checkbox를 바꾸는 동안에는 Sheet 내부 상태만 바뀌고, 확인을 눌러야 선택값을 반환합니다.
Future<List<int>?> showGenreFilterSheet(
  BuildContext context, {
  required List<TmdbGenreDto> genres,
  required List<int> selectedIds,
}) {
  return showModalBottomSheet<List<int>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) => _GenreFilterSheet(
        genres: genres,
        initialSelectedIds: selectedIds,
        scrollController: scrollController,
      ),
    ),
  );
}

class _GenreFilterSheet extends StatefulWidget {
  const _GenreFilterSheet({
    required this.genres,
    required this.initialSelectedIds,
    required this.scrollController,
  });

  final List<TmdbGenreDto> genres;
  final List<int> initialSelectedIds;
  final ScrollController scrollController;

  @override
  State<_GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<_GenreFilterSheet> {
  late final Set<int> _selected = widget.initialSelectedIds.toSet();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Expanded(
                child: Text('장르 선택', style: AppTextStyles.titleMedium),
              ),
              TextButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () => setState(_selected.clear),
                child: const Text('전체 해제'),
              ),
            ],
          ),
        ),
        // 목록 영역만 스크롤되고 확인 버튼은 하단에 고정됩니다.
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: widget.genres.length,
            itemBuilder: (context, index) {
              final genre = widget.genres[index];
              return CheckboxListTile(
                dense: true,
                value: _selected.contains(genre.id),
                title: Text(genre.name),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (checked) {
                  setState(() {
                    if (checked ?? false) {
                      _selected.add(genre.id);
                    } else {
                      _selected.remove(genre.id);
                    }
                  });
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: MovieLogButton(
            label: _selected.isEmpty ? '전체 보기' : '${_selected.length}개 장르 적용',
            width: double.infinity,
            onPressed: () => Navigator.of(context).pop(
              // Genre API 순서를 유지합니다.
              widget.genres
                  .map((genre) => genre.id)
                  .where(_selected.contains)
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
