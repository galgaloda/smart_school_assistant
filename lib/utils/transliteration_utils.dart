class TransliterationUtils {
  // Simple Oromo to Amharic transliteration map
  static const Map<String, String> oromoToAmharic = {
    'aa': 'አ',
    'ee': 'ኢ',
    'ii': 'ኢ',
    'oo': 'ኦ',
    'uu': 'ኡ',
    'ba': 'ባ',
    'be': 'ቤ',
    'bi': 'ቢ',
    'bo': 'ቦ',
    'bu': 'ቡ',
    // Add more as needed
  };

  static String transliterateOromoToAmharic(String oromoText) {
    String result = oromoText.toLowerCase();
    oromoToAmharic.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    return result;
  }
}