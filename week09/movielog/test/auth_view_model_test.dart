import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/view_models/auth_view_model.dart';

import 'support/fake_services.dart';

void main() {
  late MemoryTokenStorage storage;
  late FakeAuthApiService authApi;
  late FakeMemberApiService members;
  late AuthViewModel auth;

  setUp(() {
    storage = MemoryTokenStorage();
    authApi = FakeAuthApiService();
    members = FakeMemberApiService();
    auth = AuthViewModel(authApi, members, storage);
  });

  group('restoreSession', () {
    test('저장된 토큰이 없으면 GET me 없이 signedOut', () async {
      await auth.restoreSession();

      expect(auth.status, AuthStatus.signedOut);
      expect(members.fetchCalls, 0);
    });

    test('토큰이 있어도 GET me 검증이 끝난 뒤에만 signedIn', () async {
      storage.token = testToken;
      final gate = Completer<MemberInfo>();
      members.fetchHandler = () => gate.future;

      final pending = auth.restoreSession();
      await Future<void>.delayed(Duration.zero);
      expect(auth.status, AuthStatus.initializing);

      gate.complete(member());
      await pending;
      expect(auth.status, AuthStatus.signedIn);
      expect(auth.member?.nickname, '무비러버');
      expect(auth.memberStatus, MemberLoadStatus.success);
    });

    for (final code in ['AUTH401_2', 'AUTH401_3', 'AUTH401_4']) {
      test('$code면 토큰을 지우고 만료로 signedOut', () async {
        storage.token = testToken;
        members.fetchHandler = () async =>
            throw commonError(401, code, '인증 오류');

        await auth.restoreSession();

        expect(auth.status, AuthStatus.signedOut);
        expect(auth.sessionExpired, isTrue);
        expect(storage.token, isNull);
      });
    }

    test('네트워크 실패는 토큰을 지우지 않고 retryRequired', () async {
      storage.token = testToken;
      members.fetchHandler = () async => throw dioError();

      await auth.restoreSession();

      expect(auth.status, AuthStatus.retryRequired);
      expect(auth.message, AuthViewModel.sessionCheckFailedMessage);
      expect(storage.token, testToken);
      expect(storage.deleteCalls, 0);

      // 재시도에서 성공하면 signedIn
      members.fetchHandler = null;
      await auth.restoreSession();
      expect(auth.status, AuthStatus.signedIn);
    });

    test('저장소를 읽지 못하면 retryRequired이고 토큰을 지우지 않는다', () async {
      storage.readError = StateError('keychain');

      await auth.restoreSession();

      expect(auth.status, AuthStatus.retryRequired);
      expect(auth.message, AuthViewModel.storageReadFailedMessage);
      expect(storage.deleteCalls, 0);
    });
  });

  group('login', () {
    test('성공하면 토큰을 저장하고 signedIn. 내 정보는 아직 부르지 않는다', () async {
      await auth.login('movie@example.com', 'movie1234');

      expect(auth.status, AuthStatus.signedIn);
      expect(storage.token, testToken);
      expect(members.fetchCalls, 0);
    });

    test('AUTH401_1은 Form 오류 문구만 남기고 만료로 보지 않는다', () async {
      authApi.handler = (_) async =>
          throw commonError(401, 'AUTH401_1', '이메일 또는 비밀번호가 틀렸습니다.');

      await auth.login('movie@example.com', 'wrong1234');

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.message, AuthViewModel.invalidCredentialsMessage);
      expect(auth.sessionExpired, isFalse);
      expect(storage.saveCalls, 0);
    });

    test('네트워크 실패는 로그인 실패 문구와 구분한다', () async {
      authApi.handler = (_) async => throw dioError();

      await auth.login('movie@example.com', 'movie1234');

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.message, AuthViewModel.loginFailedMessage);
    });
  });

  group('loadMember', () {
    test('네트워크 실패는 로그아웃하지 않고 토큰을 유지하며 error로 남긴다', () async {
      await auth.login('movie@example.com', 'movie1234');
      members.fetchHandler = () async => throw dioError();

      await auth.loadMember();

      expect(auth.status, AuthStatus.signedIn);
      expect(auth.memberStatus, MemberLoadStatus.error);
      expect(storage.token, testToken);

      members.fetchHandler = null;
      await auth.loadMember(force: true);
      expect(auth.memberStatus, MemberLoadStatus.success);
    });

    test('AUTH401_3이면 세션을 정리하고 만료 표시를 켠다', () async {
      await auth.login('movie@example.com', 'movie1234');
      members.fetchHandler = () async =>
          throw commonError(401, 'AUTH401_3', '유효하지 않은 토큰입니다.');

      await auth.loadMember();

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.member, isNull);
      expect(auth.sessionExpired, isTrue);
      expect(storage.token, isNull);

      auth.consumeSessionExpired();
      expect(auth.sessionExpired, isFalse);
    });

    test('DioException 외 예외도 loading에 멈추지 않는다', () async {
      await auth.login('movie@example.com', 'movie1234');
      members.fetchHandler = () async => throw StateError('형식 오류');

      await auth.loadMember();

      expect(auth.memberStatus, MemberLoadStatus.error);
      expect(auth.status, AuthStatus.signedIn);
    });
  });

  group('sessionVersion', () {
    test('직접 로그아웃은 토큰을 지우지만 만료 Snackbar 표시는 켜지 않는다', () async {
      await auth.login('movie@example.com', 'movie1234');
      final before = auth.sessionVersion;

      await auth.logout();

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.sessionExpired, isFalse);
      expect(storage.token, isNull);
      expect(auth.sessionVersion, greaterThan(before));
    });

    test('로그아웃 뒤 늦게 도착한 GET me 응답은 반영하지 않는다', () async {
      await auth.login('movie@example.com', 'movie1234');
      final gate = Completer<MemberInfo>();
      members.fetchHandler = () => gate.future;

      final pending = auth.loadMember();
      await auth.logout();
      gate.complete(member());
      await pending;

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.member, isNull);
    });

    test('이전 세션에서 늦게 온 401이 새로 로그인한 세션을 지우지 않는다', () async {
      await auth.login('movie@example.com', 'movie1234');
      final gate = Completer<MemberInfo>();
      members.fetchHandler = () => gate.future;
      final stale = auth.loadMember();

      await auth.logout();
      await auth.login('other@example.com', 'other1234');
      gate.completeError(commonError(401, 'AUTH401_4', '토큰이 만료되었습니다.'));
      await stale;

      expect(auth.status, AuthStatus.signedIn);
      expect(auth.sessionExpired, isFalse);
      expect(storage.token, testToken);
    });

    test('dispose 뒤에 끝난 로그인은 상태를 바꾸거나 알리지 않는다', () async {
      final gate = Completer<void>();
      authApi.handler = (_) async {
        await gate.future;
        throw commonError(401, 'AUTH401_1', '실패');
      };
      var notified = 0;
      auth.addListener(() => notified++);

      final pending = auth.login('movie@example.com', 'movie1234');
      final afterStart = notified;
      auth.dispose();
      gate.complete();
      await pending;

      expect(auth.status, AuthStatus.authenticating);
      expect(notified, afterStart);
    });
  });
}
