// Movie Class를 작성한다.
class Movie {
  const Movie({required this.nickname, this.title});
  final String nickname;
  final String? title;
}

// 영화 3개를 List<Movie>에 넣는다.
List<Movie> movies = [
  Movie(nickname: "무비러버1", title: "너의 이름은"),
  Movie(nickname: "무비러버2", title: "노트북"),
  Movie(nickname: "무비러버3", title: "극장판 귀멸의 칼날: 무한성편"),
];

void runPractice() {
  const movie = Movie(nickname: "예진", title: '별빛 아래 우리');
  print(movie.title);

  // for 또는 map으로 제목 출력
  for (var m in movies) {
    print(m.title);
  }
}
