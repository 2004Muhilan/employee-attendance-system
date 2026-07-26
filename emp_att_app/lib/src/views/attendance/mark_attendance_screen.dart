import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/office_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/employee_provider.dart';
import '../../services/api_service.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  OfficeModel? _office;
  bool _isLoadingOffice = true;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchOfficeDetails();
  }

  // Fetch Office details to know the Check-In/Check-Out time windows
  Future<void> _fetchOfficeDetails() async {
    try {
      final token = Provider.of<EmployeeProvider>(context, listen: false).authToken;
      if (token != null) {
        final office = await ApiService().getOfficeGeofence(token);
        if (mounted) {
          setState(() {
            _office = office;
            _isLoadingOffice = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingOffice = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading office hours: $e")));
      }
    }
  }

  // --- TIME VALIDATION LOGIC ---
  bool _isTimeValid(String? timeStr, bool isCheckIn) {
    if (_office == null || timeStr == null) return false;

    // Helper: Convert "09:00" string to double (e.g., 9.0) for comparison
    double toDouble(String time) {
      final parts = time.split(':');
      return double.parse(parts[0]) + (double.parse(parts[1]) / 60.0);
    }

    final now = TimeOfDay.now();
    final currentDouble = now.hour + (now.minute / 60.0);
    final targetDouble = toDouble(timeStr);

    // If it's check-in or check-out, we generally want to ensure
    // we are AFTER the start time.
    return currentDouble >= targetDouble;
  }

  Future<void> _handleAttendanceAction(bool isCheckIn) async {
    setState(() => _isActionLoading = true);

    try {
      // 1. Check Permissions & Get Location
      final position = await _determinePosition();

      // 2. Get Token
      final token = Provider.of<EmployeeProvider>(context, listen: false).authToken;
      if (token == null) throw "Authentication error. Please relogin.";

      // 3. Call API
      final api = ApiService();
      if (isCheckIn) {
        await api.markCheckIn(token, position.latitude, position.longitude);
      } else {
        await api.markCheckOut(token, position.latitude, position.longitude);
      }

      // 4. Success! Refresh Status
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCheckIn ? "Checked In Successfully!" : "Checked Out Successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the provider so the UI updates (buttons disable, status changes)
        await Provider.of<AttendanceProvider>(context, listen: false).fetchTodayStatus(token);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // Geo-location Helper
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled. Please enable GPS.';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permissions are denied';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are permanently denied, we cannot request permissions.';
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    final attendance = Provider.of<AttendanceProvider>(context);
    final now = DateTime.now();

    // 1. Determine Button States
    bool canCheckIn = false;
    bool canCheckOut = false;
    String statusMessage = "Loading...";

    if (!_isLoadingOffice && _office != null) {
      // CHECK IN LOGIC:
      // Enabled if: Not checked in yet AND Current Time >= CheckInStart
      final isTimeForCheckIn = _isTimeValid(_office!.checkInStart, true);
      canCheckIn = attendance.canCheckIn && isTimeForCheckIn;

      // CHECK OUT LOGIC:
      // Enabled if: Checked In AND Current Time >= CheckOutStart
      final isTimeForCheckOut = _isTimeValid(_office!.checkOutStart, false);
      canCheckOut = attendance.canCheckOut && isTimeForCheckOut;

      // Status Message Logic
      if (attendance.canCheckIn && !isTimeForCheckIn) {
        statusMessage = "Wait until ${_office!.checkInStart} to Check In";
      } else if (attendance.canCheckOut && !isTimeForCheckOut) {
        statusMessage = "Wait until ${_office!.checkOutStart} to Check Out";
      } else {
        statusMessage = "You are ready to mark attendance";
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Mark Attendance")),
      body: _isLoadingOffice
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- DATE & TIME CARD ---
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM y').format(now),
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      DateFormat('hh:mm a').format(now),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(attendance.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Status: ${attendance.status.name.toUpperCase()}",
                        style: TextStyle(
                          color: _getStatusColor(attendance.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --- ACTION BUTTONS ---
            Row(
              children: [
                // CHECK IN BUTTON
                Expanded(
                  child: _buildAttendanceButton(
                    label: "CHECK IN",
                    icon: Icons.login,
                    color: Colors.green,
                    isEnabled: canCheckIn && !_isActionLoading,
                    onTap: () {
                      _handleAttendanceAction(true);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Checking In...")));
                    },
                  ),
                ),
                const SizedBox(width: 20),
                // CHECK OUT BUTTON
                Expanded(
                  child: _buildAttendanceButton(
                    label: "CHECK OUT",
                    icon: Icons.logout,
                    color: Colors.red,
                    isEnabled: canCheckOut && !_isActionLoading,
                    onTap: () {
                      _handleAttendanceAction(false);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Checking Out...")));
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- INFO MESSAGE ---
            if (!canCheckIn && !canCheckOut && !attendance.isCompleted)
              Text(
                statusMessage,
                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),

            if (attendance.isCompleted)
              const Text(
                "You have completed your work day!",
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),

            const Spacer(),

            // --- OFFICE HOURS INFO ---
            Text(
              "Office Hours: ${_office?.checkInStart} - ${_office?.checkOutEnd}",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: isEnabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: Colors.grey[300], // Grey out when disabled
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.grey[600],
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: isEnabled ? 4 : 0,
      ),
      child: Column(
        children: [
          Icon(icon, size: 30),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.checkedIn: return Colors.green;
      case AttendanceStatus.completed: return Colors.blue;
      default: return Colors.orange;
    }
  }
}