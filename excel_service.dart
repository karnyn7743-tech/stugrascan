import 'dart:typed_data';
import 'package:excel/excel.dart';

class ExcelService {
  Excel? _excel;

  bool loadExcel(Uint8List bytes) {
    try {
      _excel = Excel.decodeBytes(bytes);
      return true;
    } catch (e) {
      print("Error loading Excel file: $e");
      return false;
    }
  }

  List<String> getSubjects() {
    if (_excel == null) return [];
    try {
      var sheet = _excel!.tables[_excel!.tables.keys.first];
      if (sheet == null || sheet.maxRows == 0) return [];

      List<String> subjects = [];
      var firstRow = sheet.rows.first;

      // المواد تبدأ من العمود الخامس (المؤشر 4)
      for (int i = 4; i < firstRow.length; i++) {
        if (firstRow[i] != null && firstRow[i]!.value != null) {
          subjects.add(firstRow[i]!.value.toString().trim());
        }
      }
      return subjects;
    } catch (e) {
      print("Error reading subjects: $e");
      return [];
    }
  }

  Map<String, String>? getStudentByQR(String qrCode) {
    if (_excel == null) return null;
    try {
      var sheet = _excel!.tables[_excel!.tables.keys.first];
      if (sheet == null) return null;

      for (int i = 1; i < sheet.maxRows; i++) {
        var row = sheet.rows[i];
        if (row.length > 3 && row[3] != null && row[3]!.value != null) {
          String cellValue = row[3]!.value.toString().trim();

          if (cellValue == qrCode.trim()) {
            String studentName = "طالب مجهول";
            if (row.length > 1 && row[1] != null && row[1]!.value != null) {
              studentName = row[1]!.value.toString().trim();
            }

            return {
              'name': studentName,
              'code': qrCode,
              'rowIndex': i.toString()
            };
          }
        }
      }
    } catch (e) {
      print("Error searching for student: $e");
    }
    return null;
  }

  bool saveGrade(String qrCode, String subject, String grade) {
    if (_excel == null) return false;
    try {
      var sheet = _excel!.tables[_excel!.tables.keys.first];
      if (sheet == null) return false;

      int studentRow = -1;
      for (int i = 1; i < sheet.maxRows; i++) {
        var row = sheet.rows[i];
        if (row.length > 3 && row[3] != null && row[3]!.value != null) {
          if (row[3]!.value.toString().trim() == qrCode.trim()) {
            studentRow = i;
            break;
          }
        }
      }

      int subjectCol = -1;
      var firstRow = sheet.rows.first;
      for (int j = 4; j < firstRow.length; j++) {
        if (firstRow[j] != null && firstRow[j]!.value != null) {
          if (firstRow[j]!.value.toString().trim() == subject.trim()) {
            subjectCol = j;
            break;
          }
        }
      }

      if (studentRow != -1 && subjectCol != -1) {
        var cell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: subjectCol, rowIndex: studentRow));

        // 💡 إسناد القيمة بطريقة مرنة تتوافق مع إصدارات مكتبة Excel المختلفة وتمنع الخطأ البرمجي
        try {
          cell.value = TextCellValue(grade);
        } catch (_) {
          // طريقة احتياطية للإصدارات الأقدم
          cell.value = grade as CellValue?;
        }
        return true;
      }
    } catch (e) {
      print("Error saving grade: $e");
    }
    return false;
  }
}
