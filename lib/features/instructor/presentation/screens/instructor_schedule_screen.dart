import 'package:flutter/material.dart';
import 'package:attendro/core/theme/app_colors.dart';
import 'package:attendro/features/instructor/presentation/screens/instructor_profile_screen.dart';

class InstructorScheduleScreen extends StatelessWidget {
  const InstructorScheduleScreen({super.key});

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
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InstructorProfileScreen()),
                      );
                    },
                    icon: const Icon(Icons.person_outline, color: AppColors.primary, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: Table(
                      defaultColumnWidth: const FixedColumnWidth(100),
                      border: TableBorder.all(color: AppColors.primary, width: 1.5),
                      children: [
                        _buildTableHeader(),
                        _buildTableRow('Saturday', ['Intelligent Algorithm Lecture', 'Software Development lecture', '']),
                        _buildTableRow('Sunday', ['', 'Graduation project', '']),
                        _buildTableRow('Monday', ['', 'Software Development sec4', 'Intelligent Algorithm sec 2']),
                        _buildTableRow('Tuesday', ['', 'Deep Learning sec 5', 'IOT sec 2']),
                        _buildTableRow('Wednesday', ['', 'Computation Cognitive Systems sec 4', 'Deep Learning lecture']),
                        _buildTableRow('Thursday', ['', 'Computation Cognitive Systems lecture', 'IOT lecture']),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildTableHeader() {
    return const TableRow(
      children: [
        TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Time/Date', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
        TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('9:00-10:40', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
        TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('10:40-12:20', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
        TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('1:20-3:00', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
      ],
    );
  }

  TableRow _buildTableRow(String day, List<String> slots) {
    return TableRow(
      children: [
        TableCell(child: Padding(padding: EdgeInsets.symmetric(vertical: 24, horizontal: 8), child: Text(day, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)))),
        ...slots.map((s) => TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(s, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500)),
              ),
            )),
      ],
    );
  }
}
