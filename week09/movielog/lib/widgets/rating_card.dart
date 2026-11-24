import 'package:flutter/material.dart';

import '../data/models/rating_with_movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'tmdb_poster_image.dart';

/// 평점 한 건과 TMDB 영화 정보를 보여주는 카드.
/// entry.movie가 null이면 제목·포스터 대신 placeholder를 표시하고 평점은 유지합니다.
/// - onEdit/onDelete가 있으면 카드 오른쪽에 개별 수정·삭제 버튼을 보여줍니다.
/// - onSelectedChanged가 있으면 다중 선택 모드로, 버튼 대신 체크박스를 보여줍니다.
class RatingCard extends StatelessWidget {
  const RatingCard({
    super.key,
    required this.entry,
    this.onEdit,
    this.onDelete,
    this.isSelected = false,
    this.onSelectedChanged,
  });

  final RatingWithMovie entry;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isSelected;
  final ValueChanged<bool>? onSelectedChanged;

  static String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}.$month.$day';
  }

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final movie = entry.movie;
    final comment = rating.comment?.trim(); // null이면 표시하지 않습니다.
    final selectionMode = onSelectedChanged != null;

    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.violet
              : AppColors.gray.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TmdbPosterImage(
              posterPath: movie?.posterPath,
              width: 64,
              height: 96,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie?.title ?? '영화 정보를 불러오지 못했습니다',
                  style: AppTextStyles.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (movie == null)
                  Text(
                    '영화 ID ${rating.movieId}',
                    style: AppTextStyles.bodySmall,
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, size: 18, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('${rating.score}', style: AppTextStyles.bodyMedium),
                  ],
                ),
                if (comment != null && comment.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    comment,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  _formatDate(rating.createdAt),
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          if (selectionMode)
            Checkbox(
              value: isSelected,
              activeColor: AppColors.violet,
              onChanged: (value) => onSelectedChanged!(value ?? false),
            )
          else if (onEdit != null || onDelete != null)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null)
                  IconButton(
                    tooltip: '수정',
                    visualDensity: VisualDensity.compact,
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.violet,
                    ),
                  ),
                if (onDelete != null)
                  IconButton(
                    tooltip: '삭제',
                    visualDensity: VisualDensity.compact,
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.gray,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );

    if (!selectionMode) return card;

    // 다중 선택 모드에서는 카드 어디를 눌러도 선택이 바뀝니다.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelectedChanged!(!isSelected),
      child: card,
    );
  }
}
