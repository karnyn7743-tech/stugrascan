import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:excel/excel.dart' as my_excel;
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  String? _excelPath;
  String? _scannedSecretCode;
  String? _studentName;

  List<String> _dynamicSubjects = [];
  String? _selectedSubject;
  int _selectedSubjectIndexInFile = -1;

  final TextEditingController _gradeController = TextEditingController();
  final MobileScannerController cameraController = MobileScannerController();
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void dispose() {
    _gradeController.dispose();
    cameraController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  void _pickExcelFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null && result.files.single.path != null) {
      String path = result.files.single.path!;
      var bytes = File(path).readAsBytesSync();
      var excel = my_excel.Excel.decodeBytes(bytes);
      String sheetName = excel.tables.keys.first;
      var sheet = excel.tables[sheetName]!;

      List<String> extractedSubjects = [];
      if (sheet.maxRows > 0) {
        var headerRow = sheet.rows[0];
        for (int i = 4; i < headerRow.length; i++) {
          var cellValue = headerRow[i]?.value?.toString();
          if (cellValue != null && cellValue.trim().isNotEmpty) {
            extractedSubjects.add(cellValue.trim());
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _excelPath = path;
        _dynamicSubjects = extractedSubjects;
        if (extractedSubjects.isNotEmpty) {
          _selectedSubject = extractedSubjects.first;
          _selectedSubjectIndexInFile = 1;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم تحميل ملف الدرجات وتنشيط الفحص الثلاثي الأمني!')),
      );
    }
  }

  void _onBarcodeDetected(BarcodeCapture capture) async {
    if (_excelPath == null || _selectedSubject == null) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && _scannedSecretCode == null) {
        String secretCode = barcode.rawValue!;

        await cameraController.stop();

        String detectedSubjectNumber = "";
        String detectedGrade = "";

        if (capture.image != null) {
          final InputImage inputImage = InputImage.fromBytes(
            bytes: capture.image!,
            metadata: InputImageMetadata(
              size: Size(capture.size.width, capture.size.height),
              rotation: InputImageRotation.rotation0deg,
              format: InputImageFormat.nv21,
              bytesPerRow: capture.size.width.toInt(),
            ),
          );

          final RecognizedText recognizedText =
              await _textRecognizer.processImage(inputImage);

          RegExp regExp = RegExp(r'[0-9٠-٩]+');
          Iterable<Match> matches = regExp.allMatches(recognizedText.text);
          List<String> foundNumbers = [];

          for (Match match in matches) {
            foundNumbers.add(_convertHindiToArabicDigits(match.group(0) ?? ""));
          }

          if (foundNumbers.length >= 2) {
            detectedSubjectNumber = foundNumbers.first;
            detectedGrade = foundNumbers.last;
          } else if (foundNumbers.length == 1) {
            detectedGrade = foundNumbers.first;
          }
        }

        _verifyThreeZones(secretCode, detectedSubjectNumber, detectedGrade);
        break;
      }
    }
  }

  String _convertHindiToArabicDigits(String input) {
    var hindiDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    for (int i = 0; i < hindiDigits.length; i++) {
      input = input.replaceAll(hindiDigits[i], englishDigits[i]);
    }
    return input;
  }

  void _verifyThreeZones(String secretCode, String subjectNum, String grade) {
    if (subjectNum.isNotEmpty &&
        subjectNum != _selectedSubjectIndexInFile.toString()) {
      _showSecurityWarningDialog(subjectNum);
      return;
    }

    var bytes = File(_excelPath!).readAsBytesSync();
    var excel = my_excel.Excel.decodeBytes(bytes);
    String sheetName = excel.tables.keys.first;
    var sheet = excel.tables[sheetName]!;

    bool found = false;
    String name = "";

    for (int i = 1; i < sheet.maxRows; i++) {
      var row = sheet.rows[i];
      if (row.length > 3 && row[3]?.value?.toString() == secretCode) {
        name = row[1]?.value?.toString() ?? 'اسم غير معروف';
        found = true;
        break;
      }
    }

    if (found) {
      setState(() {
        _scannedSecretCode = secretCode;
        _studentName = name;
        _gradeController.text = grade;
      });

      _showConfirmationForm();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('الرقم السري ($secretCode) غير مسجل بالكشوفات!')),
      );
      cameraController.start();
    }
  }

  void _showSecurityWarningDialog(String wrongNum) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.gpp_bad, color: Colors.red),
              SizedBox(width: 8),
              Text('تنبيه: تعارض في مادة الرصد!')
            ],
          ),
          content: Text(
              'الورقة الحالية تتبع مادة رقم ($wrongNum)، بينما أنت تقوم حالياً برصد مادة "$_selectedSubject" رقم ($_selectedSubjectIndexInFile).\n\nيرجى تعديل المادة من القائمة السفلية أولاً وتكرار المسح من أجل سلامة البيانات.'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                cameraController.start();
              },
              child: const Text('فهمت، إعادة المحاولة',
                  style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  void _showConfirmationForm() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.edit_note, color: Colors.blue, size: 28),
                  SizedBox(width: 10),
                  Text('فورم مراجعة واعتماد الدرجة',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('اسم الطالب: $_studentName',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                    'مادة الرصد: $_selectedSubject (كود: $_selectedSubjectIndexInFile)',
                    style:
                        const TextStyle(color: Colors.blueGrey, fontSize: 13)),
                const Divider(),
                const Text(
                    'الدرجة المقروءة من الصندوق (عدّلها بيدك إذا لزم الأمر):',
                    style: TextStyle(fontSize: 14)),
                const SizedBox(height: 10),
                TextField(
                  controller: _gradeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    fillColor: Colors.grey[50],
                    filled: true,
                    suffixIcon: const Icon(Icons.calculate, color: Colors.blue),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('إلغاء العملية',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _scannedSecretCode = null;
                  });
                  cameraController.start();
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: const Text('حفظ واعتماد الدرجة',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.of(context).pop();
                  _executeSaveIntoExcel();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _executeSaveIntoExcel() {
    if (_excelPath == null ||
        _selectedSubject == null ||
        _scannedSecretCode == null) {
      return;
    }

    var bytes = File(_excelPath!).readAsBytesSync();
    var excel = my_excel.Excel.decodeBytes(bytes);
    String sheetName = excel.tables.keys.first;
    var sheet = excel.tables[sheetName]!;

    int subjectColumnIndex = 4 + _dynamicSubjects.indexOf(_selectedSubject!);
    bool updated = false;

    for (int i = 1; i < sheet.maxRows; i++) {
      var row = sheet.rows[i];
      if (row.length > 3 && row[3]?.value?.toString() == _scannedSecretCode) {
        sheet.updateCell(
          my_excel.CellIndex.indexByColumnRow(
              columnIndex: subjectColumnIndex, rowIndex: i),
          my_excel.TextCellValue(_gradeController.text),
        );
        updated = true;
        break;
      }
    }

    if (updated) {
      var fileBytes = excel.save();
      File(_excelPath!)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'تم رصد درجة الطالب بنجاح! الدرجة المعتمدة: ${_gradeController.text}')),
      );

      setState(() {
        _scannedSecretCode = null;
        _studentName = null;
        _gradeController.clear();
      });
      cameraController.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('نظام أبو الخضر للرصد الذكي'),
          centerTitle: true,
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.file_open),
              onPressed: _pickExcelFile,
              tooltip: 'تحميل ملف الإكسيل',
            )
          ],
        ),
        body: Column(
          children: [
            if (_excelPath == null)
              Container(
                color: Colors.red[100],
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                child: TextButton.icon(
                  onPressed: _pickExcelFile,
                  icon: const Icon(Icons.warning, color: Colors.red),
                  label: const Text(
                      'الرجاء تحديد ملف إكسيل الدرجات لتنشيط الفحص الجداري والمواد',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ),
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: cameraController,
                    onDetect: _onBarcodeDetected,
                  ),
                  Center(
                    child: Container(
                      width: 330,
                      height: 110,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.blue, width: 3),
                          bottom: BorderSide(color: Colors.blue, width: 3),
                          left: BorderSide(color: Colors.blue, width: 3),
                          right: BorderSide(color: Colors.blue, width: 3),
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_dynamicSubjects.isNotEmpty)
                        Row(
                          children: [
                            const Text('المادة الحالية: ',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedSubject,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                items: _dynamicSubjects.map((String sub) {
                                  return DropdownMenuItem<String>(
                                      value: sub, child: Text(sub));
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedSubject = val;
                                    _selectedSubjectIndexInFile =
                                        _dynamicSubjects.indexOf(val!) + 1;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            // تم حل المشكلة نهائياً هنا عبر إزالة السطر المسبب للتعارض وتمرير خلفية دائرية مستقرة ومتوافقة مع كل الأجهزة
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'كود المادة: $_selectedSubjectIndexInFile',
                                style: TextStyle(
                                    color: Colors.blue[900],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ),
                          ],
                        )
                      else
                        const Center(
                            child: Text(
                                'قم برفع ملف الإكسيل الدراسي لتنشيط الفحص الثلاثي وتأمين المواد.',
                                style: TextStyle(color: Colors.grey))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
