import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../utils/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserRole _selectedRole = UserRole.student;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        role: _selectedRole,
        phone: _phoneController.text.trim().isEmpty 
            ? null 
            : _phoneController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi berhasil! Silakan login.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/login');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Registrasi gagal'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }
    if (value != _passwordController.text) {
      return 'Password tidak cocok';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daftar Akun'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Bergabung dengan Seangkatan.id',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Buat akun baru untuk memulai perjalanan belajar Anda',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Role Selection
                Text(
                  'Pilih Peran Anda',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonFormField<UserRole>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: UserRole.student,
                        child: Text('Siswa'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.teacher,
                        child: Text('Guru'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.parent,
                        child: Text('Orang Tua'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.schoolAdmin,
                        child: Text('Admin Sekolah'),
                      ),
                    ],
                    onChanged: (UserRole? value) {
                      if (value != null) {
                        setState(() {
                          _selectedRole = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
                
                // Username Field
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'Masukkan username unik',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: MultiValidator([
                    RequiredValidator(errorText: 'Username wajib diisi'),
                    MinLengthValidator(3, errorText: 'Username minimal 3 karakter'),
                    MaxLengthValidator(50, errorText: 'Username maksimal 50 karakter'),
                  ]),
                ),
                const SizedBox(height: 16),
                
                // Full Name Field
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    hintText: 'Masukkan nama lengkap Anda',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: MultiValidator([
                    RequiredValidator(errorText: 'Nama lengkap wajib diisi'),
                    MinLengthValidator(2, errorText: 'Nama minimal 2 karakter'),
                  ]),
                ),
                const SizedBox(height: 16),
                
                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Masukkan email Anda',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: MultiValidator([
                    RequiredValidator(errorText: 'Email wajib diisi'),
                    EmailValidator(errorText: 'Format email tidak valid'),
                  ]),
                ),
                const SizedBox(height: 16),
                
                // Phone Field (Optional)
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon (Opsional)',
                    hintText: 'Masukkan nomor telepon',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Masukkan password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: MultiValidator([
                    RequiredValidator(errorText: 'Password wajib diisi'),
                    MinLengthValidator(6, errorText: 'Password minimal 6 karakter'),
                  ]),
                ),
                const SizedBox(height: 16),
                
                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password',
                    hintText: 'Ulangi password Anda',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: _validateConfirmPassword,
                ),
                const SizedBox(height: 32),
                
                // Register Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: authProvider.isLoading
                          ? const SpinKitThreeBounce(
                              color: AppColors.white,
                              size: 20,
                            )
                          : const Text('Daftar'),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sudah punya akun? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        context.go('/login');
                      },
                      child: const Text('Masuk Sekarang'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}