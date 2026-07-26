import 'package:flutter/material.dart';
import '../services/api_service.dart';

enum AttendanceStatus { notCheckedIn, checkedIn, completed, loading }

class AttendanceProvider with ChangeNotifier {
  AttendanceStatus _status = AttendanceStatus.loading;
  String? _checkInTime;
  String? _checkOutTime;

  // --- Getters ---
  AttendanceStatus get status => _status;
  String? get checkInTime => _checkInTime;
  String? get checkOutTime => _checkOutTime;

  bool get isLoading => _status == AttendanceStatus.loading;

  // Logic Helpers
  bool get canCheckIn => _status == AttendanceStatus.notCheckedIn;
  bool get canCheckOut => _status == AttendanceStatus.checkedIn;
  bool get isCompleted => _status == AttendanceStatus.completed;

  // --- MAIN ACTION: Fetch & Initialize ---
  Future<void> fetchTodayStatus(String token) async {
    // 1. Set Loading (prevents button flickering)
    _status = AttendanceStatus.loading;
    notifyListeners();

    try {
      // 2. Call API
      final apiService = ApiService();
      final data = await apiService.getAttendanceStatus(token);

      // 3. Update State
      _setStatusFromApi(data);

    } catch (e) {
      print("⚠️ Error fetching status: $e");
      // Fallback: If API fails, maybe default to not checked in,
      // or show an error. For now, we unlock the UI.
      _status = AttendanceStatus.notCheckedIn;
      notifyListeners();
    }
  }

  // --- Internal State Setter ---
  void _setStatusFromApi(Map<String, dynamic> data) {
    final statusStr = data['status'];

    if (statusStr == 'NOT_CHECKED_IN') {
      _status = AttendanceStatus.notCheckedIn;
      _checkInTime = null;
      _checkOutTime = null;

    } else if (statusStr == 'CHECKED_IN') {
      _status = AttendanceStatus.checkedIn;
      _checkInTime = _parseTime(data['check_in_time']);
      _checkOutTime = null;

    } else if (statusStr == 'COMPLETED') {
      _status = AttendanceStatus.completed;
      _checkInTime = _parseTime(data['check_in_time']);
      _checkOutTime = _parseTime(data['check_out_time']);
    }

    notifyListeners();
  }

  // Helper to safely convert server timestamp to String
  String? _parseTime(dynamic timestamp) {
    if (timestamp == null) return null;
    // If server sends ISO string "2026-02-09...", just return it.
    // If you want to format it nicely (e.g. "09:00 AM"), do it here or in UI.
    return timestamp.toString();
  }
}