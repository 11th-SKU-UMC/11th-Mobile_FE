import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/view_models/favorite_detail_view_model.dart';

// 영화 상세의 제목/정보 텍스트 오른쪽에 두는 북마크 버튼입니다.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key});

  // 3주차처럼 Snackbar로 결과를 안내합니다. 문구는 서버 요청 결과를 따릅니다.
  Future<void> _toggle(BuildContext context, FavoriteDetailViewModel vm) async {
    await vm.toggle();
    if (!context.mounted || vm.isDisposed) return;
    final message =
        vm.errorMessage ?? (vm.isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteDetailViewModel>(
      builder: (context, vm, _) {
        final busy = vm.isLoading || vm.isSaving;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.SecondaryScale300),
              ),
              child: busy
                  // 요청 중에는 북마크 자리에만 로딩을 보여 줍니다.
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
                      color: AppColors.primary,
                      tooltip: vm.isFavorite ? '즐겨찾기 해제' : '즐겨찾기 등록',
                      onPressed: vm.hasLoadedStatus
                          ? () => _toggle(context, vm)
                          : null,
                      icon: Icon(
                        vm.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                        size: 30,
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            const Text(
              '즐겨찾기',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            // 첫 여부 조회에 실패했을 때만 새로고침 버튼을 보여 줍니다.
            if (!vm.hasLoadedStatus && !vm.isLoading)
              SizedBox(
                width: 62,
                child: IconButton(
                  tooltip: '여부 다시 확인',
                  color: AppColors.primary,
                  onPressed: vm.load,
                  icon: const Icon(Icons.refresh),
                ),
              ),
          ],
        );
      },
    );
  }
}
