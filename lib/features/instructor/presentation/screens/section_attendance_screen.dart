import 'package:flutter/material.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentRecord {
  final String name;
  final String id;
  final String uid;
  final String attendance;

  StudentRecord({required this.name, required this.id, required this.uid, required this.attendance});
}

class SectionAttendanceScreen extends StatefulWidget {
  final String title;
  final String courseCode;
  const SectionAttendanceScreen({super.key, required this.title, required this.courseCode});

  @override
  State<SectionAttendanceScreen> createState() => _SectionAttendanceScreenState();
}

class _SectionAttendanceScreenState extends State<SectionAttendanceScreen> {
  String _selectedWeek = 'Week 6';
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  
  List<StudentRecord> _allStudents = [];
  List<StudentRecord> _filteredStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
    setState(() => _isLoading = true);
    try {
      // Get attendance sessions for this course
      final sessionsSnap = await FirebaseFirestore.instance
          .collection('attendance_sessions')
          .where('courseCode', isEqualTo: widget.courseCode)
          .get();
          
      int totalSessions = sessionsSnap.docs.length;
      
      Map<String, int> attendanceCounts = {};
      for (var doc in sessionsSnap.docs) {
        final data = doc.data();
        final List<dynamic> attended = data['attendedStudents'] ?? [];
        for (var uid in attended) {
          attendanceCounts[uid.toString()] = (attendanceCounts[uid.toString()] ?? 0) + 1;
        }
      }

      List<StudentRecord> loadedStudents = [];
      Set<String> addedCodes = {}; // Track added student codes to avoid duplicates

      // --- Source 1: Read from enrolled_sections (uploaded Excel sheets) ---
      final courseDoc = await FirebaseFirestore.instance
          .collection('courses_management')
          .doc(widget.courseCode)
          .get();

      if (courseDoc.exists) {
        final courseData = courseDoc.data() as Map<String, dynamic>;
        final enrolledSections = courseData['enrolled_sections'] as Map<String, dynamic>? ?? {};

        for (var sectionEntry in enrolledSections.entries) {
          final sectionData = sectionEntry.value as Map<String, dynamic>;
          final students = sectionData['students'] as List<dynamic>? ?? [];

          for (var student in students) {
            final s = student as Map<String, dynamic>;
            final code = (s['code'] ?? '').toString();
            final name = (s['name'] ?? 'Unknown').toString();

            if (code.isNotEmpty && !addedCodes.contains(code)) {
              addedCodes.add(code);
              loadedStudents.add(StudentRecord(
                name: name,
                id: code,
                uid: code, // Use code as uid for sheet-uploaded students
                attendance: totalSessions == 0 ? '0%' : '0%',
              ));
            }
          }
        }
      }

      // --- Source 2: Read from users collection (registered app users) ---
      final usersSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      for (var doc in usersSnap.docs) {
        final data = doc.data();
        final courses = data['courses'] as List<dynamic>? ?? [];
        
        bool isEnrolled = courses.any((c) {
          final cMap = c as Map<String, dynamic>;
          return cMap['code'] == widget.courseCode;
        });

        if (isEnrolled) {
          final studentId = data['studentId'] ?? data['id'] ?? doc.id.substring(0, 5);
          int attended = attendanceCounts[doc.id] ?? 0;
          double percentage = totalSessions == 0 ? 0 : (attended / totalSessions) * 100;

          // If this student was already added from the sheet, update their record with real data
          if (addedCodes.contains(studentId.toString())) {
            final existingIndex = loadedStudents.indexWhere((s) => s.id == studentId.toString());
            if (existingIndex != -1) {
              loadedStudents[existingIndex] = StudentRecord(
                name: data['name'] ?? loadedStudents[existingIndex].name,
                id: studentId.toString(),
                uid: doc.id, // Use real Firebase UID
                attendance: '${percentage.toInt()}%',
              );
            }
          } else {
            addedCodes.add(studentId.toString());
            loadedStudents.add(StudentRecord(
              name: data['name'] ?? 'Unknown',
              id: studentId.toString(),
              uid: doc.id,
              attendance: '${percentage.toInt()}%',
            ));
          }
        }
      }

      setState(() {
        _allStudents = loadedStudents;
        _filteredStudents = loadedStudents;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching attendance data: $e");
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    setState(() {
      _filteredStudents = _allStudents
          .where((s) => s.id.contains(_searchController.text) || s.name.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.primary, size: 28),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Image.asset('assets/images/icons/printer.png', width: 22, color: AppColors.primary),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => setState(() => _isSearchMode = !_isSearchMode),
                        child: Image.asset('assets/images/icons/filter-search.png', width: 22, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_isSearchMode)
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBDCEDB).withAlpha(128),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search by ID',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: AppColors.primary, fontSize: 13),
                          ),
                          style: const TextStyle(color: AppColors.primary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedWeek,
                      dropdownColor: AppColors.primary,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      onChanged: (String? newValue) {
                        setState(() => _selectedWeek = newValue!);
                      },
                      items: <String>[
                        'Week 1',
                        'Week 2',
                        'Week 3',
                        'Week 4',
                        'Week 5',
                        'Week 6',
                        'Week 7',
                        'Week 8'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 32),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text('Name', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('ID', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Attendance', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('send warning', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: AppColors.primary, thickness: 2),

              Expanded(
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _filteredStudents.isEmpty
                        ? const Center(child: Text("No students found.", style: TextStyle(color: AppColors.primary)))
                        : ListView.builder(
                            itemCount: _filteredStudents.length,
                            itemBuilder: (context, index) {
                              final student = _filteredStudents[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Row(
                                  children: [
                                    Expanded(flex: 3, child: Text(student.name, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w500))),
                                    Expanded(flex: 2, child: Text(student.id, style: const TextStyle(color: AppColors.primary, fontSize: 10))),
                                    Expanded(flex: 2, child: Text(student.attendance, style: const TextStyle(color: AppColors.primary, fontSize: 10))),
                                    Expanded(
                                      flex: 2,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: GestureDetector(
                                          onTap: () async {
                                            final warningId = '${widget.courseCode}_manual_warning_${DateTime.now().millisecondsSinceEpoch}';
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(student.uid)
                                                .collection('notifications')
                                                .doc(warningId)
                                                .set({
                                              'title': '⚠️ Instructor Warning',
                                              'message': 'Your instructor has issued a warning regarding your attendance in ${widget.courseCode}.',
                                              'courseCode': widget.courseCode,
                                              'type': 'absence_warning',
                                              'isRead': false,
                                              'timestamp': FieldValue.serverTimestamp(),
                                            });
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Warning sent to ${student.name}.'), backgroundColor: Colors.green),
                                              );
                                            }
                                          },
                                          child: const Icon(Icons.send_outlined, color: AppColors.primary, size: 18),
                                        ),
                                      ),
                                    ),
                                  ],
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
