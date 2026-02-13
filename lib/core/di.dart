import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../features/quran/services/quran_service.dart';
import '../features/quran/state/quran_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> setupDependencies() async {
  // ─── Hive ──────────────────────────────────
  await Hive.initFlutter();
  final quranCacheBox = await Hive.openBox<dynamic>('quran_cache');

  // ─── Dio ───────────────────────────────────
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Accept': 'application/json',
      // Quran.com ke liye koi API key nahi chahiye
      // AlQuran.cloud ke liye bhi nahi
    },
  ));

  // Optional: Logging interceptor (debug mode mein)
  dio.interceptors.add(LogInterceptor(
    requestBody: false,
    responseBody: false,
    logPrint: (obj) => debugPrint('DIO: $obj'),
  ));

  // ─── Services ──────────────────────────────
  sl.registerLazySingleton<QuranService>(
        () => QuranService(dio, quranCacheBox),
  );

  // ─── BLoCs ─────────────────────────────────
  sl.registerFactory<QuranBloc>(
        () => QuranBloc(sl<QuranService>()),
  );
}