import 'dart:async';
import 'package:flutter/foundation.dart'; // For kIsWeb check
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'src/views/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'src/providers/employee_provider.dart';
import 'src/providers/office_provider.dart';
import 'src/providers/attendance_provider.dart';
import 'src/providers/history_provider.dart';

// ⚠️ WEB-ONLY IMPORT: This line allows us to reload the page.
// If you build for Android later, you will need to remove this line.
// import 'dart:html' as html;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => OfficeProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: const AppEntryPoint(),
    ),
  );
}

class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  Future<FirebaseApp>? _initialization;

  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  void _startInitialization() {
    setState(() {
      _initialization = _initializeFirebaseWithTimeout();
    });
  }

  Future<FirebaseApp> _initializeFirebaseWithTimeout() async {
    // Artificial delay so the user sees the spinner (UX best practice)
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      return await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 4)); // Timeout faster (4s)
    } catch (e) {
      rethrow;
    }
  }

  void _reloadPage() {
    // ⚠️ HARD RELOAD: This forces the browser to re-download the correct scripts
    // if (kIsWeb) {
    //   html.window.location.reload();
    // } else {
      // Fallback for mobile (just tries the function again)
      _startInitialization();
    // }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // FIX 1: FORCE 'Arial' so text is visible offline (no download needed)
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {

          // --- 1. LOADING STATE ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(
                      "Connecting to System...",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }

          // --- 2. ERROR STATE (No Internet) ---
          if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 80, color: Colors.redAccent),
                      const SizedBox(height: 24),

                      // Explicit style to ensure visibility
                      const Text(
                        "Connection Failed",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black, // Force Black Color
                            fontFamily: 'Arial'
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Could not load system resources. Please check your connection and reload.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16, fontFamily: 'Arial'),
                      ),
                      const SizedBox(height: 30),

                      // RETRY BUTTON
                      SizedBox(
                        width: 220,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _reloadPage, // <--- Calls the Hard Reload
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text(
                              "Reload Application",
                              style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // --- 3. SUCCESS STATE ---
          return const LoginScreen();
        },
      ),
    );
  }
}