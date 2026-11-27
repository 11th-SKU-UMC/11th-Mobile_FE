import 'package:flutter/material.dart';

/// TMDB `poster_path`(또는 `backdrop_path`)로 이미지를 그린다.
///
/// API는 파일 경로만 주므로 이미지 base URL과 size를 붙여야 한다.
/// 경로가 없거나 로드에 실패하면 placeholder를 보여준다.
/// [width]·[height]를 생략하면 부모 크기를 따른다.
class TmdbPosterImage extends StatelessWidget {
  const TmdbPosterImage({
    super.key,
    required this.posterPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String? posterPath;
  final double? width;
  final double? height;
  final BoxFit fit;

  static const String _baseUrl = 'https://image.tmdb.org/t/p';
  static const String _size = 'w500';

  String? get _imageUrl {
    final path = posterPath;
    if (path == null || path.isEmpty) return null;
    return '$_baseUrl/$_size$path';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl;

    if (imageUrl == null) return _placeholder(context);

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: height,
      color: colors.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.image_not_supported_outlined, color: colors.outline),
    );
  }
}
