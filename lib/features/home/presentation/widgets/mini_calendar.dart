import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MiniCalendar extends StatelessWidget {
  const MiniCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(now).toUpperCase();
    final today = now.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          monthName,
          style: const TextStyle(
            color: Color(0xFFFF5252),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['S', 'S', 'M', 'T', 'W', 'T', 'F'].map((day) {
            return SizedBox(
              width: 20,
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        ..._generateCalendarRows(now, today),
      ],
    );
  }

  List<Widget> _generateCalendarRows(DateTime now, int today) {
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7; 

    List<int?> allDays = [
      ...List.generate(startWeekday, (_) => null),
      ...List.generate(daysInMonth, (i) => i + 1),
    ];
    
    while (allDays.length % 7 != 0) {
        allDays.add(null);
    }

    List<Widget> rows = [];
    for (int i = 0; i < allDays.length; i += 7) {
        rows.add(_buildCalendarRow(allDays.sublist(i, i + 7), highlightedDay: today));
    }
    return rows;
  }

  Widget _buildCalendarRow(List<int?> days, {int? highlightedDay}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days.map((day) {
          if (day == null) return const SizedBox(width: 20);
          
          bool isHighlighted = day == highlightedDay;
          
          return Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isHighlighted ? const Color(0xFFFF5252) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  color: isHighlighted ? Colors.white : Colors.black87,
                  fontSize: 9,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
