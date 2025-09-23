import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'privacy_policy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _classCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  User? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _nameController.text = _currentUser!.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _classCodeController.dispose();
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateClassCode() async {
    if (_classCodeController.text.trim().isEmpty) {
      _showSnackBar('Kode kelas tidak boleh kosong', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Here you would typically save the class code to Firestore or your database
      // For now, we'll just show a success message
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      _showSnackBar('Kode kelas berhasil diperbarui');
      _classCodeController.clear();
    } catch (e) {
      _showSnackBar('Gagal memperbarui kode kelas: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateDisplayName() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Nama tidak boleh kosong', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await _currentUser!.updateDisplayName(_nameController.text.trim());
      await _currentUser!.reload();
      setState(() {
        _currentUser = FirebaseAuth.instance.currentUser;
      });
      
      _showSnackBar('Nama berhasil diperbarui');
    } catch (e) {
      _showSnackBar('Gagal memperbarui nama: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showSnackBar('Semua field password harus diisi', isError: true);
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('Password baru dan konfirmasi tidak cocok', isError: true);
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showSnackBar('Password baru minimal 6 karakter', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: _currentUser!.email!,
        password: _currentPasswordController.text,
      );
      
      await _currentUser!.reauthenticateWithCredential(credential);
      
      // Update password
      await _currentUser!.updatePassword(_newPasswordController.text);
      
      _showSnackBar('Password berhasil diubah');
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      String message = 'Gagal mengubah password';
      if (e.code == 'wrong-password') {
        message = 'Password saat ini salah';
      } else if (e.code == 'weak-password') {
        message = 'Password terlalu lemah';
      }
      _showSnackBar(message, isError: true);
    } catch (e) {
      _showSnackBar('Gagal mengubah password: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await _showDeleteConfirmationDialog();
    if (!confirmed) return;

    setState(() => _isLoading = true);
    
    try {
      await _currentUser!.delete();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Gagal menghapus akun';
      if (e.code == 'requires-recent-login') {
        message = 'Silakan login ulang sebelum menghapus akun';
      }
      _showSnackBar(message, isError: true);
    } catch (e) {
      _showSnackBar('Gagal menghapus akun: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Akun'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus akun? Tindakan ini tidak dapat dibatalkan dan semua data Anda akan hilang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    
    try {
      await _authService.signOut();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      _showSnackBar('Gagal logout: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Profil Saya",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // User Info Card
                  _buildUserInfoCard(),
                  const SizedBox(height: 16),
                  
                  // Account Settings Menu
                  _buildAccountSettingsMenu(),
                  const SizedBox(height: 16),
                  
                  // App Settings Menu
                  _buildAppSettingsMenu(),
                  const SizedBox(height: 16),
                  
                  // Danger Zone Menu
                  _buildDangerZoneMenu(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF4F46E5),
            child: Text(
              (_currentUser?.displayName?.isNotEmpty == true)
                  ? _currentUser!.displayName![0].toUpperCase()
                  : _currentUser?.email?[0].toUpperCase() ?? 'U',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _currentUser?.displayName ?? 'Pengguna',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currentUser?.email ?? '',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettingsMenu() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pengaturan Akun',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildMenuItem(
            icon: LucideIcons.graduationCap,
            title: 'Kode Kelas',
            subtitle: 'Atur kode kelas Anda',
            onTap: () => _showClassCodeDialog(),
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: LucideIcons.user,
            title: 'Ubah Nama',
            subtitle: 'Perbarui nama profil Anda',
            onTap: () => _showChangeNameDialog(),
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: LucideIcons.lock,
            title: 'Ubah Password',
            subtitle: 'Ganti password akun Anda',
            onTap: () => _showChangePasswordDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsMenu() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pengaturan Aplikasi',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildMenuItem(
            icon: LucideIcons.shield,
            title: 'Kebijakan Privasi',
            subtitle: 'Baca kebijakan privasi kami',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: LucideIcons.logOut,
            title: 'Keluar',
            subtitle: 'Keluar dari akun Anda',
            onTap: () => _logout(),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZoneMenu() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.alertTriangle,
                color: Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Zona Berbahaya',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMenuItem(
            icon: LucideIcons.trash2,
            title: 'Hapus Akun',
            subtitle: 'Hapus akun dan semua data Anda',
            onTap: () => _deleteAccount(),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFF4F46E5),
        size: 24,
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : const Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFF64748B),
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        color: const Color(0xFF64748B),
        size: 20,
      ),
      onTap: onTap,
    );
  }

  void _showClassCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kode Kelas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _classCodeController,
              decoration: const InputDecoration(
                hintText: 'Masukkan kode kelas',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateClassCode();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showChangeNameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Masukkan nama baru',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateDisplayName();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Password saat ini',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Password baru',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Konfirmasi password baru',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _changePassword();
            },
            child: const Text('Ubah'),
          ),
        ],
      ),
    );
  }
}