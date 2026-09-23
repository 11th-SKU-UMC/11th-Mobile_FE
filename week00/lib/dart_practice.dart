// ignore_for_file: avoid_print

void main() {
    final String appName = 'MovieLog';
    const int currentWeek = 0;
    var isReady = false;

    final DateTime now = DateTime.now();

    isReady = true;   // O 같은 bool 타입으로 재대입 가능

    print(appName);
    print(currentWeek);
    print(isReady);
    print(now);

    print(greeting(name: '케이'));
    print(greeting(name: '케이', week: 3));

    final genres = <String>['드라마', 'SF', '애니메이션'];

    final profile = <String, Object>{
        'nickname': '무비러버',
        'week': 0,
    };

    print(genres);
    print(genres[0]);
    print(genres[1]);

    print(profile);
    print(profile['nickname']);
    print(profile['week']);

    for (final genre in genres) {
        print('장르: $genre');
    }

    print(displayName('케이'));
    print(displayName(null));
    print(displayName('   '));

    final movie = Movie(
        id: 1,
        title: '인터스텔라',
    );

    print(movie.id);
    print(movie.title);

    final movies = <Movie>[
        Movie(id: 1, title: '인터스텔라'),
        Movie(id: 2, title: '인셉션'),
        Movie(id: 3, title: '라라랜드'),
    ];

    for (final movie in movies) {
        print('영화 제목: ${movie.title}');
    }
}

String greeting({required String name, int week = 0}) {
    return '$name님, Flutter $week주차를 시작합니다.';
}

String displayName(String? nickname) {
    return nickname?.trim().isNotEmpty == true ? nickname! : '이름 없음';
}

class Movie {
    const Movie({
        required this.id,
        required this.title,
    });

    final int id;
    final String title;
}