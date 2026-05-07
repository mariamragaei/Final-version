import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:attendro/features/auth/presentation/screens/login_screen.dart';

import 'package:attendro/core/services/auth_service.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 250,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
