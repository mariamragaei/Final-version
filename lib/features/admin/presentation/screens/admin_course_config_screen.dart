import 'package:flutter/material.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCourseConfigScreen extends StatefulWidget {
  final String courseCode;
  final String courseName;
  const AdminCourseConfigScreen({super.key, required this.courseCode, required this.courseName});

  @override
  State<AdminCourseConfigScreen> createState() => _AdminCourseConfigScreenState();
}

class _AdminCourseConfigScreenState extends State<AdminCourseConfigScreen> {
  int _numGroups = 3;
  int _numSections = 5;

  List<Map<String, dynamic>> _doctorsList = [];
  List<Map<String, dynamic>> _tasList = [];

  final Map<int, String?> _selectedDoctors = {};
  final Map<int, String?> _selectedTAs = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      _doctorsList = usersSnap.docs
          .where((doc) {
            final role = doc.data()['role']?.toString().toLowerCase();
            return role == 'doctor' || role == 'instructor';
          })
          .map((doc) => {'uid': doc.id, 'name': doc.data()['name'] ?? 'Unknown'})
          .toList();
      
      _tasList = usersSnap.docs
          .where((doc) {
            final role = doc.data()['role']?.toString().toLowerCase();
            return role == 'ta';
          })
          .map((doc) => {'uid': doc.id, 'name': doc.data()['name'] ?? 'Unknown'})
          .toList();

      final courseSnap = await FirebaseFirestore.instance.collection('courses_management').doc(widget.courseCode).get();
      if (courseSnap.exists) {
        final data = courseSnap.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _numGroups = data['numGroups'] ?? 3;
            _numSections = data['numSections'] ?? 5;
            
            if (data['groups'] != null) {
              Map<String, dynamic> groupsMap = data['groups'];
              groupsMap.forEach((key, value) {
                _selectedDoctors[int.parse(key)] = value;
              });
            }
            if (data['sections'] != null) {
              Map<String, dynamic> sectionsMap = data['sections'];
              sectionsMap.forEach((key, value) {
                _selectedTAs[int.parse(key)] = value;
              });
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching config: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveConfig() async {
    Map<String, dynamic> groupsMap = {};
    _selectedDoctors.forEach((key, value) {
      if (value != null) groupsMap[key.toString()] = value;
    });

    Map<String, dynamic> sectionsMap = {};
    _selectedTAs.forEach((key, value) {
      if (value != null) sectionsMap[key.toString()] = value;
    });

    await FirebaseFirestore.instance.collection('courses_management').doc(widget.courseCode).set({
      'numGroups': _numGroups,
      'numSections': _numSections,
      'groups': groupsMap,
      'sections': sectionsMap,
      'title': widget.courseName,
      'code': widget.courseCode,
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course configuration saved successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 48),
                    Text(
                      widget.courseName,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildNumberedField('number of groups:', _numGroups, (val) {
                      setState(() => _numGroups = val);
                    }),
                    const SizedBox(height: 16),
                    _buildNumberedField('number of sections:', _numSections, (val) {
                      setState(() => _numSections = val);
                    }),

                    const SizedBox(height: 40),

                    const Text(
                      'Doctor:',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    ...List.generate(_numGroups, (index) {
                      return _buildGenericDropdown('Group ${index + 1}', _doctorsList, _selectedDoctors, index, 200);
                    }),

                    const SizedBox(height: 40),

                    const Text(
                      'Teaching assistant:',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    ...List.generate(_numSections, (index) {
                      return _buildGenericDropdown('Section ${index + 1}', _tasList, _selectedTAs, index, 180);
                    }),
                    
                    const SizedBox(height: 40),

                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFF001F3F),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextButton(
                          onPressed: _saveConfig,
                          child: const Text(
                            'Save Configuration',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildNumberedField(String label, int value, Function(int) onChanged) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => onChanged(value >= 9 ? 1 : value + 1),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                value.toString(),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenericDropdown(String label, List<Map<String, dynamic>> items, Map<int, String?> selectionMap, int index, double width) {
    String? currentVal = selectionMap[index];
    bool exists = items.any((item) => item['uid'] == currentVal);
    if (!exists) {
      currentVal = null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentVal,
              hint: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              dropdownColor: AppColors.primary,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              onChanged: (String? newValue) {
                setState(() {
                  selectionMap[index] = newValue;
                });
              },
              items: items.map<DropdownMenuItem<String>>((Map<String, dynamic> item) {
                return DropdownMenuItem<String>(
                  value: item['uid'],
                  child: Text(item['name']),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
