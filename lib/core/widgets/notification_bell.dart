import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendro/core/services/auth_service.dart';
import 'package:attendro/core/theme/app_colors.dart';

class NotificationBell extends StatelessWidget {
  final Color color;
  final double size;
  final bool useAsset;

  const NotificationBell({
    super.key,
    this.color = AppColors.primary,
    this.size = 28,
    this.useAsset = false,
  });

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;

    if (uid == null) {
      return _buildIcon(false);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        final hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        return _buildIcon(hasUnread);
      },
    );
  }

  Widget _buildIcon(bool hasUnread) {
    return Stack(
      children: [
        useAsset
            ? Image.asset(
                'assets/images/icons/notification.png',
                width: size,
                color: color,
              )
            : Icon(
                Icons.notifications_none,
                color: color,
                size: size,
              ),
        if (hasUnread)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(
                minWidth: 10,
                minHeight: 10,
              ),
            ),
          ),
      ],
    );
  }
}
