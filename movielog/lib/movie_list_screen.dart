/* import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movielog/main_screen.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});


 */
import 'package:movielog/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movielog/main_screen.dart';
import 'package:movielog/ProfileScreens/AppBar/common_app_bar.dart';
import 'package:movielog/movie.dart';
import 'package:movielog/movie_grid_card.dart';
import 'package:movielog/movie_card.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final genres = ['전체', '드라마', 'SF', '애니메이션', '스릴러', '로맨스'];
  String selectedGenre = '전체';

  @override
  Widget build(BuildContext context) {
    // 선택된 장르에 맞는 영화만 골라내기
    final filteredMovies = selectedGenre == '전체'
        ? movies
        : movies.where((movie) => movie.genre == selectedGenre).toList();

    return Scaffold(
      appBar: CommonAppBar(title: '영화', titleStyle: AppTextStyles.titleAppBar),
      body: Column(
        children: [
          // 장르 칩 (가로 스크롤)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                for (final genre in genres) ...[
                  ChoiceChip(
                    label: Text(genre),
                    selected: selectedGenre == genre,
                    showCheckmark: false,
                    selectedColor: AppColors.primaryScale600,
                    backgroundColor: AppColors.primaryScale200,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selectedGenre == genre
                          ? Colors.white
                          : AppColors.primaryScale600,
                    ),
                    onSelected: (_) {
                      setState(() {
                        selectedGenre = genre;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          // 영화 그리드
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredMovies.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 20,
                childAspectRatio: 0.55,
              ),
              itemBuilder: (context, index) {
                return MovieGridCard(movie: filteredMovies[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
