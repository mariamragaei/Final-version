import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:attendro/features/instructor/presentation/screens/instructor_home_screen.dart';
import 'package:attendro/features/instructor/presentation/screens/instructor_courses_screen.dart';

import 'package:attendro/features/instructor/presentation/screens/instructor_profile_screen.dart';

class InstructorMainLayoutScreen extends StatefulWidget {
  const InstructorMainLayoutScreen({super.key});

  @override
  State<InstructorMainLayoutScreen> createState() => _InstructorMainLayoutScreenState();
}

class _InstructorMainLayoutScreenState extends State<InstructorMainLayoutScreen> {
  int _currentIndex = 0;
  DateTime? _lastPressedAt;
  
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      InstructorHomeScreen(onSeeAll: () => setState(() => _currentIndex = 1)),
      const InstructorCoursesScreen(),
      const InstructorProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return;
        }

        final now = DateTime.now();
        if (_lastPressedAt == null || now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Press back again to exit'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }

        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFC7DBE8),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.primary.withAlpha(153),
            items: [
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/images/icons/home.png', 
                  height: 24, 
                  color: _currentIndex == 0 ? AppColors.primary : AppColors.primary.withAlpha(153),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/images/icons/book.png', 
                  height: 24, 
                  color: _currentIndex == 1 ? AppColors.primary : AppColors.primary.withAlpha(153),
                ),
                label: 'Courses',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/images/icons/frame.png', 
                  height: 24, 
                  color: _currentIndex == 2 ? AppColors.primary : AppColors.primary.withAlpha(153),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
