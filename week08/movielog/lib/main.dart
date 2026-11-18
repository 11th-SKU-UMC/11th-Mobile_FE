import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'core/network/auth_interceptor.dart';
import 'core/network/movie_log_client.dart';
import 'core/network/tmdb_client.dart';
import 'data/services/auth_api_service.dart';
import 'data/services/member_api_service.dart';
import 'data/services/rating_api_service.dart';
import 'data/services/sign_up_service.dart';
import 'data/services/tmdb_movie_service.dart';
import 'router/app_router.dart';
import 'services/token_storage.dart';
import 'theme/app_theme.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/session_ratings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MovieLogApp());
}

class MovieLogApp extends StatefulWidget {
  const MovieLogApp({
    super.key,
    this.tokenStorage = const SecureTokenStorage(FlutterSecureStorage()),
    this.movieLogAdapter,
  });

  final TokenStorage tokenStorage;
  final HttpClientAdapter? movieLogAdapter;

  @override
  State<MovieLogApp> createState() => _MovieLogAppState();
}

class _MovieLogAppState extends State<MovieLogApp> {
  late final Dio _publicClient;
  late final Dio _authClient;
  late final AuthViewModel _auth;
  late final RatingApiService _ratingApi;
  late final SessionRatings _ratings;
  late final AppRouter _router;

  @override
  void initState() {
    super.initState();
    _publicClient = createMovieLogClient();
    _authClient = createMovieLogClient();
    final adapter = widget.movieLogAdapter;
    if (adapter != null) {
      _publicClient.httpClientAdapter = adapter;
      _authClient.httpClientAdapter = adapter;
    }
    _auth = AuthViewModel(
      widget.tokenStorage,
      AuthApiService(_publicClient),
      MemberApiService(_authClient),
    );
    _authClient.interceptors.add(
      AuthInterceptor(
        Uri.parse(_authClient.options.baseUrl),
        () => _auth.credentials,
        _auth.expireSession,
      ),
    );
    _ratingApi = RatingApiService(_publicClient, _authClient);
    _ratings = SessionRatings(_auth, _ratingApi);
    _router = AppRouter(_auth);
    unawaited(_auth.restoreSession());
  }

  @override
  void dispose() {
    _router.router.dispose();
    _ratings.dispose();
    _auth.dispose();
    _publicClient.close(force: true);
    _authClient.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _ratings),
        Provider.value(value: _ratingApi),
        Provider(create: (_) => SignUpService(_publicClient)),
        Provider<Dio>(
          create: (_) => createTmdbClient(),
          dispose: (_, client) => client.close(force: true),
        ),
        Provider(create: (context) => TmdbMovieService(context.read<Dio>())),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router.router,
      ),
    );
  }
}
