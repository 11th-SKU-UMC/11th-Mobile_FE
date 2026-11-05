import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/my_ratings_view_model.dart';
import '../widgets/tmdb_poster_image.dart';

class MyRatingsScreen extends StatefulWidget {
  const MyRatingsScreen({super.key});

  @override
  State<MyRatingsScreen> createState() => _MyRatingsScreenState();
}

class _MyRatingsScreenState extends State<MyRatingsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyRatingsViewModel>().loadRatings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyRatingsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('내가 등록한 평점'),
      ),
      body: switch (vm.state) {
        MyRatingsState.idle ||
        MyRatingsState.loading =>
          const Center(
            child: CircularProgressIndicator(),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '평점 목록을 불러오지 못했습니다.',
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: vm.loadRatings,
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),

        MyRatingsState.success =>
          ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: vm.ratings.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = vm.ratings[index];

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 135,
                        child: TmdbPosterImage(
                          posterPath:
                              item.movie.posterPath,
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.movie.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              '내 평점: ${item.rating.score}점',
                            ),

                            const SizedBox(height: 8),

                            Text(
                              item.rating.comment ??
                                  '작성한 코멘트가 없습니다.',
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
    );
  }
}