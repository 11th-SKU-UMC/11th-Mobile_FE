/// [values]를 [convert]로 바꾸되 동시에 최대 [concurrency]개만 실행한다.
///
/// 결과는 입력과 같은 순서로 돌려준다. [convert]가 던지면 전체가 실패하므로
/// 항목별 실패를 남기려면 [convert] 안에서 결과 값으로 바꿔 돌려준다.
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
