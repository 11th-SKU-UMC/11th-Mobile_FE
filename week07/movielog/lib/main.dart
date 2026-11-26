import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/movie_log_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // runApp 전에 .env 로드를 끝내야 Token이 빈 값으로 읽히지 않습니다.
  await dotenv.load(fileName: '.env', isOptional: true);
  runApp(const MovieLogApp());
}
