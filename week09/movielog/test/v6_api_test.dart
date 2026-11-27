import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';

import 'support/fake_services.dart';

/// 요청을 기록하고 [respond]가 정한 응답을 돌려주는 Dio. 실제 네트워크는 쓰지 않는다.
class _Recorder {
  _Recorder(this.respond);

  final Response<dynamic> Function(RequestOptions options) respond;
  final List<RequestOptions> requests = [];

  Dio get dio =>
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add(options);
              handler.resolve(respond(options));
            },
          ),
        );
}

Response<dynamic> _response(
  RequestOptions options,
  int statusCode, [
  Object? data,
]) => Response(requestOptions: options, statusCode: statusCode, data: data);

void main() {
  group('요청·응답 Model', () {
    test('CommonResponse는 result를 제네릭으로 파싱하고, null result를 허용한다', () {
      final response = CommonResponse<int>.fromJson({
        'isSuccess': true,
        'code': 'COMMON200',
        'message': 'OK',
        'result': null,
      }, (value) => value! as int);

      expect(response.isSuccess, isTrue);
      expect(response.result, isNull);
    });

    test('tryParseError는 공통 형식이 아니면 예외 없이 null을 준다', () {
      expect(CommonResponse.tryParseError('<html>'), isNull);
      expect(
        CommonResponse.tryParseError({'message': 'x', 'statusCode': 404}),
        isNull,
      );
    });

    test('CreateMemberRequest는 이메일·닉네임만 trim하고 비밀번호는 그대로 둔다', () {
      const request = CreateMemberRequest(
        email: ' a@b.com ',
        password: ' Pass1! ',
        nickname: ' 무비 ',
      );

      expect(request.toJson(), {
        'email': 'a@b.com',
        'password': ' Pass1! ',
        'nickname': '무비',
      });
    });

    test('CreateRatingRequest는 비어 있는 comment를 생략한다', () {
      expect(
        const CreateRatingRequest(
          movieId: 550,
          score: 4,
          comment: '  ',
        ).toJson(),
        {'movieId': 550, 'score': 4},
      );
      expect(
        const CreateRatingRequest(
          movieId: 550,
          score: 4,
          comment: ' 좋아 ',
        ).toJson(),
        {'movieId': 550, 'score': 4, 'comment': '좋아'},
      );
    });

    test('validateServerScore는 1~5 정수만 통과시킨다', () {
      expect(validateServerScore(3), 3);
      expect(() => validateServerScore(0), throwsArgumentError);
      expect(() => validateServerScore(3.5), throwsArgumentError);
      expect(() => validateServerScore(6), throwsArgumentError);
    });
  });

  group('SignUpService', () {
    test('중복 확인은 v8 path를 쓴다', () async {
      final recorder = _Recorder((o) => _response(o, 200, {'available': true}));
      final service = SignUpService(recorder.dio);

      await service.checkNickname('무비 러버');
      await service.checkEmail('a@b.com');

      expect(recorder.requests.map((r) => r.path), [
        '/v8/members/nickname/${Uri.encodeComponent('무비 러버')}',
        '/v8/members/email/${Uri.encodeComponent('a@b.com')}',
      ]);
    });

    test('signUp은 POST /v8/members로 보내고 result.memberId를 읽는다', () async {
      final recorder = _Recorder(
        (o) => _response(o, 201, {
          'isSuccess': true,
          'code': 'COMMON201',
          'message': '성공',
          'result': {'memberId': 7, 'email': 'a@b.com', 'nickname': '무비'},
        }),
      );

      final response = await SignUpService(recorder.dio).signUp(
        const CreateMemberRequest(
          email: 'a@b.com',
          password: 'Pass1234!',
          nickname: '무비',
        ),
      );

      expect(recorder.requests.single.method, 'POST');
      expect(recorder.requests.single.path, '/v8/members');
      expect(response.result?.memberId, 7);
    });

    test('writeSignUpErrorMessage는 서버 message를 그대로 쓰고, 형식이 다르면 기본 문구', () {
      expect(
        writeSignUpErrorMessage(
          commonError(409, 'COMMON409', '이미 사용 중인 이메일입니다.'),
        ),
        '이미 사용 중인 이메일입니다.',
      );
      expect(
        writeSignUpErrorMessage(dioError()),
        '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.',
      );
    });
  });

  group('RatingApiService (v8)', () {
    Map<String, dynamic> ratingJson({int ratingId = 12, int score = 5}) => {
      'ratingId': ratingId,
      'movieId': 550,
      'score': score,
      'comment': null,
      'createdAt': '2026-09-06T12:14:03.000Z',
      'updatedAt': '2026-09-06T12:14:03.000Z',
    };

    Map<String, dynamic> success(Object? result, {String code = 'COMMON200'}) =>
        {'isSuccess': true, 'code': code, 'message': '성공', 'result': result};

    test('유저별 조회는 공개 Client로 GET /v8, 등록은 보호 Client로 POST /v8/ratings에 보내고 '
        'body에 memberId가 없다', () async {
      final public = _Recorder((o) => _response(o, 200, [ratingJson()]));
      final auth = _Recorder(
        (o) => _response(o, 201, success(ratingJson(), code: 'COMMON201')),
      );
      final service = RatingApiService(public.dio, auth.dio);

      final list = await service.fetchMemberRatings(7);
      final created = await service.createRating(
        const CreateRatingRequest(movieId: 550, score: 5),
      );

      expect(public.requests.single.path, '/v8/members/7/ratings');
      expect(list.single.ratingId, 12);
      expect(auth.requests.single.method, 'POST');
      expect(auth.requests.single.path, '/v8/ratings');
      expect(auth.requests.single.data, {'movieId': 550, 'score': 5});
      // 등록 result는 Rating 객체다.
      expect(created.ratingId, 12);
    });

    test('등록 응답에 result(Rating)가 없으면 StateError', () async {
      final recorder = _Recorder(
        (o) => _response(o, 201, success(null, code: 'COMMON201')),
      );

      await expectLater(
        RatingApiService(
          Dio(),
          recorder.dio,
        ).createRating(const CreateRatingRequest(movieId: 550, score: 5)),
        throwsStateError,
      );
    });

    test('수정은 PATCH /v8/ratings/{id}로 comment가 null이어도 score와 함께 보내고 '
        'result Rating을 돌려준다', () async {
      final recorder = _Recorder(
        (o) => _response(o, 200, success(ratingJson(ratingId: 3, score: 2))),
      );

      final updated = await RatingApiService(
        Dio(),
        recorder.dio,
      ).updateRating(ratingId: 3, score: 2, comment: null);

      final request = recorder.requests.single;
      expect(request.method, 'PATCH');
      expect(request.path, '/v8/ratings/3');
      expect(request.data, {'score': 2, 'comment': null});
      expect((request.data as Map).containsKey('comment'), isTrue);
      expect(updated.score, 2);
    });

    test(
      '삭제는 DELETE /v8/ratings/{id}이고 200(result null)이 성공, 그 외는 StateError',
      () async {
        final ok = _Recorder((o) => _response(o, 200, success(null)));
        await RatingApiService(Dio(), ok.dio).deleteRating(3);
        expect(ok.requests.single.method, 'DELETE');
        expect(ok.requests.single.path, '/v8/ratings/3');

        // v6의 204는 이제 예상 밖 응답이다.
        final unexpected = _Recorder((o) => _response(o, 204));
        await expectLater(
          RatingApiService(Dio(), unexpected.dio).deleteRating(3),
          throwsStateError,
        );
      },
    );

    test('ratingErrorAction은 401 만료·403/409·404·그 외를 구분하고, '
        'writeErrorMessage는 code별 문구를 준다', () {
      for (final code in ['AUTH401_2', 'AUTH401_3', 'AUTH401_4']) {
        expect(
          ratingErrorAction(commonError(401, code, '인증 오류')),
          RatingErrorAction.expireSession,
        );
      }
      final forbidden = commonError(
        403,
        'RATING403_1',
        '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.',
      );
      expect(ratingErrorAction(forbidden), RatingErrorAction.snackbar);
      expect(writeErrorMessage(forbidden), '본인이 작성한 평점만 수정하거나 삭제할 수 있어요.');
      expect(
        ratingErrorAction(commonError(409, 'RATING409_1', '중복')),
        RatingErrorAction.snackbar,
      );
      expect(
        ratingErrorAction(commonError(404, 'RATING404_1', '없음')),
        RatingErrorAction.notFound,
      );
      final invalid = commonError(400, 'COMMON400', '별점은 5점 이하여야 합니다.');
      expect(ratingErrorAction(invalid), RatingErrorAction.inline);
      expect(writeErrorMessage(invalid), '별점은 5점 이하여야 합니다.');
      // 로그인 실패(AUTH401_1)는 보호 요청 만료가 아니다.
      expect(
        ratingErrorAction(commonError(401, 'AUTH401_1', '로그인 실패')),
        RatingErrorAction.inline,
      );
      expect(writeErrorMessage(dioError()), '네트워크 상태를 확인하고 다시 시도해 주세요.');
    });
  });
}
