import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// 장르 여러 개를 Checkbox로 고르는 BottomSheet 내용.
///
/// - 위아래로 드래그해 높이를 바꿀 수 있다. ([DraggableScrollableSheet])
/// - 장르 목록만 스크롤되고 '확인' 버튼은 항상 아래에 고정된다.
/// - 체크하는 동안에는 이 Sheet 안의 선택 상태만 바뀌고,
///   '확인'을 눌러야 선택값을 `Navigator.pop`으로 돌려준다.
///
/// 띄울 때는 [GenreFilterSheet.show]를 쓴다.
class GenreFilterSheet extends StatefulWidget {
  const GenreFilterSheet({
    super.key,
    required this.genres,
    required this.initialSelection,
  });

  final List<String> genres;
  final Set<String> initialSelection;

  /// Sheet를 띄우고, 확인을 누르면 선택한 장르 목록을 돌려준다.
  /// 바깥을 눌러 닫거나 아래로 내려 닫으면 null을 돌려준다.
  static Future<List<String>?> show(
    BuildContext context, {
    required List<String> genres,
    required Set<String> initialSelection,
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      // 하단 NavigationBar까지 덮도록 탭 Navigator가 아닌 root Navigator에 띄운다.
      useRootNavigator: true,
      // DraggableScrollableSheet가 화면 대부분까지 커질 수 있도록 허용한다.
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => GenreFilterSheet(
        genres: genres,
        initialSelection: initialSelection,
      ),
    );
  }

  @override
  State<GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<GenreFilterSheet> {
  late final Set<String> _selected = {...widget.initialSelection};

  void _toggle(String genre, bool checked) {
    setState(() {
      if (checked) {
        _selected.add(genre);
      } else {
        _selected.remove(genre);
      }
    });
  }

  void _confirm() {
    // 원래 장르 순서를 유지해서 돌려준다.
    final result = widget.genres.where(_selected.contains).toList();
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '장르 선택',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => setState(_selected.clear),
                    child: const Text('선택 해제'),
                  ),
                ],
              ),
            ),
            // 목록 영역만 남은 공간을 차지하고 스크롤된다.
            Expanded(
              child: ListView.builder(
                // 이 controller를 연결해야 목록 스크롤과 Sheet 드래그가 자연스럽게 이어진다.
                controller: scrollController,
                itemCount: widget.genres.length,
                itemBuilder: (context, index) {
                  final genre = widget.genres[index];
                  return CheckboxListTile(
                    value: _selected.contains(genre),
                    onChanged: (checked) => _toggle(genre, checked ?? false),
                    title: Text(genre),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                  );
                },
              ),
            ),
            // 확인 버튼은 스크롤 영역 밖이라 항상 아래에 보인다.
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _confirm,
                    child: Text(
                      _selected.isEmpty ? '확인 (전체 보기)' : '확인 (${_selected.length})',
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
