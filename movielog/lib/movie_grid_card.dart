import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/widgets/tmdb_poster_image.dart';

class MovieGridCard extends StatelessWidget {
  const MovieGridCard({super.key, required this.movie});

  final TmdbMovieDto movie;

  @override
  Widget build(BuildContext context) {
    final releaseDate = movie.releaseDate;
    final year = (releaseDate != null && releaseDate.length >= 4)
        ? releaseDate.substring(0, 4)
        : null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // TMDB id를 상세 화면으로 전달 (이후 평점 movieId로 사용)
      onTap: () => context.push('/movies/${movie.id}', extra: movie),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                // 포스터
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: TmdbPosterImage(posterPath: movie.posterPath),
                  ),
                ),
                // 오른쪽 위 평점 배지 (TMDB 평점은 10점 만점)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '★ ${movie.voteAverage.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          if (year != null)
            Text(
              year,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}
