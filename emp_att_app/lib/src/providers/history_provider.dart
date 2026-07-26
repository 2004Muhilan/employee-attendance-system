import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import 'package:intl/intl.dart';

class HistoryProvider with ChangeNotifier {
  // 1. RAW DATA (The "Database" in RAM)
  List<AttendanceRecord> _allRecords = [];
  DateTime? _joiningDate;

  // 2. LOADING STATE
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  DateTime get joiningDate => _joiningDate ?? DateTime(2024, 1, 1);

  // 3. SETTER (Called after API fetch)
  void setHistoryData(List<AttendanceRecord> records, String joiningDateStr) {
    _allRecords = records;
    try {
      _joiningDate = DateTime.parse(joiningDateStr);
    } catch (e) {
      _joiningDate = DateTime(2024, 1, 1); // Fallback
    }
    _isLoading = false;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // ... inside HistoryProvider class ...

  // 4. GETTER (The Filter Logic + Gap Filling)
  List<AttendanceRecord> getRecordsForMonth(DateTime month) {
    if (_joiningDate == null) return [];

    final dateFormat = DateFormat('yyyy-MM-dd');

    // 1. Determine Start Date
    // Start at the 1st of the requested month
    DateTime startDate = DateTime(month.year, month.month, 1);

    // CONSTRAINT: Don't show records before the employee joined.
    // Normalize joiningDate to midnight for fair comparison
    final simpleJoining = DateTime(_joiningDate!.year, _joiningDate!.month, _joiningDate!.day);
    if (startDate.isBefore(simpleJoining)) {
      startDate = simpleJoining;
    }

    // 2. Determine End Date
    // End at the last day of the requested month
    DateTime endDate = DateTime(month.year, month.month + 1, 0);

    // CONSTRAINT: Don't show "Absent" for future dates. Clamp to Today.
    final now = DateTime.now();
    final todaySimple = DateTime(now.year, now.month, now.day);
    if (endDate.isAfter(todaySimple)) {
      endDate = todaySimple;
    }

    // Edge Case: If the valid range is invalid (e.g. joined Feb 15, viewing Jan), return empty
    if (startDate.isAfter(endDate)) return [];

    // 3. Prepare Data for Fast Lookup
    // Map existing records by date string "2026-02-08" -> Record
    final existingMap = {
      for (var r in _allRecords) r.date : r
    };

    List<AttendanceRecord> finalRecords = [];

    // 4. Loop through every day in the range
    for (DateTime d = startDate;
    d.isBefore(endDate) || d.isAtSameMomentAs(endDate);
    d = d.add(const Duration(days: 1))) {

      String dateKey = dateFormat.format(d);

      if (existingMap.containsKey(dateKey)) {
        // ✅ Record Found (Present/Completed)
        finalRecords.add(existingMap[dateKey]!);
      } else {
        // ❌ Record Missing -> Create Synthetic ABSENT Record

        // --- NEW LOGIC: Check for Weekend ---
        if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
          finalRecords.add(AttendanceRecord(
            date: dateKey,
            status: 'HOLIDAY', // <--- New Status
            workHours: 0.0,
            isLate: false,
          ));
        } else {
          // Weekday -> ABSENT
          finalRecords.add(AttendanceRecord(
            date: dateKey,
            status: 'ABSENT',
            workHours: 0.0,
            isLate: false,
          ));
        }
        
      }
    }

    // 5. Sort Descending (Newest date first)
    finalRecords.sort((a, b) => b.date.compareTo(a.date));

    return finalRecords;
  }

  // Helper: Valid Months List (For your Month Picker UI)
  // Returns a list of DateTimes representing available months [Feb 2026, Jan 2026, ... Dec 2024]
  List<DateTime> getAvailableMonths() {
    if (_joiningDate == null) return [];

    List<DateTime> months = [];
    DateTime current = DateTime.now();
    DateTime start = _joiningDate!;

    // Normalize to start of month
    current = DateTime(current.year, current.month);
    start = DateTime(start.year, start.month);

    while (current.isAfter(start) || current.isAtSameMomentAs(start)) {
      months.add(current);
      // Go back one month
      current = DateTime(current.year, current.month - 1);
    }
    return months;
  }
}