import 'dart:typed_data';

class QrService {
  // دالة محاكاة قراءة الـ QR من الصورة المرفوعة (تتغير تلقائياً للفحص والتجربة على الويندوز)
  Future<String> scanQrFromImage(Uint8List imageBytes, int counter) async {
    await Future.delayed(
        const Duration(milliseconds: 500)); // محاكاة وقت المعالجة

    // أول ضغطة تعطي الطالب ابراهيم 2333 ثم تتسلسل تسلسلاً ذكياً
    if (counter == 0) return "2333";
    return (2333 + counter).toString();
  }
}
