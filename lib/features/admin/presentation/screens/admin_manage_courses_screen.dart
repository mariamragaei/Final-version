import 'package:flutter/material.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:attendro/features/admin/presentation/screens/admin_course_config_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminManageCoursesScreen extends StatefulWidget {
  const AdminManageCoursesScreen({super.key});

  @override
  State<AdminManageCoursesScreen> createState() => _AdminManageCoursesScreenState();
}

class _AdminManageCoursesScreenState extends State<AdminManageCoursesScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _allCourses = [
    {
      'code': 'AI415',
      'title': 'Selected Topic in AI',
      'subtitle': 'Artificial Intelligence',
    },
    {
      'code': 'AI403',
      'title': 'Deep Learning',
      'subtitle': 'Artificial Intelligence',
    },
    {
      'code': 'AI404',
      'title': 'Graduation Project 1',
      'subtitle': 'Artificial Intelligence',
    },
  ];

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
                  if (!_isSearching)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSearching = true;
                        });
                      },
                      child: Image.asset('assets/images/icons/filter-search.png', width: 24),
                    ),
                ],
              ),
              const SizedBox(height: 32),

              Expanded(
                child: ListView(
                  children: [
                    ..._allCourses.where((course) {
                      if (_searchQuery.isEmpty) return true;
                      final code = course['code']!.toLowerCase();
                      final title = course['title']!.toLowerCase();
                      return code.contains(_searchQuery) || title.contains(_searchQuery);
                    }).map((course) => Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildAdminCourseDetailCard(
                            context: context,
                            code: course['code']!,
                            title: course['title']!,
                            subtitle: course['subtitle']!,
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminCourseDetailCard({
    required BuildContext context,
    required String code,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9).withAlpha(180),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminCourseConfigScreen(courseCode: code, courseName: title),
                    ),
                  );
                },
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.bottomRight,
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('courses_management').doc(code).snapshots(),
              builder: (context, snapshot) {
                bool isActive = false;
                if (snapshot.hasData && snapshot.data!.exists) {
                  isActive = (snapshot.data!.data() as Map<String, dynamic>)['isActive'] ?? false;
                }
                return Transform.scale(
                  scale: 1.2,
                  child: Switch(
                    value: isActive,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withAlpha(100),
                    onChanged: (val) {
                      FirebaseFirestore.instance.collection('courses_management').doc(code).set({
                        'isActive': val,
                        'title': title,
                        'code': code,
                      }, SetOptions(merge: true));
                    },
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}
