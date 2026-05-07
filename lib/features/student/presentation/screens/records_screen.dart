import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendro/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class RecordsScreen extends StatefulWidget {
  final String courseCode;
  final String courseTitle;
  final String courseSubtitle;

  const RecordsScreen({
    super.key,
    required this.courseCode,
    required this.courseTitle,
    required this.courseSubtitle,
  });

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.courseCode,
          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _buildCourseHeader(),
              const SizedBox(height: 32),
              _buildAttendanceSummary(uid),
              const SizedBox(height: 32),
              const Text(
                'Attendance History',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildSessionsList(uid),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFBDCEDB).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.courseTitle,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.courseSubtitle,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary(String? uid) {
    if (uid == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance_sessions')
          .where('courseCode', isEqualTo: widget.courseCode)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final sessions = snapshot.data?.docs ?? [];
        int totalSessions = sessions.length;
        int attendedCount = 0;

        for (var doc in sessions) {
          final data = doc.data() as Map<String, dynamic>;
          final List<dynamic> attendedStudents = data['attendedStudents'] ?? [];
          if (attendedStudents.contains(uid)) {
            attendedCount++;
          }
        }

        int absences = totalSessions - attendedCount;
        double attendanceRate = totalSessions == 0 ? 0 : (attendedCount / totalSessions);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSummaryItem('Total', totalSessions.toString(), AppColors.primary),
            _buildSummaryItem('Attended', attendedCount.toString(), Colors.green),
            _buildSummaryItem('Absences', absences.toString(), absences > 3 ? Colors.red : Colors.orange),
            _buildSummaryItem('Rate', '${(attendanceRate * 100).toInt()}%', AppColors.primary),
          ],
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionsList(String? uid) {
    if (uid == null) return const Center(child: Text('User not found'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance_sessions')
          .where('courseCode', isEqualTo: widget.courseCode)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No attendance records found yet.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final sessions = snapshot.data!.docs;

        return ListView.separated(
          itemCount: sessions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final session = sessions[index].data() as Map<String, dynamic>;
            final timestamp = session['timestamp'] as Timestamp?;
            final List<dynamic> attendedStudents = session['attendedStudents'] ?? [];
            final isAttended = attendedStudents.contains(uid);

            final dateStr = timestamp != null
                ? DateFormat('EEEE, MMM d, yyyy').format(timestamp.toDate())
                : 'Unknown Date';
            final timeStr = timestamp != null
                ? DateFormat('hh:mm a').format(timestamp.toDate())
                : '';

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAttended ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isAttended ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isAttended ? Icons.check_circle_outline : Icons.cancel_outlined,
                      color: isAttended ? Colors.green : Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (timeStr.isNotEmpty)
                          Text(
                            timeStr,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    isAttended ? 'PRESENT' : 'ABSENT',
                    style: TextStyle(
                      color: isAttended ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
