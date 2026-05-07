import 'package:flutter/material.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:attendro/features/student/presentation/screens/notifications_screen.dart';
import 'package:attendro/core/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendro/core/widgets/notification_bell.dart';

class InstructorProfileScreen extends StatelessWidget {
  const InstructorProfileScreen({super.key});

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

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              name = data['name'] ?? 'Instructor';
              email = data['email'] ?? 'No Email';
            }

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
                            child: const NotificationBell(size: 28),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.person_outline, color: AppColors.primary, size: 28),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  _buildInfoField('Name:', name),
                  _buildInfoField('Faculty:', 'Artificial intelligence'),
                  _buildInfoField('Position:', 'Head of Artificial Intelligence Department'),
                  _buildInfoField('Academic Status:', 'PhD in Artificial Intelligence'),
                  _buildInfoField('Experience:', '12+ years in AI research and academic leadership'),
                  _buildInfoField('E-mail:', email),

                  const SizedBox(height: 40),

                  const Text(
                    'Assigned Courses (Groups/Sections):',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('courses_management').snapshots(),
                    builder: (context, courseSnapshot) {
                      if (courseSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator()));
                      }
                      if (!courseSnapshot.hasData || courseSnapshot.data!.docs.isEmpty) {
                        return _buildReportItem('No courses assigned yet.');
                      }

                      final String currentUid = AuthService().currentUser?.uid ?? '';
                      List<Widget> courseWidgets = [];

                      for (var doc in courseSnapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final title = data['title'] ?? doc.id;
                        
                        List<String> assignedTo = [];
                        
                        if (data['groups'] != null) {
                          final Map<String, dynamic> groups = data['groups'];
                          groups.forEach((key, value) {
                            if (value == currentUid) {
                              assignedTo.add('Group ${int.parse(key) + 1}');
                            }
                          });
                        }
                        
                        if (data['sections'] != null) {
                          final Map<String, dynamic> sections = data['sections'];
                          sections.forEach((key, value) {
                            if (value == currentUid) {
                              assignedTo.add('Section ${int.parse(key) + 1}');
                            }
                          });
                        }

                        if (assignedTo.isNotEmpty) {
                          for (var assignment in assignedTo) {
                            courseWidgets.add(_buildReportItem('$title - $assignment'));
                          }
                        }
                      }

                      if (courseWidgets.isEmpty) {
                        return _buildReportItem('No courses assigned yet.');
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: courseWidgets,
                      );
                    },
                  ),

                  const SizedBox(height: 60),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFF001F3F), // Dark navy as in image
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

  Widget _buildReportItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
