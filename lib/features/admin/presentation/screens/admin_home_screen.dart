import 'package:flutter/material.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:attendro/features/admin/presentation/screens/admin_requests_screen.dart';
import 'package:attendro/features/admin/presentation/screens/admin_manage_courses_screen.dart';
import 'package:attendro/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendro/core/services/auth_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final AuthService _authService = AuthService();

  Future<void> _updateStatus(String uid, String newStatus) async {
    try {
      await _authService.updateUserRole(uid, status: newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${newStatus == 'approved' ? 'Approved' : 'Rejected'}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteUser(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted from database')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                const Icon(Icons.person_outline, color: AppColors.primary, size: 28),
              ],
            ),
            const SizedBox(height: 32),

            const Text(
              'Good Evening, Ziad!',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader(
              'Requests',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminRequestsScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('status', isEqualTo: 'pending')
                  .limit(4)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ));
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('No pending requests', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildRequestItem(
                      doc.id,
                      data['name'] ?? 'No Name',
                      data['role']?.toString().toUpperCase() ?? 'TA',
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 32),

            _buildSectionHeader(
              'Courses',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminManageCoursesScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  _buildAdminCourseCard('AI404', 'Graduation Project 1\nArtificial Intelligence'),
                  const SizedBox(width: 16),
                  _buildAdminCourseCard('AI403', 'Deep Learning\nArtificial Intelligence'),
                  const SizedBox(width: 16),
                  _buildAdminCourseCard('AI415', 'Selected Topic in AI\nArtificial Intelligence'),
                ],
              ),
            ),
            const SizedBox(height: 40),

            _buildSectionHeader(
              'Users',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No users found');
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (doc.id == _authService.currentUser?.uid) return const SizedBox.shrink();
                    
                    return _buildUserActionItem(
                      doc.id,
                      data['name'] ?? 'No Name',
                      data['role'] ?? 'Student',
                      data['status'] == 'blocked',
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            'See all',
            style: TextStyle(color: AppColors.primary.withAlpha(180), fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestItem(String uid, String name, String role) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            role,
            style: const TextStyle(color: AppColors.primary, fontSize: 13),
          ),
          const SizedBox(width: 32),
          GestureDetector(
            onTap: () => _updateStatus(uid, 'approved'),
            child: Image.asset('assets/images/icons/image 1.png', width: 22),
          ), // Check
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => _updateStatus(uid, 'rejected'),
            child: Image.asset('assets/images/icons/image 2.png', width: 22),
          ), // X
        ],
      ),
    );
  }

  Widget _buildAdminCourseCard(String code, String title) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('courses_management').doc(code).snapshots(),
      builder: (context, snapshot) {
        bool isActive = false;
        if (snapshot.hasData && snapshot.data!.exists) {
          isActive = (snapshot.data!.data() as Map<String, dynamic>)['isActive'] ?? false;
        }
        return Container(
          width: 110,
          padding: const EdgeInsets.all(10),
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
              Text(title, style: const TextStyle(color: Colors.black54, fontSize: 8, height: 1.2), maxLines: 2),
              const SizedBox(height: 4),
              Transform.scale(
                scale: 0.6,
                alignment: Alignment.centerLeft,
                child: Switch(
                  value: isActive,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {
                    FirebaseFirestore.instance.collection('courses_management').doc(code).set({
                      'isActive': val,
                      'title': title,
                      'code': code,
                    }, SetOptions(merge: true));
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildUserActionItem(String uid, String name, String role, bool isBlocked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                name,
                style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  role.toUpperCase(),
                  style: const TextStyle(color: AppColors.primary, fontSize: 12),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () => _authService.updateUserRole(uid, role: 'admin'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            child: const Text('Make admin', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => _updateStatus(uid, isBlocked ? 'approved' : 'blocked'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            child: Text(
              isBlocked ? 'Unblock' : 'Block', 
              style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _deleteUser(uid),
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
