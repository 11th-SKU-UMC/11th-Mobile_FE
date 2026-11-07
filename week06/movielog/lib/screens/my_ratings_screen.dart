import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_with_movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';
import '../widgets/tmdb_poster_image.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '내가 등록한 평점',
        centerTitle: true,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: Consumer<MyRatingsViewModel>(
          builder: (context, viewModel, child) {
            return switch (viewModel.status) {
              MyRatingsLoadStatus.idle || MyRatingsLoadStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              MyRatingsLoadStatus.empty => const Center(
                child: Text('등록된 평점이 없습니다.'),
              ),
              MyRatingsLoadStatus.error => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        viewModel.message ?? '평점을 불러오지 못했습니다.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      MovieLogButton(
                        label: '다시 시도',
                        width: 120,
                        onPressed: viewModel.load,
                      ),
                    ],
                  ),
                ),
              ),
              MyRatingsLoadStatus.success => ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: viewModel.ratings.length + 1,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '학습용 회원 1의 샘플 평점입니다.',
                          style: AppTextStyles.bodySmall,
                        ),
                        if (viewModel.message != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            viewModel.message!,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ],
                    );
                  }
                  return _RatingCard(entry: viewModel.ratings[index - 1]);
                },
              ),
            };
          },
        ),
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.entry});

  final RatingWithMovie entry;

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final date = rating.createdAt.toLocal();
    final dateText =
        '${date.year}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TmdbPosterImage(
              posterPath: entry.movie?.posterPath,
              width: 80,
              height: 120,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.movie?.title ?? '영화 정보 없음 · ${rating.movieId}',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.violet, size: 20),
                    const SizedBox(width: 4),
                    Text('${rating.score}점', style: AppTextStyles.bodyMedium),
                  ],
                ),
                if (rating.comment != null) ...[
                  const SizedBox(height: 8),
                  Text(rating.comment!, style: AppTextStyles.bodyMedium),
                ],
                const SizedBox(height: 8),
                Text(dateText, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
