import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di.dart';
import 'features/quran/state/quran_bloc.dart';
import 'features/quran/screens/surah_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(const IslamicApp());
}

class IslamicApp extends StatelessWidget {
  const IslamicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Islamic App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          brightness: Brightness.light,
        ),
        fontFamily: 'Poppins', // Latin text ke liye
      ),
      home: BlocProvider(
        create: (_) => sl<QuranBloc>(),
        child: const SurahListScreen(),
      ),
    );
  }
}