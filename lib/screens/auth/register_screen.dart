import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';
import '../../models/admin_models.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final _adminService = AdminService();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreeToTerms = false;
  bool _isAdminRegister = false; // Toggle untuk register admin

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Back button
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.arrowLeft),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  padding: const EdgeInsets.all(12),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Welcome text
              Text(
                _isAdminRegister ? 'Daftar Admin' : 'Daftar Sekarang',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                _isAdminRegister 
                  ? 'Buat akun admin untuk mengelola sistem'
                  : 'Buat akun baru untuk memulai perjalanan belajar kamu',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Toggle untuk memilih mode registrasi
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isAdminRegister ? Colors.orange[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isAdminRegister ? Colors.orange[200]! : Colors.blue[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isAdminRegister ? LucideIcons.shield : LucideIcons.user,
                      color: _isAdminRegister ? Colors.orange[600] : Colors.blue[600],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isAdminRegister ? 'Daftar sebagai Admin' : 'Daftar sebagai Siswa',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _isAdminRegister ? Colors.orange[700] : Colors.blue[700],
                        ),
                      ),
                    ),
                    Switch(
                      value: _isAdminRegister,
                      onChanged: (value) {
                        setState(() {
                          _isAdminRegister = value;
                          // Clear form ketika switch mode
                          _nameController.clear();
                          _emailController.clear();
                          _passwordController.clear();
                          _confirmPasswordController.clear();
                        });
                      },
                      activeColor: Colors.orange[600],
                      inactiveThumbColor: Colors.blue[600],
                      inactiveTrackColor: Colors.blue[200],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Register form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        hintText: 'Masukkan nama lengkap kamu',
                        prefixIcon: const Icon(LucideIcons.user),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                      ),
                      style: GoogleFonts.poppins(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama lengkap tidak boleh kosong';
                        }
                        if (value.length < 2) {
                          return 'Nama minimal 2 karakter';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Masukkan email kamu',
                        prefixIcon: const Icon(LucideIcons.mail),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                      ),
                      style: GoogleFonts.poppins(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Masukkan password kamu',
                        prefixIcon: const Icon(LucideIcons.lock),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                          icon: Icon(
                            _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                      ),
                      style: GoogleFonts.poppins(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password tidak boleh kosong';
                        }
                        if (value.length < 8) {
                          return 'Password minimal 8 karakter';
                        }
                        if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
                          return 'Password harus mengandung huruf besar, kecil, dan angka';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Confirm Password field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password',
                        hintText: 'Masukkan ulang password kamu',
                        prefixIcon: const Icon(LucideIcons.lock),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                          icon: Icon(
                            _isConfirmPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                      ),
                      style: GoogleFonts.poppins(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Konfirmasi password tidak boleh kosong';
                        }
                        if (value != _passwordController.text) {
                          return 'Password tidak sama';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Terms and conditions checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _agreeToTerms,
                          onChanged: (value) {
                            setState(() {
                              _agreeToTerms = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFF4F46E5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                children: [
                                  const TextSpan(text: 'Saya setuju dengan '),
                                  TextSpan(
                                    text: 'Syarat & Ketentuan',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF4F46E5),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const TextSpan(text: ' dan '),
                                  TextSpan(
                                    text: 'Kebijakan Privasi',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF4F46E5),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Register button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_isLoading || !_agreeToTerms) ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isAdminRegister ? 'Daftar sebagai Admin' : 'Daftar',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'atau',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Google register button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement Google register
                  },
                  icon: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage('https://developers.google.com/identity/images/g-logo.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  label: Text(
                    'Daftar dengan Google',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sudah punya akun? ',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Masuk Sekarang',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF4F46E5),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isAdminRegister) {
        // Register admin user
        debugPrint('Starting admin registration process...');
        final adminUser = AdminUser(
          id: '', // Will be set by Firestore
          name: _nameController.text.trim(),
          email: _emailController.text.trim().toLowerCase(),
          password: _passwordController.text, // In production, this should be hashed
          role: AdminRole.teacher, // Default role for new admin registrations
          createdAt: DateTime.now(),
          isActive: true,
          lastLogin: null,
          managedClassCodes: const [],
        );

        debugPrint('Admin user object created: ${adminUser.toJson()}');
        final adminId = await _adminService.createAdminUser(adminUser);
        debugPrint('Admin creation result: $adminId');

        // If we reach here, admin creation was successful
        if (mounted) {
          debugPrint('Admin registration successful, showing success message');
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Pendaftaran admin berhasil! Silakan login dengan akun admin Anda.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: const Duration(seconds: 4),
            ),
          );

          // Navigate to login screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        // Register regular user with Firebase
        final userCredential = await _authService.registerWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (userCredential != null) {
          // Send email verification
          await _authService.sendEmailVerification();

          if (mounted) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Pendaftaran berhasil! Email verifikasi telah dikirim ke ${_emailController.text}',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                duration: const Duration(seconds: 4),
              ),
            );

            // Navigate to login screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}