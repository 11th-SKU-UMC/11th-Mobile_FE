import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';

import 'support/fake_services.dart';

void main() {
  test('닉네임과 이메일 상태는 서로 영향을 주지 않는다', () async {
    final service = FakeMemberCheckService(
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
    final service = FakeMemberCheckService(nickname: (_) => completer.future);
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
    final service = FakeMemberCheckService(
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
    final service = FakeMemberCheckService(
      nickname: (_) async => throw dioError(),
    );
    final viewModel = SignUpViewModel(service)..onNicknameChanged('무비러버');

    await viewModel.checkNickname('무비러버');

    expect(viewModel.nicknameCheckStatus, CheckStatus.error);
    expect(viewModel.nicknameErrorText, SignUpViewModel.networkErrorMessage);
  });

  test('형식이 틀렸거나 중복 상태면 요청하지 않는다', () async {
    final service = FakeMemberCheckService(nickname: (_) async => false);
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
    final service = FakeMemberCheckService(nickname: (_) => completer.future);
    final viewModel = SignUpViewModel(service)..onNicknameChanged('무비러버');

    final pending = viewModel.checkNickname('무비러버');
    viewModel.dispose();
    completer.complete(true);

    await expectLater(pending, completes);
  });
}
