import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'movie_grid.dart';

/// 영화 목록 Loading 상태.
///
/// 빙글빙글 도는 표시 대신, 실제 카드와 같은 자리에 회색 카드(Skeleton)를 깜빡이며 보여준다.
/// 데이터가 들어왔을 때 화면 배치가 크게 바뀌지 않아서 덜 어색하다.
class MovieListLoading extends StatefulWidget {
  const MovieListLoading({super.key});

  static const int _skeletonCount = 4;

  @override
  State<MovieListLoading> createState() => _MovieListLoadingState();
}

class _MovieListLoadingState extends State<MovieListLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.45,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    // 화면에서 사라질 때 반복 애니메이션을 멈추지 않으면 계속 프레임을 요청한다.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '영화 목록을 불러오는 중',
      liveRegion: true,
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: _opacity,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: movieGridPadding,
            itemCount: MovieListLoading._skeletonCount,
            gridDelegate: movieGridDelegate,
            itemBuilder: (context, index) => const _SkeletonCard(),
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    Widget bar({required double widthFactor, required double height}) {
      return FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        bar(widthFactor: 0.8, height: 18),
        const SizedBox(height: AppSpacing.xs + 2),
        bar(widthFactor: 0.5, height: 14),
      ],
    );
  }
}
