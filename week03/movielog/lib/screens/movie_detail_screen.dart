import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../widgets/rating_dialog.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movie});

  final Movie movie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isFavorite = false;
  double? _myRating;

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _showRatingDialog() async {
    final rating = await showDialog<double>(
      context: context,
      builder: (context) => RatingDialog(initialRating: _myRating ?? 3),
    );

    if (rating == null || !mounted) return;
    setState(() => _myRating = rating);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('평점 ${rating.toStringAsFixed(1)}점을 저장했습니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Cinema Archive',
          style: TextStyle(
            color: AppColors.violet,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('공유 기능은 준비 중입니다.')));
            },
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 0.68,
                child: Image.asset(movie.posterAsset, fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${movie.year} · ${movie.genre} · 124분',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: movie.rating,
                          itemCount: 5,
                          itemSize: 19,
                          unratedColor: colors.outline.withValues(alpha: 0.35),
                          itemBuilder: (context, _) =>
                              Icon(Icons.star, color: colors.primary),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          movie.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(1,245)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (_myRating != null) ...[
                          const Spacer(),
                          Text(
                            '내 평점 ${_myRating!.toStringAsFixed(1)}',
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const _MovieTag(label: '로맨스'),
                        _MovieTag(label: movie.genre),
                        const _MovieTag(label: '감동적인'),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(height: 1, color: Color(0xFFE7E0EC)),
                    ),
                    Text(
                      '시놉시스',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      movie.synopsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _toggleFavorite,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              side: BorderSide(color: colors.primary),
                            ),
                            icon: Icon(
                              _isFavorite
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                            ),
                            label: Text(_isFavorite ? '즐겨찾기 해제' : '즐겨찾기'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _showRatingDialog,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                            ),
                            icon: const Icon(Icons.rate_review_outlined),
                            label: Text(_myRating == null ? '평점 남기기' : '평점 수정'),
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
      ),
    );
  }
}

class _MovieTag extends StatelessWidget {
  const _MovieTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFECE9E6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
