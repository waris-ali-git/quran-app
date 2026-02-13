import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  try {
    print('Fetching Surah 114 (Nas)...');
    // Request multiple editions to mimic app behavior
    final response = await dio.get('http://api.alquran.cloud/v1/surah/114/editions/quran-uthmani,quran-tajweed');
    
    final data = response.data['data'] as List;
    final arabicData = data[0]; // Uthmani data directly
    
    print('Surah: ${arabicData['englishName']}');
    final ayahs = arabicData['ayahs'] as List;
    
    for (var ayahJson in ayahs) {
        final number = ayahJson['number']; // Global number
        final numberInSurah = ayahJson['numberInSurah'];
        
        final generatedUrl = 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$number.mp3';
        
        print('Ayah $numberInSurah (Global ID: $number) -> URL: $generatedUrl');
    }

  } catch (e) {
    print('Error: $e');
  }
}
