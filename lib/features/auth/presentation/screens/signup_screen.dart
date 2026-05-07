import 'package:flutter/material.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:attendro/core/widgets/custom_text_field.dart';
import 'package:attendro/core/widgets/custom_button.dart';
import 'package:attendro/features/auth/presentation/screens/role_screen.dart';
import 'package:attendro/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:attendro/core/services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  final AuthService _auth = AuthService();

  void _onSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Please fill all fields');
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.registerWithEmail(email, password, name: name);
      _showSnackBar('Account created successfully!');
      if (mounted) Navigator.pop(context); // Go back to login or let StreamBuilder handle it
    } catch (e) {
      _showSnackBar('Registration failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.primary),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
              const SizedBox(height: 40),

              const Text(
                'Where Attendance Meets\nIntelligence.',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to attendro!',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),

              CustomTextField(
                label: 'Name',
                hintText: 'John Doe',
                controller: _nameController,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Email address',
                hintText: 'Example@eru.edu.eg',
                controller: _emailController,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Password',
                hintText: '**********',
                isPassword: _obscurePassword,
                controller: _passwordController,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.primary,
                    size: 20,
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
                label: 'confirm password',
                hintText: '**********',
                isPassword: _obscureConfirmPassword,
                controller: _confirmPasswordController,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),

              Align(
                alignment: Alignment.centerRight,
                child: _isLoading 
                ? const CircularProgressIndicator()
                : CustomButton(
                  text: 'Continue',
                  width: 140,
                  onPressed: _onSignup,
                ),
              ),
              const SizedBox(height: 48),

              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.primary, thickness: 1)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.primary, thickness: 1)),
                ],
              ),
              const SizedBox(height: 48),

              Align(
                alignment: Alignment.center,
                child: CustomButton(
                  text: 'Already have account',
                  width: 280, // Matches width from login
                  onPressed: () {
                    Navigator.pop(context);
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
