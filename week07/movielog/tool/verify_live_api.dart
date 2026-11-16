import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';

// Opt-in live check. Creates only its own disposable learning accounts and
// deletes only ratings created by this run. Passwords never leave memory/log.
Future<void> main() async {
  final movieLog = Dio(
    BaseOptions(
      baseUrl: 'https://workbook.devnoco.com',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  final signUp = SignUpService(movieLog);
  final ratings = RatingApiService(movieLog);
  final events = <Map<String, Object?>>[];
  final created = <(int, int)>[];
  final suffix = DateTime.now().millisecondsSinceEpoch.toString();
  final secret =
      'W7a!${List.generate(24, (_) => Random.secure().nextInt(10)).join()}';
  final request = CreateMemberRequest(
    email: 'week07.$suffix@example.com',
    password: secret,
    nickname: 'w7${suffix.substring(4)}',
  );
  final envFile = File('.env');
  final envLines = await envFile.readAsLines();
  final tokenLine = envLines.firstWhere(
    (line) => line.startsWith('TMDB_ACCESS_TOKEN='),
  );
  final token = tokenLine
      .substring('TMDB_ACCESS_TOKEN='.length)
      .trim()
      .replaceAll(RegExp(r'''^['"]|['"]$'''), '');
  final tmdb = Dio(
    BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      headers: {'Authorization': 'Bearer $token'},
    ),
  );

  Future<void> expectError(
    String label,
    int expected,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      throw StateError('$label unexpectedly succeeded');
    } on DioException catch (error) {
      if (error.response?.statusCode != expected) {
        throw StateError(
          '$label: unexpected HTTP status ${error.response?.statusCode}',
        );
      }
      final data = error.response?.data as Map<String, dynamic>;
      events.add({
        'check': label,
        'status': expected,
        'code': data['code'],
        'message': data['message'],
      });
    }
  }

  try {
    final movies =
        (await tmdb.get(
              '/movie/popular',
              queryParameters: {'language': 'ko-KR'},
            )).data
            as Map<String, dynamic>;
    final selectedMovie =
        (movies['results'] as List).first as Map<String, dynamic>;
    final movieId = (selectedMovie['id'] as num).toInt();
    events.add({
      'check': 'TMDB movie selection',
      'movieId': movieId,
      'title': selectedMovie['title'],
    });
    if (!await signUp.checkNickname(request.nickname) ||
        !await signUp.checkEmail(request.email)) {
      throw StateError('Generated account is unavailable');
    }
    events.add({
      'check': 'nickname and email checks',
      'status': 200,
      'available': true,
    });
    await expectError('password validation', 400, () async {
      await signUp.signUp(
        CreateMemberRequest(
          email: request.email,
          password: 'invalid',
          nickname: request.nickname,
        ),
      );
    });
    final member = (await signUp.signUp(request)).result!;
    events.add({
      'check': 'signup',
      'status': 201,
      'memberId': member.memberId,
      'email': member.email,
      'nickname': member.nickname,
    });
    await expectError('final signup conflict', 409, () async {
      await signUp.signUp(request);
    });
    await ratings.createRating(
      memberId: member.memberId,
      request: CreateRatingRequest(
        movieId: movieId,
        score: 5,
        comment: '7주차 실제 API 등록 검증',
      ),
    );
    var list = await ratings.fetchMyRatings(member.memberId);
    final saved = list.singleWhere((rating) => rating.movieId == movieId);
    created.add((member.memberId, saved.ratingId));
    events.add({
      'check': 'create then GET',
      'status': 201,
      'memberId': member.memberId,
      'movieId': movieId,
      'ratingId': saved.ratingId,
      'score': saved.score,
      'comment': saved.comment,
    });
    await expectError(
      'duplicate rating',
      409,
      () => ratings.createRating(
        memberId: member.memberId,
        request: CreateRatingRequest(movieId: movieId, score: 5),
      ),
    );
    await expectError('invalid score', 400, () async {
      await movieLog.patch(
        '/v6/members/${member.memberId}/ratings/${saved.ratingId}',
        data: {'score': 6},
      );
    });
    final otherMember = (await signUp.signUp(
      CreateMemberRequest(
        email: 'week07.other.$suffix@example.com',
        password: secret,
        nickname: 'w8${suffix.substring(4)}',
      ),
    )).result!;
    events.add({
      'check': 'own second account for permission check',
      'memberId': otherMember.memberId,
    });
    await expectError(
      'forbidden update using own second account',
      403,
      () => ratings.updateRating(
        memberId: otherMember.memberId,
        ratingId: saved.ratingId,
        score: 3,
        comment: 'permission check',
      ),
    );
    await expectError(
      'forbidden delete using own second account',
      403,
      () => ratings.deleteRating(
        memberId: otherMember.memberId,
        ratingId: saved.ratingId,
      ),
    );
    await ratings.updateRating(
      memberId: member.memberId,
      ratingId: saved.ratingId,
      score: 4,
      comment: saved.comment,
    );
    list = await ratings.fetchMyRatings(member.memberId);
    if (list.single.score != 4 || list.single.comment != saved.comment) {
      throw StateError('Update did not preserve comment');
    }
    events.add({
      'check': 'update preserves comment then GET',
      'status': 200,
      'score': list.single.score,
      'comment': list.single.comment,
    });
    await ratings.updateRating(
      memberId: member.memberId,
      ratingId: saved.ratingId,
      score: 3,
      comment: null,
    );
    list = await ratings.fetchMyRatings(member.memberId);
    if (list.single.comment != null) {
      throw StateError('Comment was not cleared');
    }
    events.add({
      'check': 'clear comment then GET',
      'status': 200,
      'comment': null,
    });
    await ratings.deleteRating(
      memberId: member.memberId,
      ratingId: saved.ratingId,
    );
    created.clear();
    list = await ratings.fetchMyRatings(member.memberId);
    if (list.isNotEmpty) throw StateError('List was not empty after deletion');
    events.add({
      'check': 'DELETE 204 then empty GET',
      'status': 204,
      'ratings': 0,
    });
    await expectError(
      'deleted rating missing',
      404,
      () => ratings.deleteRating(
        memberId: member.memberId,
        ratingId: saved.ratingId,
      ),
    );
    final evidence = {
      'verifiedAt': DateTime.now().toUtc().toIso8601String(),
      'baseUrl': movieLog.options.baseUrl,
      'events': events,
    };
    await Directory('docs/evidence').create(recursive: true);
    await File('docs/evidence/live-api.json')
        .writeAsString(const JsonEncoder.withIndent('  ').convert(evidence));
    stdout.writeln(
      'Live v6 verification passed: ${events.length} checks. Passwords omitted.',
    );
  } finally {
    for (final (memberId, ratingId) in created) {
      await ratings.deleteRating(memberId: memberId, ratingId: ratingId);
    }
    movieLog.close(force: true);
    tmdb.close(force: true);
  }
}
