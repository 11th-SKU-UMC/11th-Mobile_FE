/// 3주차 Mock 영화 데이터.
///
/// 홈·목록·상세가 모두 이 파일의 [movies]만 읽는다.
/// 화면마다 따로 하드코딩하지 않아서 같은 ID는 어디서든 같은 영화를 가리킨다.
class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.posterAsset,
    required this.runtimeMinutes,
    required this.averageRating,
    required this.ratingCount,
    required this.tags,
    required this.synopsis,
    this.backdropAsset,
  });

  final int id;
  final String title;

  /// 목록 필터에 쓰는 대표 장르.
  final String genre;
  final int year;
  final String posterAsset;

  /// 상세 화면 상단에 쓰는 가로 이미지. 없으면 포스터를 대신 쓴다.
  final String? backdropAsset;
  final int runtimeMinutes;
  final double averageRating;
  final int ratingCount;

  /// 상세 화면의 태그 칩.
  final List<String> tags;
  final String synopsis;

  String get headerImage => backdropAsset ?? posterAsset;
}

const String _posterDir = 'assets/images/posters';

const List<Movie> movies = [
  Movie(
    id: 1,
    title: '별빛 아래 우리',
    genre: '드라마',
    year: 2024,
    posterAsset: '$_posterDir/hero_under_the_starlight.jpg',
    backdropAsset: '$_posterDir/hero_under_the_starlight.jpg',
    runtimeMinutes: 124,
    averageRating: 4.5,
    ratingCount: 1245,
    tags: ['로맨스', '드라마', '감동적인'],
    synopsis:
        '바쁜 현대 사회 속에서 서로의 존재를 잊고 살아가던 두 남녀가 우연한 계기로 '
        '작은 천문대에서 만나게 됩니다. 매일 밤 별을 관측하며 서로의 상처를 치유하고, '
        '잊고 있던 꿈과 사랑을 다시금 깨닫게 되는 따뜻한 이야기입니다.\n\n'
        '과거의 아픔으로 인해 사람에게 마음을 열지 못하던 여주인공은, 별자리처럼 '
        '변함없는 모습으로 자신을 기다려주는 남주인공을 통해 서서히 마음의 문을 열게 '
        '됩니다. 하지만 두 사람 앞에 놓인 현실적인 장벽들은 그들의 관계를 시험하게 '
        '되는데...\n\n'
        '별이 쏟아지는 밤하늘 아래, 그들이 나눈 조용한 약속들은 과연 영원할 수 '
        '있을까요? 눈부신 영상미와 감성적인 OST가 어우러져 깊은 여운을 남기는 올 '
        '겨울 최고의 로맨스 영화.',
  ),
  Movie(
    id: 2,
    title: '우주의 끝에서',
    genre: 'SF',
    year: 2024,
    posterAsset: '$_posterDir/poster_echoes_of_the_void.jpg',
    runtimeMinutes: 138,
    averageRating: 4.2,
    ratingCount: 892,
    tags: ['SF', '우주', '미스터리'],
    synopsis:
        '인류의 마지막 탐사선이 도착한 미지의 행성. 홀로 남겨진 우주비행사는 '
        '모래 폭풍 너머에서 정체불명의 신호를 발견합니다. 그 신호가 가리키는 곳에는 '
        '지구로 돌아갈 단 하나의 길이 숨겨져 있었습니다.',
  ),
  Movie(
    id: 3,
    title: '기억의 숲',
    genre: '애니메이션',
    year: 2024,
    posterAsset: '$_posterDir/poster_whispering_woods.jpg',
    runtimeMinutes: 102,
    averageRating: 4.9,
    ratingCount: 2310,
    tags: ['애니메이션', '판타지', '가족'],
    synopsis:
        '할머니 댁 뒷산의 오래된 숲에 들어간 소녀는 사람들의 잊힌 기억을 모으는 '
        '작은 정령을 만납니다. 정령과 함께 숲을 지키며 소녀는 자신이 잃어버린 '
        '소중한 기억을 하나씩 되찾아 갑니다.',
  ),
  Movie(
    id: 4,
    title: '밤의 그림자',
    genre: '스릴러',
    year: 2024,
    posterAsset: '$_posterDir/poster_night_shadows.jpg',
    runtimeMinutes: 117,
    averageRating: 3.8,
    ratingCount: 654,
    tags: ['스릴러', '범죄', '누아르'],
    synopsis:
        '비 내리는 도시의 뒷골목, 연쇄 실종 사건을 쫓던 형사는 모든 사건 현장에 '
        '남겨진 같은 그림자를 발견합니다. 진실에 가까워질수록 그림자는 점점 그를 '
        '향해 다가옵니다.',
  ),
  Movie(
    id: 5,
    title: '어비스 워커',
    genre: '액션',
    year: 2023,
    posterAsset: '$_posterDir/poster_abyss_walker.jpg',
    runtimeMinutes: 131,
    averageRating: 4.0,
    ratingCount: 1032,
    tags: ['액션', '어드벤처', '심해'],
    synopsis:
        '심해 기지가 정체불명의 존재에게 공격받고, 마지막 남은 잠수부가 동료들을 '
        '구하기 위해 빛이 닿지 않는 심연으로 내려갑니다.',
  ),
  Movie(
    id: 6,
    title: '네 번째 오후',
    genre: '드라마',
    year: 2023,
    posterAsset: '$_posterDir/poster_fourth_afternoon.jpg',
    runtimeMinutes: 109,
    averageRating: 4.3,
    ratingCount: 478,
    tags: ['드라마', '일상', '잔잔한'],
    synopsis:
        '매주 목요일 오후, 같은 카페 같은 자리에 앉는 두 사람. 말 한마디 나눈 적 '
        '없는 그들 사이에 네 번째 오후, 작은 변화가 찾아옵니다.',
  ),
];

/// 홈 상단에 크게 보여주는 추천 영화.
const int featuredMovieId = 1;

/// 목록의 장르 칩과 필터 BottomSheet에 쓰는 장르 목록. Mock 데이터 순서를 따른다.
final List<String> movieGenres = {
  for (final movie in movies) movie.genre,
}.toList();

Movie? findMovieById(int? id) {
  for (final movie in movies) {
    if (movie.id == id) return movie;
  }
  return null;
}

/// [genres]가 비어 있으면 전체 목록을, 아니면 해당 장르의 영화만 돌려준다.
List<Movie> filterMoviesByGenres(Iterable<String> genres) {
  final selected = genres.toSet();
  if (selected.isEmpty) return movies;
  return movies.where((movie) => selected.contains(movie.genre)).toList();
}
