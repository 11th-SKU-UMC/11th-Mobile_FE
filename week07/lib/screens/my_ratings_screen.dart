import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/rating_dto.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/movielog_button.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

class MyRatingsScreen extends StatefulWidget {
  const MyRatingsScreen({super.key});

  @override
  State<MyRatingsScreen> createState() =>
      _MyRatingsScreenState();
}

class _MyRatingsScreenState
    extends State<MyRatingsScreen> {
  Future<void> _onEditPressed(
    BuildContext context,
    RatingDto rating,
  ) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        initialScore: rating.score,
        initialComment: rating.comment,
        onSubmit: (score, comment) =>
            context
                .read<MyRatingsViewModel>()
                .updateRating(
                  ratingId: rating.ratingId,
                  score: score,
                  comment: comment,
                ),
      ),
    );

    if (!context.mounted || saved != true) {
      return;
    }
  }

  Future<void> _onDeletePressed(
    BuildContext context,
    RatingDto rating,
  ) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteRatingDialog(
        onConfirm: () =>
            context
                .read<MyRatingsViewModel>()
                .deleteRating(
                  rating.ratingId,
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm =
        context.watch<MyRatingsViewModel>();

    final refreshWarning =
        vm.refreshWarning;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '내가 등록한 평점',
        ),
      ),
      body: Column(
        children: [
          if (refreshWarning != null)
            MaterialBanner(
              content: Text(
                refreshWarning,
              ),
              actions: [
                TextButton(
                  onPressed:
                      vm.loadRatings,
                  child: const Text(
                    '다시 조회',
                  ),
                ),
              ],
            ),

          Expanded(
            child: switch (vm.state) {
              MyRatingsState.idle ||
              MyRatingsState.loading =>
                const Center(
                  child:
                      CircularProgressIndicator(),
                ),

              MyRatingsState.empty =>
                const Center(
                  child: Text(
                    '등록한 평점이 없습니다.',
                  ),
                ),

              MyRatingsState.error =>
                Center(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      const Text(
                        '평점 목록을 불러오지 못했습니다.',
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      ElevatedButton(
                        onPressed:
                            vm.loadRatings,
                        child: const Text(
                          '다시 시도',
                        ),
                      ),
                    ],
                  ),
                ),

              MyRatingsState.success =>
                ListView.separated(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  itemCount:
                      vm.ratings.length,
                  separatorBuilder:
                      (_, _) =>
                          const SizedBox(
                    height: 16,
                  ),
                  itemBuilder:
                      (context, index) {
                    final item =
                        vm.ratings[index];

                    return Card(
                      child: Padding(
                        padding:
                            const EdgeInsets
                                .all(12),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            SizedBox(
                              width: 90,
                              height: 135,
                              child:
                                  TmdbPosterImage(
                                posterPath:
                                    item
                                        .movie
                                        .posterPath,
                              ),
                            ),

                            const SizedBox(
                              width: 16,
                            ),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    item.movie
                                        .title,
                                    style:
                                        const TextStyle(
                                      fontSize:
                                          18,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  Text(
                                    '내 평점: ${item.rating.score}점',
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  Text(
                                    item.rating
                                            .comment ??
                                        '작성한 코멘트가 없습니다.',
                                  ),

                                  const SizedBox(
                                    height: 12,
                                  ),

                                  Row(
                                    children: [
                                      OutlinedButton(
                                        onPressed:
                                            () {
                                          _onEditPressed(
                                            context,
                                            item.rating,
                                          );
                                        },
                                        child:
                                            const Text(
                                          '수정',
                                        ),
                                      ),

                                      const SizedBox(
                                        width: 8,
                                      ),

                                      OutlinedButton(
                                        onPressed:
                                            () {
                                          _onDeletePressed(
                                            context,
                                            item.rating,
                                          );
                                        },
                                        child:
                                            const Text(
                                          '삭제',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _DeleteRatingDialog
    extends StatefulWidget {
  const _DeleteRatingDialog({
    required this.onConfirm,
  });

  final Future<void> Function()
      onConfirm;

  @override
  State<_DeleteRatingDialog>
      createState() =>
          _DeleteRatingDialogState();
}

class _DeleteRatingDialogState
    extends State<
        _DeleteRatingDialog> {
  bool _isDeleting = false;

  @override
  Widget build(
    BuildContext context,
  ) {
    return PopScope(
      canPop: !_isDeleting,
      child: AlertDialog(
        title: const Text(
          '평점을 삭제할까요?',
        ),
        content: const Text(
          '삭제한 평점은 복구할 수 없습니다.',
        ),
        actions: [
          MovieLogButton(
            label: '취소',
            onPressed:
                _isDeleting
                    ? null
                    : () {
                        Navigator.pop(
                          context,
                          false,
                        );
                      },
          ),
          MovieLogButton(
            label: '삭제',
            isLoading:
                _isDeleting,
            onPressed:
                _isDeleting
                    ? null
                    : _onConfirm,
          ),
        ],
      ),
    );
  }

  Future<void> _onConfirm() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await widget.onConfirm();

      if (!mounted) return;

      Navigator.pop(
        context,
        true,
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            '삭제하지 못했습니다. 잠시 후 다시 시도해 주세요.',
          ),
        ),
      );
    }
  }
}