import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:attendro/core/services/notification_service.dart';

class AbsenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, int>> getAbsenceCount(String studentUid, String courseCode) async {
    try {
      final sessionsSnap = await _firestore
          .collection('attendance_sessions')
          .where('courseCode', isEqualTo: courseCode)
          .get();

      int totalSessions = sessionsSnap.docs.length;
      int attended = 0;

      for (var doc in sessionsSnap.docs) {
        final data = doc.data();
        final List<dynamic> attendedStudents = data['attendedStudents'] ?? [];
        if (attendedStudents.contains(studentUid)) {
          attended++;
        }
      }

      return {
        'totalSessions': totalSessions,
        'attended': attended,
        'absences': totalSessions - attended,
      };
    } catch (e) {
      debugPrint("Error calculating absences: $e");
      return {'totalSessions': 0, 'attended': 0, 'absences': 0};
    }
  }

  Future<void> checkAndSendWarnings(String studentUid) async {
    try {
      final studentDoc = await _firestore.collection('users').doc(studentUid).get();
      if (!studentDoc.exists) return;

      final studentData = studentDoc.data() as Map<String, dynamic>;
      final courses = studentData['courses'] as List<dynamic>? ?? [];

      for (var course in courses) {
        final c = course as Map<String, dynamic>;
        final courseCode = c['code'] ?? '';
        final courseTitle = c['title'] ?? '';

        if (courseCode.isEmpty) continue;

        final absenceData = await getAbsenceCount(studentUid, courseCode);
        final absences = absenceData['absences'] ?? 0;

        if (absences > 3) {
          final today = DateTime.now().toIso8601String().substring(0, 10);
          final warningId = '${courseCode}_warning_$today';

          final existingWarning = await _firestore
              .collection('users')
              .doc(studentUid)
              .collection('notifications')
              .doc(warningId)
              .get();

          if (!existingWarning.exists) {
            final warningTitle = '⚠️ Absence Warning!';
            final warningMessage = 'You have exceeded the allowed absences in "$courseTitle" ($courseCode). Total absences: $absences. Please contact your instructor immediately.';

            await _firestore
                .collection('users')
                .doc(studentUid)
                .collection('notifications')
                .doc(warningId)
                .set({
              'title': warningTitle,
              'message': warningMessage,
              'courseCode': courseCode,
              'type': 'absence_warning',
              'isRead': false,
              'timestamp': FieldValue.serverTimestamp(),
            });

            await NotificationService().showLocalNotification(
              title: warningTitle,
              body: warningMessage,
              payload: courseCode,
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking warnings: $e");
    }
  }
}
