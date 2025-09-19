import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      eventProvider.loadMyBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Saya'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Consumer2<EventProvider, AuthProvider>(
        builder: (context, eventProvider, authProvider, child) {
          if (eventProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
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
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    eventProvider.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => eventProvider.loadMyBookings(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final bookings = eventProvider.myBookings;

          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada booking',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Anda belum melakukan booking untuk event apapun',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/events'),
                    child: const Text('Lihat Event'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await eventProvider.loadMyBookings();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return _BookingCard(
                  booking: booking,
                  onCancel: () => _showCancelDialog(context, booking),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showCancelDialog(BuildContext context, EventBooking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Booking'),
        content: Text(
          'Apakah Anda yakin ingin membatalkan booking untuk event "${booking.eventTitle}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final eventProvider = Provider.of<EventProvider>(context, listen: false);
              await eventProvider.cancelBooking(booking.id);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Booking berhasil dibatalkan'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
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
}

class _BookingCard extends StatelessWidget {
  final EventBooking booking;
  final VoidCallback onCancel;

  const _BookingCard({
    required this.booking,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
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
                Expanded(
                  child: Text(
                    booking.eventTitle ?? 'Event',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _BookingStatusChip(status: booking.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  booking.formattedDate ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  booking.formattedTime ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
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
                    booking.eventLocation ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            if (booking.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catatan:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.notes ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/events/${booking.eventId}'),
                    child: const Text('Lihat Event'),
                  ),
                ),
                const SizedBox(width: 12),
                if (booking.status == BookingStatus.confirmed) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Batalkan'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingStatusChip extends StatelessWidget {
  final BookingStatus status;

  const _BookingStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case BookingStatus.pending:
        backgroundColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
        text = 'Menunggu';
        break;
      case BookingStatus.confirmed:
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        text = 'Dikonfirmasi';
        break;
      case BookingStatus.cancelled:
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        text = 'Dibatalkan';
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
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}