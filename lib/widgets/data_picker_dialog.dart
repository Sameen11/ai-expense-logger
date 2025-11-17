import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../common/colors.dart';

Future<DateTime?> showCustomDatePicker({
  required BuildContext context,
  required DateTime initialDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) {
      return _CustomDatePickerDialog(initialDate: initialDate);
    },
  );
}

class _CustomDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  const _CustomDatePickerDialog({required this.initialDate});

  @override
  State<_CustomDatePickerDialog> createState() =>
      _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<_CustomDatePickerDialog> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDate;
    _focusedDay = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    // --- UPDATED: Added fallback colors in case AppColors is not setup ---
    const primaryColor = AppColors.primaryColor ?? Colors.blue;
    const backgroundColor = AppColors.bgColorWhite ?? Colors.white;
    const textColor = Colors.black;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: primaryColor, // Blue header
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Text(
                // --- UPDATED: Format to show the month/year we care about ---
                DateFormat('MMMM yyyy').format(_focusedDay),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            // Calendar
            TableCalendar(
              firstDay: DateTime.utc(2010, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              // --- UPDATED: This picker is for the *month*, so just highlight the day ---
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay; // update focused day
                });
              },
              onPageChanged: (focusedDay) {
                // --- UPDATED: Keep focused day in sync with page changes ---
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              // Style
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
                leftChevronIcon:
                const Icon(Icons.arrow_back_ios, size: 16, color: Colors.black),
                rightChevronIcon: const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.black),
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(color: Colors.white),
              ),
            ),
            // Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                          side: BorderSide(color: Colors.grey[300]!)
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: textColor)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('OK', style: TextStyle(color: Colors.white)),
                    // --- UPDATED: Return the selected/focused day ---
                    onPressed: () => Navigator.pop(context, _selectedDay),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}