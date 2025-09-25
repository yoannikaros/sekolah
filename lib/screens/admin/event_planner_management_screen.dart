import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/event_planner_models.dart';
import '../../services/event_planner_service.dart';
import '../../services/admin_service.dart';
import '../../models/admin_models.dart';
import '../../models/quiz_models.dart';

class EventPlannerManagementScreen extends StatefulWidget {
  const EventPlannerManagementScreen({super.key});

  @override
  State<EventPlannerManagementScreen> createState() => _EventPlannerManagementScreenState();
}

class _EventPlannerManagementScreenState extends State<EventPlannerManagementScreen> {
  final EventPlannerService _eventPlannerService = EventPlannerService();
  final AdminService _adminService = AdminService();
  
  List<EventPlanner> _events = [];
  List<School> _schools = [];
  List<ClassCode> _classCodes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  EventType? _selectedType;
  EventStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (kDebugMode) {
        print('=== Starting data load ===');
      }
      
      // Load events, schools, and class codes in parallel
      final results = await Future.wait([
        _eventPlannerService.getAllEventPlanners(),
        _adminService.getAllSchools(),
        _adminService.getAllClassCodes(),
      ]);
      
      final events = results[0] as List<EventPlanner>;
      final schools = results[1] as List<School>;
      final classCodes = results[2] as List<ClassCode>;
      
      if (kDebugMode) {
        print('=== Data load results ===');
        print('Events loaded: ${events.length}');
        print('Schools loaded: ${schools.length}');
        print('Class codes loaded: ${classCodes.length}');
        
        if (events.isNotEmpty) {
          print('First event: ${events.first.title}');
          print('First event ID: ${events.first.id}');
          print('First event isActive: ${events.first.isActive}');
          print('First event type: ${events.first.type}');
          print('First event status: ${events.first.status}');
        } else {
          print('No events found in Firebase!');
        }
      }
      
      setState(() {
        _events = events;
        _schools = schools;
        _classCodes = classCodes;
        _isLoading = false;
      });
      
      if (kDebugMode) {
        print('State updated. Current _events length: ${_events.length}');
        print('=== Data load complete ===');
      }
    } catch (e) {
      if (kDebugMode) {
        print('=== Error loading data ===');
        print('Error: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await _eventPlannerService.getAllEventPlanners();
      
      if (kDebugMode) {
        print('Loaded ${events.length} events');
      }
      
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading events: $e');
      }
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: $e')),
        );
      }
    }
  }

  Future<void> _showEventDialog({EventPlanner? event}) async {
    final titleController = TextEditingController(text: event?.title ?? '');
    final descriptionController = TextEditingController(text: event?.description ?? '');
    final locationController = TextEditingController(text: event?.location ?? '');
    final notesController = TextEditingController(text: event?.notes ?? '');
    final tagsController = TextEditingController(text: event?.tags.join(', ') ?? '');
    
    // Dropdown values
    String? selectedClassCodeId = event?.classCode;
    String? selectedSchoolId = event?.schoolId != 'default_school' ? event?.schoolId : null;
    EventVisibility selectedVisibility = event?.visibility ?? EventVisibility.school;
    
    DateTime selectedDate = event?.eventDate ?? DateTime.now();
    TimeOfDay selectedTime = event != null 
        ? TimeOfDay(
            hour: int.parse(event.eventTime.split(':')[0]),
            minute: int.parse(event.eventTime.split(':')[1]),
          )
        : TimeOfDay.now();
    EventType selectedType = event?.type ?? EventType.classActivity;
    EventStatus selectedStatus = event?.status ?? EventStatus.planned;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Filter class codes based on selected school
            List<ClassCode> availableClassCodes = selectedSchoolId != null
                ? _classCodes.where((cc) => cc.schoolId == selectedSchoolId).toList()
                : _classCodes;

            return AlertDialog(
              title: Text(event == null ? 'Tambah Event' : 'Edit Event'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Judul Event',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      // Visibility Selection
                      DropdownButtonFormField<EventVisibility>(
                        value: selectedVisibility,
                        decoration: const InputDecoration(
                          labelText: 'Visibilitas Event',
                          border: OutlineInputBorder(),
                        ),
                        items: EventVisibility.values.map((visibility) {
                          return DropdownMenuItem(
                            value: visibility,
                            child: Text(_getEventVisibilityLabel(visibility)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedVisibility = value!;
                            // Reset required class code when visibility changes
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedSchoolId,
                              decoration: const InputDecoration(
                                labelText: 'Sekolah',
                                border: OutlineInputBorder(),
                              ),
                              hint: const Text('Pilih Sekolah'),
                              items: _schools.map((school) {
                                return DropdownMenuItem<String>(
                                  value: school.id,
                                  child: Text(school.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedSchoolId = value;
                                  // Reset class code when school changes
                                  selectedClassCodeId = null;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Pilih sekolah';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedClassCodeId,
                              decoration: const InputDecoration(
                                labelText: 'Kode Kelas',
                                border: OutlineInputBorder(),
                              ),
                              hint: const Text('Pilih Kelas'),
                              items: availableClassCodes.map((classCode) {
                                return DropdownMenuItem<String>(
                                  value: classCode.code,
                                  child: Text('${classCode.name} (${classCode.code})'),
                                );
                              }).toList(),
                              onChanged: selectedSchoolId != null ? (value) {
                                setDialogState(() {
                                  selectedClassCodeId = value;
                                });
                              } : null,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Pilih kode kelas';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      if (selectedSchoolId != null && availableClassCodes.isEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Belum ada kode kelas untuk sekolah ini.\nTambahkan kode kelas terlebih dahulu di menu Kelola Kode Kelas.',
                            style: TextStyle(color: Colors.orange),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<EventType>(
                              value: selectedType,
                              decoration: const InputDecoration(
                                labelText: 'Tipe Event',
                                border: OutlineInputBorder(),
                              ),
                              items: EventType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(_getEventTypeLabel(type)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedType = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<EventStatus>(
                              value: selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                              ),
                              items: EventStatus.values.map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(_getEventStatusLabel(status)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedStatus = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setDialogState(() {
                                    selectedDate = date;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Tanggal Event',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime,
                                );
                                if (time != null) {
                                  setDialogState(() {
                                    selectedTime = time;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Waktu Event',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'Lokasi (Opsional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (Opsional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags (pisahkan dengan koma)',
                          border: OutlineInputBorder(),
                          hintText: 'olahraga, akademik, seni',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    
                    if (titleController.text.trim().isEmpty ||
                         selectedSchoolId == null ||
                         selectedClassCodeId == null) {
                       scaffoldMessenger.showSnackBar(
                         const SnackBar(content: Text('Judul, sekolah, dan kode kelas harus diisi')),
                       );
                       return;
                     }

                     final tags = tagsController.text
                         .split(',')
                         .map((tag) => tag.trim())
                         .where((tag) => tag.isNotEmpty)
                         .toList();

                     final eventTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

                     final newEvent = EventPlanner(
                       id: event?.id ?? '',
                       title: titleController.text.trim(),
                       description: descriptionController.text.trim(),
                       eventDate: selectedDate,
                       eventTime: eventTime,
                       schoolId: selectedSchoolId!,
                       classCode: selectedClassCodeId!,
                       type: selectedType,
                       status: selectedStatus,
                       createdBy: 'admin', // TODO: Get from auth
                       creatorName: 'Admin', // TODO: Get from auth
                       createdAt: event?.createdAt ?? DateTime.now(),
                       updatedAt: DateTime.now(),
                       location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
                       notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                       tags: tags,
                       visibility: selectedVisibility,
                       requiredClassCode: null,
                       challengedSchoolName: null,
                       challengeDeadline: selectedVisibility == EventVisibility.public 
                           ? selectedDate.add(const Duration(days: 7)) // 7 days to accept challenge
                           : null,
                     );

                    bool success;
                    if (event == null) {
                      final id = await _eventPlannerService.createEventPlanner(newEvent);
                      success = id != null;
                    } else {
                      success = await _eventPlannerService.updateEventPlanner(event.id, newEvent);
                    }

                    if (success) {
                      navigator.pop();
                      _loadEvents();
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(event == null ? 'Event berhasil ditambahkan' : 'Event berhasil diperbarui'),
                        ),
                      );
                    } else {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(event == null ? 'Gagal menambahkan event' : 'Gagal memperbarui event'),
                        ),
                      );
                    }
                  },
                  child: Text(event == null ? 'Tambah' : 'Perbarui'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteEvent(EventPlanner event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus event "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _eventPlannerService.deleteEventPlanner(event.id);
      if (success) {
        _loadEvents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event berhasil dihapus')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus event')),
          );
        }
      }
    }
  }

  List<EventPlanner> get filteredEvents {
    return _events.where((event) {
      final matchesSearch = _searchQuery.isEmpty ||
          event.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.classCode.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesType = _selectedType == null || event.type == _selectedType;
      final matchesStatus = _selectedStatus == null || event.status == _selectedStatus;
      
      return matchesSearch && matchesType && matchesStatus;
    }).toList();
  }

  String _getEventTypeLabel(EventType type) {
    switch (type) {
      case EventType.parentMeeting:
        return 'Pertemuan Orang Tua';
      case EventType.interClassCompetition:
        return 'Lomba Antar Kelas';
      case EventType.interSchoolChallenge:
        return 'Tantangan Antar Sekolah';
      case EventType.schoolEvent:
        return 'Event Sekolah';
      case EventType.classActivity:
        return 'Kegiatan Kelas';
    }
  }

  String _getEventStatusLabel(EventStatus status) {
    switch (status) {
      case EventStatus.planned:
        return 'Direncanakan';
      case EventStatus.confirmed:
        return 'Dikonfirmasi';
      case EventStatus.ongoing:
        return 'Berlangsung';
      case EventStatus.completed:
        return 'Selesai';
      case EventStatus.cancelled:
        return 'Dibatalkan';
      case EventStatus.postponed:
        return 'Ditunda';
    }
  }

  String _getEventVisibilityLabel(EventVisibility visibility) {
    switch (visibility) {
      case EventVisibility.internalClass:
        return 'Internal Kelas';
      case EventVisibility.school:
        return 'Sekolah';
      case EventVisibility.public:
        return 'Publik';
    }
  }

  Color _getStatusColor(EventStatus status) {
    switch (status) {
      case EventStatus.planned:
        return Colors.orange;
      case EventStatus.confirmed:
        return Colors.blue;
      case EventStatus.ongoing:
        return Colors.green;
      case EventStatus.completed:
        return Colors.grey;
      case EventStatus.cancelled:
        return Colors.red;
      case EventStatus.postponed:
        return Colors.purple;
    }
  }

  IconData _getTypeIcon(EventType type) {
    switch (type) {
      case EventType.parentMeeting:
        return Icons.people;
      case EventType.interClassCompetition:
        return Icons.emoji_events;
      case EventType.interSchoolChallenge:
        return Icons.school;
      case EventType.schoolEvent:
        return Icons.event;
      case EventType.classActivity:
        return Icons.class_;
    }
  }

  String _getSchoolName(String schoolId) {
    final school = _schools.firstWhere(
      (s) => s.id == schoolId,
      orElse: () => School(
        id: '',
        name: 'Sekolah Tidak Ditemukan',
        address: '',
        phone: '',
        email: '',
        createdAt: DateTime.now(),
        isActive: true,
      ),
    );
    return school.name;
  }

  String _getClassCodeName(String classCode) {
    final classCodeObj = _classCodes.firstWhere(
      (cc) => cc.code == classCode,
      orElse: () => ClassCode(
        id: '',
        code: classCode,
        name: classCode,
        description: '',
        teacherId: '',
        schoolId: '',
        createdAt: DateTime.now(),
        isActive: true,
      ),
    );
    return '${classCodeObj.name} (${classCodeObj.code})';
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents = this.filteredEvents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Event Planner'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Cari event...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<EventType?>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Filter Tipe',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<EventType?>(
                            value: null,
                            child: Text('Semua Tipe'),
                          ),
                          ...EventType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(_getEventTypeLabel(type)),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<EventStatus?>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Filter Status',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<EventStatus?>(
                            value: null,
                            child: Text('Semua Status'),
                          ),
                          ...EventStatus.values.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(_getEventStatusLabel(status)),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Events List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredEvents.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_note,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Belum ada event',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredEvents.length,
                        itemBuilder: (context, index) {
                          final event = filteredEvents[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _getTypeIcon(event.type),
                                        color: const Color(0xFF6366F1),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          event.title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(event.status).withAlpha(25),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _getStatusColor(event.status),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          _getEventStatusLabel(event.status),
                                          style: TextStyle(
                                            color: _getStatusColor(event.status),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    event.description,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                     children: [
                                       Icon(
                                         Icons.calendar_today,
                                         size: 16,
                                         color: Colors.grey[600],
                                       ),
                                       const SizedBox(width: 4),
                                       Text(
                                         '${event.eventDate.day}/${event.eventDate.month}/${event.eventDate.year}',
                                         style: TextStyle(
                                           color: Colors.grey[600],
                                           fontSize: 12,
                                         ),
                                       ),
                                       const SizedBox(width: 16),
                                       Icon(
                                         Icons.access_time,
                                         size: 16,
                                         color: Colors.grey[600],
                                       ),
                                       const SizedBox(width: 4),
                                       Text(
                                         event.eventTime,
                                         style: TextStyle(
                                           color: Colors.grey[600],
                                           fontSize: 12,
                                         ),
                                       ),
                                       const SizedBox(width: 16),
                                       Icon(
                                         Icons.class_,
                                         size: 16,
                                         color: Colors.grey[600],
                                       ),
                                       const SizedBox(width: 4),
                                       Text(
                                         _getClassCodeName(event.classCode),
                                         style: TextStyle(
                                           color: Colors.grey[600],
                                           fontSize: 12,
                                         ),
                                       ),
                                       const Spacer(),
                                       Text(
                                         _getEventTypeLabel(event.type),
                                         style: TextStyle(
                                           color: Colors.grey[600],
                                           fontSize: 12,
                                           fontWeight: FontWeight.w500,
                                         ),
                                       ),
                                     ],
                                   ),
                                   const SizedBox(height: 8),
                                   Row(
                                     children: [
                                       Icon(
                                         Icons.school,
                                         size: 16,
                                         color: Colors.grey[600],
                                       ),
                                       const SizedBox(width: 4),
                                       Text(
                                         _getSchoolName(event.schoolId),
                                         style: TextStyle(
                                           color: Colors.grey[600],
                                           fontSize: 12,
                                         ),
                                       ),
                                       const SizedBox(width: 16),
                                       Icon(
                                         Icons.visibility,
                                         size: 16,
                                         color: Colors.grey[600],
                                       ),
                                       const SizedBox(width: 4),
                                       Text(
                                         _getEventVisibilityLabel(event.visibility),
                                         style: TextStyle(
                                           color: Colors.grey[600],
                                           fontSize: 12,
                                         ),
                                       ),
                                     ],
                                   ),
                                  if (event.location != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          event.location!,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (event.challengedSchoolName != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.school,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'vs ${event.challengedSchoolName}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _showEventDialog(event: event),
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('Edit'),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: () => _deleteEvent(event),
                                        icon: const Icon(Icons.delete, size: 16),
                                        label: const Text('Hapus'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                    ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEventDialog(),
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}