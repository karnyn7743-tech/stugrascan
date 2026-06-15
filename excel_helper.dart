import 'dart:typed_data';
import 'package:excel/excel.dart';

class ExcelHelper {
  Excel? excel;
  Sheet? currentSheet;
  Uint8List? webFileBytes;

  // دالة القراءة المخصصة للويب عبر البايتات مباشرة
  Future<bool> loadExcelFromBytes(Uint8List bytes) async {
    try {
      webFileBytes = bytes;
      excel = Excel.decodeBytes(bytes);

      if (excel!.tables.keys.isNotEmpty) {
        String firstSheetName = excel!.tables.keys.first;
        currentSheet = excel!.tables[firstSheetName];
        return true;
      }
      return false;
    } catch (e) {
      print("خطأ في قراءة ملف الأكسيل: $e");
      return false;
    }
  }

  // قراءة المواد من الصف الأول (الرأس)
  List<String> getSubjects() {
    List<String> subjects = [];
    if (currentSheet == null) return subjects;

    var headerRow = currentSheet!.rows.first;

    // الفحص من العمود 4 إلى 22 (المواد)
    for (int i = 4; i <= 22; i++) {
      if (i < headerRow.length) {
        var cellValue = headerRow[i]?.value;
        if (cellValue != null && cellValue.toString().trim().isNotEmpty) {
          subjects.add(cellValue.toString().trim());
        }
      }
    }
    return subjects;
  }

  // فحص الدرجة المسبقة لمنع التكرار
  String? checkExistingGrade(String secretCode, String selectedSubject) {
    if (currentSheet == null) return null;

    int subjectIndex = _getSubjectColumnIndex(selectedSubject);
    if (subjectIndex == -1) return null;

    for (var row in currentSheet!.rows.skip(1)) {
      var secretCellValue = row[3]?.value;

      if (secretCellValue != null &&
          secretCellValue.toString().trim() == secretCode.trim()) {
        var gradeValue = row[subjectIndex]?.value;
        if (gradeValue != null && gradeValue.toString().trim().isNotEmpty) {
          return gradeValue.toString().trim();
        }
        return "";
      }
    }
    return null;
  }

  // حفظ الدرجة في الذاكرة لتطبيق الويب
  bool saveGrade({
    required String secretCode,
    required String selectedSubject,
    required String newGrade,
    required String studentName,
  }) {
    if (currentSheet == null) return false;

    int subjectIndex = _getSubjectColumnIndex(selectedSubject);
    if (subjectIndex == -1) return false;

    for (var row in currentSheet!.rows.skip(1)) {
      var secretCellValue = row[3]?.value;

      if (secretCellValue != null &&
          secretCellValue.toString().trim() == secretCode.trim()) {
        var cell = row[subjectIndex];

        if (cell != null) {
          cell.value = TextCellValue(newGrade);
        } else {
          row[subjectIndex]?.value = TextCellValue(newGrade);
        }

        // تحديث البيانات في الذاكرة
        var fileBytes = excel!.save();
        if (fileBytes != null) {
          webFileBytes = Uint8List.fromList(fileBytes);
        }
        return true;
      }
    }
    return false;
  }

  // جلب معلومات الطالب بناء على الكود الممسوح
  Map<String, String>? getStudentInfo(String secretCode) {
    if (currentSheet == null) return null;

    for (var row in currentSheet!.rows.skip(1)) {
      var secretCellValue = row[3]?.value;
      if (secretCellValue != null &&
          secretCellValue.toString().trim() == secretCode.trim()) {
        var nameValue = row[1]?.value;
        return {
          "name": nameValue?.toString() ?? "بدون اسم",
          "code": secretCode,
        };
      }
    }
    return null;
  }

  int _getSubjectColumnIndex(String subjectName) {
    var headerRow = currentSheet!.rows.first;
    for (int i = 4; i <= 22; i++) {
      if (i < headerRow.length) {
        if (headerRow[i]?.value?.toString().trim() == subjectName.trim()) {
          return i;
        }
      }
    }
    return -1;
  }
}
