import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/core/sign_up_validation.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/services/api_error.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/screens/signup_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/widgets/delete_rating_dialog.dart';
import 'package:movielog/widgets/loading_overlay.dart';
import 'package:movielog/widgets/movie_rating_input.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:movielog/widgets/rating_dialog.dart';

class _Reply {
  const _Reply(this.status, [this.body]);
  final int status;
  final Object? body;
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final FutureOr<_Reply> Function(RequestOptions) respond;
  final calls = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    final reply = await respond(options);
    return ResponseBody.fromString(
      reply.status == 204 ? '' : jsonEncode(reply.body),
      reply.status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> _common({
  bool success = true,
  Object? result,
  int status = 200,
  String message = '성공',
}) => {
  'isSuccess': success,
  'code': 'COMMON$status',
  'message': message,
  'result': result,
};
_Reply _error(int status, String message) =>
    _Reply(status, _common(success: false, status: status, message: message));
Map<String, Object?> _rating(
  int id, {
  int movieId = 550,
  int score = 5,
  String? comment = '처음 코멘트',
}) => {
  'ratingId': id,
  'movieId': movieId,
  'score': score,
  'comment': comment,
  'createdAt': '2026-11-12T00:00:00Z',
};
Map<String, Object?> _movie(int id) => {
  'id': id,
  'title': '영화$id',
  'overview': '줄거리',
  'poster_path': null,
  'vote_average': 8,
};
const _request = CreateMemberRequest(
  email: 'week07@example.com',
  password: 'Example123!',
  nickname: '내계정',
);

(_Adapter, SignUpService, RatingApiService, TmdbMovieService) _services(
  FutureOr<_Reply> Function(RequestOptions) respond,
) {
  final adapter = _Adapter(respond);
  final dio = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'))
    ..httpClientAdapter = adapter;
  final tmdb = Dio(BaseOptions(baseUrl: 'https://api.themoviedb.org/3'))
    ..httpClientAdapter = adapter;
  addTearDown(() {
    dio.close(force: true);
    tmdb.close(force: true);
  });
  return (
    adapter,
    SignUpService(dio),
    RatingApiService(dio),
    TmdbMovieService(tmdb),
  );
}

Future<SignUpViewModel> _ready(SignUpService service) async {
  final vm = SignUpViewModel(service);
  addTearDown(vm.dispose);
  vm.onNicknameChanged(_request.nickname);
  vm.onEmailChanged(_request.email);
  await vm.checkNickname(_request.nickname);
  await vm.checkEmail(_request.email);
  return vm;
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

final _captureKey = GlobalKey();
Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('UPDATE_EVIDENCE')) return;
  await tester.pump();
  final boundary =
      _captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('docs/evidence').create(recursive: true);
    await File('docs/evidence/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _pumpRatings(WidgetTester tester, MyRatingsViewModel vm) async {
  _phone(tester);
  await tester.runAsync(vm.load);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _captureKey,
      child: ChangeNotifierProvider.value(
        value: vm,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const MyRatingsScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    // Load real fonts for exported evidence; behavioral assertions also work
    // on platforms without the optional Windows Korean fallback.
    final fonts = FontLoader('Manrope')
      ..addFont(
        File('assets/fonts/Manrope-VariableFont_wght.ttf')
            .readAsBytes()
            .then(ByteData.sublistView),
      );
    final koreanFont = File('C:/Windows/Fonts/malgun.ttf');
    if (Platform.isWindows && await koreanFont.exists()) {
      fonts.addFont(koreanFont.readAsBytes().then(ByteData.sublistView));
    }
    await fonts.load();
    final config = jsonDecode(
      await File('.dart_tool/package_config.json').readAsString(),
    ) as Map<String, dynamic>;
    final flutterPackage = (config['packages'] as List)
        .cast<Map<String, dynamic>>()
        .singleWhere((package) => package['name'] == 'flutter');
    final flutterDirectory = Directory.fromUri(
      Uri.parse(flutterPackage['rootUri'] as String),
    );
    final iconFile = File.fromUri(
      flutterDirectory.uri.resolve(
        '../../bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
    );
    await (FontLoader(
      'MaterialIcons',
    )..addFont(iconFile.readAsBytes().then(ByteData.sublistView))).load();
  });
  test(
    'Request serialization preserves password and validates integer scores',
    () {
      const request = CreateMemberRequest(
        email: ' user@example.com ',
        password: ' Example123! ',
        nickname: ' 닉네임 ',
      );
      expect(request.toJson(), {
        'email': 'user@example.com',
        'password': ' Example123! ',
        'nickname': '닉네임',
      });
      expect(
        const CreateRatingRequest(
          movieId: 550,
          score: 5,
          comment: ' ',
        ).toJson(),
        {'movieId': 550, 'score': 5},
      );
      expect(
        const CreateRatingRequest(
          movieId: 550,
          score: 4,
          comment: ' 후기 ',
        ).toJson()['comment'],
        '후기',
      );
      for (final value in [0.0, 0.5, 4.5, 6.0, double.nan, double.infinity]) {
        expect(() => validateServerScore(value), throwsArgumentError);
      }
      expect(() => normalizeComment('가' * 501), throwsArgumentError);
      expect(validateServerScore(5), 5);
      expect(validateNickname('가' * 13), isNotNull);
      for (final invalid in [
        'short',
        'password123!',
        'PASSWORD123!',
        'Example!!!!',
        'Example1234',
      ]) {
        expect(validatePasswordFormat(invalid), isNotNull);
      }
      expect(validatePasswordFormat(_request.password), isNull);
    },
  );

  test('Generic wrapper accepts null without invoking the payload parser', () {
    final result = CommonResponse<int>.fromJson(
      _common(),
      (_) => throw StateError('must not parse null'),
    );
    expect(result.result, isNull);
    expect(result.isSuccess, isTrue);
  });

  test('MovieLog client has no TMDB authorization or body logging', () {
    final client = createMovieLogClient();
    addTearDown(() => client.close(force: true));
    expect(
      client.options.headers.keys.map((key) => key.toLowerCase()),
      isNot(contains('authorization')),
    );
    expect(client.interceptors.whereType<LogInterceptor>(), isEmpty);
    final session = LearningMemberSession()..setMemberId(42);
    expect(session.memberId, 42);
    session.clear();
    expect(session.memberId, isNull);
    session.dispose();
  });

  test('POST accepts number or null result; PATCH sends comment null; DELETE has no body', () async {
    Object? result = 91;
    final (adapter, _, service, _) = _services(
      (options) => switch (options.method) {
        'POST' => _Reply(201, _common(status: 201, result: result)),
        'PATCH' => _Reply(200, _common()),
        'DELETE' => const _Reply(204),
        _ => const _Reply(200, []),
      },
    );
    await service.createRating(
      memberId: 42,
      request: const CreateRatingRequest(movieId: 969681, score: 5),
    );
    result = null;
    await service.createRating(
      memberId: 42,
      request: const CreateRatingRequest(movieId: 550, score: 4),
    );
    await service.updateRating(
      memberId: 42,
      ratingId: 91,
      score: 3,
      comment: null,
    );
    await service.deleteRating(memberId: 42, ratingId: 91);
    expect(adapter.calls[0].path, '/v6/members/42/ratings');
    expect(adapter.calls[0].data['movieId'], 969681);
    expect(adapter.calls[2].data, {'score': 3, 'comment': null});
    expect(adapter.calls.last.path, '/v6/members/42/ratings/91');
  });

  test(
    'Signup requires current checks and blocks a second in-flight POST',
    () async {
      final pending = Completer<_Reply>();
      final started = Completer<void>();
      final (adapter, service, _, _) = _services((options) {
        if (options.method == 'POST') {
          started.complete();
          return pending.future;
        }
        return const _Reply(200, {'available': true});
      });
      final vm = SignUpViewModel(service);
      addTearDown(vm.dispose);
      await vm.submit(_request);
      expect(adapter.calls, isEmpty);
      vm.onNicknameChanged(_request.nickname);
      vm.onEmailChanged(_request.email);
      await vm.checkNickname(_request.nickname);
      await vm.checkEmail(_request.email);
      final first = vm.submit(_request);
      await vm.submit(_request);
      await started.future;
      expect(vm.submitStatus, SubmitStatus.submitting);
      expect(
        adapter.calls.where((call) => call.method == 'POST'),
        hasLength(1),
      );
      pending.complete(
        _Reply(
          201,
          _common(
            status: 201,
            result: {
              'memberId': 42,
              'email': _request.email,
              'nickname': _request.nickname,
            },
          ),
        ),
      );
      await first;
      expect(vm.createdMemberId, 42);
      expect(vm.submitStatus, SubmitStatus.success);
    },
  );

  for (final (status, message, fieldError) in [
    (400, '비밀번호 형식 오류입니다.', true),
    (400, '올바른 이메일 형식이 아닙니다.', false),
    (409, '이미 사용 중인 이메일입니다.', false),
  ]) {
    test(
      'Signup $status $message goes to the correct UI destination',
      () async {
        final (_, service, _, _) = _services(
          (options) => options.method == 'POST'
              ? _error(status, message)
              : const _Reply(200, {'available': true}),
        );
        final vm = await _ready(service);
        await vm.submit(_request);
        expect(vm.submitStatus, SubmitStatus.error);
        expect(vm.passwordErrorText, fieldError ? message : null);
        expect(vm.snackbarMessage, fieldError ? null : message);
        vm.onEmailChanged('new@example.com');
        expect(vm.emailCheckStatus, CheckStatus.idle);
        expect(vm.passwordErrorText, isNull);
        expect(vm.snackbarMessage, isNull);
        expect(vm.canSubmit(_request), isFalse);
      },
    );
  }

  test('Missing signup memberId is a contract error; disposed signup ignores success', () async {
    final (_, service, _, _) = _services(
      (options) => options.method == 'POST'
          ? _Reply(201, _common(status: 201))
          : const _Reply(200, {'available': true}),
    );
    final vm = await _ready(service);
    await vm.submit(_request);
    expect(vm.createdMemberId, isNull);
    expect(vm.submitStatus, SubmitStatus.error);
    expect(vm.snackbarMessage, contains('가입 결과'));
    final pending = Completer<_Reply>();
    final (_, delayedService, _, _) = _services(
      (options) => options.method == 'POST'
          ? pending.future
          : const _Reply(200, {'available': true}),
    );
    final disposed = SignUpViewModel(delayedService);
    disposed.onNicknameChanged(_request.nickname);
    disposed.onEmailChanged(_request.email);
    await disposed.checkNickname(_request.nickname);
    await disposed.checkEmail(_request.email);
    final saving = disposed.submit(_request);
    disposed.dispose();
    pending.complete(
      _Reply(
        201,
        _common(
          status: 201,
          result: {
            'memberId': 42,
            'email': _request.email,
            'nickname': _request.nickname,
          },
        ),
      ),
    );
    await saving;
    expect(disposed.createdMemberId, isNull);
  });

  test(
    'Detail rejects missing member and forwards TMDB id when saving',
    () async {
      final (adapter, _, service, movies) = _services(
        (options) => options.method == 'POST'
            ? _Reply(201, _common(status: 201))
            : _Reply(200, _movie(969681)),
      );
      final anonymous = MovieDetailViewModel(
        movies,
        movieId: 969681,
        ratingService: service,
      );
      addTearDown(anonymous.dispose);
      await expectLater(
        anonymous.createRating(score: 5),
        throwsA(isA<ApiException>()),
      );
      expect(adapter.calls, isEmpty);
      final vm = MovieDetailViewModel(
        movies,
        movieId: 969681,
        memberId: 42,
        ratingService: service,
      );
      addTearDown(vm.dispose);
      await vm.createRating(score: 4, comment: '후기');
      expect(adapter.calls.single.path, '/v6/members/42/ratings');
      expect(adapter.calls.single.data, {
        'movieId': 969681,
        'score': 4,
        'comment': '후기',
      });
      expect(vm.submitStatus, SubmitStatus.success);
    },
  );

  test('Successful PATCH plus failed GET retries GET only', () async {
    var failGet = false;
    final (adapter, _, service, movies) = _services((options) {
      if (options.method == 'PATCH') {
        failGet = true;
        return _Reply(200, _common());
      }
      if (options.path.startsWith('/movie/')) return _Reply(200, _movie(550));
      return failGet ? _error(503, '조회 일시 실패') : _Reply(200, [_rating(91)]);
    });
    final vm = MyRatingsViewModel(service, movies, 42);
    addTearDown(vm.dispose);
    await vm.load();
    await vm.updateRating(ratingId: 91, score: 4, comment: '유지');
    expect(vm.refreshWarning, contains('저장은 완료'));
    expect(vm.status, MyRatingsLoadStatus.error);
    expect(vm.isWriting, isFalse);
    failGet = false;
    await vm.load();
    expect(vm.refreshWarning, isNull);
    expect(adapter.calls.where((call) => call.method == 'PATCH'), hasLength(1));
  });

  for (final status in [400, 403, 404]) {
    test(
      'PATCH $status rethrows; only 403/404 trigger GET reconciliation',
      () async {
        final (adapter, _, service, movies) = _services((options) {
          if (options.method == 'PATCH') return _error(status, '오류$status');
          if (options.path.startsWith('/movie/')) {
            return _Reply(200, _movie(550));
          }
          return _Reply(200, [_rating(91)]);
        });
        final vm = MyRatingsViewModel(service, movies, 42);
        addTearDown(vm.dispose);
        await expectLater(
          vm.updateRating(ratingId: 91, score: 4),
          throwsA(isA<DioException>()),
        );
        expect(vm.writeMessage, '오류$status');
        expect(
          adapter.calls.where(
            (call) => call.method == 'GET' && call.path.contains('/ratings'),
          ),
          hasLength(status == 400 ? 0 : 1),
        );
        expect(vm.isWriting, isFalse);
      },
    );
  }

  test(
    'Last DELETE becomes Empty; bulk deletion keeps only failed selections',
    () async {
      var records = [_rating(91), _rating(92, movieId: 13)];
      final pending = Completer<_Reply>();
      final (adapter, _, service, movies) = _services((options) {
        if (options.method == 'DELETE') {
          if (options.path.endsWith('/92')) return _error(503, '일시 실패');
          records.removeWhere((record) => record['ratingId'] == 91);
          return pending.future;
        }
        if (options.path.startsWith('/movie/')) return _Reply(200, _movie(550));
        return _Reply(200, records);
      });
      final vm = MyRatingsViewModel(service, movies, 42);
      addTearDown(vm.dispose);
      await vm.load();
      vm.toggleEditing();
      vm.toggleSelected(91);
      vm.toggleSelected(92);
      final deleting = vm.deleteSelectedRatings();
      expect(vm.isDeletingSelected, isTrue);
      await vm.deleteSelectedRatings();
      pending.complete(const _Reply(204));
      await deleting;
      expect(vm.selectedRatingIds, {92});
      expect(vm.ratings.single.rating.ratingId, 92);
      expect(vm.writeMessage, contains('1개 항목'));
      expect(
        adapter.calls.where((call) => call.method == 'DELETE'),
        hasLength(2),
      );
      expect(vm.isWriting, isFalse);
      expect(vm.isDeletingSelected, isFalse);
      records = [];
      await vm.load();
      expect(vm.status, MyRatingsLoadStatus.empty);
    },
  );

  test(
    'Late write completion never notifies a disposed ratings screen',
    () async {
      final pending = Completer<_Reply>();
      final (adapter, _, service, movies) = _services((_) => pending.future);
      final vm = MyRatingsViewModel(service, movies, 42);
      var notifications = 0;
      vm.addListener(() => notifications++);
      final saving = vm.updateRating(ratingId: 91, score: 4);
      vm.dispose();
      pending.complete(_Reply(200, _common()));
      await saving;
      expect(notifications, 1);
      expect(adapter.calls, hasLength(1));
    },
  );

  testWidgets(
    'Dialog requires a star, preserves text through failure, blocks exit, then retries',
    (tester) async {
      _phone(tester);
      final pending = Completer<void>();
      var attempts = 0;
      final submitted = <(int, String?)>[];
      await tester.pumpWidget(
        RepaintBoundary(
          key: _captureKey,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => RatingDialog(
                      onSubmit: (score, comment) async {
                        submitted.add((score, comment));
                        attempts++;
                        if (attempts == 1) await pending.future;
                      },
                    ),
                  ),
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      MovieLogButton confirm() => tester.widget<MovieLogButton>(
        find.widgetWithText(MovieLogButton, '확인'),
      );
      expect(confirm().onPressed, isNull);
      await tester.enterText(
        find.byKey(const ValueKey('rating-comment')),
        '입력을 유지해 주세요',
      );
      tester
          .widget<MovieRatingInput>(find.byType(MovieRatingInput))
          .onChanged(4);
      await tester.pump();
      expect(find.text('입력을 유지해 주세요'), findsOneWidget);
      await _capture(tester, '01-rating-comment');
      await tester.tap(find.text('확인'));
      await tester.pump();
      await tester.tapAt(const Offset(5, 5));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(RatingDialog), findsOneWidget);
      expect(
        tester.widget<MovieRatingInput>(find.byType(MovieRatingInput)).enabled,
        isFalse,
      );
      pending.completeError(const ApiException('네트워크 오류: 입력을 유지합니다.'));
      await tester.pumpAndSettle();
      expect(find.text('입력을 유지해 주세요'), findsOneWidget);
      expect(confirm().onPressed, isNotNull);
      await _capture(tester, '02-save-failure-preserves-input');
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(find.byType(RatingDialog), findsNothing);
      expect(submitted, [(4, '입력을 유지해 주세요'), (4, '입력을 유지해 주세요')]);
    },
  );

  testWidgets(
    'Edit preloads score/comment, preserves values, and GET-only retry follows successful PATCH',
    (tester) async {
      var failGet = false;
      final (adapter, _, service, movies) = _services((options) {
        if (options.method == 'PATCH') {
          failGet = true;
          return _Reply(200, _common());
        }
        if (options.path.startsWith('/movie/')) return _Reply(200, _movie(550));
        return failGet
            ? _error(503, '목록 조회에 실패했습니다.')
            : _Reply(200, [_rating(91, score: 4)]);
      });
      final vm = MyRatingsViewModel(service, movies, 42);
      addTearDown(vm.dispose);
      await _pumpRatings(tester, vm);
      await _capture(tester, '03-my-ratings');
      await tester.tap(find.byTooltip('평점 수정'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MovieRatingInput>(find.byType(MovieRatingInput)).rating,
        4,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('rating-comment')))
            .controller!
            .text,
        '처음 코멘트',
      );
      await _capture(tester, '04-edit-prefilled');
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(find.byType(RatingDialog), findsNothing);
      expect(find.textContaining('저장은 완료'), findsOneWidget);
      await _capture(tester, '05-write-success-refresh-failure');
      failGet = false;
      await tester.tap(find.text('조회 다시 시도'));
      await tester.pumpAndSettle();
      expect(
        adapter.calls.where((call) => call.method == 'PATCH'),
        hasLength(1),
      );
      expect(
        adapter.calls
            .singleWhere((call) => call.method == 'PATCH')
            .data['comment'],
        '처음 코멘트',
      );
      expect(find.byTooltip('평점 수정'), findsOneWidget);
    },
  );

  testWidgets(
    'Single delete cancel sends no request; pending delete keeps the dialog; last item becomes Empty',
    (tester) async {
      final pending = Completer<_Reply>();
      var deleted = false;
      final (adapter, _, service, movies) = _services((options) {
        if (options.method == 'DELETE') {
          deleted = true;
          return pending.future;
        }
        if (options.path.startsWith('/movie/')) return _Reply(200, _movie(550));
        return _Reply(200, deleted ? [] : [_rating(91)]);
      });
      final vm = MyRatingsViewModel(service, movies, 42);
      addTearDown(vm.dispose);
      await _pumpRatings(tester, vm);
      await tester.tap(find.byTooltip('평점 삭제'));
      await tester.pumpAndSettle();
      await _capture(tester, '06-delete-confirmation');
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(adapter.calls.where((call) => call.method == 'DELETE'), isEmpty);
      await tester.tap(find.byTooltip('평점 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(DeleteRatingDialog), findsOneWidget);
      pending.complete(const _Reply(204));
      await tester.pumpAndSettle();
      expect(find.byType(DeleteRatingDialog), findsNothing);
      expect(find.text('등록된 평점이 없습니다.'), findsOneWidget);
      await _capture(tester, '07-empty-after-delete');
    },
  );

  testWidgets(
    'Bulk delete closes confirmation, shows overlay, keeps failed selections',
    (tester) async {
      final pending = Completer<_Reply>();
      var records = [_rating(91), _rating(92, movieId: 13)];
      final (_, _, service, movies) = _services((options) {
        if (options.method == 'DELETE') {
          if (options.path.endsWith('/92')) return _error(503, '일시 실패');
          records = records
              .where((record) => record['ratingId'] != 91)
              .toList();
          return pending.future;
        }
        if (options.path.startsWith('/movie/')) return _Reply(200, _movie(550));
        return _Reply(200, records);
      });
      final vm = MyRatingsViewModel(service, movies, 42);
      addTearDown(vm.dispose);
      await _pumpRatings(tester, vm);
      await tester.tap(find.text('편집'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MovieLogButton>(
              find.widgetWithText(MovieLogButton, '선택한 0개 삭제'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byType(Checkbox).first);
      await tester.tap(find.byType(Checkbox).last);
      await tester.pumpAndSettle();
      await _capture(tester, '08-multi-selection');
      await tester.tap(find.text('선택한 2개 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        tester.widget<LoadingOverlay>(find.byType(LoadingOverlay)).isLoading,
        isTrue,
      );
      await _capture(tester, '09-bulk-delete-overlay');
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(MyRatingsScreen), findsOneWidget);
      pending.complete(const _Reply(204));
      await tester.pumpAndSettle();
      expect(vm.selectedRatingIds, {92});
      expect(find.textContaining('1개 항목을 삭제하지 못했습니다'), findsOneWidget);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      await _capture(tester, '10-bulk-partial-failure');
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(vm.selectedCount, 0);
      expect(find.byType(Checkbox), findsNothing);
    },
  );

  for (final (status, serverMessage) in [
    (400, '비밀번호 형식이 올바르지 않습니다.'),
    (409, '이미 사용 중인 이메일입니다.'),
  ]) {
    testWidgets(
      'Signup displays server $status after local validation succeeds',
      (tester) async {
        _phone(tester);
        final (_, service, _, _) = _services(
          (options) => options.method == 'POST'
              ? _error(status, serverMessage)
              : const _Reply(200, {'available': true}),
        );
        final vm = SignUpViewModel(service);
        addTearDown(vm.dispose);
        await tester.pumpWidget(
          RepaintBoundary(
            key: _captureKey,
            child: ChangeNotifierProvider.value(
              value: vm,
              child: MaterialApp(
                theme: AppTheme.light,
                home: const SignUpScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), _request.nickname);
        await tester.enterText(fields.at(1), _request.email);
        await tester.enterText(fields.at(2), _request.password);
        for (var index = 0; index < 2; index++) {
          final check = find.widgetWithText(MovieLogButton, '중복 확인').at(index);
          await tester.ensureVisible(check);
          await tester.tap(check);
          await tester.pumpAndSettle();
        }
        final submit = find.widgetWithText(MovieLogButton, '가입하기');
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(find.text(serverMessage), findsOneWidget);
        if (status == 400) {
          expect(find.byType(SnackBar), findsNothing);
          expect(vm.passwordErrorText, serverMessage);
          tester.state<FormState>(find.byType(Form)).validate();
          await tester.pump();
          expect(find.text(serverMessage), findsOneWidget);
        } else {
          expect(find.byType(SnackBar), findsOneWidget);
          expect(vm.passwordErrorText, isNull);
        }
        await _capture(tester, 'signup-$status');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Signup submits once, blocks back, stores memberId and routes to movies',
    (tester) async {
      _phone(tester);
      final pending = Completer<_Reply>();
      final started = Completer<void>();
      final (adapter, signup, ratings, movies) = _services((options) {
        if (options.method == 'POST') {
          started.complete();
          return pending.future;
        }
        if (options.path.contains('/nickname/') ||
            options.path.contains('/email/')) {
          return const _Reply(200, {'available': true});
        }
        if (options.path == '/genre/movie/list') {
          return const _Reply(200, {'genres': []});
        }
        return const _Reply(200, {
          'page': 1,
          'total_pages': 1,
          'total_results': 0,
          'results': [],
        });
      });
      final session = LearningMemberSession();
      addTearDown(session.dispose);
      final router = GoRouter(
        navigatorKey: AppRouter.rootNavigatorKey,
        initialLocation: '/signup',
        routes: AppRouter.router.configuration.routes,
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        RepaintBoundary(
          key: _captureKey,
          child: MultiProvider(
            providers: [
              Provider<SignUpService>.value(value: signup),
              Provider<RatingApiService>.value(value: ratings),
              Provider<TmdbMovieService>.value(value: movies),
              ChangeNotifierProvider.value(value: session),
            ],
            child: MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: router,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), _request.nickname);
      await tester.enterText(fields.at(1), _request.email);
      await tester.enterText(fields.at(2), _request.password);
      for (var index = 0; index < 2; index++) {
        final check = find.widgetWithText(MovieLogButton, '중복 확인').at(index);
        await tester.ensureVisible(check);
        await tester.tap(check);
        await tester.pumpAndSettle();
      }
      final submit = find.widgetWithText(MovieLogButton, '가입하기');
      expect(tester.widget<MovieLogButton>(submit).onPressed, isNotNull);
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      expect(
        tester.element(find.byType(Form)).read<SignUpViewModel>().isSubmitting,
        isTrue,
      );
      for (var i = 0; i < 10 && !started.isCompleted; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(started.isCompleted, isTrue);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(router.routeInformationProvider.value.uri.path, '/signup');
      expect(
        adapter.calls.where((call) => call.method == 'POST'),
        hasLength(1),
      );
      pending.complete(
        _Reply(
          201,
          _common(
            status: 201,
            result: {
              'memberId': 42,
              'email': _request.email,
              'nickname': _request.nickname,
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(session.memberId, 42);
      expect(router.routeInformationProvider.value.uri.path, '/movies');
      expect(tester.takeException(), isNull);
    },
  );
}
