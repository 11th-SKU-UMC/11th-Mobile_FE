import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/check_result.dart';
import 'package:movielog/data/models/rating_dto.dart';

// Guided B-1: 작은 JSON 조각으로 모델 파싱을 먼저 검증합니다.
// 실행: flutter test test/rating_dto_test.dart
void main() {
  group('RatingDto.fromJson', () {
    test('comment가 있는 응답을 변환한다', () {
      final dto = RatingDto.fromJson({
        'ratingId': 12,
        'movieId': 550,
        'score': 5,
        'comment': '최고의 영화!',
        'createdAt': '2026-09-06T12:14:03.000Z',
        'updatedAt': '2026-09-06T12:14:03.000Z',
      });

      expect(dto.ratingId, 12);
      expect(dto.movieId, 550);
      expect(dto.score, 5);
      expect(dto.comment, '최고의 영화!');
      expect(dto.createdAt, DateTime.utc(2026, 9, 6, 12, 14, 3));
    });

    test('comment가 null이어도 변환된다', () {
      final dto = RatingDto.fromJson({
        'ratingId': 13,
        'movieId': 603,
        'score': 4,
        'comment': null,
        'createdAt': '2026-09-07T01:00:00.000Z',
        'updatedAt': '2026-09-07T01:00:00.000Z',
      });

      expect(dto.comment, isNull);
      expect(dto.score, 4);
    });
  });

  group('CheckResult.fromJson', () {
    test('available: true', () {
      expect(CheckResult.fromJson({'available': true}).available, isTrue);
    });

    test('available: false', () {
      expect(CheckResult.fromJson({'available': false}).available, isFalse);
    });
  });
}
