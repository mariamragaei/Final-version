import 'package:flutter/material.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:attendro/core/widgets/custom_button.dart';
import 'package:attendro/features/home/presentation/screens/main_layout_screen.dart';
import 'package:attendro/features/auth/presentation/screens/pending_approval_screen.dart';
import 'package:attendro/core/services/auth_service.dart';

enum UserRole { student, doctor, ta }

class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {
  UserRole? _selectedRole;
  bool _isLoading = false;

  void _onContinue() async {
    if (_selectedRole == null) return;
    
    setState(() => _isLoading = true);

    try {
      final auth = AuthService();
      final uid = auth.currentUser?.uid;
      
      if (uid == null) {
        return;
      }

      String roleString = 'student';
      if (_selectedRole == UserRole.doctor) roleString = 'doctor';
      if (_selectedRole == UserRole.ta) roleString = 'ta';

      await auth.updateUserRole(uid, role: roleString);

      // AuthWrapper listens to Firestore document changes and will automatically navigate
      // to the appropriate screen (MainLayoutScreen or PendingApprovalScreen) when the role updates.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating role: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 150,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 48),

              const Text(
                'Choose your role:',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRoleCard(
                    role: UserRole.student,
                    imagePath: 'assets/images/student/pngtree-student-line-icon-vector-png-image_6693109 1.png',
                    title: 'Student',
                    colorTint: AppColors.primary,
                  ),
                  const SizedBox(width: 16),
                  _buildRoleCard(
                    role: UserRole.doctor,
                    imagePath: 'assets/images/doctor/images 1.png',
                    title: 'Doctor',
                  ),
                  const SizedBox(width: 16),
                  _buildRoleCard(
                    role: UserRole.ta,
                    imagePath: 'assets/images/ta/images 2.png',
                    title: 'TA',
                  ),
                ],
              ),
              const SizedBox(height: 48),

              const Text(
                'Note:',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'If you choose your role as an instructor\nyou have to wait for organization approval.',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),

              Align(
                alignment: Alignment.centerRight,
                child: _isLoading
                  ? const CircularProgressIndicator()
                  : CustomButton(
                      text: 'Continue',
                      width: 140,
                      onPressed: _onContinue,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String imagePath,
    required String title,
    Color? colorTint,
  }) {
    final bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Column(
        children: [
          Container(
            width: 85,
            height: 105,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary,
                width: isSelected ? 3.0 : 1.0,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              color: colorTint,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
