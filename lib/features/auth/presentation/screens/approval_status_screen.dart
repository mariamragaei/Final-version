import 'package:flutter/material.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:attendro/features/auth/presentation/screens/signup_screen.dart';
import 'package:attendro/features/instructor/presentation/screens/instructor_main_layout.dart';
import 'package:attendro/core/services/auth_service.dart';

class ApprovalStatusScreen extends StatefulWidget {
  final bool isAccepted;

  const ApprovalStatusScreen({
    super.key,
    required this.isAccepted,
  });

  @override
  State<ApprovalStatusScreen> createState() => _ApprovalStatusScreenState();
}

class _ApprovalStatusScreenState extends State<ApprovalStatusScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.isAccepted) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const InstructorMainLayoutScreen(),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
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

              Text(
                widget.isAccepted
                    ? 'Your request as instructor\nhas been Accepted'
                    : 'Your request as instructor\nhas been declined',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const Spacer(flex: 1),

              Center(
                child: widget.isAccepted
                    ? Image.asset(
                        'assets/images/request/accepted.png',
                        width: 200,
                        fit: BoxFit.contain,
                      )
                    : SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset('assets/images/request/rejected/Vector-1.png'),
                            Image.asset('assets/images/request/rejected/Vector.png'),
                          ],
                        ),
                      ),
              ),

              const Spacer(flex: 2),

              if (!widget.isAccepted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create new account?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            await AuthService().signOut();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignupScreen(),
                                ),
                                (route) => route.isFirst, 
                              );
                            }
                          },
                          child: const Text(
                            'Sign up',
                            style: TextStyle(
                              color: Color(0xFF63B4FF),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
