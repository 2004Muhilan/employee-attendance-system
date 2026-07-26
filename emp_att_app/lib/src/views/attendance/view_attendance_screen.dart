import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http; // Added
import 'dart:convert';                   // Added
import '../../constants/api_constants.dart'; // Added for endpoint URLs
import '../../providers/employee_provider.dart';
import '../../providers/history_provider.dart';
import '../../models/attendance_model.dart';
import '../../services/api_service.dart';

class ViewAttendanceScreen extends StatefulWidget {
  const ViewAttendanceScreen({super.key});

  @override
  State<ViewAttendanceScreen> createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen> {
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = true;

  // New state variable to hold approved leaves
  List<dynamic> _approvedLeaves = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchHistory();
    });
  }

  Future<void> _fetchHistory() async {
    final provider = Provider.of<HistoryProvider>(context, listen: false);
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);

    final token = employeeProvider.authToken;
    final user = employeeProvider.employee;

    if (token == null || user == null) return;

    try {
      final api = ApiService();
      // Fetch Attendance
      final data = await api.getAttendanceHistory(token);

      // --- NEW: Fetch Leave History ---
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.leaveHistoryEndpoint}/${user.id}');
      final leaveResponse = await http.get(uri);

      List<dynamic> fetchedApprovedLeaves = [];

      if (leaveResponse.statusCode == 200) {
        final leaveData = jsonDecode(leaveResponse.body);
        if (leaveData['success'] == true) {
          final List<dynamic> allLeaves = leaveData['data'];
          // Filter out only Approved leaves
          fetchedApprovedLeaves = allLeaves.where((leave) => leave['status'] == 'Approved').toList();
        }
      }
      // --------------------------------

      if (mounted) {
        setState(() {
          _approvedLeaves = fetchedApprovedLeaves;
          _isLoading = false;
        });

        provider.setHistoryData(
            data['records'] as List<AttendanceRecord>,
            data['joining_date'] as String
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = Provider.of<HistoryProvider>(context);

    final availableMonths = historyProvider.getAvailableMonths();

    if (availableMonths.isNotEmpty &&
        !availableMonths.any((d) => _isSameMonth(d, _selectedMonth))) {
      _selectedMonth = availableMonths.first;
    }

    final records = historyProvider.getRecordsForMonth(_selectedMonth);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Attendance Report"),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // --- MONTH SELECTOR ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Select Month:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<DateTime>(
                        value: availableMonths.any((d) => _isSameMonth(d, _selectedMonth))
                            ? availableMonths.firstWhere((d) => _isSameMonth(d, _selectedMonth))
                            : null,
                        isExpanded: true,
                        hint: const Text("Loading months..."),
                        items: availableMonths.map((date) {
                          return DropdownMenuItem(
                            value: date,
                            child: Text(
                              DateFormat('MMMM yyyy').format(date),
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedMonth = val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- SUMMARY STATS ---
          _buildSummaryStats(records),

          // --- CALENDAR LIST ---
          Expanded(
            child: records.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final record = records[index];
                return _buildAttendanceCard(record);
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildSummaryStats(List<AttendanceRecord> records) {
    int present = records.where((r) => r.status == "PRESENT" || r.status == "COMPLETED").length;
    int late = records.where((r) => r.isLate).length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildStatCard("Present", present.toString(), Colors.green),
          const SizedBox(width: 10),
          _buildStatCard("Late", late.toString(), Colors.orange),
          const SizedBox(width: 10),
          _buildStatCard("Total", records.length.toString(), Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord record) {
    DateTime date = DateTime.parse(record.date);
    String day = DateFormat('dd').format(date);
    String weekDay = DateFormat('E').format(date);

    // --- LEAVE CHECK LOGIC ---
    bool isLeave = false;
    String leaveName = "";

    // 1. We ONLY check for overlapping leaves if it's NOT already a holiday
    if (record.status != 'HOLIDAY') {
      DateTime recordDate = DateTime(date.year, date.month, date.day);

      for (var leave in _approvedLeaves) {
        try {
          DateTime start = DateTime.parse(leave['start_date']);
          DateTime end = DateTime.parse(leave['end_date']);

          // Strip times to ensure precise midnight-to-midnight comparison
          DateTime startDate = DateTime(start.year, start.month, start.day);
          DateTime endDate = DateTime(end.year, end.month, end.day);

          // If the record date falls precisely inside the approved leave range
          if (!recordDate.isBefore(startDate) && !recordDate.isAfter(endDate)) {
            isLeave = true;
            leaveName = leave['leave_type'] ?? 'APPROVED LEAVE';
            break;
          }
        } catch (e) {
          // Fallback if parsing error occurs
        }
      }
    }

    Color statusColor;
    String displayStatus = record.status;

    // Set colors and status dynamically
    if (record.status == 'COMPLETED') {
      statusColor = Colors.green;
    } else if (record.status == 'PRESENT') {
      statusColor = Colors.blue;
    } else if (record.status == 'HOLIDAY') {
      statusColor = Colors.grey;
    } else {
      // If they were absent, but it was an approved leave, override it
      if (isLeave) {
        statusColor = Colors.purple;
        displayStatus = leaveName.toUpperCase();
      } else {
        statusColor = Colors.red; // Normal Absent
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          children: [
            // Date Box
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(weekDay, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Row
                  Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      // Using the overridden Display Status
                      Text(
                          displayStatus,
                          style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)
                      ),
                      if (record.isLate)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(4)),
                          child: const Text("LATE", style: TextStyle(fontSize: 10, color: Colors.orange)),
                        )
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Timestamps
                  Row(
                    children: [
                      const Icon(Icons.login, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                          _formatTime(record.checkIn) ?? "--:--",
                          style: const TextStyle(fontSize: 12)
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.logout, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                          _formatTime(record.checkOut) ?? "--:--",
                          style: const TextStyle(fontSize: 12)
                      ),
                    ],
                  )
                ],
              ),
            ),

            // Hours Pill
            if (record.workHours > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${record.workHours}h",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text("No attendance records found.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- HELPERS ---
  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  String? _formatTime(String? isoString) {
    if (isoString == null) return null;
    try {
      final date = DateTime.parse(isoString).toLocal();
      return DateFormat('hh:mm a').format(date);
    } catch (e) {
      return null;
    }
  }
}