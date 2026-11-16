import 'movie.dart';

/// 영화 목록 정렬 방식. 마지막 선택값을 로컬에 저장한다.
enum MovieSort {
  latest('최신순'),
  rating('평점순'),
  title('제목순');

  const MovieSort(this.label);

  final String label;

  /// 저장된 문자열(enum 이름)을 되돌린다. 모르는 값이면 기본값(최신순).
  static MovieSort fromName(String? name) =>
      MovieSort.values.asNameMap()[name] ?? MovieSort.latest;
}

/// [source]를 [sort] 기준으로 정렬한 새 목록을 돌려준다. 원본은 바꾸지 않는다.
List<Movie> sortMovies(List<Movie> source, MovieSort sort) {
  final sorted = [...source];
  switch (sort) {
    case MovieSort.latest:
      // 개봉 연도가 같으면 ID 순서로 고정해서 결과가 매번 같게 한다.
      sorted.sort((a, b) {
        final byYear = b.year.compareTo(a.year);
        return byYear != 0 ? byYear : a.id.compareTo(b.id);
      });
    case MovieSort.rating:
      sorted.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    case MovieSort.title:
      sorted.sort((a, b) => a.title.compareTo(b.title));
  }
  return sorted;
}
