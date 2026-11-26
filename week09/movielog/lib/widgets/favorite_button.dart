import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../view_models/favorite_detail_view_model.dart';

/// 영화 상세의 제목·정보 오른쪽에 두는 북마크 버튼입니다.
///
/// - 첫 여부 조회·등록·해제 중에는 북마크 자리에만 CircularProgressIndicator를 보여 줍니다.
/// - 결과는 Snackbar로 안내하고, 실패하면 이전 아이콘을 유지합니다.
/// - 첫 여부 조회에 실패하면 북마크 대신 새로고침 버튼으로 다시 확인합니다.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key});

  Future<void> _toggle(BuildContext context, FavoriteDetailViewModel vm) async {
    await vm.toggle();
    // 세션 만료는 로그인 화면이 안내하므로 여기서는 Snackbar를 띄우지 않습니다.
    if (!context.mounted || vm.sessionExpired) return;
    final message =
        vm.errorMessage ?? (vm.isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteDetailViewModel>(
      builder: (context, vm, _) {
        final Widget icon;
        if (vm.isBusy) {
          icon = const Center(
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          );
        } else if (!vm.hasLoadedStatus) {
          icon = IconButton(
            tooltip: '즐겨찾기 여부 다시 확인',
            color: AppColors.primary,
            onPressed: vm.load,
            icon: const Icon(Icons.refresh),
          );
        } else {
          icon = IconButton(
            tooltip: vm.isFavorite ? '즐겨찾기 해제' : '즐겨찾기 추가',
            color: AppColors.primary,
            onPressed: () => _toggle(context, vm),
            icon: Icon(vm.isFavorite ? Icons.bookmark : Icons.bookmark_border),
          );
        }

        return SizedBox(
          width: 62,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 48, child: icon),
              Text(
                vm.hasLoadedStatus || vm.isBusy ? '즐겨찾기' : '다시 확인',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
