import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class UploadSheetScreen extends StatefulWidget {
  final String courseCode;
  const UploadSheetScreen({super.key, required this.courseCode});

  @override
  State<UploadSheetScreen> createState() => _UploadSheetScreenState();
}

class _UploadSheetScreenState extends State<UploadSheetScreen> {
  bool _isLoading = false;
  String? _fileName;
  String _statusMessage = '';

  /// Pick an Excel/ODS file and process it
  Future<void> _pickAndProcessFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'ods'],
      );

      if (result == null || result.files.single.path == null) return;

      setState(() {
        _isLoading = true;
        _fileName = result.files.single.name;
        _statusMessage = 'Reading file...';
      });

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final extension = result.files.single.extension?.toLowerCase() ?? '';

      // Parse file into a common 2D list format based on file type
      List<List<String>> rows;
      if (extension == 'ods') {
        rows = _parseOdsFile(bytes);
      } else {
        rows = _parseXlsxFile(bytes);
      }

      if (rows.isEmpty) {
        _showError('Could not read the file or file is empty.');
        return;
      }

      // --- Extract Course Code from the header area ---
      String? sheetCourseCode;
      final searchLimit = rows.length > 10 ? 10 : rows.length;
      for (int i = 0; i < searchLimit; i++) {
        final row = rows[i];
        for (int j = 0; j < row.length; j++) {
          if (row[j].toLowerCase().contains('course code')) {
            for (int k = j + 1; k < row.length; k++) {
              final codeValue = row[k].trim();
              if (codeValue.isNotEmpty) {
                sheetCourseCode = codeValue.replaceAll('-', '').trim();
                break;
              }
            }
            break;
          }
        }
        if (sheetCourseCode != null) break;
      }

      // --- Find the header row with "Code" and "Student Name" ---
      int codeColIndex = -1;
      int nameColIndex = -1;
      int headerRowIndex = -1;

      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];
        for (int j = 0; j < row.length; j++) {
          final cellValue = row[j].toLowerCase().trim();
          if (cellValue == 'code') {
            codeColIndex = j;
            headerRowIndex = i;
          }
          if (cellValue == 'student name') {
            nameColIndex = j;
          }
        }
        if (codeColIndex != -1 && nameColIndex != -1) break;
      }

      if (codeColIndex == -1 || nameColIndex == -1) {
        _showError('Could not find "Code" and "Student Name" columns in the sheet.');
        return;
      }

      // --- Extract students data ---
      List<Map<String, String>> students = [];
      for (int i = headerRowIndex + 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length <= codeColIndex || row.length <= nameColIndex) continue;

        final code = row[codeColIndex].trim();
        final name = row[nameColIndex].trim();

        if (code.isNotEmpty && name.isNotEmpty) {
          students.add({'code': code, 'name': name});
        }
      }

      if (students.isEmpty) {
        _showError('No students found in the sheet.');
        return;
      }

      setState(() {
        _statusMessage = 'Found ${students.length} students.';
      });

      // --- Validate Course Code ---
      final normalizedScreenCode = widget.courseCode.replaceAll('-', '').trim().toLowerCase();
      final normalizedSheetCode = (sheetCourseCode ?? '').toLowerCase();

      if (sheetCourseCode != null && normalizedSheetCode != normalizedScreenCode) {
        final shouldContinue = await _showMismatchDialog(
          screenCode: widget.courseCode,
          sheetCode: sheetCourseCode,
        );
        if (shouldContinue != true) {
          setState(() {
            _isLoading = false;
            _statusMessage = 'Upload cancelled.';
          });
          return;
        }
      }

      // --- Save to Firebase ---
      await _saveStudentsToFirebase(students);

    } catch (e) {
      _showError('Error processing file: $e');
    }
  }

  /// Parse XLSX file into a 2D list of strings
  List<List<String>> _parseXlsxFile(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName];
    if (sheet == null) return [];

    List<List<String>> result = [];
    for (int i = 0; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      result.add(row.map((cell) {
        if (cell == null || cell.value == null) return '';
        return cell.value.toString();
      }).toList());
    }
    return result;
  }

  /// Parse ODS file into a 2D list of strings
  /// ODS files are ZIP archives containing XML (content.xml)
  List<List<String>> _parseOdsFile(List<int> bytes) {
    // Decode the ZIP archive
    final archive = ZipDecoder().decodeBytes(bytes);

    // Find content.xml inside the archive
    ArchiveFile? contentFile;
    for (final file in archive) {
      if (file.name == 'content.xml') {
        contentFile = file;
        break;
      }
    }

    if (contentFile == null) {
      throw Exception('Invalid ODS file: content.xml not found');
    }

    // Parse the XML content
    final xmlString = utf8.decode(contentFile.content as List<int>);
    final document = XmlDocument.parse(xmlString);

    // Find all table:table elements (sheets) - we take the first one
    final tables = document.findAllElements('table:table').toList();
    if (tables.isEmpty) {
      throw Exception('No sheets found in ODS file');
    }

    final firstTable = tables.first;
    List<List<String>> result = [];

    // Iterate through all table:table-row elements
    final tableRows = firstTable.findElements('table:table-row');
    for (final tableRow in tableRows) {
      List<String> rowData = [];

      // Check if this row is repeated (empty rows)
      final rowRepeat = tableRow.getAttribute('table:number-rows-repeated');
      if (rowRepeat != null) {
        final repeatCount = int.tryParse(rowRepeat) ?? 1;
        // Skip large repeated empty rows (often used to fill the sheet)
        if (repeatCount > 50) continue;
      }

      final cells = tableRow.findElements('table:table-cell');
      for (final cell in cells) {
        // Get cell text from text:p elements
        final textElements = cell.findElements('text:p');
        final cellText = textElements.map((e) => e.innerText).join(' ').trim();

        // Check if this cell is repeated
        final colRepeat = cell.getAttribute('table:number-columns-repeated');
        if (colRepeat != null) {
          int repeatCount = int.tryParse(colRepeat) ?? 1;
          // Limit repeated empty cells to avoid memory issues
          if (repeatCount > 100) repeatCount = 1;
          for (int i = 0; i < repeatCount; i++) {
            rowData.add(cellText);
          }
        } else {
          rowData.add(cellText);
        }
      }

      // Only add rows that have at least one non-empty cell
      if (rowData.any((cell) => cell.isNotEmpty)) {
        result.add(rowData);
      }
    }

    return result;
  }

  /// Show a mismatch warning dialog
  Future<bool?> _showMismatchDialog({
    required String screenCode,
    required String sheetCode,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text(
              'Course Mismatch',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'The sheet you uploaded is for course "$sheetCode", but you\'re currently in "$screenCode".\n\nDo you want to add these students anyway?',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Yes, Add them',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Determine the next section number and save students to Firebase
  Future<void> _saveStudentsToFirebase(List<Map<String, String>> students) async {
    setState(() {
      _statusMessage = 'Saving to database...';
    });

    try {
      final courseDocRef = FirebaseFirestore.instance
          .collection('courses_management')
          .doc(widget.courseCode);

      final courseDoc = await courseDocRef.get();

      // Determine the next section number
      int nextSectionNumber = 1;
      if (courseDoc.exists) {
        final data = courseDoc.data() as Map<String, dynamic>;
        final enrolledSections = data['enrolled_sections'] as Map<String, dynamic>? ?? {};
        nextSectionNumber = enrolledSections.length + 1;
      }

      final sectionKey = 'section_$nextSectionNumber';

      // Convert students list to a serializable format
      final studentsList = students.map((s) => {
        'code': s['code'],
        'name': s['name'],
      }).toList();

      // Save to Firestore using merge to preserve existing data
      await courseDocRef.set({
        'enrolled_sections': {
          sectionKey: {
            'students': studentsList,
            'uploadedAt': FieldValue.serverTimestamp(),
            'studentCount': students.length,
          },
        },
      }, SetOptions(merge: true));

      setState(() {
        _isLoading = false;
        _statusMessage = '✅ ${students.length} students added to $sectionKey successfully!';
      });

      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${students.length} students added to Section $nextSectionNumber'),
            backgroundColor: const Color(0xFF2C5E7A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      _showError('Error saving to database: $e');
    }
  }

  /// Show error message
  void _showError(String message) {
    setState(() {
      _isLoading = false;
      _statusMessage = '❌ $message';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.primary, size: 32),
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Files up-load',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Show which course we're uploading for
              Text(
                'Course: ${widget.courseCode}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'You can upload your files in .xlsx,\n.xls and .ods formats',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Upload area
              GestureDetector(
                onTap: _isLoading ? null : _pickAndProcessFile,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F1F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Color(0xFF2C5E7A)),
                              SizedBox(height: 16),
                              Text(
                                'Processing...',
                                style: TextStyle(
                                  color: Color(0xFF2C5E7A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.cloud_upload_outlined,
                                size: 80,
                                color: Color(0xFF2C5E7A),
                              ),
                              const SizedBox(height: 8),
                              if (_fileName != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    _fileName!,
                                    style: const TextStyle(
                                      color: Color(0xFF2C5E7A),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
              ),

              // Status message
              if (_statusMessage.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _statusMessage.startsWith('✅')
                        ? const Color(0xFFE8F5E9)
                        : _statusMessage.startsWith('❌')
                            ? const Color(0xFFFFEBEE)
                            : const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _statusMessage.startsWith('✅')
                          ? const Color(0xFF2E7D32)
                          : _statusMessage.startsWith('❌')
                              ? const Color(0xFFC62828)
                              : AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
