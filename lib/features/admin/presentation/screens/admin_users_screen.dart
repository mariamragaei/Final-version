import 'package:flutter/material.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendro/core/services/auth_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(BuildContext context, String uid, String newStatus) async {
    try {
      await AuthService().updateUserRole(uid, status: newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${newStatus == 'blocked' ? 'Blocked' : 'Updated'}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteUser(BuildContext context, String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted from database')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

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
                  if (_isSearching)
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search by name...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close, color: AppColors.primary),
                            onPressed: () {
                              setState(() {
                                _isSearching = false;
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          ),
                        ),
                        style: const TextStyle(color: AppColors.primary),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    )
                  else
                    const Text(
                      'Users',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (!_isSearching)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSearching = true;
                        });
                      },
                      child: Image.asset('assets/images/icons/filter-search.png', width: 24),
                    ),
                ],
              ),
              const SizedBox(height: 32),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Padding(padding: EdgeInsets.only(right: 8.0), child: Text('Name', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)))),
                    Expanded(flex: 2, child: Text('Role', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold))),
                    Expanded(flex: 5, child: Text('Action', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: AppColors.primary, thickness: 2),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No users found'));
                    }

                    final currentUid = AuthService().currentUser?.uid;

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final uid = doc.id;
                        
                        if (uid == currentUid) return const SizedBox.shrink();
                        
                        final name = data['name'] ?? 'No Name';
                        final role = data['role']?.toString().toUpperCase() ?? 'STUDENT';
                        
                        if (_searchQuery.isNotEmpty) {
                          if (!name.toString().toLowerCase().contains(_searchQuery)) {
                            return const SizedBox.shrink();
                          }
                        }

                        return _buildUserDetailItem(
                          context,
                          uid,
                          name,
                          role,
                          data['status'] == 'blocked',
                        );
                      },
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

  Widget _buildUserDetailItem(BuildContext context, String uid, String name, String role, bool isBlocked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                name,
                style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                role,
                style: const TextStyle(color: AppColors.primary, fontSize: 12),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                _buildActionButton(
                  context, 
                  'Make admin', 
                  () => AuthService().updateUserRole(uid, role: 'admin')
                ),
                _buildActionButton(
                  context, 
                  isBlocked ? 'Unblock' : 'Block', 
                  () => _updateStatus(context, uid, isBlocked ? 'approved' : 'blocked')
                ),
                IconButton(
                  onPressed: () => _deleteUser(context, uid),
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF001F3F), // Dark navy
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
