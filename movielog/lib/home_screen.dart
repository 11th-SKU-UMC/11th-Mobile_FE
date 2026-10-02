import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movielog/main_screen.dart';
import 'package:movielog/ProfileScreens/AppBar/common_app_bar.dart';
import 'package:movielog/movie.dart';
import 'package:movielog/movie_card.dart';
import 'package:movielog/big_movie_card.dart';

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

                BigMovieCard(movie: movies[0]),
                const SizedBox(height: 20),

                const Text(
                  '인기 영화',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 230,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: movies.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) =>
                        MovieCard(movie: movies[index]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
