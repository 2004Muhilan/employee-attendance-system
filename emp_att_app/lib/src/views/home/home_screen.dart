import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Added
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../providers/employee_provider.dart'; // Added
import '../../providers/attendance_provider.dart';
import '../auth/login_screen.dart';
import '../map/map_screen.dart';
import '../leave/leave_screen.dart';
import '../attendance/mark_attendance_screen.dart';
import '../attendance/view_attendance_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAttendanceStatus();
    });
  }

  Future<void> _loadAttendanceStatus() async {
    // 1. Get the token from UserProvider (RAM)
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final token = employeeProvider.authToken;

    if (token != null) {
      // 2. Call the method we just created
      await Provider.of<AttendanceProvider>(context, listen: false)
          .fetchTodayStatus(token);
    }
  }

  // --- LOGOUT LOGIC ---
  Future<void> _handleLogout() async {
    await _authService.signOut();
    if (mounted) {
      // Clear Provider Data
      Provider.of<EmployeeProvider>(context, listen: false).clearEmployee(); // Added cleanup

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  void _showProfileDetails() {
    // 1. Get User Data
    final user = Provider.of<EmployeeProvider>(context, listen: false).employee;
    if (user == null) return; // Safety check

    final double dialogWidth = MediaQuery.of(context).size.width * 0.7;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Employee Profile", textAlign: TextAlign.center),
        // We use a SizedBox to force the width of the dialog content
        content: SizedBox(
          width: dialogWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dynamic Image with Fallback logic
              CircleAvatar(
                radius: 40,
                backgroundImage: (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty)
                    ? CachedNetworkImageProvider(user.profileImageUrl!)
                    : null,
                child: (user.profileImageUrl == null || user.profileImageUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              const SizedBox(height: 16),

              // Dynamic Name
              Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

              // Dynamic Role
              Text(user.role, style: const TextStyle(color: Colors.grey)),

              const SizedBox(height: 16),
              const Divider(),

              // --- UPDATED PROFILE ROWS WITH REAL DATA ---
              _buildProfileRow("ID", user.id),
              _buildProfileRow("Phone", user.phoneNumber),
              _buildProfileRow("Email", user.email),
              _buildProfileRow("Acc. Created", "${user.createdAt.year}-${user.createdAt.month}-${user.createdAt.day}"),
              _buildProfileRow("Office", user.officeName),
              // ----------------------------
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // 2. LISTEN TO PROVIDER
    final user = Provider.of<EmployeeProvider>(context).employee;

    // Safety: If user is null (e.g., hot reload wiped it), go back to login
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Home", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text("Log Out"),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Company Card
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(AppConstants.companyLogo, size: 40, color: AppConstants.primaryColor),
                      const SizedBox(width: 12),
                      const Text(
                        AppConstants.companyName,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==========================
              // DYNAMIC PROFILE CARD
              // ==========================
              SizedBox(
                width: screenWidth * 0.80,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text("Welcome back,", style: TextStyle(color: Colors.grey, fontSize: 16)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // Profile Image
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.blueAccent,
                              backgroundImage: (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty)
                                  ? CachedNetworkImageProvider(user.profileImageUrl!)
                                  : null,
                              child: (user.profileImageUrl == null || user.profileImageUrl!.isEmpty)
                                  ? const Icon(Icons.person, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            // Name
                            Expanded(
                              child: Text(
                                user.name, // <--- REAL DATA
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios, size: 16),
                              onPressed: _showProfileDetails,
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              SizedBox(
                width: screenWidth * 0.80,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionItem(
                                  Icons.assessment,
                                  "Attendance\nReport",
                                  Colors.purple,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ViewAttendanceScreen()),
                                    );
                                  }
                              ),
                            ),
                            Expanded(
                              child: _buildActionItem(
                                Icons.note_add,
                                "Leave\nApplication",
                                Colors.orange,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LeaveScreen()),
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: _buildActionItem(
                                Icons.map,
                                "Map\nView",
                                Colors.green,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const MapScreen()),
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: _buildActionItem(
                                  Icons.fingerprint,
                                  "Mark\nAttendance",
                                  Colors.blue,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const MarkAttendanceScreen()),
                                    );
                                  }
                              ),
                            ),
                          ],
                        ),
                        // const SizedBox(height: 24),
                        // Row(
                        //   children: [
                        //     Expanded(child: _buildActionItem(Icons.badge, "E-ID\nCard", Colors.teal)),
                        //     const Expanded(child: SizedBox()),
                        //     const Expanded(child: SizedBox()),
                        //     const Expanded(child: SizedBox()),
                        //   ],
                        // ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Opened $label")));
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1), // Used withOpacity for compatibility
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}