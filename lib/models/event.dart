class Event {
  final int id;
  final String title;
  final String? description;
  final EventType type;
  final DateTime eventDate;
  final String startTime;
  final String endTime;
  final String? location;
  final int createdBy;
  final int maxParticipants;
  final EventStatus status;
  final int? classId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdByName;
  final String? className;
  final int currentParticipants;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.eventDate,
    required this.startTime,
    required this.endTime,
    this.location,
    required this.createdBy,
    required this.maxParticipants,
    required this.status,
    this.classId,
    required this.createdAt,
    required this.updatedAt,
    this.createdByName,
    this.className,
    this.currentParticipants = 0,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      type: EventType.fromString(json['type'] ?? 'parent_meeting'),
      eventDate: DateTime.parse(json['event_date']),
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      location: json['location'],
      createdBy: json['created_by'] ?? 0,
      maxParticipants: json['max_participants'] ?? 0,
      status: EventStatus.fromString(json['status'] ?? 'active'),
      classId: json['class_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      createdByName: json['created_by_name'],
      className: json['class_name'],
      currentParticipants: json['current_participants'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.value,
      'event_date': eventDate.toIso8601String().split('T')[0],
      'start_time': startTime,
      'end_time': endTime,
      'location': location,
      'created_by': createdBy,
      'max_participants': maxParticipants,
      'status': status.value,
      'class_id': classId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'description': description,
      'type': type.value,
      'event_date': eventDate.toIso8601String().split('T')[0],
      'start_time': startTime,
      'end_time': endTime,
      'location': location,
      'max_participants': maxParticipants,
      'class_id': classId,
    };
  }

  Event copyWith({
    int? id,
    String? title,
    String? description,
    EventType? type,
    DateTime? eventDate,
    String? startTime,
    String? endTime,
    String? location,
    int? createdBy,
    int? maxParticipants,
    EventStatus? status,
    int? classId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdByName,
    String? className,
    int? currentParticipants,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      eventDate: eventDate ?? this.eventDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      createdBy: createdBy ?? this.createdBy,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      status: status ?? this.status,
      classId: classId ?? this.classId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByName: createdByName ?? this.createdByName,
      className: className ?? this.className,
      currentParticipants: currentParticipants ?? this.currentParticipants,
    );
  }

  bool get isActive => status == EventStatus.active;
  bool get isFull => currentParticipants >= maxParticipants && maxParticipants > 0;
  bool get canBook => isActive && !isFull;
  
  String get formattedDate {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${eventDate.day} ${months[eventDate.month - 1]} ${eventDate.year}';
  }

  String get formattedTime => '$startTime - $endTime';
}

enum EventType {
  parentMeeting('parent_meeting', 'Pertemuan Orang Tua'),
  classCompetition('class_competition', 'Kompetisi Kelas'),
  academic('academic', 'Akademik'),
  extracurricular('extracurricular', 'Ekstrakurikuler'),
  social('social', 'Sosial'),
  sports('sports', 'Olahraga'),
  cultural('cultural', 'Budaya'),
  other('other', 'Lainnya');

  const EventType(this.value, this.displayName);
  final String value;
  final String displayName;

  static EventType fromString(String value) {
    return EventType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => EventType.parentMeeting,
    );
  }
}

enum EventStatus {
  active('active', 'Aktif'),
  cancelled('cancelled', 'Dibatalkan'),
  completed('completed', 'Selesai');

  const EventStatus(this.value, this.displayName);
  final String value;
  final String displayName;

  static EventStatus fromString(String value) {
    return EventStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => EventStatus.active,
    );
  }
}

class EventBooking {
  final int id;
  final int eventId;
  final int userId;
  final int? studentId;
  final DateTime timeSlot;
  final BookingStatus status;
  final String? notes;
  final DateTime createdAt;
  final String? userName;
  final String? studentName;
  final String? eventTitle; // Added for compatibility
  final String? eventLocation; // Added for MyBookingsScreen
  final String? formattedTime; // Added for MyBookingsScreen
  final String? formattedDate; // Added for MyBookingsScreen

  EventBooking({
    required this.id,
    required this.eventId,
    required this.userId,
    this.studentId,
    required this.timeSlot,
    required this.status,
    this.notes,
    required this.createdAt,
    this.userName,
    this.studentName,
    this.eventTitle,
    this.eventLocation,
    this.formattedTime,
    this.formattedDate,
  });

  factory EventBooking.fromJson(Map<String, dynamic> json) {
    return EventBooking(
      id: json['id'] ?? 0,
      eventId: json['event_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      studentId: json['student_id'],
      timeSlot: DateTime.parse(json['time_slot']),
      status: BookingStatus.fromString(json['status'] ?? 'pending'),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      userName: json['user_name'],
      studentName: json['student_name'],
      eventTitle: json['event_title'],
      eventLocation: json['event_location'],
      formattedTime: json['formatted_time'],
      formattedDate: json['formatted_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'time_slot': timeSlot.toIso8601String(),
      'notes': notes,
    };
  }
}

enum BookingStatus {
  pending('pending', 'Menunggu'),
  confirmed('confirmed', 'Dikonfirmasi'),
  cancelled('cancelled', 'Dibatalkan');

  const BookingStatus(this.value, this.displayName);
  final String value;
  final String displayName;

  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BookingStatus.pending,
    );
  }
}