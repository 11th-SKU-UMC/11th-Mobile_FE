import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/favorite_detail_view_model.dart';

// 기존 영화 상세의 제목/정보 텍스트 오른쪽에 넣습니다. RatingDialog는 그대로 둡니다.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key});

  // 3주차처럼 Snackbar로 결과를 안내합니다. 문구는 서버 요청 결과를 따릅니다.
  Future<void> _toggle(
    BuildContext context,
    FavoriteDetailViewModel vm,
  ) async {
    await vm.toggle();
    if (!context.mounted) return;
    final message = vm.errorMessage ??
        (vm.isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteDetailViewModel>(
      builder: (context, vm, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 62,
              height: 64,
              child: vm.isLoading || vm.isSaving
                  ? const Center(
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF6750A4),
                        ),
                      ),
                    )
                  : IconButton(
                      color: const Color(0xFF6750A4),
                      onPressed: vm.hasLoadedStatus
                          ? () => _toggle(context, vm)
                          : null,
                      icon: Icon(
                        vm.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                      ),
                    ),
            ),
            const Text('즐겨찾기'),
            // 첫 여부 조회에 실패했을 때만 북마크와 같은 너비의 새로고침 버튼을 보여 줍니다.
            if (!vm.hasLoadedStatus && !vm.isLoading)
              SizedBox(
                width: 62,
                child: IconButton(
                  tooltip: '여부 다시 확인',
                  color: const Color(0xFF6750A4),
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
