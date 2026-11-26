/// [values]를 [convert]로 바꾸되, 동시에 진행하는 요청을 최대 [concurrency]개로 제한합니다.
///
/// 결과는 입력과 같은 순서로 돌려줍니다. [convert]가 던진 오류는 그대로 전파되므로
/// 카드별 실패를 허용하려면 [convert] 안에서 실패를 결과 값으로 바꿔야 합니다.
Future<List<R>> mapBounded<T, R>(
  Iterable<T> values,
  int concurrency,
  Future<R> Function(T value) convert,
) async {
  final input = values.toList(growable: false);
  if (input.isEmpty) return <R>[];
  if (concurrency <= 0) {
    throw ArgumentError.value(concurrency, 'concurrency', 'must be positive');
  }
  final output = List<R?>.filled(input.length, null);
  var next = 0;

  // worker는 남은 입력을 하나씩 가져가 처리합니다. Dart는 단일 스레드라 next++가 겹치지 않습니다.
  Future<void> worker() async {
    while (true) {
      final index = next++;
      if (index >= input.length) return;
      output[index] = await convert(input[index]);
    }
  }

  final workers = List.generate(
    concurrency.clamp(1, input.length),
    (_) => worker(),
  );
  await Future.wait(workers);
  return output.cast<R>();
}
