import 'package:flutter/material.dart';
import 'package:attendro/core/theme/app_colors.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Text(
          "Attendance Records Screen",
          style: TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
