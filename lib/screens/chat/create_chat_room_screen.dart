import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';
import '../../models/admin_models.dart';

class CreateChatRoomScreen extends StatefulWidget {
  const CreateChatRoomScreen({super.key});

  @override
  State<CreateChatRoomScreen> createState() => _CreateChatRoomScreenState();
}

class _CreateChatRoomScreenState extends State<CreateChatRoomScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  List<Student> _allStudents = [];
  List<Student> _filteredStudents = [];
  final List<String> _selectedParticipants = [];
  bool _isLoading = false;
  bool _isLoadingStudents = true;
  String _searchQuery = '';
  String? _currentUserClassCode;

  @override
  void initState() {
    super.initState();
    _loadStudentsByClassCode();
    _selectedParticipants.add(_chatService.currentUserId); // Add current user
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentsByClassCode() async {
    try {
      // First, get current user's class code
      final currentUserDoc = await _firestore.collection('users').doc(_chatService.currentUserId).get();
      
      if (!currentUserDoc.exists) {
        throw 'Data pengguna tidak ditemukan';
      }

      final userData = currentUserDoc.data()!;
      _currentUserClassCode = userData['classCodeId'] as String?;

      if (_currentUserClassCode == null || _currentUserClassCode!.isEmpty) {
        throw 'Anda belum terdaftar dalam kelas manapun';
      }

      // Get all students with the same class code
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('classCodeId', isEqualTo: _currentUserClassCode)
          .where('isActive', isEqualTo: true)
          .get();
      
      _allStudents = studentsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Student.fromJson(data);
      }).toList();
      
      // Remove current user from the list if they exist in students collection
      _allStudents.removeWhere((student) => student.id == _chatService.currentUserId);
      
      setState(() {
        _filteredStudents = List.from(_allStudents);
        _isLoadingStudents = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStudents = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat daftar siswa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterStudents(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredStudents = List.from(_allStudents);
      } else {
        _filteredStudents = _allStudents.where((student) {
          final name = student.name.toLowerCase();
          final email = student.email.toLowerCase();
          final studentId = student.studentId.toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || 
                 email.contains(searchLower) || 
                 studentId.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Buat Chat Room',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Form Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chat Room Name
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Chat Room *',
                    hintText: 'Masukkan nama chat room',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.group),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                
                const SizedBox(height: 16),
                
                // Description
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    hintText: 'Masukkan deskripsi chat room',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                
                const SizedBox(height: 16),
                
                // Selected Participants Count
                Row(
                  children: [
                    Icon(Icons.people, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Anggota Terpilih: ${_selectedParticipants.length}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Search Section
           Container(
             padding: const EdgeInsets.all(16),
             color: Colors.white,
             child: TextField(
               controller: _searchController,
               decoration: InputDecoration(
                 hintText: 'Cari siswa...',
                 border: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(8),
                 ),
                 prefixIcon: const Icon(Icons.search),
                 suffixIcon: _searchQuery.isNotEmpty
                     ? IconButton(
                         icon: const Icon(Icons.clear),
                         onPressed: () {
                           _searchController.clear();
                           _filterStudents('');
                         },
                       )
                     : null,
               ),
               onChanged: _filterStudents,
             ),
           ),
          
          // Users List
          Expanded(
            child: Container(
              color: Colors.white,
              child: _isLoadingStudents
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredStudents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? _currentUserClassCode != null 
                                        ? 'Tidak ada siswa lain di kelas Anda'
                                        : 'Anda belum terdaftar dalam kelas'
                                    : 'Tidak ada hasil pencarian',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (_searchQuery.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Coba kata kunci lain',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                              if (_currentUserClassCode != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Kelas: $_currentUserClassCode',
                                  style: TextStyle(
                                    color: Colors.blue[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            // Class info header
                            if (_currentUserClassCode != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.class_, color: Colors.blue[600]),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Siswa di kelas: $_currentUserClassCode',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${_filteredStudents.length} siswa',
                                      style: TextStyle(
                                        color: Colors.blue[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Students list
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _filteredStudents.length,
                                itemBuilder: (context, index) {
                                  final student = _filteredStudents[index];
                                  final isSelected = _selectedParticipants.contains(student.id);
                                  
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: isSelected ? Colors.blue[300]! : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blue[100],
                                        backgroundImage: student.profileImageUrl != null
                                            ? NetworkImage(student.profileImageUrl!)
                                            : null,
                                        child: student.profileImageUrl == null
                                            ? Text(
                                                student.name.isNotEmpty
                                                    ? student.name[0].toUpperCase()
                                                    : '?',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue[700],
                                                ),
                                              )
                                            : null,
                                      ),
                                      title: Text(
                                        student.name,
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student.email,
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                          Text(
                                            'ID: ${student.studentId}',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Checkbox(
                                        value: isSelected,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedParticipants.add(student.id);
                                            } else {
                                              _selectedParticipants.remove(student.id);
                                            }
                                          });
                                        },
                                        activeColor: Colors.blue[600],
                                      ),
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedParticipants.remove(student.id);
                                          } else {
                                            _selectedParticipants.add(student.id);
                                          }
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
      
      // Create Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading || _nameController.text.trim().isEmpty
              ? null
              : _createChatRoom,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Buat Chat Room',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _createChatRoom() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama chat room tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedParticipants.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal harus ada 2 anggota (termasuk Anda)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final chatRoomId = await _chatService.createChatRoom(
        name: name,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        participants: _selectedParticipants,
        type: 'group',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat room berhasil dibuat!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context, chatRoomId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat chat room: $e'),
            backgroundColor: Colors.red,
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