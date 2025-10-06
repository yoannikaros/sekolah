import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'services/event_planner_service.dart';
import 'models/event_planner_models.dart';

class TestEventService extends StatefulWidget {
  const TestEventService({super.key});

  @override
  State<TestEventService> createState() => _TestEventServiceState();
}

class _TestEventServiceState extends State<TestEventService> {
  final EventPlannerService _eventPlannerService = EventPlannerService();
  bool _isLoading = false;
  String _testResults = '';

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  Future<void> _runTests() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Starting tests...\n';
    });

    try {
      // Test 1: Get all events
      _addTestResult('=== Test 1: Getting all events ===');
      final events = await _eventPlannerService.getAllEventPlanners();
      _addTestResult('Events found: ${events.length}');
      
      if (events.isNotEmpty) {
        _addTestResult('First event details:');
        final firstEvent = events.first;
        _addTestResult('- ID: ${firstEvent.id}');
        _addTestResult('- Title: ${firstEvent.title}');
        _addTestResult('- Type: ${firstEvent.type}');
        _addTestResult('- Status: ${firstEvent.status}');
        _addTestResult('- IsActive: ${firstEvent.isActive}');
        _addTestResult('- EventDate: ${firstEvent.eventDate}');
        _addTestResult('- SchoolId: ${firstEvent.schoolId}');
        _addTestResult('- ClassCode: ${firstEvent.classCode}');
      } else {
        _addTestResult('No events found!');
      }

      // Test 2: Create a test event
      _addTestResult('\n=== Test 2: Creating test event ===');
      final testEvent = EventPlanner(
        id: '',
        title: 'Test Event ${DateTime.now().millisecondsSinceEpoch}',
        description: 'This is a test event created for debugging',
        eventDate: DateTime.now().add(const Duration(days: 1)),
        eventTime: '10:00',
        schoolId: 'test_school',
        classCode: 'TEST001',
        type: EventType.classActivity,
        status: EventStatus.planned,
        createdBy: 'test_admin',
        creatorName: 'Test Admin',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        location: 'Test Location',
        participants: [],
        notes: 'Test notes',
        metadata: {},
        tags: ['test', 'debug'],
        challengedSchoolId: null,
        challengedSchoolName: null,
      );

      final createdId = await _eventPlannerService.createEventPlanner(testEvent);
      if (createdId != null) {
        _addTestResult('Test event created successfully with ID: $createdId');
        
        // Test 3: Get the created event
        _addTestResult('\n=== Test 3: Getting created event ===');
        final retrievedEvent = await _eventPlannerService.getEventPlannerById(createdId);
        if (retrievedEvent != null) {
          _addTestResult('Retrieved event successfully:');
          _addTestResult('- Title: ${retrievedEvent.title}');
          _addTestResult('- Type: ${retrievedEvent.type}');
          _addTestResult('- Status: ${retrievedEvent.status}');
        } else {
          _addTestResult('Failed to retrieve created event!');
        }

        // Test 4: Get all events again
        _addTestResult('\n=== Test 4: Getting all events after creation ===');
        final eventsAfter = await _eventPlannerService.getAllEventPlanners();
        _addTestResult('Events found after creation: ${eventsAfter.length}');

        // Clean up: Delete the test event
        _addTestResult('\n=== Cleanup: Deleting test event ===');
        final deleted = await _eventPlannerService.deleteEventPlanner(createdId);
        _addTestResult('Test event deleted: $deleted');
      } else {
        _addTestResult('Failed to create test event!');
      }

      setState(() {
        _isLoading = false;
      });

    } catch (e, stackTrace) {
      _addTestResult('\n=== ERROR ===');
      _addTestResult('Error: $e');
      _addTestResult('Stack trace: $stackTrace');
      setState(() => _isLoading = false);
    }
  }

  void _addTestResult(String result) {
    setState(() {
      _testResults += '$result\n';
    });
    if (kDebugMode) {
      debugPrint(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Event Service'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runTests,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Results:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _testResults,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}