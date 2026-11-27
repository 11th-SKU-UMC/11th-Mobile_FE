import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/core/session/auth_session_bridge.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/data/services/favorite_api_service.dart';
import 'package:movielog/core/storage/token_storage.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/session_ratings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MovieLogApp());
}

class MovieLogApp extends StatefulWidget {
  const MovieLogApp({super.key});

  @override
  State<MovieLogApp> createState() => _MovieLogAppState();
}

class _MovieLogAppState extends State<MovieLogApp> {
  // build마다 Client가 새로 생기지 않도록 State에 한 번만 만듭니다.
  final TokenStorage _tokenStorage = SecureTokenStorage(
    const FlutterSecureStorage(),
  );
  late final _publicClient = createMovieLogClient(); // Interceptor 없음
  late final _authClient = createAuthMovieLogClient(_tokenStorage); // Bearer

  @override
  Widget build(BuildContext context) {
    // TMDB Client와 MovieLog Client는 계속 분리합니다. (TMDB에 JWT 금지)
    return MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: _tokenStorage),
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
        // 공개 Client
        Provider<AuthApiService>(create: (_) => AuthApiService(_publicClient)),
        Provider<SignUpService>(create: (_) => SignUpService(_publicClient)),
        // 보호 Client (RatingApiService는 공개 조회용 publicClient도 함께 받음)
        Provider<MemberApiService>(
          create: (_) => MemberApiService(_authClient),
        ),
        Provider<RatingApiService>(
          create: (_) => RatingApiService(_publicClient, _authClient),
        ),
        // 9주차: 즐겨찾기는 보호 Client(JWT)를 사용합니다. 새 Dio를 만들지 않습니다.
        Provider<FavoriteApiService>(
          create: (_) => FavoriteApiService(_authClient),
        ),
        // Service를 주입받는 ViewModel
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            context.read<AuthApiService>(),
            context.read<MemberApiService>(),
            context.read<TokenStorage>(),
          ),
        ),
        // 현재 세션에서 등록한 평점. 세션이 바뀌면 비웁니다.
        ChangeNotifierProxyProvider<AuthViewModel, SessionRatingsStore>(
          create: (_) => SessionRatingsStore(),
          update: (_, auth, store) =>
              store!..syncSession(auth.sessionVersion),
        ),
        // 9주차: AuthViewModel의 세션 변화를 SessionGuard에 전달합니다.
        Provider<AuthSessionBridge>(
          lazy: false, // 앱 시작부터 세션 변화를 따라가도록 바로 만듭니다.
          create: (context) {
            final auth = context.read<AuthViewModel>();
            return AuthSessionBridge(
              authSignals: auth,
              sessionVersion: () => auth.sessionVersion,
              verifiedEmail: () => auth.status == AuthStatus.signedIn
                  ? auth.member?.email
                  : null,
            );
          },
          dispose: (_, bridge) => bridge.dispose(),
        ),
        Provider<SessionGuard>(
          create: (context) => context.read<AuthSessionBridge>().guard,
        ),
      ],
      child: const _MovieLogRouterApp(),
    );
  }
}

// GoRouter는 앱이 살아있는 동안 한 번만 만듭니다.
class _MovieLogRouterApp extends StatefulWidget {
  const _MovieLogRouterApp();

  @override
  State<_MovieLogRouterApp> createState() => _MovieLogRouterAppState();
}

class _MovieLogRouterAppState extends State<_MovieLogRouterApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authViewModel = context.read<AuthViewModel>();
    _router = AppRouter.createRouter(authViewModel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) authViewModel.restoreSession(); // 첫 build 이후 세션 복원
    });
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      title: 'MovieLog',
      routerConfig: _router,
    );
  }
}
