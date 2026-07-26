import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:5000";
    } else {
      return "http://10.0.2.2:5000";
    }
  }

  // CHANGED: Matches your Python Blueprint (auth_bp) + Route
  static const String loginEndpoint = "/auth/login";
  static const String registerEndpoint = "/auth/register";
  static const String officeGeofenceEndpoint = "/geofence/my-office";
  static const String attendanceHistoryEndpoint = "/attendance/history";
  static const String attendanceStatusEndpoint = "/attendance/today-status";
  static const String attendanceCheckInEndpoint = "/attendance/check-in";
  static const String attendanceCheckOutEndpoint = "/attendance/check-out";
  static const String leaveSubmitEndpoint = "/leave/submit";
  static const String leaveHistoryEndpoint = "/leave/history";
}