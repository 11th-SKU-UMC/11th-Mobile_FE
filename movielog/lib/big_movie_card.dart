import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/movie.dart';

class BigMovieCard extends StatelessWidget {
  const BigMovieCard({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 440,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. 배경 포스터
            Image.asset(
              movie.posterAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.black87),
            ),
            // 2. 아래쪽 어둡게
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
            // 3. 글씨와 버튼
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B3E9C),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '추천 신작',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    movie.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${movie.genre} · ${movie.year}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      // path parameter를 이용하여 영화 상세 페이지로 이동
                      onPressed: () {
                        context.push('/movies/${movie.id}');
                      },
                      child: const Text(
                        '상세보기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      /*  icon: const Icon(Icons.info, color: Colors.white),
                      label: const Text(
                        '상세보기', */

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B3E9C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
