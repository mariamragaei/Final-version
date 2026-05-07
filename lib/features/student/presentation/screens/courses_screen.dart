import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendro/core/services/auth_service.dart';
import 'package:attendro/core/services/absence_service.dart';
import 'package:flutter/material.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:attendro/features/student/presentation/screens/notifications_screen.dart';
import 'package:attendro/features/student/presentation/screens/student_profile_screen.dart';
import 'package:attendro/features/student/presentation/screens/scanner_screen.dart';
import 'package:attendro/core/widgets/notification_bell.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final AbsenceService _absenceService = AbsenceService();
  Map<String, int> _absencesMap = {};
  bool _absencesLoaded = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        _absencesLoaded = true;
      });
    }

    _absenceService.checkAndSendWarnings(uid);
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_isSearching)
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search courses...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close, color: AppColors.primary),
                            onPressed: () {
                              setState(() {
                                _isSearching = false;
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          ),
                        ),
                        style: const TextStyle(color: AppColors.primary),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    )
                  else
                    const Text(
                      'Courses',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Row(
                    children: [
                      if (!_isSearching)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSearching = true;
                            });
                          },
                          child: Image.asset('assets/images/icons/filter-search.png', width: 24),
                        ),
                      if (!_isSearching)
                        const SizedBox(width: 4),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                          );
                        },
                        icon: const NotificationBell(size: 24, useAsset: true),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const StudentProfileScreen()),
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
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const Center(child: Text('No courses found', style: TextStyle(color: AppColors.primary)));
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final courses = data['courses'] as List<dynamic>? ?? [];

                    if (courses.isEmpty) {
                      return const Center(child: Text('You are not registered in any courses.', style: TextStyle(color: AppColors.primary)));
                    }

                    final filteredCourses = courses.where((course) {
                      if (_searchQuery.isEmpty) return true;
                      final courseCode = (course['code'] ?? '').toString().toLowerCase();
                      final title = (course['title'] ?? '').toString().toLowerCase();
                      return courseCode.contains(_searchQuery) || title.contains(_searchQuery);
                    }).toList();

                    if (filteredCourses.isEmpty) {
                      return const Center(child: Text('No courses match your search.', style: TextStyle(color: AppColors.primary)));
                    }

                    return ListView.builder(
                      itemCount: filteredCourses.length,
                      itemBuilder: (context, index) {
                        final course = filteredCourses[index] as Map<String, dynamic>;
                        final courseCode = course['code'] ?? '';
                        final absences = _absencesMap[courseCode] ?? 0;
                        final isWarning = absences > 3;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildCourseItem(
                            context: context,
                            code: courseCode,
                            title: course['title'] ?? '',
                            subtitle: course['subtitle'] ?? '',
                            absences: absences,
                            isWarning: isWarning,
                          ),
                        );
                      },
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

  Widget _buildCourseItem({
    required BuildContext context,
    required String code,
    required String title,
    required String subtitle,
    required int absences,
    required bool isWarning,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFFFFCDD2) : const Color(0xFFBDCEDB),
        borderRadius: BorderRadius.circular(12),
        border: isWarning ? Border.all(color: Colors.red.shade400, width: 2) : null,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '- $code',
                style: TextStyle(
                  color: isWarning ? Colors.red.shade800 : AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isWarning)
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 22),
                    const SizedBox(width: 4),
                    Text(
                      '$absences absences',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: isWarning ? Colors.red.shade800 : AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: isWarning ? Colors.red.shade700 : AppColors.primary,
              fontSize: 14,
            ),
          ),
          if (_absencesLoaded && !isWarning && absences > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Absences: $absences / 3 allowed',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScannerScreen(courseName: title),
                  ),
                );
              },
              child: Text(
                'Attend',
                style: TextStyle(
                  color: isWarning ? Colors.red.shade800 : AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
