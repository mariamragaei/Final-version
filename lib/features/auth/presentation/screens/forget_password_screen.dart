import 'package:flutter/material.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:attendro/core/widgets/custom_text_field.dart';
import 'package:attendro/core/widgets/custom_button.dart';
import 'package:attendro/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:attendro/features/auth/presentation/screens/update_password_screen.dart';

class ForgetPasswordScreen extends StatelessWidget {
  const ForgetPasswordScreen({super.key});

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
              const SizedBox(height: 60),

              const Text(
                'Update your password',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),

              const CustomTextField(
                label: 'E-mail',
                hintText: '225308@eru.edu.eg',
              ),
              const SizedBox(height: 32),

              Align(
                alignment: Alignment.centerRight,
                child: CustomButton(
                  text: 'continue', // using matching case
                  width: 140, 
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OtpVerificationScreen(
                          nextScreen: UpdatePasswordScreen(),
                        ),
                      ),
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
}
