import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendro/core/services/auth_service.dart';
import 'package:intl/intl.dart';

class GenerateQrScreen extends StatefulWidget {
  final String courseName;
  final String courseCode;
  const GenerateQrScreen({super.key, required this.courseName, this.courseCode = ''});

  @override
  State<GenerateQrScreen> createState() => _GenerateQrScreenState();
}

class _GenerateQrScreenState extends State<GenerateQrScreen> {
  late Timer _timer;
  late int _currentTimestamp;
  String _sessionId = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentTimestamp = DateTime.now().millisecondsSinceEpoch;
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentTimestamp = DateTime.now().millisecondsSinceEpoch;
        });
      }
    });

    _registerSession();
  }

  Future<void> _registerSession() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final code = widget.courseCode.isNotEmpty ? widget.courseCode : widget.courseName;
    
    final uid = AuthService().currentUser?.uid ?? '';
    String sessionType = 'Lecture';
    if (uid.isNotEmpty) {
      final role = await AuthService().getUserRole(uid);
      if (role?.toLowerCase() == 'ta') {
        sessionType = 'Section';
      }
    }

    if (mounted) {
      setState(() {
        _sessionId = '${code}_${sessionType}_$today';
      });
    }

    try {
      final docRef = FirebaseFirestore.instance.collection('attendance_sessions').doc(_sessionId);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        final existingSessions = await FirebaseFirestore.instance
            .collection('attendance_sessions')
            .where('courseCode', isEqualTo: code)
            .where('sessionType', isEqualTo: sessionType)
            .get();

        List<String> uniqueDates = [];
        for (var doc in existingSessions.docs) {
          final data = doc.data();
          if (data.containsKey('date')) {
            String d = data['date'] as String;
            if (!uniqueDates.contains(d)) {
              uniqueDates.add(d);
            }
          }
        }
        uniqueDates.sort();
        
        int weekNumber = uniqueDates.length + 1;
        String weekString = 'Week $weekNumber';

        await docRef.set({
          'courseCode': code,
          'courseName': widget.courseName,
          'date': today,
          'instructorId': uid,
          'sessionType': sessionType,
          'week': weekString,
          'timestamp': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'attendedStudents': [],
        });
      }
    } catch (e) {
      debugPrint("Error registering session: $e");
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _generateQrData() {
    final code = widget.courseCode.isNotEmpty ? widget.courseCode : widget.courseName;
    final Map<String, dynamic> data = {
      'courseName': widget.courseName,
      'courseCode': code,
      'sessionId': _sessionId,
      'timestamp': _currentTimestamp,
    };
    return jsonEncode(data);
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
                'QR code',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Scan the Qr code to record your attendance',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 48),

              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F1F6), // Matches the light blue bg
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: AppColors.primary)
                      : QrImageView(
                          data: _generateQrData(),
                          version: QrVersions.auto,
                          size: 200,
                          gapless: false,
                          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.primary),
                          dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.primary),
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
