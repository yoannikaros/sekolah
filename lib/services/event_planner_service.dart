import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/event_planner_models.dart';

class EventPlannerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Event Planner CRUD Operations
  Future<String?> createEventPlanner(EventPlanner event) async {
    try {
      final eventData = {
        'title': event.title,
        'description': event.description,
        'eventDate': event.eventDate.toIso8601String(),
        'eventTime': event.eventTime,
        'schoolId': event.schoolId,
        'classCode': event.classCode,
        'type': event.type.name,
        'status': event.status.name,
        'createdBy': event.createdBy,
        'creatorName': event.creatorName,
        'createdAt': event.createdAt.toIso8601String(),
        'updatedAt': event.updatedAt.toIso8601String(),
        'isActive': event.isActive,
        'location': event.location,
        'participants': event.participants.map((p) => p.toJson()).toList(),
        'notes': event.notes,
        'metadata': event.metadata,
        'tags': event.tags,
        'challengedSchoolId': event.challengedSchoolId,
        'challengedSchoolName': event.challengedSchoolName,
        'visibility': _getVisibilityString(event.visibility),
        'requiredClassCode': event.requiredClassCode,
        'votesCount': event.votesCount,
        'voters': event.voters.map((v) => v.toJson()).toList(),
        'challengeAccepted': event.challengeAccepted,
        'challengeDeadline': event.challengeDeadline?.toIso8601String(),
      };
      
      final docRef = await _firestore.collection('event_planners').add(eventData);
      if (kDebugMode) {
        print('Event planner created successfully with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating event planner: $e');
      }
      return null;
    }
  }

  Future<bool> updateEventPlanner(String id, EventPlanner event) async {
    try {
      final eventData = {
        'title': event.title,
        'description': event.description,
        'eventDate': event.eventDate.toIso8601String(),
        'eventTime': event.eventTime,
        'schoolId': event.schoolId,
        'classCode': event.classCode,
        'type': event.type.name,
        'status': event.status.name,
        'createdBy': event.createdBy,
        'creatorName': event.creatorName,
        'createdAt': event.createdAt.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isActive': event.isActive,
        'location': event.location,
        'participants': event.participants.map((p) => p.toJson()).toList(),
        'notes': event.notes,
        'metadata': event.metadata,
        'tags': event.tags,
        'challengedSchoolId': event.challengedSchoolId,
        'challengedSchoolName': event.challengedSchoolName,
        'visibility': _getVisibilityString(event.visibility),
        'requiredClassCode': event.requiredClassCode,
        'votesCount': event.votesCount,
        'voters': event.voters.map((v) => v.toJson()).toList(),
        'challengeAccepted': event.challengeAccepted,
        'challengeDeadline': event.challengeDeadline?.toIso8601String(),
      };
      
      await _firestore.collection('event_planners').doc(id).update(eventData);
      if (kDebugMode) {
        print('Event planner updated successfully with ID: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating event planner: $e');
      }
      return false;
    }
  }

  Future<bool> deleteEventPlanner(String id) async {
    try {
      await _firestore.collection('event_planners').doc(id).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      if (kDebugMode) {
        print('Event planner deleted successfully with ID: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting event planner: $e');
      }
      return false;
    }
  }

  Future<EventPlanner?> getEventPlannerById(String id) async {
    try {
      final doc = await _firestore.collection('event_planners').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return _mapToEventPlanner(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting event planner by ID: $e');
      }
      return null;
    }
  }

  Future<List<EventPlanner>> getAllEventPlanners({
    String? schoolId,
    String? classCode,
    EventType? type,
    EventStatus? status,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore.collection('event_planners');
      
      if (schoolId != null) {
        query = query.where('schoolId', isEqualTo: schoolId);
      }
      if (classCode != null) {
        query = query.where('classCode', isEqualTo: classCode);
      }
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      
      query = query.where('isActive', isEqualTo: true)
                  .orderBy('eventDate', descending: false)
                  .limit(limit);
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        return _mapToEventPlanner(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting event planners: $e');
      }
      return [];
    }
  }

  Future<List<EventPlanner>> getEventPlannersByClassCode(String classCode) async {
    return getAllEventPlanners(classCode: classCode);
  }

  Future<List<EventPlanner>> getEventPlannersBySchool(String schoolId) async {
    return getAllEventPlanners(schoolId: schoolId);
  }

  Future<List<EventPlanner>> getUpcomingEvents({
    String? schoolId,
    String? classCode,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection('event_planners');
      
      if (schoolId != null) {
        query = query.where('schoolId', isEqualTo: schoolId);
      }
      if (classCode != null) {
        query = query.where('classCode', isEqualTo: classCode);
      }
      
      // Get events from today onwards
      final today = DateTime.now();
      final todayString = DateTime(today.year, today.month, today.day).toIso8601String();
      
      query = query.where('isActive', isEqualTo: true)
                  .where('eventDate', isGreaterThanOrEqualTo: todayString)
                  .orderBy('eventDate', descending: false)
                  .limit(limit);
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        return _mapToEventPlanner(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting upcoming events: $e');
      }
      return [];
    }
  }

  Future<List<EventPlanner>> getEventsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? schoolId,
    String? classCode,
  }) async {
    try {
      Query query = _firestore.collection('event_planners');
      
      if (schoolId != null) {
        query = query.where('schoolId', isEqualTo: schoolId);
      }
      if (classCode != null) {
        query = query.where('classCode', isEqualTo: classCode);
      }
      
      query = query.where('isActive', isEqualTo: true)
                  .where('eventDate', isGreaterThanOrEqualTo: startDate.toIso8601String())
                  .where('eventDate', isLessThanOrEqualTo: endDate.toIso8601String())
                  .orderBy('eventDate', descending: false);
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        return _mapToEventPlanner(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting events by date range: $e');
      }
      return [];
    }
  }

  Future<bool> updateEventStatus(String id, EventStatus status) async {
    try {
      await _firestore.collection('event_planners').doc(id).update({
        'status': status.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      if (kDebugMode) {
        print('Event status updated successfully for ID: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating event status: $e');
      }
      return false;
    }
  }

  Future<List<EventPlanner>> searchEvents({
    required String query,
    String? schoolId,
    String? classCode,
  }) async {
    try {
      Query firestoreQuery = _firestore.collection('event_planners');
      
      if (schoolId != null) {
        firestoreQuery = firestoreQuery.where('schoolId', isEqualTo: schoolId);
      }
      if (classCode != null) {
        firestoreQuery = firestoreQuery.where('classCode', isEqualTo: classCode);
      }
      
      firestoreQuery = firestoreQuery.where('isActive', isEqualTo: true);
      
      final querySnapshot = await firestoreQuery.get();
      
      // Filter by title, description, or tags containing the search query
      final results = querySnapshot.docs
          .map((doc) => _mapToEventPlanner(doc.id, doc.data() as Map<String, dynamic>))
          .where((event) =>
              event.title.toLowerCase().contains(query.toLowerCase()) ||
              event.description.toLowerCase().contains(query.toLowerCase()) ||
              event.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())))
          .toList();
      
      return results;
    } catch (e) {
      if (kDebugMode) {
        print('Error searching events: $e');
      }
      return [];
    }
  }

  // Event Participant Operations
  Future<String?> createEventParticipant(EventParticipant participant) async {
    try {
      final participantData = {
        'userId': participant.userId,
        'userName': participant.userName,
        'userRole': participant.userRole,
        'participationStatus': participant.participationStatus,
        'joinedAt': participant.joinedAt?.toIso8601String(),
        'notes': participant.notes,
      };
      
      final docRef = await _firestore.collection('event_participants').add(participantData);
      if (kDebugMode) {
        print('Event participant created successfully with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating event participant: $e');
      }
      return null;
    }
  }

  Future<List<EventParticipant>> getEventParticipants(String eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection('event_participants')
          .where('eventId', isEqualTo: eventId)
          .get();
      
      return querySnapshot.docs.map((doc) {
        return _mapToEventParticipant(doc.id, doc.data());
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting event participants: $e');
      }
      return [];
    }
  }

  // Helper methods for mapping Firestore data to models
  EventPlanner _mapToEventPlanner(String id, Map<String, dynamic> data) {
    return EventPlanner(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      eventDate: DateTime.parse(data['eventDate'] ?? DateTime.now().toIso8601String()),
      eventTime: data['eventTime'] ?? '',
      schoolId: data['schoolId'] ?? '',
      classCode: data['classCode'] ?? '',
      type: _parseEventType(data['type']),
      status: _parseEventStatus(data['status']),
      createdBy: data['createdBy'] ?? '',
      creatorName: data['creatorName'] ?? '',
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String()),
      isActive: data['isActive'] ?? true,
      location: data['location'],
      participants: (data['participants'] as List<dynamic>?)
              ?.map((e) => EventParticipant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: data['notes'],
      metadata: data['metadata'] != null ? Map<String, dynamic>.from(data['metadata']) : null,
      tags: List<String>.from(data['tags'] ?? []),
      challengedSchoolId: data['challengedSchoolId'],
      challengedSchoolName: data['challengedSchoolName'],
      visibility: _parseEventVisibility(data['visibility']),
      requiredClassCode: data['requiredClassCode'],
      votesCount: data['votesCount'] ?? 0,
      voters: (data['voters'] as List<dynamic>?)
              ?.map((e) => EventVoter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      challengeAccepted: data['challengeAccepted'] ?? false,
      challengeDeadline: data['challengeDeadline'] != null 
          ? DateTime.parse(data['challengeDeadline']) 
          : null,
    );
  }

  EventParticipant _mapToEventParticipant(String id, Map<String, dynamic> data) {
    return EventParticipant(
      userId: data['userId'] ?? id,
      userName: data['userName'] ?? '',
      userRole: data['userRole'] ?? 'student',
      participationStatus: data['participationStatus'] ?? 'invited',
      joinedAt: data['joinedAt'] != null ? DateTime.parse(data['joinedAt']) : null,
      notes: data['notes'],
    );
  }

  EventType _parseEventType(String? typeString) {
    switch (typeString) {
      case 'parentMeeting':
        return EventType.parentMeeting;
      case 'interClassCompetition':
        return EventType.interClassCompetition;
      case 'interSchoolChallenge':
        return EventType.interSchoolChallenge;
      case 'schoolEvent':
        return EventType.schoolEvent;
      case 'classActivity':
        return EventType.classActivity;
      // Legacy support for old format
      case 'parent_meeting':
        return EventType.parentMeeting;
      case 'inter_class_competition':
        return EventType.interClassCompetition;
      case 'inter_school_challenge':
        return EventType.interSchoolChallenge;
      case 'school_event':
        return EventType.schoolEvent;
      case 'class_activity':
        return EventType.classActivity;
      default:
        return EventType.classActivity;
    }
  }

  EventStatus _parseEventStatus(String? statusString) {
    switch (statusString) {
      case 'planned':
        return EventStatus.planned;
      case 'confirmed':
        return EventStatus.confirmed;
      case 'ongoing':
        return EventStatus.ongoing;
      case 'completed':
        return EventStatus.completed;
      case 'cancelled':
        return EventStatus.cancelled;
      case 'postponed':
        return EventStatus.postponed;
      default:
        return EventStatus.planned;
    }
  }

  EventVisibility _parseEventVisibility(String? visibilityString) {
    switch (visibilityString) {
      case 'internalClass':
      case 'internal_class':
        return EventVisibility.internalClass;
      case 'school':
        return EventVisibility.school;
      case 'public':
        return EventVisibility.public;
      default:
        return EventVisibility.school;
    }
  }

  // Voting system methods
  Future<bool> voteForEvent({
    required String eventId,
    required String userId,
    required String userName,
    required String schoolId,
    required String schoolName,
    String voteType = 'accept',
  }) async {
    try {
      final eventDoc = await _firestore.collection('event_planners').doc(eventId).get();
      if (!eventDoc.exists) {
        if (kDebugMode) {
          print('Event not found: $eventId');
        }
        return false;
      }

      final eventData = eventDoc.data()!;
      final voters = List<Map<String, dynamic>>.from(eventData['voters'] ?? []);
      
      // Check if user already voted
      final existingVoteIndex = voters.indexWhere((voter) => voter['userId'] == userId);
      
      final newVote = {
        'userId': userId,
        'userName': userName,
        'schoolId': schoolId,
        'schoolName': schoolName,
        'votedAt': DateTime.now().toIso8601String(),
        'voteType': voteType,
      };

      if (existingVoteIndex >= 0) {
        // Update existing vote
        voters[existingVoteIndex] = newVote;
      } else {
        // Add new vote
        voters.add(newVote);
      }

      // Update vote count and voters list
      await _firestore.collection('event_planners').doc(eventId).update({
        'voters': voters,
        'votesCount': voters.length,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Check if challenge should be accepted (minimum 14 votes from challenged school)
      final challengedSchoolVotes = voters.where((voter) => 
        voter['schoolId'] == eventData['challengedSchoolId'] && 
        voter['voteType'] == 'accept'
      ).length;

      if (challengedSchoolVotes >= 14 && !eventData['challengeAccepted']) {
        await _firestore.collection('event_planners').doc(eventId).update({
          'challengeAccepted': true,
          'status': EventStatus.confirmed.name,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      if (kDebugMode) {
        print('Vote recorded successfully for event: $eventId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error voting for event: $e');
      }
      return false;
    }
  }

  Future<List<EventPlanner>> getPublicEvents({
    String? excludeSchoolId,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection('event_planners');
      
      query = query.where('visibility', isEqualTo: 'public')
                  .where('isActive', isEqualTo: true)
                  .where('challengeAccepted', isEqualTo: false);
      
      if (excludeSchoolId != null) {
        query = query.where('schoolId', isNotEqualTo: excludeSchoolId);
      }
      
      // Only show events that haven't passed their challenge deadline
      final now = DateTime.now().toIso8601String();
      query = query.where('challengeDeadline', isGreaterThan: now)
                  .orderBy('challengeDeadline', descending: false)
                  .limit(limit);
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        return _mapToEventPlanner(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting public events: $e');
      }
      return [];
    }
  }

  Future<List<EventPlanner>> getVisibleEvents({
    required String schoolId,
    String? classCode,
    int limit = 50,
  }) async {
    try {
      // Get school-wide and public events
      Query query = _firestore.collection('event_planners');
      
      query = query.where('isActive', isEqualTo: true);
      
      final querySnapshot = await query.get();
      
      final allEvents = querySnapshot.docs.map((doc) {
        return _mapToEventPlanner(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      
      // Filter events based on visibility rules
      final visibleEvents = allEvents.where((event) {
        switch (event.visibility) {
          case EventVisibility.internalClass:
            // Only visible if user has the required class code
            return classCode != null && 
                   event.requiredClassCode != null && 
                   classCode == event.requiredClassCode;
          
          case EventVisibility.school:
            // Visible to all users in the same school
            return event.schoolId == schoolId;
          
          case EventVisibility.public:
            // Visible to all schools
            return true;
        }
      }).toList();
      
      // Sort by event date
      visibleEvents.sort((a, b) => a.eventDate.compareTo(b.eventDate));
      
      return visibleEvents.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting visible events: $e');
      }
      return [];
    }
  }

  String _getVisibilityString(EventVisibility visibility) {
    switch (visibility) {
      case EventVisibility.internalClass:
        return 'internal_class';
      case EventVisibility.school:
        return 'school';
      case EventVisibility.public:
        return 'public';
    }
  }
}