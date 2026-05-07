import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendro/core/services/auth_service.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:attendro/features/student/presentation/screens/notifications_screen.dart';
import 'package:attendro/features/student/presentation/screens/student_profile_screen.dart';
import 'package:attendro/core/widgets/notification_bell.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Schedule',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                          );
                        },
                        icon: const NotificationBell(size: 28),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const StudentProfileScreen()),
                          );
                        },
                        icon: const Icon(Icons.person_outline, color: AppColors.primary, size: 28),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(AuthService().currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const Center(child: Text('No schedule found', style: TextStyle(color: AppColors.primary)));
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final timetableData = data['timetable'] as Map<String, dynamic>?;
                    final headersData = data['timetableHeaders'] as List<dynamic>?;

                    if (timetableData == null || timetableData.isEmpty || headersData == null) {
                      return const Center(child: Text('You do not have any scheduled classes.', style: TextStyle(color: AppColors.primary)));
                    }

                    final days = ['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday'];

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: Table(
                          defaultColumnWidth: const FixedColumnWidth(100),
                          border: TableBorder.all(color: AppColors.primary, width: 1.5),
                          children: [
                            TableRow(
                              children: [
                                const TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Date \\ Time', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
                                ...headersData.map((h) => TableCell(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(h.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    )),
                              ],
                            ),
                            ...days.map((day) {
                              final slots = timetableData[day] as List<dynamic>? ?? List.filled(headersData.length, '-');
                              return TableRow(
                                children: [
                                  TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8), child: Text(day, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)))),
                                  ...slots.map((s) => TableCell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(s.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w500, height: 1.3)),
                                        ),
                                      )),
                                ],
                              );
                            }).toList(),
                          ],
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

