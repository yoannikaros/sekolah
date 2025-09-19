import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/event.dart';
import '../../utils/app_colors.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Event Planner',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.go('/events/bookings'),
            icon: const Icon(Icons.bookmark_outlined, color: AppColors.white),
            tooltip: 'Booking Saya',
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.user?.role == 'admin' || 
                  authProvider.user?.role == 'teacher') {
                return IconButton(
                  icon: const Icon(Icons.add, color: AppColors.white),
                  onPressed: () => context.push('/events/create'),
                  tooltip: 'Buat Event',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<EventProvider>(
        builder: (context, eventProvider, child) {
          if (eventProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          if (eventProvider.error != null) {
            return Center(
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
                    'Terjadi kesalahan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    eventProvider.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => eventProvider.loadEvents(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (eventProvider.events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note,
                    size: 64,
                    color: AppColors.grey400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada event',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Event yang dibuat akan muncul di sini',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => eventProvider.loadEvents(),
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: eventProvider.events.length,
              itemBuilder: (context, index) {
                final event = eventProvider.events[index];
                return _EventCard(event: event);
              },
            ),
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => context.push('/events/${event.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getEventTypeColor(event.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getEventTypeIcon(event.type),
                      color: _getEventTypeColor(event.type),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.description ?? 'Tidak ada deskripsi',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _EventStatusChip(status: event.status),
                ],
              ),
              const SizedBox(height: 16),
              
              // Event Details
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    event.formattedDate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    event.formattedTime,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.location ?? 'Lokasi tidak ditentukan',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.people,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${event.currentParticipants}/${event.maxParticipants}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
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