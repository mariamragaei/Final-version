import 'package:flutter/material.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:attendro/core/widgets/custom_text_field.dart';
import 'package:attendro/core/widgets/custom_button.dart';
import 'package:attendro/features/auth/presentation/screens/signup_screen.dart';
import 'package:attendro/features/auth/presentation/screens/forget_password_screen.dart';
import 'package:attendro/features/home/presentation/screens/main_layout_screen.dart';
import 'package:attendro/features/instructor/presentation/screens/instructor_main_layout.dart';
import 'package:attendro/features/admin/presentation/screens/admin_main_layout_screen.dart';
import 'package:attendro/core/services/auth_service.dart';
import 'package:attendro/features/auth/presentation/screens/pending_approval_screen.dart';
import 'package:attendro/features/auth/presentation/screens/approval_status_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  final AuthService _auth = AuthService();

  void _onLogin() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter email and password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.loginWithEmail(email, password);
      
      if (userCredential?.user != null) {
        final userData = await _auth.getUserData(userCredential!.user!.uid);
        final role = userData?['role'];
        
        if (mounted && (role == null || role.isEmpty)) {
          // If no role is set, AuthWrapper will automatically redirect to RoleScreen.
        } else if (mounted) {
          _showSnackBar('Welcome back!');
        }
      }
    } catch (e) {
      _showSnackBar(e.toString().contains('user-not-found') 
          ? 'No user found with this email.' 
          : 'Login failed. Please check your credentials.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                'Welcome back!',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              
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
              const SizedBox(height: 24),
              
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : CustomButton(
                          text: 'Continue',
                          width: 140,
                          onPressed: _onLogin,
                        ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ForgetPasswordScreen()),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: Color(0xFF63B4FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
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
                  text: 'Create new Account',
                  width: 280,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
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
