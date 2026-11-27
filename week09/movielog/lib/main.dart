import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/network/movie_log_client.dart';
import 'core/network/tmdb_client.dart';
import 'core/session/auth_session_bridge.dart';
import 'core/session/session_guard.dart';
import 'core/storage/token_storage.dart';
import 'data/services/auth_api_service.dart';
import 'data/services/favorite_api_service.dart';
import 'data/services/member_api_service.dart';
import 'data/services/rating_api_service.dart';
import 'data/services/sign_up_service.dart';
import 'data/services/tmdb_movie_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/session_ratings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 로드가 끝나기 전에 Token을 읽으면 빈 값이 나오므로 runApp 전에 기다린다.
  await dotenv.load(fileName: '.env');
  runApp(const MovieLogApp());
}

class MovieLogApp extends StatefulWidget {
  const MovieLogApp({super.key, this.tokenStorage});

  /// 테스트에서 secure storage 대신 넣을 저장소. null이면 [SecureTokenStorage].
  final TokenStorage? tokenStorage;

  @override
  State<MovieLogApp> createState() => _MovieLogAppState();
}

class _MovieLogAppState extends State<MovieLogApp> {
  // Client는 build마다 새로 만들지 않도록 State에서 한 번만 만든다.
  late final TokenStorage _tokenStorage =
      widget.tokenStorage ?? SecureTokenStorage(const FlutterSecureStorage());

  /// 공개 요청용(로그인·회원가입·중복 확인·유저별 평점 조회). Interceptor 없음.
  late final _publicClient = createMovieLogClient();

  /// 보호 요청용(내 정보·평점 등록/수정/삭제·즐겨찾기). AuthInterceptor가 토큰을 붙인다.
  late final _authClient = createAuthMovieLogClient(_tokenStorage);

  @override
  Widget build(BuildContext context) {
    // 여러 Route가 함께 쓰는 객체는 MaterialApp.router 위에 둔다.
    // TMDB Client에는 AuthInterceptor를 붙이지 않는다. (MovieLog JWT가 TMDB로 가면 안 된다)
    return MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: _tokenStorage),
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
        // 공개 Client
        Provider<AuthApiService>(create: (_) => AuthApiService(_publicClient)),
        Provider<SignUpService>(create: (_) => SignUpService(_publicClient)),
        // 보호 Client (RatingApiService는 공개 조회용 Client도 함께 받는다)
        Provider<MemberApiService>(
          create: (_) => MemberApiService(_authClient),
        ),
        Provider<RatingApiService>(
          create: (_) => RatingApiService(_publicClient, _authClient),
        ),
        // 즐겨찾기는 JWT로 사용자를 구분하므로 8주차 보호 Client를 그대로 쓴다.
        Provider<FavoriteApiService>(
          create: (_) => FavoriteApiService(_authClient),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            context.read<AuthApiService>(),
            context.read<MemberApiService>(),
            context.read<TokenStorage>(),
          ),
        ),
        // AuthViewModel의 sessionVersion·내 정보 email을 SessionGuard에 전달한다.
        // 로그인·로그아웃·계정 전환을 놓치지 않도록 앱 시작 때 바로 만든다.
        Provider<AuthSessionBridge>(
          lazy: false,
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
        // 현재 로그인 세션에서 등록한 평점. 세션이 바뀌면 스스로 비운다.
        ChangeNotifierProvider<SessionRatingsStore>(
          create: (context) =>
              SessionRatingsStore(context.read<AuthViewModel>()),
        ),
      ],
      child: const _MovieLogRouterApp(),
    );
  }
}

/// Router를 한 번만 만들고 세션 복원을 시작하는 호스트.
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
    // 첫 build 이후 세션 복원을 시작한다. (build 중 notifyListeners 방지)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) authViewModel.restoreSession();
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
      title: 'MovieLog',
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
