import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/view_models/load_status.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';

import 'fakes.dart';

RatingDto rating(int id, int movieId, {int score = 4, String? comment}) =>
    RatingDto(
      ratingId: id,
      movieId: movieId,
      score: score,
      comment: comment,
      createdAt: DateTime.utc(2026, 11, 7),
    );

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

  group('MovieDetailViewModel.createRating', () {
    test('TMDB id를 movieId로, 학습용 memberId path로 등록한다', () async {
      final ratings = FakeRatingApiService();
      final viewModel = MovieDetailViewModel(
        FakeTmdbMovieService(),
        ratings,
        42,
        550,
        initialMovie: movieDto(550),
      );
      await viewModel.load();
      await viewModel.createRating(score: 5, comment: '  최고  ');

      expect(viewModel.submitStatus, SubmitStatus.success);
      final call = ratings.createCalls.single;
      expect(call.memberId, 42);
      expect(call.request.toJson(), {
        'movieId': 550,
        'score': 5,
        'comment': '최고',
      });
    });

    test('extra로 받은 DTO로 먼저 그리고 상세 응답으로 교체한다', () async {
      final tmdb = FakeTmdbMovieService();
      final viewModel = MovieDetailViewModel(
        tmdb,
        FakeRatingApiService(),
        42,
        550,
        initialMovie: movieDto(550, title: '목록 제목'),
      );
      await viewModel.load();

      expect(viewModel.status, LoadStatus.success);
      expect(viewModel.movie?.title, 'TMDB 영화 550');
      expect(tmdb.detailCalls, [550]);
    });

    test('memberId가 없으면 요청하지 않고 회원가입을 안내한다', () async {
      final ratings = FakeRatingApiService();
      final viewModel = MovieDetailViewModel(
        FakeTmdbMovieService(),
        ratings,
        null,
        550,
      );
      await viewModel.load();

      expect(viewModel.canRate, isFalse);
      await viewModel.createRating(score: 3);
      expect(ratings.createCalls, isEmpty);
      expect(viewModel.submitMessage, '먼저 회원가입을 완료해 주세요.');
    });

    test('409 중복 등록은 서버 message를 그대로 보여준다', () async {
      final ratings = FakeRatingApiService()
        ..createError = dioError(
          409,
          '/v6/members/42/ratings',
          code: 'COMMON409',
          message: '이미 이 영화에 평점을 남기셨습니다.',
        );
      final viewModel = MovieDetailViewModel(
        FakeTmdbMovieService(),
        ratings,
        42,
        550,
      );
      await viewModel.load();
      await viewModel.createRating(score: 3);

      expect(viewModel.submitStatus, SubmitStatus.error);
      expect(viewModel.submitMessage, '이미 이 영화에 평점을 남기셨습니다.');
    });
  });

  group('MyRatingsViewModel 수정·삭제', () {
    MyRatingsViewModel build(FakeRatingApiService service) =>
        MyRatingsViewModel(service, FakeTmdbMovieService(), 42);

    test('수정 성공 뒤 목록을 다시 조회한다', () async {
      final service = FakeRatingApiService(
        ratings: [rating(1, 550, comment: '좋아요')],
      );
      final viewModel = build(service);
      await viewModel.load();

      await viewModel.updateRating(ratingId: 1, score: 2, comment: '다시 보니 별로');

      expect(service.updateCalls.single.memberId, 42);
      expect(service.fetchCalls, 2);
      expect(viewModel.ratings.single.rating.score, 2);
      expect(viewModel.ratings.single.rating.comment, '다시 보니 별로');
    });

    test('수정 403은 다시 던지고 목록을 다시 읽어 서버와 맞춘다', () async {
      final service = FakeRatingApiService(ratings: [rating(1, 550)])
        ..updateError = dioError(
          403,
          '/v6/members/42/ratings/1',
          code: 'COMMON403',
          message: '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.',
        );
      final viewModel = build(service);
      await viewModel.load();

      await expectLater(
        viewModel.updateRating(ratingId: 1, score: 3),
        throwsA(anything),
      );
      expect(service.fetchCalls, 2);
    });

    test('400은 다시 던지지만 목록은 다시 읽지 않는다', () async {
      final service = FakeRatingApiService(ratings: [rating(1, 550)])
        ..updateError = dioError(
          400,
          '/v6/members/42/ratings/1',
          code: 'COMMON400',
          message: '별점은 5점 이하여야 합니다.',
        );
      final viewModel = build(service);
      await viewModel.load();

      await expectLater(
        viewModel.updateRating(ratingId: 1, score: 3),
        throwsA(anything),
      );
      expect(service.fetchCalls, 1);
    });

    test('마지막 항목을 삭제하면 Empty가 된다', () async {
      final service = FakeRatingApiService(ratings: [rating(1, 550)]);
      final viewModel = build(service);
      await viewModel.load();

      await viewModel.deleteRating(1);

      expect(service.deleteCalls.single.ratingId, 1);
      expect(viewModel.status, LoadStatus.empty);
    });

    test('저장 성공 뒤 GET만 실패하면 저장 실패로 던지지 않고 재조회 안내를 남긴다', () async {
      final service = FakeRatingApiService(ratings: [rating(1, 550)]);
      final viewModel = build(service);
      await viewModel.load();

      service.errorStatus = 500;
      await viewModel.deleteRating(1); // 예외 없이 끝나야 합니다.

      expect(viewModel.status, LoadStatus.error);
      expect(viewModel.refreshWarning, contains('저장은 완료됐지만'));

      service.errorStatus = null;
      await viewModel.load();
      expect(viewModel.status, LoadStatus.empty);
      expect(viewModel.refreshWarning, isNull);
    });

    test('다중 삭제에서 일부만 실패하면 실패한 항목만 선택 상태로 남긴다', () async {
      final service = FakeRatingApiService(
        ratings: [rating(1, 550), rating(2, 13), rating(3, 680)],
      );
      service.deleteErrors[2] = dioError(500, '/v6/members/42/ratings/2');
      final viewModel = build(service);
      await viewModel.load();

      viewModel.enterEditMode();
      viewModel.toggleSelection(1);
      viewModel.toggleSelection(2);
      final pending = viewModel.deleteSelectedRatings();
      expect(viewModel.isDeletingSelected, isTrue);
      final failed = await pending;

      expect(failed, 1);
      expect(viewModel.isDeletingSelected, isFalse);
      expect(viewModel.selectedRatingIds, {2});
      expect(viewModel.isEditMode, isTrue);
      expect(viewModel.ratings.map((e) => e.rating.ratingId), [2, 3]);
    });

    test('다중 삭제가 모두 성공하면 편집 모드를 끝낸다', () async {
      final service = FakeRatingApiService(
        ratings: [rating(1, 550), rating(2, 13)],
      );
      final viewModel = build(service);
      await viewModel.load();

      viewModel.enterEditMode();
      viewModel.toggleSelection(1);
      viewModel.toggleSelection(2);
      expect(await viewModel.deleteSelectedRatings(), 0);

      expect(viewModel.isEditMode, isFalse);
      expect(viewModel.status, LoadStatus.empty);
    });
  });
}
