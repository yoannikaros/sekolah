import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/event_provider.dart';
import '../../models/event.dart';
import '../../utils/app_colors.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();

  EventType _selectedType = EventType.academic;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Buat Event Baru',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Type Selection
              _SectionCard(
                title: 'Tipe Event',
                icon: Icons.category,
                child: Column(
                  children: EventType.values.map((type) {
                    return RadioListTile<EventType>(
                      title: Row(
                        children: [
                          Icon(
                            _getEventTypeIcon(type),
                            size: 20,
                            color: _getEventTypeColor(type),
                          ),
                          const SizedBox(width: 8),
                          Text(_getEventTypeText(type)),
                        ],
                      ),
                      value: type,
                      groupValue: _selectedType,
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                      activeColor: AppColors.primary,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Basic Information
              _SectionCard(
                title: 'Informasi Dasar',
                icon: Icons.info_outline,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Judul Event *',
                        hintText: 'Masukkan judul event',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Judul event harus diisi';
                        }
                        if (value.trim().length < 3) {
                          return 'Judul event minimal 3 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi *',
                        hintText: 'Masukkan deskripsi event',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Deskripsi event harus diisi';
                        }
                        if (value.trim().length < 10) {
                          return 'Deskripsi event minimal 10 karakter';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Date and Time
              _SectionCard(
                title: 'Waktu & Tempat',
                icon: Icons.schedule,
                child: Column(
                  children: [
                    // Date Picker
                    InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.grey300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: AppColors.grey600),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tanggal Event *',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.grey600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedDate != null
                                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                        : 'Pilih tanggal event',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: _selectedDate != null
                                          ? AppColors.textPrimary
                                          : AppColors.grey500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.grey400),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Time Picker
                    InkWell(
                      onTap: _selectTime,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.grey300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, color: AppColors.grey600),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Waktu Event *',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.grey600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedTime != null
                                        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                        : 'Pilih waktu event',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: _selectedTime != null
                                          ? AppColors.textPrimary
                                          : AppColors.grey500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.grey400),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Lokasi *',
                        hintText: 'Masukkan lokasi event',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Lokasi event harus diisi';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Capacity
              _SectionCard(
                title: 'Kapasitas',
                icon: Icons.people,
                child: TextFormField(
                  controller: _maxParticipantsController,
                  decoration: const InputDecoration(
                    labelText: 'Maksimal Peserta *',
                    hintText: 'Masukkan jumlah maksimal peserta',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.group),
                    suffixText: 'orang',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Maksimal peserta harus diisi';
                    }
                    final number = int.tryParse(value);
                    if (number == null || number <= 0) {
                      return 'Maksimal peserta harus berupa angka positif';
                    }
                    if (number > 1000) {
                      return 'Maksimal peserta tidak boleh lebih dari 1000';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : const Text(
                          'Buat Event',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      _showErrorSnackBar('Silakan pilih tanggal event');
      return;
    }

    if (_selectedTime == null) {
      _showErrorSnackBar('Silakan pilih waktu event');
      return;
    }

    // Check if the selected date and time is in the future
    final eventDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (eventDateTime.isBefore(DateTime.now())) {
      _showErrorSnackBar('Tanggal dan waktu event harus di masa depan');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final eventDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final event = Event(
        id: 0, // Will be set by the server
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        eventDate: eventDateTime,
        startTime: '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
        endTime: '${(_selectedTime!.hour + 1).toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}', // Default 1 hour duration
        location: _locationController.text.trim(),
        createdBy: 1, // Default user ID, should be replaced with actual user ID
        maxParticipants: int.parse(_maxParticipantsController.text),
        status: EventStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentParticipants: 0,
      );

      await context.read<EventProvider>().createEvent(event);

      if (mounted) {
        _showSuccessSnackBar('Event berhasil dibuat');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Gagal membuat event: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.parentMeeting:
        return AppColors.info;
      case EventType.classCompetition:
        return AppColors.warning;
      case EventType.academic:
        return AppColors.primary;
      case EventType.extracurricular:
        return AppColors.secondary;
      case EventType.social:
        return AppColors.accent;
      case EventType.sports:
        return AppColors.error;
      case EventType.cultural:
        return Colors.purple;
      case EventType.other:
        return AppColors.grey500;
    }
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.parentMeeting:
        return Icons.family_restroom;
      case EventType.classCompetition:
        return Icons.emoji_events;
      case EventType.academic:
        return Icons.school;
      case EventType.extracurricular:
        return Icons.group;
      case EventType.social:
        return Icons.people;
      case EventType.sports:
        return Icons.sports;
      case EventType.cultural:
        return Icons.theater_comedy;
      case EventType.other:
        return Icons.event;
    }
  }

  String _getEventTypeText(EventType type) {
    switch (type) {
      case EventType.parentMeeting:
        return 'Pertemuan Orang Tua';
      case EventType.classCompetition:
        return 'Kompetisi Kelas';
      case EventType.academic:
        return 'Akademik';
      case EventType.extracurricular:
        return 'Ekstrakurikuler';
      case EventType.social:
        return 'Sosial';
      case EventType.sports:
        return 'Olahraga';
      case EventType.cultural:
        return 'Budaya';
      case EventType.other:
        return 'Lainnya';
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}