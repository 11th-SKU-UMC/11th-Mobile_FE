import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movielog/theme/app_text_styles.dart';
import 'package:movielog/ProfileScreens/AppBar/common_app_bar.dart';
import 'package:movielog/movie_card.dart';
import 'package:movielog/big_movie_card.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CommonAppBar(
        title: 'MovieLog',
        titleStyle: AppTextStyles.titleAppBar,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '오늘은 어떤 \n영화 볼까요?',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),

                // ViewModel 상태가 바뀌면 이 영역만 다시 그려짐
                Consumer<MovieHomeViewModel>(
                  builder: (context, viewModel, child) {
                    return switch (viewModel.status) {
                      MovieHomeLoadStatus.idle ||
                      MovieHomeLoadStatus.loading => const SizedBox(
                        height: 300,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      MovieHomeLoadStatus.error => SizedBox(
                        height: 300,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline),
                              const SizedBox(height: 12),
                              Text(viewModel.message ?? '오류가 발생했어요.'),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: () => context
                                    .read<MovieHomeViewModel>()
                                    .loadPopular(),
                                child: const Text('다시 시도'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      MovieHomeLoadStatus.empty => const SizedBox(
                        height: 300,
                        child: Center(child: Text('인기 영화가 없어요.')),
                      ),
                      MovieHomeLoadStatus.success => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BigMovieCard(movie: viewModel.popularMovies.first),
                          const SizedBox(height: 20),
                          const Text(
                            '인기 영화',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 230,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: viewModel.popularMovies.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) => MovieCard(
                                movie: viewModel.popularMovies[index],
                              ),
                            ),
                          ),
                        ],
                      ),
                    };
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
