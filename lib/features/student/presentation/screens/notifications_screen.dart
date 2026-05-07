import 'package:flutter/material.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendro/core/services/auth_service.dart';
import 'package:attendro/core/services/absence_service.dart';
import 'package:attendro/features/student/presentation/screens/student_profile_screen.dart' as attendro_profile;
import 'package:attendro/core/widgets/notification_bell.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    final uid = AuthService().currentUser?.uid;
    if (uid != null) {
      AbsenceService().checkAndSendWarnings(uid);
    }
  }

  Future<void> _markAllAsRead() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    
    final notificationsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in notificationsSnap.docs) {
      await doc.reference.update({'isRead': true});
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read'), backgroundColor: AppColors.primary),
      );
    }
  }

  String _timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    }
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;

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
                    'Notifications',
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
                          // Already on notifications screen
                        },
                        icon: const NotificationBell(size: 28),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const attendro_profile.StudentProfileScreen()),
                          );
                        },
                        icon: const Icon(Icons.person_outline, color: AppColors.primary, size: 28),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 48),

              Expanded(
                child: uid == null
                    ? const Center(child: Text('Please log in first.'))
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('notifications')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text(
                                'No notifications yet.',
                                style: TextStyle(color: AppColors.primary, fontSize: 14),
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: snapshot.data!.docs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final doc = snapshot.data!.docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final isWarning = data['type'] == 'absence_warning';
                              final isRead = data['isRead'] ?? false;

                              return _buildNotificationItem(
                                title: data['title'] ?? '',
                                message: data['message'] ?? '',
                                time: _timeAgo(data['timestamp'] as Timestamp?),
                                isWarning: isWarning,
                                isRead: isRead,
                              );
                            },
                          );
                        },
                      ),
              ),

              Center(
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextButton(
                    onPressed: _markAllAsRead,
                    child: const Text('Mark as read', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String message,
    required String time,
    required bool isWarning,
    required bool isRead,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isWarning
          ? (isRead ? const Color(0xFFFFE0E0) : const Color(0xFFFFCDD2))
          : const Color(0xFFBDCEDB),
        borderRadius: BorderRadius.circular(12),
        border: isWarning && !isRead
          ? Border.all(color: Colors.red.shade400, width: 1.5)
          : null,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isWarning) ...[
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isWarning ? Colors.red.shade800 : AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: isWarning ? Colors.red.shade700 : AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            time,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
