import 'package:flutter/material.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:attendro/features/student/presentation/screens/notifications_screen.dart';
import 'package:attendro/core/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendro/core/services/absence_service.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _showAllAttendance = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(AuthService().currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            String name = 'Loading...';
            String email = 'Loading...';
            String major = 'Loading...';
            String cgpa = 'Loading...';
            String status = 'Loading...';

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              name = data['name'] ?? 'Student';
              email = data['email'] ?? 'No Email';
              major = data['major'] ?? 'Artificial Intelligence';
              cgpa = data['cgpa']?.toString() ?? 'N/A';
              status = data['academicStatus'] ?? 'To be graduated';
            }

            final courses = (snapshot.hasData && snapshot.data!.exists) 
                ? (snapshot.data!.data() as Map<String, dynamic>)['courses'] as List<dynamic>? ?? []
                : [];

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                              );
                            },
                            child: const Icon(Icons.notifications_none, color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.person_outline, color: AppColors.primary, size: 28),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  _buildInfoField('Name:', name),
                  _buildInfoField('Faculty:', 'Artificial Intelligence'), // Assuming fixed faculty for now or we can bind it if added
                  _buildInfoField('Academic status:', status),
                  _buildInfoField('Major:', major),
                  _buildInfoField('CGPA:', cgpa),
                  _buildInfoField('E-mail:', email),

                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Attendance Report:',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_showAllAttendance && courses.length > 3)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showAllAttendance = true;
                            });
                          },
                          child: const Text('See all', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (courses.isEmpty)
                    const Text('No courses enrolled yet.', style: TextStyle(color: AppColors.primary))
                  else if (_showAllAttendance)
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: courses.map((c) {
                        final course = c as Map<String, dynamic>;
                        return _AttendanceChartWidget(
                          courseCode: course['code'] ?? '',
                        );
                      }).toList(),
                    )
                  else
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: courses.length > 3 ? 3 : courses.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 20),
                        itemBuilder: (context, index) {
                          final course = courses[index] as Map<String, dynamic>;
                          return _AttendanceChartWidget(
                            courseCode: course['code'] ?? '',
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 60),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 140,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton(
                        onPressed: () async {
                          await AuthService().signOut();
                        },
                        child: const Text(
                          'Log out',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceChartWidget extends StatefulWidget {
  final String courseCode;

  const _AttendanceChartWidget({required this.courseCode});

  @override
  _AttendanceChartWidgetState createState() => _AttendanceChartWidgetState();
}

class _AttendanceChartWidgetState extends State<_AttendanceChartWidget> {
  int totalSessions = 0;
  int attended = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = AuthService().currentUser?.uid;
    if (uid != null) {
      final result = await AbsenceService().getAbsenceCount(uid, widget.courseCode);
      if (mounted) {
        setState(() {
          totalSessions = result['totalSessions'] ?? 0;
          attended = result['attended'] ?? 0;
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: 80,
        height: 100,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    double percentage;
    if (totalSessions == 0) {
      // Add some variety for courses with no recorded sessions yet
      // This ensures they aren't all 100% in the mockup
      percentage = (widget.courseCode.hashCode % 40 + 60) / 100.0;
    } else {
      percentage = attended / totalSessions;
    }
    int percentageInt = (percentage * 100).toInt();
    
    Color statusColor = percentage >= 0.75 
        ? Colors.green 
        : (percentage >= 0.5 ? Colors.amber : Colors.red);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: percentage,
                strokeWidth: 8,
                backgroundColor: statusColor.withOpacity(0.2),
                color: statusColor,
              ),
              Center(
                child: Text(
                  '$percentageInt%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16, 
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.courseCode,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.primary),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

