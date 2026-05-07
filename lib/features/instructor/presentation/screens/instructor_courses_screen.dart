import 'package:flutter/material.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:attendro/features/instructor/presentation/screens/upload_sheet_screen.dart';
import 'package:attendro/features/instructor/presentation/screens/generate_qr_screen.dart';
import 'package:attendro/features/instructor/presentation/screens/course_attendance_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendro/core/services/auth_service.dart';
import 'package:attendro/features/instructor/presentation/screens/instructor_profile_screen.dart';

class InstructorCoursesScreen extends StatefulWidget {
  const InstructorCoursesScreen({super.key});

  @override
  State<InstructorCoursesScreen> createState() => _InstructorCoursesScreenState();
}

class _InstructorCoursesScreenState extends State<InstructorCoursesScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('courses_management').snapshots(),
                  builder: (context, courseSnapshot) {
                    if (courseSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!courseSnapshot.hasData || courseSnapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No courses assigned yet.', style: TextStyle(color: AppColors.primary)));
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
                        final courseCode = (data['code'] ?? doc.id).toString();
                        final courseTitle = (data['title'] ?? 'Course Title').toString();
                        
                        if (_searchQuery.isEmpty || 
                            courseCode.toLowerCase().contains(_searchQuery) || 
                            courseTitle.toLowerCase().contains(_searchQuery)) {
                          courseCards.add(_buildInstructorCourseCard(
                            context: context,
                            code: courseCode,
                            title: courseTitle,
                            subtitle: 'Artificial Intelligence',
                          ));
                          courseCards.add(const SizedBox(height: 16));
                        }
                      }
                    }

                    if (courseCards.isEmpty) {
                      return const Center(child: Text('No courses assigned yet.', style: TextStyle(color: AppColors.primary)));
                    }

                    return ListView(
                      children: courseCards,
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

  Widget _buildInstructorCourseCard({
    required BuildContext context,
    required String code,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFBDCEDB),
        borderRadius: BorderRadius.circular(12),
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
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
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
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
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
                      MaterialPageRoute(builder: (_) => UploadSheetScreen(courseCode: code)),
                    );
                  },
                  child: const Text(
                    'Upload student sheet',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GenerateQrScreen(courseName: title, courseCode: code),
                      ),
                    );
                  },
                  child: const Text(
                    'Generate QR',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
