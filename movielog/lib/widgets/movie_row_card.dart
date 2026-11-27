import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/widgets/tmdb_poster_image.dart';

// 내 즐겨찾기·검색 결과에서 쓰는 가로형 영화 카드 (포스터 + 제목 + 보조 문구)
class MovieRowCard extends StatelessWidget {
  const MovieRowCard({
    super.key,
    required this.title,
    required this.posterPath,
    this.subtitle,
    this.tag,
    this.action,
    this.onTap,
    this.showPoster = true,
  });

  final String title;
  final String? posterPath;
  final String? subtitle;
  final String? tag; // 보라색 강조 문구 (예: 즐겨찾기한 영화)
  final Widget? action; // 카드 안 추가 버튼 (예: 정보 다시 불러오기)
  final VoidCallback? onTap;
  final bool showPoster; // false면 placeholder 상자

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.NeutralScale600, width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: showPoster
                      ? TmdbPosterImage(
                          posterPath: posterPath,
                          width: 78,
                          height: 116,
                        )
                      : Container(
                          width: 78,
                          height: 116,
                          color: AppColors.primaryScale100,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.NeutralScale800,
                          ),
                        ),
                      ],
                      if (tag != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          tag!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                      if (action != null) action!,
                    ],
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
