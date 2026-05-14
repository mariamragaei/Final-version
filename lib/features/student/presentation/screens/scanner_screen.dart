import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendro/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ScannerScreen extends StatefulWidget {
  final String courseName;

  const ScannerScreen({super.key, required this.courseName});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<String?> _getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id; // Unique ID on Android
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor; // Unique ID on iOS
      }
    } catch (e) {
      debugPrint("Error getting device info: $e");
    }
    return null;
  }

  Future<void> _handleScan(String rawValue) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    controller.stop();

    try {
      final Map<String, dynamic> data = jsonDecode(rawValue);
      final qrCourseName = data['courseName'];
      final qrTimestamp = data['timestamp'];
      final qrSessionId = data['sessionId'];

      if (qrCourseName != widget.courseName) {
        throw Exception("Invalid Course QR Code.");
      }

      final currentTime = DateTime.now().millisecondsSinceEpoch;
      if (currentTime - qrTimestamp > 10000 || currentTime < qrTimestamp) {
        throw Exception("QR Code Expired. Please scan a fresh code.");
      }

      final uid = AuthService().currentUser?.uid;
      if (uid == null) throw Exception("User not logged in.");

      // Get Device ID for anti-cheating
      final deviceId = await _getDeviceId();

      final studentDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (studentDoc.exists) {
        final studentData = studentDoc.data() as Map<String, dynamic>;
        final courses = studentData['courses'] as List<dynamic>? ?? [];
        bool isRegistered = courses.any((course) {
          final c = course as Map<String, dynamic>;
          return c['title'] == widget.courseName || c['code'] == (data['courseCode'] ?? '');
        });
        if (!isRegistered) {
          throw Exception("This course is not registered in your schedule. Attendance cannot be recorded.");
        }
      }

      if (qrSessionId == null || qrSessionId.toString().isEmpty) {
        throw Exception("Invalid QR Code. No session found.");
      }

      final sessionDoc = await FirebaseFirestore.instance
          .collection('attendance_sessions')
          .doc(qrSessionId)
          .get();

      if (!sessionDoc.exists) {
        throw Exception("This attendance session does not exist.");
      }

      final sessionData = sessionDoc.data() as Map<String, dynamic>;
      final List<dynamic> attendedStudents = sessionData['attendedStudents'] ?? [];
      final List<dynamic> usedDeviceIds = sessionData['usedDeviceIds'] ?? [];

      if (attendedStudents.contains(uid)) {
        throw Exception("You have already recorded your attendance for this session.");
      }

      // Check if device already used
      if (deviceId != null && usedDeviceIds.contains(deviceId)) {
        throw Exception("This device has already been used to record attendance for this session.");
      }

      await FirebaseFirestore.instance
          .collection('attendance_sessions')
          .doc(qrSessionId)
          .update({
        'attendedStudents': FieldValue.arrayUnion([uid]),
        if (deviceId != null) 'usedDeviceIds': FieldValue.arrayUnion([deviceId]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Attendance recorded successfully for ${widget.courseName}'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
        );
        setState(() => _isProcessing = false);
        controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR - ${widget.courseName}', style: const TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleScan(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _buildCorner(0),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _buildCorner(1),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: _buildCorner(2),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _buildCorner(3),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Text(
              'Align QR code within the frame',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(int type) {
    const double size = 30.0;
    const double thickness = 4.0;
    const Color color = Colors.blue;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: (type == 0 || type == 1) ? const BorderSide(color: color, width: thickness) : BorderSide.none,
          bottom: (type == 2 || type == 3) ? const BorderSide(color: color, width: thickness) : BorderSide.none,
          left: (type == 0 || type == 2) ? const BorderSide(color: color, width: thickness) : BorderSide.none,
          right: (type == 1 || type == 3) ? const BorderSide(color: color, width: thickness) : BorderSide.none,
        ),
      ),
    );
  }
}
