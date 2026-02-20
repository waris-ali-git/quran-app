import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  try {
    print('Fetching Surah 114 (Nas)...');
    // Check Tafseer edition (e.g., ur.tafheem or ur.maududi)
    final response = await dio.get('http://api.alquran.cloud/v1/surah/114/editions/ur.maududi');
    
    final data = response.data['data'] as List;
    final tafseerData = data[0]; 
    
    print('Edition: ${tafseerData['edition']['identifier']} - ${tafseerData['edition']['name']}');
    
    print('Surah: ${tafseerData['englishName']}');
    final ayahs = tafseerData['ayahs'] as List;
    
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
