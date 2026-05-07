import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:attendro/features/home/presentation/widgets/mini_calendar.dart';
import 'package:attendro/features/student/presentation/screens/notifications_screen.dart';
import 'package:attendro/features/student/presentation/screens/student_profile_screen.dart';
import 'package:attendro/features/student/presentation/screens/scanner_screen.dart';
import 'package:attendro/features/student/presentation/screens/records_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendro/core/services/auth_service.dart';
import 'package:attendro/core/services/absence_service.dart';
import 'package:attendro/core/widgets/notification_bell.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSeeAll;
  const HomeScreen({super.key, this.onSeeAll});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AbsenceService _absenceService = AbsenceService();
  Map<String, int> _absencesMap = {};

  @override
  void initState() {
    super.initState();
    _loadAbsences();
  }

  Future<void> _loadAbsences() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;

    final studentDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!studentDoc.exists) return;

    final data = studentDoc.data() as Map<String, dynamic>;
    final courses = data['courses'] as List<dynamic>? ?? [];

    Map<String, int> absencesMap = {};
    for (var course in courses) {
      final c = course as Map<String, dynamic>;
      final code = c['code'] ?? '';
      if (code.isNotEmpty) {
        final result = await _absenceService.getAbsenceCount(uid, code);
        absencesMap[code] = result['absences'] ?? 0;
      }
    }

    if (mounted) {
      setState(() {
        _absencesMap = absencesMap;
      });
    }

    _absenceService.checkAndSendWarnings(uid);
  }

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
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        );
                      },
                      child: const NotificationBell(size: 24, useAsset: true),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StudentProfileScreen()),
                        );
                      },
                      child: Image.asset('assets/images/icons/profile-2user.png', width: 24),
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
                String displayName = 'Student';
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  displayName = data['name'] ?? 'Student';
                }
                return Text(
                  'Good Evening, ${displayName.split(' ')[0]}!',
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
                          color: Color(0xFFFF5252), // Reddish coral
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
                  onPressed: widget.onSeeAll,
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

            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(AuthService().currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const SizedBox(height: 115, child: Center(child: Text('No courses found', style: TextStyle(color: AppColors.primary))));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final coursesList = data['courses'] as List<dynamic>? ?? [];

                if (coursesList.isEmpty) {
                  return const SizedBox(height: 115, child: Center(child: Text('No enrolled courses yet.', style: TextStyle(color: AppColors.primary))));
                }

                final firstCourse = coursesList.isNotEmpty ? coursesList[0] as Map<String, dynamic> : null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 130,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: coursesList.length,
                        itemBuilder: (context, index) {
                          final course = coursesList[index] as Map<String, dynamic>;
                          final courseCode = course['code'] ?? '';
                          final absences = _absencesMap[courseCode] ?? 0;
                          final isWarning = absences > 3;

                          return Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: _buildCourseCard(
                              context: context,
                              code: courseCode,
                              title: course['title'] ?? '',
                              subtitle: course['subtitle'] ?? '',
                              absences: absences,
                              isWarning: isWarning,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    const Text(
                      'Happening now',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (firstCourse != null)
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScannerScreen(
                                courseName: firstCourse['title'] ?? '',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.70,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary, width: 1.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.school_outlined,
                                    color: AppColors.primary,
                                    size: 32,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text('-${firstCourse['code'] ?? ''}', style: const TextStyle(color: Colors.black54, fontSize: 9, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                '${firstCourse['title'] ?? ''}\n${firstCourse['subtitle'] ?? ''}',
                                style: const TextStyle(color: Colors.black54, fontSize: 9, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                );
              },
            ),
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
    required int absences,
    required bool isWarning,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecordsScreen(
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
          color: isWarning ? const Color(0xFFFFCDD2) : AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isWarning ? Colors.red.shade400 : AppColors.primary,
            width: isWarning ? 2 : 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWarning)
              Align(
                alignment: Alignment.topRight,
                child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 16),
              ),
            if (!isWarning)
              const SizedBox(height: 4),
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isWarning ? Colors.red.shade100 : AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.book_outlined,
                  color: isWarning ? Colors.red.shade700 : AppColors.primary,
                  size: 24,
                ),
              ),
            ),
            const Spacer(),
            Text(
              '-$code',
              style: TextStyle(
                color: isWarning ? Colors.red.shade800 : Colors.black54,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$title\n$subtitle',
              style: TextStyle(
                color: isWarning ? Colors.red.shade700 : Colors.black54,
                fontSize: 8,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
