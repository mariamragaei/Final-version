import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:attendro/features/home/presentation/widgets/mini_calendar.dart';
import 'package:attendro/features/student/presentation/screens/notifications_screen.dart';
import 'package:attendro/features/instructor/presentation/screens/instructor_profile_screen.dart';
import 'package:attendro/features/instructor/presentation/screens/course_attendance_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendro/core/services/auth_service.dart';
import 'package:attendro/core/widgets/notification_bell.dart';

class InstructorHomeScreen extends StatelessWidget {
  final VoidCallback? onSeeAll;
  const InstructorHomeScreen({super.key, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(now).toUpperCase();
    final dayNumber = DateFormat('d').format(now);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset('assets/images/logo.png', width: 140, fit: BoxFit.contain),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        );
                      },
                      icon: const NotificationBell(size: 28),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const InstructorProfileScreen()),
                        );
                      },
                      icon: const Icon(Icons.person_outline, color: AppColors.primary, size: 28),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(AuthService().currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                String displayName = 'Doctor';
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  displayName = data['name'] ?? 'Doctor';
                }
                return Text(
                  'Good Evening, Dr. ${displayName.split(' ')[0]}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayName,
                        style: const TextStyle(
                          color: Color(0xFFFF5252),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        dayNumber,
                        style: const TextStyle(
                          color: AppColors.black,
                          fontSize: 48,
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'No Events Today',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: MiniCalendar(),
                ),
              ],
            ),
            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Courses',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'See all',
                    style: TextStyle(color: AppColors.primary, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 115,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('courses_management').snapshots(),
                builder: (context, courseSnapshot) {
                  if (courseSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!courseSnapshot.hasData || courseSnapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No courses assigned', style: TextStyle(color: AppColors.primary, fontSize: 12)));
                  }

                  final String currentUid = AuthService().currentUser?.uid ?? '';
                  List<Widget> courseCards = [];

                  for (var doc in courseSnapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    bool isAssigned = false;
                    
                    if (data['groups'] != null) {
                      final Map<String, dynamic> groups = data['groups'];
                      if (groups.containsValue(currentUid)) isAssigned = true;
                    }
                    if (data['sections'] != null) {
                      final Map<String, dynamic> sections = data['sections'];
                      if (sections.containsValue(currentUid)) isAssigned = true;
                    }

                    if (isAssigned) {
                      courseCards.add(_buildCourseCard(
                        context: context,
                        code: data['code'] ?? doc.id,
                        title: data['title'] ?? 'Course',
                        subtitle: data['subtitle'] ?? 'Artificial Intelligence',
                      ));
                      courseCards.add(const SizedBox(width: 16));
                    }
                  }

                  if (courseCards.isEmpty) {
                    return const Center(child: Text('No courses assigned', style: TextStyle(color: AppColors.primary, fontSize: 12)));
                  }

                  return ListView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: courseCards,
                  );
                },
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard({
    required BuildContext context,
    required String code,
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourseAttendanceDetailsScreen(
              courseCode: code,
              courseTitle: title,
              courseSubtitle: subtitle,
            ),
          ),
        );
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.book_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ),
            const Spacer(),
            Text('-$code', style: const TextStyle(color: Colors.black54, fontSize: 8, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(color: Colors.black54, fontSize: 8, height: 1.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
