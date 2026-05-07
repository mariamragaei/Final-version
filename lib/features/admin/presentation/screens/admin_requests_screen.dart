import 'package:flutter/material.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(BuildContext context, String uid, String status) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'status': status,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User request $status successfully.'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
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
                          hintText: 'Search by email...',
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
                      'Instructor Requests',
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
                    Expanded(flex: 3, child: Text('Email', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Role', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold))),
                    SizedBox(width: 80), // Space for action icons
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: AppColors.primary, thickness: 2),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading requests'));
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No pending requests at the moment.',
                          style: TextStyle(color: AppColors.primary, fontSize: 16),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final uid = docs[index].id;
                        final email = data['email'] ?? 'Unknown';
                        final role = data['role'] ?? 'Unknown';

                        if (_searchQuery.isNotEmpty) {
                          if (!email.toString().toLowerCase().contains(_searchQuery)) {
                            return const SizedBox.shrink();
                          }
                        }

                        return _buildFullRequestItem(context, uid, email, role);
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

  Widget _buildFullRequestItem(BuildContext context, String uid, String email, String role) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              email.toString().split('@')[0],
              style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              role.toUpperCase(),
              style: const TextStyle(color: AppColors.primary, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _updateStatus(context, uid, 'approved'),
            child: Image.asset('assets/images/icons/image 1.png', width: 22),
          ), // Check
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => _updateStatus(context, uid, 'rejected'),
            child: Image.asset('assets/images/icons/image 2.png', width: 22),
          ), // X
        ],
      ),
    );
  }
}
