import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';
import '../../constants/app_constants.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/employee_provider.dart';
import '../../providers/office_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Toggle State: true = Login Mode, false = Register Mode
  bool _isLogin = true;

  // --- CONTROLLERS ---
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  XFile? _pickedImage;
  Uint8List? _webImageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();

        setState(() {
          _pickedImage = image;
          _webImageBytes = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  // --- REGISTRATION LOGIC ---
  Future<void> _handleRegister() async {
    // 1. IMAGE VALIDATION: Ensure the user picked an image
    if (_webImageBytes == null || _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a profile image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();

      final response = await apiService.submitRegistration(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        imageBytes: _webImageBytes,
        imageName: _pickedImage?.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response['message'] ?? 'Registration successful!'),
              backgroundColor: Colors.green
          ),
        );

        setState(() {
          _isLogin = true;
          _fullNameController.clear();
          _phoneController.clear();
          _pickedImage = null;
          _webImageBytes = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIN LOGIC ---
  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await _authService.loginWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        final token = await _authService.getIdToken();

        if (token != null) {
          final apiService = ApiService();
          final employeeProfile = await apiService.fetchUserProfile(token);

          if (employeeProfile != null) {
            try {
              final officeDetails = await apiService.getOfficeGeofence(token);
              if (mounted) {
                Provider.of<OfficeProvider>(context, listen: false).setOffice(officeDetails);
              }
            } catch (e) {
              print("⚠️ Could not fetch office details: $e");
            }

            if (mounted) {
              final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);

              employeeProvider.setEmployee(employeeProfile);
              employeeProvider.setToken(token);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Login Successful!'), backgroundColor: Colors.green),
              );

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(AppConstants.companyLogo, size: 80, color: AppConstants.primaryColor),
                const SizedBox(height: 20),

                const Text(
                  AppConstants.companyName,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _isLogin = true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _isLogin ? Colors.blue : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "Login",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _isLogin ? Colors.white : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _isLogin = false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: !_isLogin ? Colors.blue : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "Register",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: !_isLogin ? Colors.white : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (!_isLogin) ...[
                            GestureDetector(
                              onTap: _pickProfileImage,
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: Colors.grey[300],
                                    backgroundImage: _webImageBytes != null
                                        ? MemoryImage(_webImageBytes!)
                                        : null,
                                    child: _webImageBytes == null
                                        ? const Icon(Icons.person, size: 40, color: Colors.white)
                                        : null,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _fullNameController,
                              decoration: const InputDecoration(
                                labelText: "Full Name",
                                prefixIcon: Icon(Icons.badge_outlined),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Enter your name' : null,
                            ),
                            const SizedBox(height: 16),

                            // 2. PHONE VALIDATION: Check for exactly 10 numeric digits
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: "Phone Number",
                                prefixIcon: Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter your phone number';
                                }
                                if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                                  return 'Phone number must be exactly 10 digits';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: "Email",
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                            (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
                          ),
                          const SizedBox(height: 16),

                          if (_isLogin) ...[
                            TextFormField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: "Password",
                                prefixIcon: Icon(Icons.lock_outline),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              obscureText: true,
                              validator: (value) =>
                              (value == null || value.length < 6) ? 'Password too short' : null,
                            ),
                            const SizedBox(height: 24),
                          ] else ...[
                            const SizedBox(height: 8),
                          ],

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_isLoading) return;

                                if (_isLogin) {
                                  _handleAuth();
                                } else {
                                  _handleRegister();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                                  : Text(
                                _isLogin ? "Login" : "Submit Registration",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),

                          if (_isLogin)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: TextButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Contact Admin to reset password')),
                                  );
                                },
                                child: const Text("Forgot Password?", style: TextStyle(color: Colors.grey)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}