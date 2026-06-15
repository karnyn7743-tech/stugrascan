/// دالة ذكية لتحويل الأرقام الهندية (١٢٣) إلى أرقام إنجليزية قياسية (123)
/// لتجنب أخطاء الإدخال في ملف الأكسيل بسبب اختلاف خطوط المصححين
String convertToEnglishNumbers(String input) {
  const arabicHindiNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  const englishNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

  String result = input;
  for (int i = 0; i < arabicHindiNumbers.length; i++) {
    result = result.replaceAll(arabicHindiNumbers[i], englishNumbers[i]);
  }
  return result.trim();
}
