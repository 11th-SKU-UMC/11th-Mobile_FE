import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common_app_bar.dart';

/// 영화 한 편에 대한 평점을 남기는 화면.
///
/// 사용 예:
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute(
///     builder: (_) => const RatingScreen(
///       movieTitle: '영화제목',
///       posterAssetPath: 'assets/images/interstellar.jpg',
///     ),
///   ),
/// );
/// ```
class RatingScreen extends StatefulWidget {
  const RatingScreen({
    super.key,
    required this.movieTitle,
    required this.posterAssetPath,
  });

  /// 평점을 남길 영화 제목
  final String movieTitle;

  /// assets 폴더 안의 포스터 이미지 경로
  final String posterAssetPath;

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double _rating = 0;

  bool get _canSubmit => _rating > 0;

  void _handleSubmit() {
    // TODO: 실제 저장 로직(로컬 DB, API 등)은 이후 단계에서 연결합니다.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('평점 ${_rating.toStringAsFixed(1)}점이 저장되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '평점 남기기',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MoviePoster(assetPath: widget.posterAssetPath),
              const SizedBox(height: 16),
              Text(
                widget.movieTitle,
                style: AppTextStyles.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Text(
                '이 영화, 어떠셨나요?',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Center(
                child: RatingBar.builder(
                  initialRating: _rating,
                  minRating: 0,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: 40,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 2),
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: AppColors.violet,
                  ),
                  onRatingUpdate: (value) {
                    setState(() => _rating = value);
                  },
                ),
              ),
              const SizedBox(height: 32),
              _SaveButton(
                enabled: _canSubmit,
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 영화 포스터 이미지
class _MoviePoster extends StatelessWidget {
  const _MoviePoster({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppColors.gray.withOpacity(0.2),
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.gray,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}

/// 평점 저장 버튼 (별점 선택 전에는 비활성화)
class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.violet,
          disabledBackgroundColor: AppColors.violet.withOpacity(0.4),
          foregroundColor: AppColors.white,
          disabledForegroundColor: AppColors.white.withOpacity(0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          '평점 저장',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.white),
        ),
      ),
    );
  }
}
