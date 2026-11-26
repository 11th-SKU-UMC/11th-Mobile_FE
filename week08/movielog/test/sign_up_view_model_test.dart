import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';

import 'fakes.dart';

const request = CreateMemberRequest(
  email: ' lover@umc.com ',
  password: 'Movie123!',
  nickname: ' 무비러버 ',
);

void main() {
  group('SignUpViewModel.submit', () {
    test('성공하면 result.memberId를 createdMemberId로 보관한다', () async {
      final service = FakeSignUpService(createdMemberId: 77);
      final viewModel = SignUpViewModel(service);

      await viewModel.submit(request);

      expect(viewModel.submitStatus, SubmitStatus.success);
      expect(viewModel.createdMemberId, 77);
      expect(service.signUpRequests.single.toJson(), {
        'email': 'lover@umc.com',
        'password': 'Movie123!',
        'nickname': '무비러버',
      });
    });

    test('비밀번호 400은 passwordErrorText로, 입력을 바꾸면 지운다', () async {
      const message = '비밀번호는 대문자/소문자/숫자/특수문자를 포함한 8자 이상이어야 합니다.';
      final service = FakeSignUpService()
        ..signUpError = dioError(
          400,
          '/v6/members',
          code: 'COMMON400',
          message: message,
        );
      final viewModel = SignUpViewModel(service);

      await viewModel.submit(request);

      expect(viewModel.submitStatus, SubmitStatus.error);
      expect(viewModel.passwordErrorText, message);
      expect(viewModel.snackbarMessage, isNull);

      viewModel.onPasswordChanged();
      expect(viewModel.passwordErrorText, isNull);
    });

    test('비밀번호와 무관한 400과 409는 snackbarMessage로 보여준다', () async {
      final service = FakeSignUpService()
        ..signUpError = dioError(
          400,
          '/v6/members',
          code: 'COMMON400',
          message: '올바른 이메일 형식이 아닙니다.',
        );
      final viewModel = SignUpViewModel(service);
      await viewModel.submit(request);
      expect(viewModel.passwordErrorText, isNull);
      expect(viewModel.snackbarMessage, '올바른 이메일 형식이 아닙니다.');
    });

    test('최종 409는 서버 message를 보여주고 해당 필드를 중복 상태로 되돌린다', () async {
      final service = FakeSignUpService();
      final viewModel = SignUpViewModel(service);
      viewModel.onEmailChanged('lover@umc.com');
      await viewModel.checkEmail('lover@umc.com');
      expect(viewModel.emailCheckStatus, CheckStatus.available);

      service.signUpError = dioError(
        409,
        '/v6/members',
        code: 'COMMON409',
        message: '이미 사용 중인 이메일입니다.',
      );
      await viewModel.submit(request);

      expect(viewModel.snackbarMessage, '이미 사용 중인 이메일입니다.');
      expect(viewModel.emailCheckStatus, CheckStatus.duplicated);
      expect(viewModel.isAllChecked, isFalse);
    });

    test('통신 실패처럼 body가 없으면 기본 문구를 쓴다', () async {
      final service = FakeSignUpService()
        ..signUpError = dioError(500, '/v6/members');
      final viewModel = SignUpViewModel(service);
      await viewModel.submit(request);
      expect(viewModel.snackbarMessage, '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.');
    });

    test('제출 중에는 다시 제출해도 요청을 한 번만 보낸다', () async {
      final service = FakeSignUpService()..signUpGate = Completer<void>();
      final viewModel = SignUpViewModel(service);

      final first = viewModel.submit(request);
      expect(viewModel.isSubmitting, isTrue);
      expect(viewModel.canCheckEmail, isFalse);
      await viewModel.submit(request);
      service.signUpGate!.complete();
      await first;

      expect(service.signUpRequests.length, 1);
      expect(viewModel.submitStatus, SubmitStatus.success);
    });
  });
}
