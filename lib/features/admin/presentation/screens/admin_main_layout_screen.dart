import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:attendro/features/admin/presentation/screens/admin_home_screen.dart';
import 'package:attendro/features/admin/presentation/screens/admin_requests_screen.dart';
import 'package:attendro/features/admin/presentation/screens/admin_manage_courses_screen.dart';
import 'package:attendro/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:attendro/core/services/auth_service.dart';

class AdminMainLayoutScreen extends StatefulWidget {
  const AdminMainLayoutScreen({super.key});

  @override
  State<AdminMainLayoutScreen> createState() => _AdminMainLayoutScreenState();
}

class _AdminMainLayoutScreenState extends State<AdminMainLayoutScreen> {
  int _currentIndex = 0;
  DateTime? _lastPressedAt;
  
  final List<Widget> _screens = [
    const AdminHomeScreen(),
    const AdminManageCoursesScreen(),
    const AdminRequestsScreen(),
    const AdminUsersScreen(),
  ];

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
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Admin Panel',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.primary),
              onPressed: () async {
                await AuthService().signOut();
              },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.primary.withAlpha(30),
            height: 1,
          ),
        ),
      ),
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
                icon: Icon(
                  Icons.assignment_ind_outlined, 
                  size: 26, 
                  color: _currentIndex == 2 ? AppColors.primary : AppColors.primary.withAlpha(153),
                ),
                label: 'Requests',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/images/icons/profile-2user.png', 
                  height: 24, 
                  color: _currentIndex == 3 ? AppColors.primary : AppColors.primary.withAlpha(153),
                ),
                label: 'Users',
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
