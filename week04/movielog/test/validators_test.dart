import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/utils/validators.dart';

void main() {
  group('Validators.nickname', () {
    test('빈 값이면 입력 안내를 반환한다', () {
      expect(Validators.nickname(null), '닉네임을 입력해주세요.');
      expect(Validators.nickname(''), '닉네임을 입력해주세요.');
      expect(Validators.nickname('   '), '닉네임을 입력해주세요.');
    });

    test('공백을 제외하고 2자 미만이면 오류를 반환한다', () {
      expect(Validators.nickname('a'), '닉네임은 2자 이상이어야 합니다.');
      expect(Validators.nickname(' a '), '닉네임은 2자 이상이어야 합니다.');
    });

    test('2자 이상이면 null을 반환한다', () {
      expect(Validators.nickname('무비'), isNull);
      expect(Validators.nickname('무비러버'), isNull);
    });
  });

  group('Validators.email', () {
    test('빈 값이면 입력 안내를 반환한다', () {
      expect(Validators.email(''), '이메일 주소를 입력해주세요.');
    });

    test('형식이 올바르지 않으면 오류를 반환한다', () {
      for (final value in ['test', 'test@', '@example.com', 'a@b', 'a b@c.com']) {
        expect(
          Validators.email(value),
          '올바른 이메일 형식이 아닙니다.',
          reason: value,
        );
      }
    });

    test('형식이 올바르면 null을 반환한다', () {
      expect(Validators.email('movie@example.com'), isNull);
      expect(Validators.email(' movie@example.com '), isNull);
    });
  });

  group('Validators.password', () {
    test('빈 값이면 입력 안내를 반환한다', () {
      expect(Validators.password(''), '비밀번호를 입력해주세요.');
    });

    test('8자 미만이면 길이 오류를 반환한다', () {
      expect(Validators.password('abc1234'), '비밀번호는 8자 이상이어야 합니다.');
    });

    test('영문이나 숫자가 빠지면 구성 오류를 반환한다', () {
      expect(
        Validators.password('abcdefgh'),
        '비밀번호는 영문과 숫자를 모두 포함해야 합니다.',
      );
      expect(
        Validators.password('12345678'),
        '비밀번호는 영문과 숫자를 모두 포함해야 합니다.',
      );
    });

    test('8자 이상이고 영문과 숫자를 포함하면 null을 반환한다', () {
      expect(Validators.password('movie1234'), isNull);
    });
  });
}
