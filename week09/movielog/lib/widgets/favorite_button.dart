import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/favorite_detail_view_model.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FavoriteDetailViewModel>();
    final favorite = viewModel.isFavorite == true;
    final busy = viewModel.isLoading || viewModel.isSaving;
    final label = viewModel.needsCheck && !busy
        ? '즐겨찾기 다시 확인'
        : favorite
        ? '즐겨찾기 해제'
        : '즐겨찾기 추가';

    return IconButton(
      tooltip: label,
      onPressed: viewModel.canToggle
          ? () async {
              final message = await viewModel.toggle();
              if (!context.mounted || message == null) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(message),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
            }
          : null,
      icon: busy
          ? const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                semanticsLabel: '즐겨찾기 요청 중',
              ),
            )
          : Icon(
              favorite ? Icons.bookmark : Icons.bookmark_border,
              color: viewModel.errorMessage == null
                  ? null
                  : Theme.of(context).colorScheme.error,
            ),
    );
  }
}
