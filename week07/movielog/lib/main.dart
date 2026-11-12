import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/network/movie_log_client.dart';
import 'core/network/tmdb_client.dart';
import 'data/services/rating_api_service.dart';
import 'data/services/sign_up_service.dart';
import 'data/services/tmdb_movie_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'view_models/learning_member_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 로드가 끝나기 전에 Token을 읽으면 빈 값이 나오므로 runApp 전에 기다린다.
  await dotenv.load(fileName: '.env');
  runApp(const MovieLogApp());
}

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 여러 Route가 함께 쓰는 상태 없는 객체는 MaterialApp.router 위에 둔다.
    // (특정 화면 아래에만 두면 다른 Route에서 context.read로 찾지 못한다.)
    // 워크북 백엔드를 부르는 두 Service는 같은 Dio를 공유하고,
    // TMDB Client와는 baseUrl·헤더가 달라 분리한다.
    final movieLogClient = createMovieLogClient();

    return MultiProvider(
      providers: [
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
        Provider<SignUpService>(create: (_) => SignUpService(movieLogClient)),
        Provider<RatingApiService>(
          create: (_) => RatingApiService(movieLogClient),
        ),
        // 회원가입으로 얻은 학습용 memberId. 영화 상세·마이페이지 Route가 함께 읽는다.
        ChangeNotifierProvider<LearningMemberSession>(
          create: (_) => LearningMemberSession(),
        ),
      ],
      // 첫 화면과 화면 이동은 MaterialApp이 아니라 AppRouter의 GoRouter가 결정한다.
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MovieLog',
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
