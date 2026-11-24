import 'package:flutter/material.dart';
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

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenStorage = SecureTokenStorage(const FlutterSecureStorage());
    // 공개용 Client: Interceptor 없음 (로그인, 중복 체크, 유저별 평점 조회)
    final publicClient = createMovieLogClient();
    // 보호용 Client: AuthInterceptor 등록 (내 정보, 평점 등록/수정/삭제)
    final authClient = createAuthMovieLogClient(tokenStorage);
    // TMDB Client는 위 두 Client와 절대 합치지 않습니다. (TMDB 토큰 ↔ MovieLog JWT 분리)

    return MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: tokenStorage),
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
        // 공개 Client
        Provider<AuthApiService>(create: (_) => AuthApiService(publicClient)),
        Provider<SignUpService>(create: (_) => SignUpService(publicClient)),
        // 보호 Client
        Provider<MemberApiService>(create: (_) => MemberApiService(authClient)),
        // RatingApiService: 공개 조회는 publicClient, 등록·수정·삭제는 authClient
        Provider<RatingApiService>(
          create: (_) => RatingApiService(publicClient, authClient),
        ),
        // 9주차: 즐겨찾기 API는 보호용 authClient(JWT)를 사용합니다.
        Provider<FavoriteApiService>(
          create: (_) => FavoriteApiService(authClient),
        ),
        // Service를 주입받는 ViewModel
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            context.read<AuthApiService>(),
            context.read<MemberApiService>(),
            context.read<TokenStorage>(),
          ),
        ),
        ChangeNotifierProvider<SessionRatingsStore>(
          create: (context) => SessionRatingsStore(context.read<AuthViewModel>()),
        ),
        // 9주차: 인증 상태(AuthViewModel)를 SessionGuard에 전달합니다.
        // 앱 시작부터 로그인 상태 변화를 따라가도록 lazy: false로 바로 만듭니다.
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
      ],
      child: const _MovieLogRouterApp(),
    );
  }
}

/// GoRouter를 initState에서 한 번만 만들고, 첫 프레임 이후 세션 복원을 시작합니다.
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
