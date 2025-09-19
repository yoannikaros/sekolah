import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event.dart';
import 'api_service.dart';

class EventService {
  static const String baseUrl = 'http://localhost:3000/api';
  final ApiService _apiService = ApiService();

  // Get all events with optional filters
  Future<ApiResponse<List<Event>>> getEvents({
    EventType? type,
    EventStatus? status,
    int? classId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (type != null) queryParams['type'] = type.value;
      if (status != null) queryParams['status'] = status.value;
      if (classId != null) queryParams['class_id'] = classId.toString();

      final uri = Uri.parse('$baseUrl/events').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final eventsJson = data['events'] as List<dynamic>;
        final events = eventsJson
            .map((json) => Event.fromJson(json as Map<String, dynamic>))
            .toList();

        return ApiResponse<List<Event>>(
          success: true,
          message: 'Events retrieved successfully',
          data: events,
        );
      } else {
        return ApiResponse<List<Event>>(
          success: false,
          message: data['error'] as String? ?? 'Failed to get events',
        );
      }
    } catch (e) {
      return ApiResponse<List<Event>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Get event by ID
  Future<ApiResponse<Event>> getEventById(int eventId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: await _getHeaders(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final event = Event.fromJson(data['event'] as Map<String, dynamic>);
        
        return ApiResponse<Event>(
          success: true,
          message: 'Event retrieved successfully',
          data: event,
        );
      } else {
        return ApiResponse<Event>(
          success: false,
          message: data['error'] as String? ?? 'Failed to get event',
        );
      }
    } catch (e) {
      return ApiResponse<Event>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Create new event
  Future<ApiResponse<Event>> createEvent(Event event) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/events'),
        headers: await _getHeaders(),
        body: jsonEncode(event.toCreateJson()),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final createdEvent = Event.fromJson(data['event'] as Map<String, dynamic>);
        
        return ApiResponse<Event>(
          success: true,
          message: data['message'] as String? ?? 'Event created successfully',
          data: createdEvent,
        );
      } else {
        return ApiResponse<Event>(
          success: false,
          message: data['error'] as String? ?? 'Failed to create event',
        );
      }
    } catch (e) {
      return ApiResponse<Event>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Update event
  Future<ApiResponse<Event>> updateEvent(int eventId, Event event) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: await _getHeaders(),
        body: jsonEncode(event.toCreateJson()),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final updatedEvent = Event.fromJson(data['event'] as Map<String, dynamic>);
        
        return ApiResponse<Event>(
          success: true,
          message: data['message'] as String? ?? 'Event updated successfully',
          data: updatedEvent,
        );
      } else {
        return ApiResponse<Event>(
          success: false,
          message: data['error'] as String? ?? 'Failed to update event',
        );
      }
    } catch (e) {
      return ApiResponse<Event>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Delete event
  Future<ApiResponse<void>> deleteEvent(int eventId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: await _getHeaders(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: data['message'] as String? ?? 'Event deleted successfully',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: data['error'] as String? ?? 'Failed to delete event',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Book event slot
  Future<ApiResponse<EventBooking>> bookEvent({
    required int eventId,
    int? studentId,
    DateTime? timeSlot,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (studentId != null) body['student_id'] = studentId;
      if (timeSlot != null) body['time_slot'] = timeSlot.toIso8601String();
      if (notes != null) body['notes'] = notes;

      final response = await http.post(
        Uri.parse('$baseUrl/events/$eventId/book'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final booking = EventBooking.fromJson(data['booking'] as Map<String, dynamic>);
        
        return ApiResponse<EventBooking>(
          success: true,
          message: data['message'] as String? ?? 'Event booked successfully',
          data: booking,
        );
      } else {
        return ApiResponse<EventBooking>(
          success: false,
          message: data['error'] as String? ?? 'Failed to book event',
        );
      }
    } catch (e) {
      return ApiResponse<EventBooking>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Get event bookings
  Future<ApiResponse<List<EventBooking>>> getEventBookings(int eventId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events/$eventId/bookings'),
        headers: await _getHeaders(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final bookingsJson = data['bookings'] as List<dynamic>;
        final bookings = bookingsJson
            .map((json) => EventBooking.fromJson(json as Map<String, dynamic>))
            .toList();

        return ApiResponse<List<EventBooking>>(
          success: true,
          message: 'Bookings retrieved successfully',
          data: bookings,
        );
      } else {
        return ApiResponse<List<EventBooking>>(
          success: false,
          message: data['error'] as String? ?? 'Failed to get bookings',
        );
      }
    } catch (e) {
      return ApiResponse<List<EventBooking>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Cancel booking
  Future<ApiResponse<void>> cancelBooking(int bookingId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/bookings/$bookingId'),
        headers: await _getHeaders(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: data['message'] as String? ?? 'Booking cancelled successfully',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: data['error'] as String? ?? 'Failed to cancel booking',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Get user's bookings
  Future<ApiResponse<List<EventBooking>>> getUserBookings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/my'),
        headers: await _getHeaders(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final bookingsJson = data['bookings'] as List<dynamic>;
        final bookings = bookingsJson
            .map((json) => EventBooking.fromJson(json as Map<String, dynamic>))
            .toList();

        return ApiResponse<List<EventBooking>>(
          success: true,
          message: 'User bookings retrieved successfully',
          data: bookings,
        );
      } else {
        return ApiResponse<List<EventBooking>>(
          success: false,
          message: data['error'] as String? ?? 'Failed to get user bookings',
        );
      }
    } catch (e) {
      return ApiResponse<List<EventBooking>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Get headers with authorization
  Future<Map<String, String>> _getHeaders() async {
    final token = await _apiService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}