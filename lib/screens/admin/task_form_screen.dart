import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/admin_models.dart';
import '../../models/quiz_models.dart';
import '../../services/admin_service.dart';

class TaskFormScreen extends StatefulWidget {
  final AdminTask? task;
  
  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();
  
  // Form controllers
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _linkSoalController = TextEditingController();
  final _linkPdfController = TextEditingController();
  
  // Form data
  String? _selectedKodeKelas;
  String? _selectedMataPelajaran;
  DateTime? _tanggalDibuat;
  DateTime? _tanggalDibuka;
  DateTime? _tanggalBerakhir;
  
  // Data lists
  List<ClassCode> _classCodes = [];
  List<Subject> _subjects = [];
  
  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeForm();
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _linkSoalController.dispose();
    _linkPdfController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final classCodes = await _adminService.getAllClassCodes();
      final subjects = await _adminService.getAllSubjects();
      setState(() {
        _classCodes = classCodes;
        _subjects = subjects;
        _isLoadingData = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading data: $e');
      }
      setState(() => _isLoadingData = false);
    }
  }

  void _initializeForm() {
    if (widget.task != null) {
      final task = widget.task!;
      _judulController.text = task.judul;
      _deskripsiController.text = task.deskripsi;
      _linkSoalController.text = task.linkSoal ?? '';
      _linkPdfController.text = task.linkPdf ?? '';
      _selectedKodeKelas = task.kodeKelas;
      _selectedMataPelajaran = task.mataPelajaran;
      _tanggalDibuat = task.tanggalDibuat;
      _tanggalDibuka = task.tanggalDibuka;
      _tanggalBerakhir = task.tanggalBerakhir;
    } else {
      _tanggalDibuat = DateTime.now();
    }
  }

  Future<void> _selectDate(BuildContext context, String field) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _getDateForField(field) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      if (!mounted) return;
      
      final TimeOfDay? timePicked = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: context,
        initialTime: TimeOfDay.fromDateTime(_getDateForField(field) ?? DateTime.now()),
      );
      
      if (timePicked != null && mounted) {
        final selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          timePicked.hour,
          timePicked.minute,
        );
        
        setState(() {
          switch (field) {
            case 'dibuat':
              _tanggalDibuat = selectedDateTime;
              break;
            case 'dibuka':
              _tanggalDibuka = selectedDateTime;
              break;
            case 'berakhir':
              _tanggalBerakhir = selectedDateTime;
              break;
          }
        });
      }
    }
  }

  DateTime? _getDateForField(String field) {
    switch (field) {
      case 'dibuat':
        return _tanggalDibuat;
      case 'dibuka':
        return _tanggalDibuka;
      case 'berakhir':
        return _tanggalBerakhir;
      default:
        return null;
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Pilih tanggal dan waktu';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_tanggalDibuka == null || _tanggalBerakhir == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harap pilih tanggal dibuka dan berakhir'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    if (_tanggalDibuka!.isAfter(_tanggalBerakhir!)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tanggal dibuka tidak boleh setelah tanggal berakhir'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      
      if (widget.task != null) {
        // Update existing task
        final updatedTask = widget.task!.copyWith(
          tanggalDibuat: _tanggalDibuat!,
          kodeKelas: _selectedKodeKelas!,
          mataPelajaran: _selectedMataPelajaran!,
          judul: _judulController.text.trim(),
          deskripsi: _deskripsiController.text.trim(),
          linkSoal: _linkSoalController.text.trim().isEmpty ? null : _linkSoalController.text.trim(),
          tanggalDibuka: _tanggalDibuka!,
          tanggalBerakhir: _tanggalBerakhir!,
          linkPdf: _linkPdfController.text.trim().isEmpty ? null : _linkPdfController.text.trim(),
          updatedAt: now,
        );
        
        final success = await _adminService.updateTask(widget.task!.id, updatedTask);
        
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tugas berhasil diperbarui')),
            );
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal memperbarui tugas'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Create new task
        final newTask = AdminTask(
          id: '', // Will be set by Firestore
          tanggalDibuat: _tanggalDibuat!,
          kodeKelas: _selectedKodeKelas!,
          mataPelajaran: _selectedMataPelajaran!,
          judul: _judulController.text.trim(),
          deskripsi: _deskripsiController.text.trim(),
          linkSoal: _linkSoalController.text.trim().isEmpty ? null : _linkSoalController.text.trim(),
          tanggalDibuka: _tanggalDibuka!,
          tanggalBerakhir: _tanggalBerakhir!,
          linkPdf: _linkPdfController.text.trim().isEmpty ? null : _linkPdfController.text.trim(),
          komentar: [],
          createdBy: 'admin', // TODO: Get from current user
          createdAt: now,
          updatedAt: now,
        );
        
        final taskId = await _adminService.createTask(newTask);
        
        if (taskId != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tugas berhasil dibuat')),
            );
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal membuat tugas'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving task: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task != null ? 'Edit Tugas' : 'Tambah Tugas'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveTask,
              child: const Text(
                'Simpan',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Tanggal Dibuat
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today, color: Color(0xFF2196F3)),
                      title: const Text('Tanggal Dibuat'),
                      subtitle: Text(_formatDateTime(_tanggalDibuat)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _selectDate(context, 'dibuat'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Kode Kelas
                  DropdownButtonFormField<String>(
                    value: _selectedKodeKelas,
                    decoration: InputDecoration(
                      labelText: 'Kode Kelas *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.class_),
                    ),
                    items: _classCodes.map((classCode) => DropdownMenuItem<String>(
                      value: classCode.code,
                      child: Text('${classCode.code} - ${classCode.name}'),
                    )).toList(),
                    onChanged: (value) {
                      setState(() => _selectedKodeKelas = value);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harap pilih kode kelas';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Mata Pelajaran
                  DropdownButtonFormField<String>(
                    value: _selectedMataPelajaran,
                    decoration: InputDecoration(
                      labelText: 'Mata Pelajaran *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.book),
                    ),
                    items: _subjects.map((subject) => DropdownMenuItem<String>(
                      value: subject.name,
                      child: Text(subject.name),
                    )).toList(),
                    onChanged: (value) {
                      setState(() => _selectedMataPelajaran = value);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harap pilih mata pelajaran';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Judul
                  TextFormField(
                    controller: _judulController,
                    decoration: InputDecoration(
                      labelText: 'Judul *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Harap masukkan judul';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Deskripsi
                  TextFormField(
                    controller: _deskripsiController,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.description),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Harap masukkan deskripsi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Link Soal
                  TextFormField(
                    controller: _linkSoalController,
                    decoration: InputDecoration(
                      labelText: 'Link Soal (Opsional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.link),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),
                  
                  // Tanggal Dibuka
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.schedule, color: Color(0xFF4CAF50)),
                      title: const Text('Tanggal Dibuka *'),
                      subtitle: Text(_formatDateTime(_tanggalDibuka)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _selectDate(context, 'dibuka'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Tanggal Berakhir
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.event, color: Color(0xFFFF5722)),
                      title: const Text('Tanggal Berakhir *'),
                      subtitle: Text(_formatDateTime(_tanggalBerakhir)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _selectDate(context, 'berakhir'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Link PDF
                  TextFormField(
                    controller: _linkPdfController,
                    decoration: InputDecoration(
                      labelText: 'Link PDF (Opsional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.picture_as_pdf),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 32),
                  
                  // Comments Section (for edit mode)
                  if (widget.task != null && widget.task!.komentar.isNotEmpty) ...[
                    const Text(
                      'Komentar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.task!.komentar.map((comment) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: comment.authorType == 'guru' 
                              ? Colors.blue 
                              : Colors.green,
                          child: Text(
                            comment.authorName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(comment.authorName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(comment.comment),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(comment.createdAt),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(
                            comment.authorType.toUpperCase(),
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor: comment.authorType == 'guru' 
                              ? Colors.blue.withValues(alpha: 0.1)
                              : Colors.green.withValues(alpha: 0.1),
                        ),
                      ),
                    )),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
    );
  }
}