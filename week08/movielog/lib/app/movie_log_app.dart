import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/network/movie_log_client.dart';
import '../core/network/tmdb_client.dart';
import '../core/storage/token_storage.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/email_preference.dart';
import '../data/services/genre_preference.dart';
import '../data/services/member_api_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/my_ratings_view_model.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({
    super.key,
    this.tokenStorage,
    this.tmdbMovieService,
    this.authApiService,
    this.memberApiService,
    this.signUpService,
    this.ratingApiService,
    this.genrePreference,
    this.emailPreference,
  });

  /// 아래 값들은 테스트에서 대체 구현을 주입할 때만 사용합니다.
  final TokenStorage? tokenStorage;
  final TmdbMovieService? tmdbMovieService;
  final AuthApiService? authApiService;
  final MemberApiService? memberApiService;
  final SignUpService? signUpService;
  final RatingApiService? ratingApiService;
  final GenrePreference? genrePreference;
  final EmailPreference? emailPreference;

  @override
  Widget build(BuildContext context) {
    final storage =
        tokenStorage ?? SecureTokenStorage(const FlutterSecureStorage());
    // 공개 Client에는 Interceptor가 없고, 보호 Client에만 Bearer 헤더를 붙입니다.
    // TMDB Client와는 계속 분리해 TMDB Token과 MovieLog JWT가 섞이지 않게 합니다.
    final publicClient = createMovieLogClient();
    final authClient = createAuthMovieLogClient(storage);

    return MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: storage),
        Provider<TmdbMovieService>(
          create: (_) =>
              tmdbMovieService ?? TmdbMovieService(createTmdbClient()),
        ),
        // 공개 Client
        Provider<AuthApiService>(
          create: (_) => authApiService ?? AuthApiService(publicClient),
        ),
        Provider<SignUpService>(
          create: (_) => signUpService ?? SignUpService(publicClient),
        ),
        // 보호 Client (RatingApiService는 공개 조회용 publicClient도 함께 받습니다)
        Provider<MemberApiService>(
          create: (_) => memberApiService ?? MemberApiService(authClient),
        ),
        Provider<RatingApiService>(
          create: (_) =>
              ratingApiService ?? RatingApiService(publicClient, authClient),
        ),
        Provider<GenrePreference>(
          create: (_) => genrePreference ?? GenrePreference(),
        ),
        Provider<EmailPreference>(
          create: (_) => emailPreference ?? EmailPreference(),
        ),
        // Service를 주입받는 ViewModel
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            context.read<AuthApiService>(),
            context.read<MemberApiService>(),
            context.read<TokenStorage>(),
          ),
        ),
        // 현재 로그인 세션에서 등록한 평점입니다. 세션이 바뀌면 스스로 비웁니다.
        ChangeNotifierProvider<MyRatingsViewModel>(
          create: (context) => MyRatingsViewModel(
            context.read<RatingApiService>(),
            context.read<AuthViewModel>(),
          ),
        ),
      ],
      child: const _MovieLogRouterApp(),
    );
  }
}

/// GoRouter는 앱이 살아있는 동안 한 번만 만들어야 합니다.
/// build()에서 만들면 다시 그려질 때마다 현재 위치가 초기화됩니다.
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
    // 첫 build 이후 세션 복원을 시작합니다.
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
