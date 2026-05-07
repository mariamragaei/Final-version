import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:attendro/core/theme/app_theme.dart';
import 'package:attendro/core/services/auth_service.dart';
import 'package:attendro/core/services/notification_service.dart';
import 'package:attendro/features/landing/presentation/screens/landing_screen.dart';
import 'package:attendro/features/home/presentation/screens/main_layout_screen.dart';
import 'package:attendro/features/instructor/presentation/screens/instructor_main_layout.dart';
import 'package:attendro/features/admin/presentation/screens/admin_main_layout_screen.dart';
import 'package:attendro/features/auth/presentation/screens/login_screen.dart';
import 'package:attendro/features/auth/presentation/screens/role_screen.dart';
import 'package:attendro/features/auth/presentation/screens/pending_approval_screen.dart';
import 'package:attendro/features/auth/presentation/screens/approval_status_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await NotificationService().initialize();
  
  runApp(const AttendroApp());
}

class AttendroApp extends StatelessWidget {
  const AttendroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Antigravity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const LandingScreen();
    }

    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (authSnapshot.hasData) {
          NotificationService().saveTokenToFirestore(authSnapshot.data!.uid);

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(authSnapshot.data!.uid).snapshots(),
            builder: (context, userDocSnapshot) {
              if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (userDocSnapshot.hasError) {
                return Scaffold(body: Center(child: Text('Error loading user data: ${userDocSnapshot.error}')));
              }

              if (!userDocSnapshot.hasData || !userDocSnapshot.data!.exists) {
                return const RoleScreen();
              }

              final userData = userDocSnapshot.data!.data() as Map<String, dynamic>?;
              final role = userData?['role'] as String?;
              final status = userData?['status'] as String?;

              if (role == null || role.isEmpty) {
                return const RoleScreen();
              }

              if (role == 'admin') return const AdminMainLayoutScreen();

              if (role == 'instructor' || role == 'doctor' || role == 'ta') {
                if (status == 'pending') {
                  return const PendingApprovalScreen();
                } else if (status == 'declined' || status == 'rejected') {
                  return const ApprovalStatusScreen(isAccepted: false);
                } else {
                  return const InstructorMainLayoutScreen();
                }
              }

              return const MainLayoutScreen();
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}
