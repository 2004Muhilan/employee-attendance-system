import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/employee_provider.dart';
import '../../services/api_service.dart';

enum LeaveScreenState { menu, form, history }

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  LeaveScreenState _currentState = LeaveScreenState.menu;
  final _formKey = GlobalKey<FormState>();

  bool _isLoadingSubmit = false;
  bool _isLoadingHistory = false;

  String? _selectedLeaveType;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();

  final List<String> _leaveTypes = [
    'Sick Leave',
    'Casual Leave',
    'Annual Leave',
    'Unpaid Leave'
  ];

  // List to hold actual data from the backend
  List<dynamic> _pastApplications = [];

  int get _totalDays {
    if (_startDate != null && _endDate != null) {
      if (_endDate!.isBefore(_startDate!)) return 0;
      return _endDate!.difference(_startDate!).inDays + 1;
    }
    return 0;
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // --- API: Submit Leave Request ---
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both start and end dates.')),
        );
        return;
      }

      setState(() {
        _isLoadingSubmit = true;
      });

      try {
        final token = Provider.of<EmployeeProvider>(context, listen: false).authToken;
        if (token == null) throw "Authentication error. Please login again.";

        await ApiService().submitLeave(
          token,
          {
            'leave_type': _selectedLeaveType,
            'start_date': _formatDate(_startDate),
            'end_date': _formatDate(_endDate),
            'reason': _reasonController.text,
            'total_days': _totalDays,
          },
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully!')),
        );

        setState(() {
          _currentState = LeaveScreenState.menu;
          _selectedLeaveType = null;
          _startDate = null;
          _endDate = null;
          _reasonController.clear();
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingSubmit = false;
          });
        }
      }
    }
  }

  // --- API: Fetch Leave History ---
  Future<void> _fetchHistory() async {
    setState(() {
      _isLoadingHistory = true;
      _currentState = LeaveScreenState.history;
    });

    try {
      final token = Provider.of<EmployeeProvider>(context, listen: false).authToken;
      if (token == null) throw "Authentication error. Please login again.";

      final data = await ApiService().getLeaveHistory(token);
      
      setState(() {
        _pastApplications = data;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching history: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Widget _buildInitialScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_note, size: 100, color: Colors.blue),
          ),
          const SizedBox(height: 40),
          const Text(
            "Manage Your Time Off",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 40),

          ElevatedButton.icon(
            onPressed: () => setState(() => _currentState = LeaveScreenState.form),
            icon: const Icon(Icons.add_circle_outline),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text('Create New Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),

          OutlinedButton.icon(
            // Call _fetchHistory instead of just changing the state
            onPressed: _fetchHistory,
            icon: const Icon(Icons.history),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text('View Past Applications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              backgroundColor: Colors.white,
              side: const BorderSide(color: Colors.blue, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Apply for Time Off", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 24),

            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Leave Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              value: _selectedLeaveType,
              items: _leaveTypes.map((String type) => DropdownMenuItem<String>(value: type, child: Text(type))).toList(),
              onChanged: (String? newValue) => setState(() => _selectedLeaveType = newValue),
              validator: (value) => value == null ? 'Please select a leave type' : null,
            ),
            const SizedBox(height: 20),

            InkWell(
              onTap: () => _selectDate(context, true),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Start Date',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: const Icon(Icons.calendar_today, color: Colors.blue),
                ),
                child: Text(_formatDate(_startDate)),
              ),
            ),
            const SizedBox(height: 20),

            InkWell(
              onTap: () => _selectDate(context, false),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'End Date',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: const Icon(Icons.calendar_today, color: Colors.blue),
                  errorText: (_endDate != null && _startDate != null && _endDate!.isBefore(_startDate!))
                      ? 'End date cannot be before start date' : null,
                ),
                child: Text(_formatDate(_endDate)),
              ),
            ),
            const SizedBox(height: 20),

            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Total Days',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              child: Text(_totalDays > 0 ? '$_totalDays Day(s)' : '-', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reason for Leave',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Please enter a reason';
                if (value.trim().length < 10) return 'Please provide a bit more detail';
                return null;
              },
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _isLoadingSubmit ? null : _submitForm,
              icon: _isLoadingSubmit
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                    _isLoadingSubmit ? 'Submitting...' : 'Submit Application',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryScreen() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pastApplications.isEmpty) {
      return const Center(
        child: Text(
          'No past applications found.',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _pastApplications.length,
      itemBuilder: (context, index) {
        final leave = _pastApplications[index];
        Color statusColor = Colors.orange;
        if (leave['status'] == 'Approved') statusColor = Colors.green;
        if (leave['status'] == 'Rejected') statusColor = Colors.red;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Using backend keys
                    Text(leave['leave_type'] ?? 'Unknown', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(leave['status'] ?? 'Pending', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    // Using backend keys
                    Text('${leave['start_date']} to ${leave['end_date']}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    // Using backend keys
                    Text('${leave['total_days']} Day(s)'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle = 'Leave Menu';
    if (_currentState == LeaveScreenState.form) appBarTitle = 'New Application';
    if (_currentState == LeaveScreenState.history) appBarTitle = 'Past Applications';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: _currentState != LeaveScreenState.menu
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _currentState = LeaveScreenState.menu),
        )
            : null,
        title: Text(appBarTitle, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: _currentState == LeaveScreenState.menu
          ? _buildInitialScreen()
          : _currentState == LeaveScreenState.form
          ? _buildFormScreen()
          : _buildHistoryScreen(),
    );
  }
}