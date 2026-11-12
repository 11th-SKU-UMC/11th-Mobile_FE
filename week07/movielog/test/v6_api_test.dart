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
    test('중복 확인은 v6 path를 쓴다', () async {
      final recorder = _Recorder((o) => _response(o, 200, {'available': true}));
      final service = SignUpService(recorder.dio);

      await service.checkNickname('무비 러버');
      await service.checkEmail('a@b.com');

      expect(recorder.requests.map((r) => r.path), [
        '/v6/members/nickname/${Uri.encodeComponent('무비 러버')}',
        '/v6/members/email/${Uri.encodeComponent('a@b.com')}',
      ]);
    });

    test('signUp은 POST /v6/members로 보내고 result.memberId를 읽는다', () async {
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
      expect(recorder.requests.single.path, '/v6/members');
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

  group('RatingApiService', () {
    test('조회는 GET /v6, 등록은 201을 확인하고 POST body에 movieId·score를 담는다', () async {
      final recorder = _Recorder(
        (o) => o.method == 'GET'
            ? _response(o, 200, <dynamic>[])
            : _response(o, 201, {
                'isSuccess': true,
                'code': 'COMMON201',
                'message': '성공',
                'result': null,
              }),
      );
      final service = RatingApiService(recorder.dio);

      await service.fetchMyRatings(7);
      await service.createRating(
        memberId: 7,
        request: const CreateRatingRequest(movieId: 550, score: 5),
      );

      expect(recorder.requests[0].path, '/v6/members/7/ratings');
      expect(recorder.requests[1].method, 'POST');
      expect(recorder.requests[1].path, '/v6/members/7/ratings');
      expect(recorder.requests[1].data, {'movieId': 550, 'score': 5});
    });

    test('등록이 201이 아니면 StateError', () async {
      final recorder = _Recorder((o) => _response(o, 200, {}));

      await expectLater(
        RatingApiService(recorder.dio).createRating(
          memberId: 7,
          request: const CreateRatingRequest(movieId: 550, score: 5),
        ),
        throwsStateError,
      );
    });

    test('수정은 comment가 null이어도 score와 함께 항상 보낸다', () async {
      final recorder = _Recorder((o) => _response(o, 200, {}));

      await RatingApiService(
        recorder.dio,
      ).updateRating(memberId: 7, ratingId: 3, score: 2, comment: null);

      final request = recorder.requests.single;
      expect(request.method, 'PATCH');
      expect(request.path, '/v6/members/7/ratings/3');
      expect(request.data, {'score': 2, 'comment': null});
      expect((request.data as Map).containsKey('comment'), isTrue);
    });

    test('삭제는 204 body 없음을 파싱하지 않고, 204가 아니면 StateError', () async {
      final ok = _Recorder((o) => _response(o, 204));
      await RatingApiService(ok.dio).deleteRating(memberId: 7, ratingId: 3);
      expect(ok.requests.single.method, 'DELETE');
      expect(ok.requests.single.path, '/v6/members/7/ratings/3');

      final unexpected = _Recorder((o) => _response(o, 200, {}));
      await expectLater(
        RatingApiService(unexpected.dio).deleteRating(memberId: 7, ratingId: 3),
        throwsStateError,
      );
    });

    test('writeErrorMessage는 서버 message를 쓰고, 403·404만 재조회 대상이다', () {
      final forbidden = commonError(
        403,
        'COMMON403',
        '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.',
      );
      expect(writeErrorMessage(forbidden), '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.');
      expect(shouldRefreshAfterRatingError(forbidden), isTrue);
      expect(
        shouldRefreshAfterRatingError(
          commonError(404, 'COMMON404', '존재하지 않는 평점입니다.'),
        ),
        isTrue,
      );
      expect(
        shouldRefreshAfterRatingError(
          commonError(409, 'COMMON409', '이미 이 영화에 평점을 남기셨습니다.'),
        ),
        isFalse,
      );
      expect(
        shouldRefreshAfterRatingError(
          commonError(400, 'COMMON400', '별점은 5점 이하여야 합니다.'),
        ),
        isFalse,
      );
      expect(writeErrorMessage(dioError()), '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.');
    });
  });
}
