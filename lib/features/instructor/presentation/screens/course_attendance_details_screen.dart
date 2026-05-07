import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendro/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:attendro/features/instructor/presentation/screens/section_attendance_screen.dart';
import 'package:attendro/features/instructor/presentation/screens/instructor_profile_screen.dart';

class CourseAttendanceDetailsScreen extends StatelessWidget {
  final String courseCode;
  final String courseTitle;
  final String courseSubtitle;

  const CourseAttendanceDetailsScreen({
    super.key,
    required this.courseCode,
    required this.courseTitle,
    required this.courseSubtitle,
  });

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Attendance',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Image.asset('assets/images/icons/filter-search.png', width: 24),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const InstructorProfileScreen()),
                          );
                        },
                        icon: Image.asset('assets/images/icons/profile-2user.png', width: 24),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(AuthService().currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    String role = 'instructor';
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      role = data['role'] ?? 'instructor';
                    }

                    return ListView(
                      children: [
                        _buildAttendanceCard(
                          context: context,
                          code: courseCode,
                          title: courseTitle,
                          subtitle: courseSubtitle,
                          role: role,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceCard({
    required BuildContext context,
    required String code,
    required String title,
    required String subtitle,
    required String role,
  }) {
    final bool isTA = role.toLowerCase() == 'ta';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFBDCEDB),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '- $code',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.bottomRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SectionAttendanceScreen(title: 'Section Attendance', courseCode: code),
                      ),
                    );
                  },
                  child: const Text(
                    'section attendance',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isTA) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SectionAttendanceScreen(title: 'Lecture Attendance', courseCode: code),
                        ),
                      );
                    },
                    child: const Text(
                      'Lecture attendance',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
