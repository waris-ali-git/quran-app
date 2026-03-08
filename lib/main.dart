import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di.dart';
import 'features/quran/state/quran_bloc.dart';
import 'features/hadith/state/hadith_bloc.dart';
import 'features/home/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(const IslamicApp());
}

class IslamicApp extends StatelessWidget {
  const IslamicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<QuranBloc>()),
        BlocProvider(create: (_) => sl<HadithBloc>()),
      ],
      child: MaterialApp(
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
        home: const HomeScreen(),
      ),
    );
  }
}
