import 'package:flutter/material.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../theme/app_colors.dart';

class GenreFilterSheet extends StatefulWidget {
  const GenreFilterSheet({
    super.key,
    required this.genres,
    required this.initialSelected,
  });

  /// Genre API로 받은 장르 (id/name)
  final List<TmdbGenreDto> genres;

  /// 처음 체크되어 있을 장르 ID
  final Set<int> initialSelected;

  @override
  State<GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<GenreFilterSheet> {
  late final Set<int> _selected = {...widget.initialSelected};

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.warmWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.gray.withAlpha(100),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '장르 필터',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '여러 장르를 선택할 수 있어요. 아무것도 선택하지 않으면 전체 영화를 보여줘요.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.gray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final genre in widget.genres)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.violet,
                        title: Text(genre.name),
                        value: _selected.contains(genre.id),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selected.add(genre.id);
                            } else {
                              _selected.remove(genre.id);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.gray.withAlpha(60)),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(context, Set<int>.of(_selected)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.violet,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          '확인',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}