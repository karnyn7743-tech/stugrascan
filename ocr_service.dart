import 'dart:typed_data';
import 'dart:math';

class OcrService {
  // دالة قراءة الدرجة المتواجدة على يسار كود الـ QR
  Future<String> readGradeFromLeftOfQr(Uint8List imageBytes) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // توليد درجة عشوائية ذكية تجريبية بين 18 و 30 تحاكي قراءة الـ OCR الحية من الورقة
    int mockGrade = 18 + Random().nextInt(13);
    return mockGrade.toString();
  }
}
