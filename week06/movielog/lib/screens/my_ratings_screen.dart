import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_text_styles.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_list_error.dart';
import '../widgets/movie_list_loading.dart';
import '../widgets/rating_card.dart';

/// 마이페이지 → 내가 등록한 평점.
/// root Navigator 위에 push되므로 하단 NavigationBar를 전달하지 않습니다.
/// 6주차 조회 대상은 로그인 사용자가 아니라 학습용 memberId 1입니다.
class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '내가 등록한 평점',
        centerTitle: true,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/my');
          }
        },
      ),
      body: SafeArea(
        child: Consumer<MyRatingsViewModel>(
          builder: (context, viewModel, child) {
            switch (viewModel.status) {
              case MyRatingsLoadStatus.idle:
              case MyRatingsLoadStatus.loading:
                return const MovieListLoading();
              case MyRatingsLoadStatus.error:
                return MovieListError(
                  onRetry: viewModel.load,
                  message: viewModel.message,
                );
              case MyRatingsLoadStatus.empty:
                return const _EmptyRatings();
              case MyRatingsLoadStatus.success:
                return _RatingList(viewModel: viewModel);
            }
          },
        ),
      ),
    );
  }
}

class _EmptyRatings extends StatelessWidget {
  const _EmptyRatings();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('아직 등록한 평점이 없습니다.'));
  }
}

class _RatingList extends StatelessWidget {
  const _RatingList({required this.viewModel});

  final MyRatingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final message = viewModel.message; // 일부 영화 정보 조회 실패 안내
    final ratings = viewModel.ratings;
    final hasNotice = message != null;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: ratings.length + (hasNotice ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (hasNotice && index == 0) {
          return Text(message, style: AppTextStyles.bodySmall);
        }
        final entry = ratings[hasNotice ? index - 1 : index];
        return RatingCard(entry: entry);
      },
    );
  }
}
