import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../view_models/movie_home_view_model.dart';
import '../widgets/featured_movie_card.dart';
import '../widgets/popular_movie_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'MovieLog',
                          style: textTheme.titleLarge?.copyWith(
                            color: AppColors.violet,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.search,
                            color: AppColors.violet,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '오늘은 어떤\n영화를 볼까요?',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 상단 큰 카드: 성공했을 때만 인기 1위 영화를 보여준다.
                    Consumer<MovieHomeViewModel>(
                      builder: (context, vm, child) {
                        if (vm.status == MovieHomeLoadStatus.success) {
                          return FeaturedMovieCard(movie: vm.popularMovies.first);
                        }
                        return AspectRatio(
                          aspectRatio: 4 / 5,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.gray.withAlpha(51),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Center(
                              child: vm.status == MovieHomeLoadStatus.loading ||
                                      vm.status == MovieHomeLoadStatus.idle
                                  ? const CircularProgressIndicator()
                                  : const Icon(
                                      Icons.movie_outlined,
                                      color: AppColors.gray,
                                      size: 40,
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Text(
                          '인기 영화',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => context.go('/movies'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.violet,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('전체보기'),
                              Icon(Icons.chevron_right, size: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              // 인기 영화 목록: 4가지 상태를 여기서 분기한다.
              SizedBox(
                height: 270,
                child: Consumer<MovieHomeViewModel>(
                  builder: (context, vm, child) {
                    return switch (vm.status) {
                      MovieHomeLoadStatus.idle ||
                      MovieHomeLoadStatus.loading =>
                        const Center(child: CircularProgressIndicator()),
                      MovieHomeLoadStatus.error => _HomeMessage(
                          message: vm.message ?? '오류가 발생했어요.',
                          onRetry: () =>
                              context.read<MovieHomeViewModel>().loadPopular(),
                        ),
                      MovieHomeLoadStatus.empty =>
                        const _HomeMessage(message: '표시할 영화가 없어요.'),
                      MovieHomeLoadStatus.success => ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: vm.popularMovies.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            return PopularMovieCard(
                              movie: vm.popularMovies[index],
                              rank: index + 1,
                            );
                          },
                        ),
                    };
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeMessage extends StatelessWidget {
  const _HomeMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}