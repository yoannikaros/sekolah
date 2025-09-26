import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'models/event_planner_models.dart';
import 'services/event_planner_service.dart';

class CreateTestEvent extends StatefulWidget {
  const CreateTestEvent({super.key});

  @override
  State<CreateTestEvent> createState() => _CreateTestEventState();
}

class _CreateTestEventState extends State<CreateTestEvent> {
  final EventPlannerService _eventPlannerService = EventPlannerService();
  bool _isLoading = false;
  String _result = '';

  Future<void> _createTestEventForIPA() async {
    setState(() {
      _isLoading = true;
      _result = 'Creating test event for IPA class code...';
    });

    try {
      final testEvent = EventPlanner(
        id: '',
        title: 'Test Event untuk Kelas IPA',
        description: 'Event test untuk debugging class code IPA',
        eventDate: DateTime.now().add(const Duration(days: 1)),
        eventTime: '10:00',
        schoolId: '', // Empty schoolId to match IPA class code
        classCode: 'IPA',
        type: EventType.classActivity,
        status: EventStatus.planned,
        createdBy: 'admin',
        creatorName: 'Admin Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        location: 'Ruang Kelas IPA',
        participants: [],
        notes: 'Event test untuk debugging',
        metadata: {},
        tags: ['test', 'debug', 'ipa'],
        challengedSchoolId: null,
        challengedSchoolName: null,
        visibility: EventVisibility.internalClass,
        requiredClassCode: 'IPA',
        votesCount: 0,
        voters: [],
        challengeAccepted: false,
        challengeDeadline: null,
      );

      final createdId = await _eventPlannerService.createEventPlanner(testEvent);
      
      if (createdId != null) {
        setState(() {
          _result = 'Test event created successfully!\nEvent ID: $createdId\nClass Code: IPA\nTitle: ${testEvent.title}';
        });
        
        if (kDebugMode) {
          print('Test event created for IPA class code with ID: $createdId');
        }
      } else {
        setState(() {
          _result = 'Failed to create test event!';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error creating test event: $e';
      });
      
      if (kDebugMode) {
        print('Error creating test event: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Test Event'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _createTestEventForIPA,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Create Test Event for IPA'),
            ),
            const SizedBox(height: 20),
            if (_result.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _result,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}