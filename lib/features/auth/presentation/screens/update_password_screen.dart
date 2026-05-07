import 'package:flutter/material.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:attendro/core/widgets/custom_text_field.dart';
import 'package:attendro/core/widgets/custom_button.dart';
import 'package:attendro/features/auth/presentation/screens/login_screen.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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

              CustomTextField(
                label: 'Password:',
                hintText: '***************',
                isPassword: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Image.asset(
                    'assets/images/icons/eye-slash.png',
                    width: 20,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              
              CustomTextField(
                label: 'Confirm Password:',
                hintText: '***************',
                isPassword: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Image.asset(
                    'assets/images/icons/eye-slash.png',
                    width: 20,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 32),

              Align(
                alignment: Alignment.centerRight,
                child: CustomButton(
                  text: 'continue',
                  width: 140, 
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
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
