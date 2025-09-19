import 'package:flutter/foundation.dart';
import '../models/event.dart';
import '../services/event_service.dart';

class EventProvider with ChangeNotifier {
  final EventService _eventService = EventService();
  
  List<Event> _events = [];
  List<EventBooking> _userBookings = [];
  Event? _selectedEvent;
  List<EventBooking> _selectedEventBookings = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Event> get events => _events;
  List<EventBooking> get userBookings => _userBookings;
  List<EventBooking> get myBookings => _userBookings; // Alias for compatibility
  Event? get selectedEvent => _selectedEvent;
  List<EventBooking> get selectedEventBookings => _selectedEventBookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filter getters
  List<Event> get activeEvents => _events.where((event) => event.isActive).toList();
  List<Event> get parentMeetings => _events.where((event) => event.type == EventType.parentMeeting).toList();
  List<Event> get classCompetitions => _events.where((event) => event.type == EventType.classCompetition).toList();
  List<Event> get upcomingEvents {
    final now = DateTime.now();
    return _events.where((event) => 
      event.isActive && 
      event.eventDate.isAfter(now.subtract(const Duration(days: 1)))
    ).toList()..sort((a, b) => a.eventDate.compareTo(b.eventDate));
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String error) {
    _error = error;
    _setLoading(false);
  }

  // Load all events
  Future<void> loadEvents({
    EventType? type,
    EventStatus? status,
    int? classId,
  }) async {
    _setLoading(true);
    clearError();

    try {
      final response = await _eventService.getEvents(
        type: type,
        status: status,
        classId: classId,
      );

      if (response.success && response.data != null) {
        _events = response.data!;
        _setLoading(false);
      } else {
        _setError(response.message ?? 'Failed to load events');
      }
    } catch (e) {
      _setError('Network error: $e');
    }
  }

  // Load event by ID
  Future<void> loadEventById(int eventId) async {
    _setLoading(true);
    clearError();

    try {
      final response = await _eventService.getEventById(eventId);

      if (response.success && response.data != null) {
        _selectedEvent = response.data!;
        
        // Also load bookings for this event
        await loadEventBookings(eventId);
        
        _setLoading(false);
      } else {
        _setError(response.message ?? 'Failed to load event');
      }
    } catch (e) {
      _setError('Network error: $e');
    }
  }

  // Create new event
  Future<bool> createEvent(Event event) async {
    _setLoading(true);
    clearError();

    try {
      final response = await _eventService.createEvent(event);

      if (response.success && response.data != null) {
        _events.add(response.data!);
        _setLoading(false);
        return true;
      } else {
        _setError(response.message ?? 'Failed to create event');
        return false;
      }
    } catch (e) {
      _setError('Network error: $e');
      return false;
    }
  }

  // Update event
  Future<bool> updateEvent(int eventId, Event event) async {
    _setLoading(true);
    clearError();

    try {
      final response = await _eventService.updateEvent(eventId, event);

      if (response.success && response.data != null) {
        final index = _events.indexWhere((e) => e.id == eventId);
        if (index != -1) {
          _events[index] = response.data!;
        }
        
        if (_selectedEvent?.id == eventId) {
          _selectedEvent = response.data!;
        }
        
        _setLoading(false);
        return true;
      } else {
        _setError(response.message ?? 'Failed to update event');
        return false;
      }
    } catch (e) {
      _setError('Network error: $e');
      return false;
    }
  }

  // Delete event
  Future<bool> deleteEvent(int eventId) async {
    _setLoading(true);
    clearError();

    try {
      final response = await _eventService.deleteEvent(eventId);

      if (response.success) {
        _events.removeWhere((event) => event.id == eventId);
        
        if (_selectedEvent?.id == eventId) {
          _selectedEvent = null;
          _selectedEventBookings.clear();
        }
        
        _setLoading(false);
        return true;
      } else {
        _setError(response.message ?? 'Failed to delete event');
        return false;
      }
    } catch (e) {
      _setError('Network error: $e');
      return false;
    }
  }

  // Book event
  Future<bool> bookEvent({
    required int eventId,
    int? studentId,
    DateTime? timeSlot,
    String? notes,
  }) async {
    _setLoading(true);
    clearError();

    try {
      final response = await _eventService.bookEvent(
        eventId: eventId,
        studentId: studentId,
        timeSlot: timeSlot,
        notes: notes,
      );

      if (response.success && response.data != null) {
        _userBookings.add(response.data!);
        
        // Update selected event bookings if this is the current event
        if (_selectedEvent?.id == eventId) {
          _selectedEventBookings.add(response.data!);
        }
        
        // Update event participant count
        final eventIndex = _events.indexWhere((e) => e.id == eventId);
        if (eventIndex != -1) {
          _events[eventIndex] = _events[eventIndex].copyWith(
            currentParticipants: _events[eventIndex].currentParticipants + 1,
          );
        }
        
        _setLoading(false);
        return true;
      } else {
        _setError(response.message ?? 'Failed to book event');
        return false;
      }
    } catch (e) {
      _setError('Network error: $e');
      return false;
    }
  }

  // Cancel booking
  Future<bool> cancelBooking(int bookingId) async {
    _setLoading(true);
    clearError();

    try {
      final response = await _eventService.cancelBooking(bookingId);

      if (response.success) {
        // Find and remove the booking
        final booking = _userBookings.firstWhere(
          (b) => b.id == bookingId,
          orElse: () => _selectedEventBookings.firstWhere((b) => b.id == bookingId),
        );
        
        _userBookings.removeWhere((b) => b.id == bookingId);
        _selectedEventBookings.removeWhere((b) => b.id == bookingId);
        
        // Update event participant count
        final eventIndex = _events.indexWhere((e) => e.id == booking.eventId);
        if (eventIndex != -1) {
          _events[eventIndex] = _events[eventIndex].copyWith(
            currentParticipants: _events[eventIndex].currentParticipants - 1,
          );
        }
        
        _setLoading(false);
        return true;
      } else {
        _setError(response.message ?? 'Failed to cancel booking');
        return false;
      }
    } catch (e) {
      _setError('Network error: $e');
      return false;
    }
  }

  // Load user bookings (alias for loadUserBookings for compatibility)
  Future<void> loadMyBookings() async {
    await loadUserBookings();
  }

  // Load user bookings
  Future<void> loadUserBookings() async {
    _setLoading(true);
    clearError();

    try {
      final response = await _eventService.getUserBookings();

      if (response.success && response.data != null) {
        _userBookings = response.data!;
        _setLoading(false);
      } else {
        _setError(response.message ?? 'Failed to load user bookings');
      }
    } catch (e) {
      _setError('Network error: $e');
    }
  }

  // Load event bookings
  Future<void> loadEventBookings(int eventId) async {
    try {
      final response = await _eventService.getEventBookings(eventId);

      if (response.success && response.data != null) {
        _selectedEventBookings = response.data!;
        notifyListeners();
      }
    } catch (e) {
      // Don't set error for this as it's a background operation
      debugPrint('Failed to load event bookings: $e');
    }
  }

  // Refresh all data
  Future<void> refresh() async {
    await Future.wait([
      loadEvents(),
      loadUserBookings(),
    ]);
  }

  // Clear selected event
  void clearSelectedEvent() {
    _selectedEvent = null;
    _selectedEventBookings.clear();
    notifyListeners();
  }

  // Check if user has booked an event
  bool hasUserBookedEvent(int eventId) {
    return _userBookings.any((booking) => 
      booking.eventId == eventId && 
      booking.status != BookingStatus.cancelled
    );
  }

  // Get user's booking for an event
  EventBooking? getUserBookingForEvent(int eventId) {
    try {
      return _userBookings.firstWhere((booking) => 
        booking.eventId == eventId && 
        booking.status != BookingStatus.cancelled
      );
    } catch (e) {
      return null;
    }
  }

  // Get events by type
  List<Event> getEventsByType(EventType type) {
    return _events.where((event) => event.type == type).toList();
  }

  // Get events by status
  List<Event> getEventsByStatus(EventStatus status) {
    return _events.where((event) => event.status == status).toList();
  }

  // Get events by class
  List<Event> getEventsByClass(int classId) {
    return _events.where((event) => event.classId == classId).toList();
  }
}