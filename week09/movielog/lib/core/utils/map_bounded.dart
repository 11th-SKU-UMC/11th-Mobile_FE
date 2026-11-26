import 'dart:math' as math;

Future<List<R>> mapBounded<T, R>(
  List<T> items,
  Future<R> Function(T item) transform, {
  required int concurrency,
}) async {
  RangeError.checkValueInInterval(concurrency, 1, 0x7fffffff);
  final results = List<R?>.filled(items.length, null);
  var next = 0;

  Future<void> work() async {
    while (next < items.length) {
      final index = next++;
      results[index] = await transform(items[index]);
    }
  }

  await Future.wait(
    List.generate(math.min(concurrency, items.length), (_) => work()),
  );
  return results.cast<R>();
}
