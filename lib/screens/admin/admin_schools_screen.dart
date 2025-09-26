import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';

class AdminSchoolsScreen extends StatefulWidget {
  const AdminSchoolsScreen({super.key});

  @override
  State<AdminSchoolsScreen> createState() => _AdminSchoolsScreenState();
}

class _AdminSchoolsScreenState extends State<AdminSchoolsScreen> {
  final AdminService _adminService = AdminService();
  List<School> _schools = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    setState(() => _isLoading = true);
    try {
      if (kDebugMode) {
        print('Loading schools from AdminService...');
      }
      final schools = await _adminService.getAllSchools();
      if (kDebugMode) {
        print('Loaded ${schools.length} schools from AdminService');
        for (var school in schools) {
          print('School: ${school.name} (ID: ${school.id})');
        }
      }
      setState(() {
        _schools = schools;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading schools: $e');
      }
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading schools: $e')),
        );
      }
    }
  }

  Future<void> _showSchoolDialog({School? school}) async {
    final nameController = TextEditingController(text: school?.name ?? '');
    final addressController = TextEditingController(text: school?.address ?? '');
    final phoneController = TextEditingController(text: school?.phone ?? '');
    final emailController = TextEditingController(text: school?.email ?? '');
    
    // Controllers for school account login credentials
    final loginEmailController = TextEditingController();
    final loginPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    bool createLoginAccount = school == null; // Only show for new schools

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(school == null ? 'Tambah Sekolah' : 'Edit Sekolah'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Sekolah *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Alamat',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telepon',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    
                    // Show login account creation section only for new schools
                    if (school == null) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Checkbox(
                            value: createLoginAccount,
                            onChanged: (value) {
                              setState(() {
                                createLoginAccount = value ?? false;
                              });
                            },
                          ),
                          const Expanded(
                            child: Text(
                              'Buat akun login untuk sekolah',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      
                      if (createLoginAccount) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          'Kredensial Login Sekolah',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF673AB7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: loginEmailController,
                          decoration: const InputDecoration(
                            labelText: 'Email Login *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: loginPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Password *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: confirmPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Konfirmasi Password *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          obscureText: true,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: Text(school == null ? 'Tambah' : 'Update'),
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nama sekolah harus diisi')),
                      );
                      return;
                    }

                    // Validate login credentials if creating account
                    if (school == null && createLoginAccount) {
                      if (loginEmailController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Email login harus diisi')),
                        );
                        return;
                      }
                      
                      if (loginPasswordController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password harus diisi')),
                        );
                        return;
                      }
                      
                      if (loginPasswordController.text != confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password dan konfirmasi password tidak sama')),
                        );
                        return;
                      }
                      
                      if (loginPasswordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password minimal 6 karakter')),
                        );
                        return;
                      }
                    }

                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    try {
                      if (school == null) {
                        // Create new school
                        final newSchool = School(
                          id: '', // This will be ignored by Firebase, document ID will be auto-generated
                          name: nameController.text.trim(),
                          address: addressController.text.trim(),
                          phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                          email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                          website: null, // Set to null instead of empty string
                          createdAt: DateTime.now(),
                          isActive: true, // Explicitly set isActive to true
                          logoUrl: null, // Set to null for new schools
                        );
                        
                        if (kDebugMode) {
                          print('Creating school with data: ${newSchool.name}');
                        }
                        final result = await _adminService.createSchool(newSchool);
                        if (kDebugMode) {
                          print('Create school result: $result');
                        }
                        
                        if (result == null) {
                          throw Exception('Gagal menambahkan sekolah ke database');
                        }
                        
                        // Create school account if requested
                         if (createLoginAccount) {
                           try {
                             final now = DateTime.now();
                             final schoolAccount = SchoolAccount(
                               id: '', // Will be set by Firestore
                               schoolId: result,
                               email: loginEmailController.text.trim().toLowerCase(),
                               password: loginPasswordController.text.trim(),
                               schoolName: nameController.text.trim(),
                               createdAt: now,
                               updatedAt: now,
                             );
                             
                             await _adminService.createSchoolAccount(schoolAccount);
                            
                            if (mounted) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Sekolah dan akun login berhasil dibuat'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (accountError) {
                            if (mounted) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Sekolah berhasil dibuat, tetapi gagal membuat akun login: $accountError'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                        }
                      } else {
                        // Update existing school
                        final updatedSchool = school.copyWith(
                          name: nameController.text.trim(),
                          address: addressController.text.trim(),
                          phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                          email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                        );
                        final result = await _adminService.updateSchool(updatedSchool.id, updatedSchool);
                        if (!result) {
                          throw Exception('Gagal mengupdate sekolah di database');
                        }
                      }

                      if (mounted) {
                        navigator.pop();
                        _loadSchools();
                        
                        if (school != null) {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text('Sekolah berhasil diupdate'),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteSchool(School school) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus sekolah "${school.name}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteSchool(school.id);
        _loadSchools();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sekolah berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting school: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Sekolah'),
        backgroundColor: const Color(0xFF673AB7),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Sekolah: ${_schools.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showSchoolDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Sekolah'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF673AB7),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _schools.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada sekolah',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _schools.length,
                          itemBuilder: (context, index) {
                            final school = _schools[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFF673AB7),
                                  child: Icon(Icons.school, color: Colors.white),
                                ),
                                title: Text(
                                  school.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (school.address.isNotEmpty)
                                      Text('Alamat: ${school.address}'),
                                    if (school.phone?.isNotEmpty ?? false)
                                      Text('Telepon: ${school.phone}'),
                                    if (school.email?.isNotEmpty ?? false)
                                      Text('Email: ${school.email}'),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showSchoolDialog(school: school);
                                    } else if (value == 'delete') {
                                      _deleteSchool(school);
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    const PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Hapus', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}