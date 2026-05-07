import 'package:flutter/material.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:attendro/core/widgets/custom_button.dart';
import 'package:attendro/core/services/auth_service.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 48),
              const Icon(
                Icons.hourglass_empty_rounded,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                'Pending Approval',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your request to join as an instructor has been sent to the organization. Please wait for an admin to approve your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              CustomButton(
                text: 'Sign Out',
                width: 200,
                onPressed: () async {
                  await AuthService().signOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
