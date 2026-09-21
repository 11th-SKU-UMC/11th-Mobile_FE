import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../theme/app_spacing.dart';
import '../widgets/common_app_bar.dart';

/// 별점 입력 상태만 다루는 미니 실습 화면. 실제 저장(API)은 연결하지 않는다.
class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  static const int _maxStars = 5;

  double _rating = 0;

  bool get _hasRating => _rating > 0;

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('평점 $_rating점을 저장했어요.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const CommonAppBar(title: '평점 남기기'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/posters/poster_abyss_walker.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Abyss Walker',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: RatingBar.builder(
                  initialRating: _rating,
                  minRating: 0.5,
                  itemCount: _maxStars,
                  itemSize: 40,
                  allowHalfRating: true,
                  glow: false,
                  unratedColor: colors.outlineVariant,
                  itemBuilder: (context, index) =>
                      Icon(Icons.star_rounded, color: colors.primary),
                  onRatingUpdate: (rating) => setState(() => _rating = rating),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _hasRating ? '$_rating / $_maxStars' : '별점을 선택해주세요',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _hasRating ? _save : null,
                  style: ElevatedButton.styleFrom(
                    textStyle: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('평점 저장'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
