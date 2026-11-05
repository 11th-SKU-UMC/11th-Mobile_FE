import 'package:flutter_test/flutter_test.dart';

import 'package:movielog_week04/core/network/tmdb_client.dart';
import 'package:movielog_week04/data/services/tmdb_movie_service.dart';
import 'package:movielog_week04/main.dart';

void main() {
  testWidgets('MovieLog app starts', (WidgetTester tester) async {
    final movieService = TmdbMovieService(createTmdbClient());

    await tester.pumpWidget(MovieLogApp(movieService: movieService));

    expect(find.text('MovieLog'), findsNothing);
  });
}
