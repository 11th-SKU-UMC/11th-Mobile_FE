import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/view_models/auth_view_model.dart';

void main() {
  const protectedPaths = [
    '/home',
    '/movies',
    '/movies/550',
    '/my',
    '/my/ratings',
    '/my/profile/edit',
  ];

  group('authRedirect', () {
    for (final status in [AuthStatus.initializing, AuthStatus.retryRequired]) {
      test('$status: 스플래시(/start)에 머문다', () {
        expect(authRedirect(status, '/start'), isNull);
        for (final path in [...protectedPaths, '/login', '/register']) {
          expect(authRedirect(status, path), '/start', reason: path);
        }
      });
    }

    for (final status in [AuthStatus.signedOut, AuthStatus.authenticating]) {
      test('$status: 공개 화면(/login, /register)만 허용하고 나머지는 /login', () {
        expect(authRedirect(status, '/login'), isNull);
        expect(authRedirect(status, '/register'), isNull);
        for (final path in [...protectedPaths, '/start']) {
          expect(authRedirect(status, path), '/login', reason: path);
        }
      });
    }

    test('signedIn: 스플래시·로그인·회원가입은 /home, 보호 화면은 그대로', () {
      for (final path in ['/start', '/login', '/register']) {
        expect(authRedirect(AuthStatus.signedIn, path), '/home', reason: path);
      }
      for (final path in protectedPaths) {
        expect(authRedirect(AuthStatus.signedIn, path), isNull, reason: path);
      }
    });
  });
}
