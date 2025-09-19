import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/event.dart';
import '../../utils/app_colors.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eventId = int.tryParse(widget.eventId);
      if (eventId != null) {
        final eventProvider = context.read<EventProvider>();
        eventProvider.loadEventById(eventId);
        eventProvider.loadUserBookings(); // Load user bookings to check if user has booked this event
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<EventProvider>(
        builder: (context, eventProvider, child) {
          if (eventProvider.isLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            );
          }

          if (eventProvider.error != null) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Event tidak ditemukan',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Kembali'),
                    ),
                  ],
                ),
              ),
            );
          }

          final event = eventProvider.selectedEvent;
          if (event == null) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // App Bar with Event Image
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _getEventTypeColor(event.type),
                          _getEventTypeColor(event.type).withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _getEventTypeIcon(event.type),
                        size: 80,
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
                actions: [
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      if (authProvider.user?.id == event.createdBy ||
                          authProvider.user?.role == 'admin') {
                        return PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                context.push('/events/${event.id}/edit');
                                break;
                              case 'delete':
                                _showDeleteConfirmation(context, event);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Edit Event'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: AppColors.error),
                                  SizedBox(width: 8),
                                  Text('Hapus Event'),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),

              // Event Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _EventTypeChip(type: event.type),
                              ],
                            ),
                          ),
                          _EventStatusChip(status: event.status),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Event Description
                      _SectionCard(
                        title: 'Deskripsi',
                        icon: Icons.description,
                        child: Text(
                          event.description ?? 'Tidak ada deskripsi',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Event Details
                      _SectionCard(
                        title: 'Detail Event',
                        icon: Icons.info_outline,
                        child: Column(
                          children: [
                            _DetailRow(
                              icon: Icons.calendar_today,
                              label: 'Tanggal',
                              value: event.formattedDate,
                            ),
                            const SizedBox(height: 12),
                            _DetailRow(
                              icon: Icons.access_time,
                              label: 'Waktu',
                              value: event.formattedTime,
                            ),
                            const SizedBox(height: 12),
                            _DetailRow(
                              icon: Icons.location_on,
                              label: 'Lokasi',
                              value: event.location ?? 'Lokasi tidak ditentukan',
                            ),
                            const SizedBox(height: 12),
                            _DetailRow(
                              icon: Icons.people,
                              label: 'Kapasitas',
                              value: '${event.currentParticipants}/${event.maxParticipants} peserta',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Participants Section
                      if (event.currentParticipants > 0)
                        _SectionCard(
                          title: 'Peserta Terdaftar',
                          icon: Icons.group,
                          child: Column(
                            children: [
                              LinearProgressIndicator(
                                value: event.currentParticipants / event.maxParticipants,
                                backgroundColor: AppColors.grey200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  event.currentParticipants >= event.maxParticipants
                                      ? AppColors.error
                                      : AppColors.success,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${event.currentParticipants} dari ${event.maxParticipants} peserta',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 100), // Space for floating button
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer2<EventProvider, AuthProvider>(
        builder: (context, eventProvider, authProvider, child) {
          final event = eventProvider.selectedEvent;
          if (event == null || event.status != EventStatus.active) {
            return const SizedBox.shrink();
          }

          final isBooked = eventProvider.userBookings
              .any((booking) => booking.eventId == event.id);

          if (isBooked) {
            return FloatingActionButton.extended(
              onPressed: () => _showCancelBookingDialog(context, event),
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              icon: const Icon(Icons.cancel),
              label: const Text('Batalkan Booking'),
            );
          }

          final isFull = event.currentParticipants >= event.maxParticipants;
          if (isFull) {
            return FloatingActionButton.extended(
              onPressed: null,
              backgroundColor: AppColors.grey400,
              foregroundColor: AppColors.white,
              icon: const Icon(Icons.people),
              label: const Text('Event Penuh'),
            );
          }

          return FloatingActionButton.extended(
            onPressed: () => _showBookingDialog(context, event),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            icon: const Icon(Icons.event_available),
            label: const Text('Daftar Event'),
          );
        },
      ),
    );
  }

  void _showBookingDialog(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pendaftaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apakah Anda yakin ingin mendaftar untuk event ini?'),
            const SizedBox(height: 16),
            Text(
              'Event: ${event.title}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Tanggal: ${event.formattedDate}'),
            Text('Waktu: ${event.formattedTime}'),
            Text('Lokasi: ${event.location}'),
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
              context.read<EventProvider>().bookEvent(eventId: event.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Daftar'),
          ),
        ],
      ),
    );
  }

  void _showCancelBookingDialog(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Pendaftaran'),
        content: const Text('Apakah Anda yakin ingin membatalkan pendaftaran untuk event ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<EventProvider>().cancelBooking(event.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Event'),
        content: const Text('Apakah Anda yakin ingin menghapus event ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<EventProvider>().deleteEvent(event.id).then((_) {
                if (context.mounted) {
                  context.pop(); // Return to event list
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
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
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _EventTypeChip extends StatelessWidget {
  final EventType type;

  const _EventTypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    String text;
    switch (type) {
      case EventType.parentMeeting:
        text = 'Pertemuan Orang Tua';
        break;
      case EventType.classCompetition:
        text = 'Kompetisi Kelas';
        break;
      case EventType.academic:
        text = 'Akademik';
        break;
      case EventType.extracurricular:
        text = 'Ekstrakurikuler';
        break;
      case EventType.social:
        text = 'Sosial';
        break;
      case EventType.sports:
        text = 'Olahraga';
        break;
      case EventType.cultural:
        text = 'Budaya';
        break;
      case EventType.other:
        text = 'Lainnya';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getEventTypeColor(type).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getEventTypeIcon(type),
            size: 16,
            color: _getEventTypeColor(type),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _getEventTypeColor(type),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
}

class _EventStatusChip extends StatelessWidget {
  final EventStatus status;

  const _EventStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case EventStatus.active:
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        text = 'Aktif';
        break;
      case EventStatus.cancelled:
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        text = 'Dibatalkan';
        break;
      case EventStatus.completed:
        backgroundColor = AppColors.grey200;
        textColor = AppColors.grey700;
        text = 'Selesai';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}