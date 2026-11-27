import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../view_models/favorite_detail_view_model.dart';

/// 영화 상세의 제목·정보 오른쪽에 두는 북마크 버튼.
///
/// 조회·저장 중에는 북마크 자리에만 인디케이터를 보여주고, 결과는 Snackbar로 안내한다.
/// 첫 여부 조회에 실패하면 아래에 새로고침 버튼을 보여준다.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key});

  static const String addedMessage = '즐겨찾기에 추가했습니다.';
  static const String removedMessage = '즐겨찾기에서 삭제했습니다.';

  Future<void> _toggle(BuildContext context, FavoriteDetailViewModel vm) async {
    final before = vm.isFavorite;
    await vm.toggle();
    if (!context.mounted) return;
    // 세션 만료로 정리된 경우처럼 바뀐 것도 오류도 없으면 안내하지 않는다.
    final message =
        vm.errorMessage ??
        (vm.isFavorite == before
            ? null
            : (vm.isFavorite ? addedMessage : removedMessage));
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Consumer<FavoriteDetailViewModel>(
      builder: (context, vm, _) {
        final busy = vm.isLoading || vm.isSaving;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: busy
                  ? const Center(
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : IconButton(
                      tooltip: vm.isFavorite ? '즐겨찾기 해제' : '즐겨찾기 추가',
                      color: AppColors.primary,
                      onPressed: vm.hasLoadedStatus
                          ? () => _toggle(context, vm)
                          : null,
                      icon: Icon(
                        vm.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                      ),
                    ),
            ),
            Text('즐겨찾기', style: textTheme.labelSmall),
            // 첫 여부 조회에 실패했을 때만 다시 확인 버튼을 보여준다.
            if (!vm.hasLoadedStatus && !vm.isLoading)
              IconButton(
                tooltip: '여부 다시 확인',
                color: AppColors.primary,
                onPressed: vm.load,
                icon: const Icon(Icons.refresh),
              ),
          ],
        );
      },
    );
  }
}
