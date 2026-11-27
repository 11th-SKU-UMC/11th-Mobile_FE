import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';

import 'support/fake_services.dart';

void main() {
  test('닉네임과 이메일 상태는 서로 영향을 주지 않는다', () async {
    final service = FakeSignUpService(
      nickname: (_) async => false,
      email: (_) async => true,
    );
    final viewModel = SignUpViewModel(service)
      ..onNicknameChanged('무비러버')
      ..onEmailChanged('movie@example.com');

    await viewModel.checkNickname('무비러버');
    await viewModel.checkEmail('movie@example.com');

    expect(viewModel.nicknameCheckStatus, CheckStatus.duplicated);
    expect(viewModel.emailCheckStatus, CheckStatus.available);
    expect(viewModel.emailErrorText, isNull);
    expect(viewModel.isBothAvailable, isFalse);
  });

  test('통신 중에 입력이 바뀌면 늦게 온 응답을 버린다', () async {
    final completer = Completer<bool>();
    final service = FakeSignUpService(nickname: (_) => completer.future);
    final viewModel = SignUpViewModel(service)..onNicknameChanged('무비러버');

    final pending = viewModel.checkNickname('무비러버');
    expect(viewModel.nicknameCheckStatus, CheckStatus.checking);
    expect(viewModel.canCheckNickname, isFalse);

    viewModel.onNicknameChanged('무비러버2');
    completer.complete(false);
    await pending;

    expect(viewModel.nicknameCheckStatus, CheckStatus.idle);
    expect(viewModel.nicknameErrorText, isNull);
    // 버려진 응답의 '중복' 값은 기억하지 않는다.
    viewModel.onNicknameChanged('무비러버');
    expect(viewModel.nicknameCheckStatus, CheckStatus.idle);
  });

  test('DioException 외 예외도 checking에 멈추지 않고 error가 된다', () async {
    final service = FakeSignUpService(
      email: (_) async => throw const FormatException('bad body'),
    );
    final viewModel = SignUpViewModel(service)
      ..onEmailChanged('movie@example.com');

    await viewModel.checkEmail('movie@example.com');

    expect(viewModel.emailCheckStatus, CheckStatus.error);
    expect(viewModel.emailErrorText, SignUpViewModel.unknownErrorMessage);
    expect(viewModel.canCheckEmail, isTrue);
  });

  test('DioException은 중복과 다른 문구의 error가 된다', () async {
    final service = FakeSignUpService(nickname: (_) async => throw dioError());
    final viewModel = SignUpViewModel(service)..onNicknameChanged('무비러버');

    await viewModel.checkNickname('무비러버');

    expect(viewModel.nicknameCheckStatus, CheckStatus.error);
    expect(viewModel.nicknameErrorText, SignUpViewModel.networkErrorMessage);
  });

  test('형식이 틀렸거나 중복 상태면 요청하지 않는다', () async {
    final service = FakeSignUpService(nickname: (_) async => false);
    final viewModel = SignUpViewModel(service)..onNicknameChanged('a');

    await viewModel.checkNickname('a');
    expect(service.nicknameCalls, isEmpty);

    viewModel.onNicknameChanged('무비러버');
    await viewModel.checkNickname('무비러버');
    await viewModel.checkNickname('무비러버');
    expect(service.nicknameCalls, ['무비러버']);
  });

  test('dispose 뒤에 도착한 응답은 무시하고 오류를 내지 않는다', () async {
    final completer = Completer<bool>();
    final service = FakeSignUpService(nickname: (_) => completer.future);
    final viewModel = SignUpViewModel(service)..onNicknameChanged('무비러버');

    final pending = viewModel.checkNickname('무비러버');
    viewModel.dispose();
    completer.complete(true);

    await expectLater(pending, completes);
  });

  group('submit', () {
    const request = CreateMemberRequest(
      email: 'movie@example.com',
      password: 'Movie1234!',
      nickname: '무비러버',
    );

    SignUpViewModel available(FakeSignUpService service) {
      return SignUpViewModel(service)
        ..onNicknameChanged('무비러버')
        ..onEmailChanged('movie@example.com');
    }

    test('성공하면 createdMemberId를 저장하고 success가 된다', () async {
      final viewModel = available(FakeSignUpService());
      await viewModel.checkNickname('무비러버');
      await viewModel.checkEmail('movie@example.com');
      expect(viewModel.canSubmit, isTrue);

      final pending = viewModel.submit(request);
      expect(viewModel.submitStatus, SubmitStatus.submitting);
      expect(viewModel.canSubmit, isFalse);
      expect(viewModel.canCheckNickname, isFalse);
      await pending;

      expect(viewModel.submitStatus, SubmitStatus.success);
      expect(viewModel.createdMemberId, 42);
    });

    test('제출 중에 다시 눌러도 요청은 한 번만 간다', () async {
      final completer = Completer<CommonResponse<SignUpResult>>();
      final service = FakeSignUpService(signUpHandler: (_) => completer.future);
      final viewModel = available(service);

      final first = viewModel.submit(request);
      await viewModel.submit(request);
      completer.complete(signUpSuccess(1));
      await first;

      expect(service.signUpCalls, 1);
    });

    test('비밀번호가 언급된 400만 passwordErrorText, 다른 400은 Snackbar', () async {
      final passwordError = available(
        FakeSignUpService(
          signUpHandler: (_) async => throw commonError(
            400,
            'COMMON400',
            '비밀번호는 대문자/소문자/숫자/특수문자를 포함한 8자 이상이어야 합니다.',
          ),
        ),
      );
      await passwordError.submit(request);
      expect(passwordError.submitStatus, SubmitStatus.error);
      expect(passwordError.passwordErrorText, contains('비밀번호'));
      expect(passwordError.snackbarMessage, isNull);

      passwordError.onPasswordChanged();
      expect(passwordError.passwordErrorText, isNull);

      final otherError = available(
        FakeSignUpService(
          signUpHandler: (_) async =>
              throw commonError(400, 'COMMON400', '닉네임은 12자 이하여야 합니다.'),
        ),
      );
      await otherError.submit(request);
      expect(otherError.passwordErrorText, isNull);
      expect(otherError.takeSnackbarMessage(), '닉네임은 12자 이하여야 합니다.');
      expect(otherError.takeSnackbarMessage(), isNull);
    });

    test('409 닉네임 중복은 Snackbar와 함께 닉네임을 duplicated로 되돌린다', () async {
      final viewModel = available(
        FakeSignUpService(
          signUpHandler: (_) async =>
              throw commonError(409, 'COMMON409', '이미 사용 중인 닉네임입니다.'),
        ),
      );
      await viewModel.checkNickname('무비러버');
      await viewModel.checkEmail('movie@example.com');

      await viewModel.submit(request);

      expect(viewModel.snackbarMessage, '이미 사용 중인 닉네임입니다.');
      expect(viewModel.nicknameCheckStatus, CheckStatus.duplicated);
      expect(viewModel.emailCheckStatus, CheckStatus.available);
      expect(viewModel.canSubmit, isFalse);
    });

    test('result에 memberId가 없으면 가입 완료로 표시하지 않는다', () async {
      final viewModel = available(
        FakeSignUpService(
          signUpHandler: (_) async => const CommonResponse<SignUpResult>(
            isSuccess: true,
            code: 'COMMON201',
            message: '성공',
          ),
        ),
      );

      await viewModel.submit(request);

      expect(viewModel.submitStatus, SubmitStatus.error);
      expect(viewModel.createdMemberId, isNull);
      expect(viewModel.snackbarMessage, SignUpViewModel.contractErrorMessage);
    });

    test('DioException 외 예외도 submitting에 멈추지 않는다', () async {
      final viewModel = available(
        FakeSignUpService(signUpHandler: (_) async => throw TypeError()),
      );

      await viewModel.submit(request);

      expect(viewModel.submitStatus, SubmitStatus.error);
      expect(viewModel.snackbarMessage, SignUpViewModel.submitErrorMessage);
    });

    test('dispose 뒤에 도착한 가입 결과는 반영하지 않는다', () async {
      final completer = Completer<CommonResponse<SignUpResult>>();
      final viewModel = available(
        FakeSignUpService(signUpHandler: (_) => completer.future),
      );

      final pending = viewModel.submit(request);
      viewModel.dispose();
      completer.complete(signUpSuccess(9));
      await pending;

      expect(viewModel.createdMemberId, isNull);
    });
  });
}
