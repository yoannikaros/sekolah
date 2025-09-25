import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/event_planner_models.dart';
import '../../models/admin_models.dart';
import '../../services/event_planner_service.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';

class PublicEventsScreen extends StatefulWidget {
  const PublicEventsScreen({super.key});

  @override
  State<PublicEventsScreen> createState() => _PublicEventsScreenState();
}

class _PublicEventsScreenState extends State<PublicEventsScreen> {
  final EventPlannerService _eventService = EventPlannerService();
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();

  List<EventPlanner> _publicEvents = [];
  List<School> _schools = [];
  bool _isLoading = true;
  String? _currentUserId;
  String? _currentSchoolId;
  String? _currentSchoolName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user info
      final user = _authService.currentUser;
      if (user != null) {
        _currentUserId = user.uid;
        
        // Try to get user's school info from different user types
        // First try as teacher
        final teacher = await _authService.getCurrentTeacher();
        if (teacher != null) {
          _currentSchoolId = teacher.schoolId;
          
          // Get school name
          final school = await _adminService.getSchoolById(_currentSchoolId!);
          if (school != null) {
            _currentSchoolName = school.name;
          }
        } else {
          // Try as student
          final student = await _adminService.getStudentById(_currentUserId!);
          if (student != null) {
            _currentSchoolId = student.schoolId;
            
            // Get school name
            final school = await _adminService.getSchoolById(_currentSchoolId!);
            if (school != null) {
              _currentSchoolName = school.name;
            }
          }
        }
      }

      // Load public events (excluding current user's school)
      final events = await _eventService.getPublicEvents(
        excludeSchoolId: _currentSchoolId,
      );
      
      // Load all schools for reference
      final schools = await _adminService.getAllSchools();

      setState(() {
        _publicEvents = events;
        _schools = schools;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading public events: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _voteForEvent(EventPlanner event, String voteType) async {
    if (_currentUserId == null || _currentSchoolId == null || _currentSchoolName == null) {
      _showMessage('Error: User information not available');
      return;
    }

    try {
      final success = await _eventService.voteForEvent(
        eventId: event.id,
        userId: _currentUserId!,
        userName: 'Current User', // You might want to get actual user name
        schoolId: _currentSchoolId!,
        schoolName: _currentSchoolName!,
        voteType: voteType,
      );

      if (success) {
        _showMessage(voteType == 'accept' ? 'Vote berhasil! Anda menerima tantangan.' : 'Vote berhasil! Anda menolak tantangan.');
        _loadData(); // Refresh the list
      } else {
        _showMessage('Gagal memberikan vote. Silakan coba lagi.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error voting: $e');
      }
      _showMessage('Terjadi error saat memberikan vote.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _getSchoolName(String schoolId) {
    final school = _schools.firstWhere(
      (s) => s.id == schoolId,
      orElse: () => School(
        id: '',
        name: 'Sekolah Tidak Ditemukan',
        address: '',
        phone: '',
        email: '',
        createdAt: DateTime.now(),
        isActive: true,
      ),
    );
    return school.name;
  }

  IconData _getTypeIcon(EventType type) {
    switch (type) {
      case EventType.parentMeeting:
        return Icons.people;
      case EventType.interClassCompetition:
        return Icons.emoji_events;
      case EventType.interSchoolChallenge:
        return Icons.school;
      case EventType.schoolEvent:
        return Icons.event;
      case EventType.classActivity:
        return Icons.class_;
    }
  }

  bool _hasUserVoted(EventPlanner event) {
    if (_currentUserId == null) return false;
    return event.voters.any((voter) => voter.userId == _currentUserId);
  }

  String? _getUserVoteType(EventPlanner event) {
    if (_currentUserId == null) return null;
    final userVote = event.voters.firstWhere(
      (voter) => voter.userId == _currentUserId,
      orElse: () => EventVoter(
        userId: '',
        userName: '',
        schoolId: '',
        schoolName: '',
        votedAt: DateTime.now(),
        voteType: '',
      ),
    );
    return userVote.userId.isNotEmpty ? userVote.voteType : null;
  }

  int _getAcceptVotesFromChallengedSchool(EventPlanner event) {
    return event.voters.where((voter) => 
      voter.schoolId == event.challengedSchoolId && 
      voter.voteType == 'accept'
    ).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Publik'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _publicEvents.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.public_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Belum ada event publik',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Event publik adalah tantangan antar sekolah yang membutuhkan minimal 14 vote untuk diterima',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _publicEvents.length,
                    itemBuilder: (context, index) {
                      final event = _publicEvents[index];
                      final hasVoted = _hasUserVoted(event);
                      final userVoteType = _getUserVoteType(event);
                      final acceptVotes = _getAcceptVotesFromChallengedSchool(event);
                      final isDeadlinePassed = event.challengeDeadline != null && 
                          DateTime.now().isAfter(event.challengeDeadline!);

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
                                  Icon(
                                    _getTypeIcon(event.type),
                                    color: const Color(0xFF6366F1),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      event.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withAlpha(25),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.purple,
                                        width: 1,
                                      ),
                                    ),
                                    child: const Text(
                                      'PUBLIK',
                                      style: TextStyle(
                                        color: Colors.purple,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                event.description,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${event.eventDate.day}/${event.eventDate.month}/${event.eventDate.year}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    event.eventTime,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.school,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Dari: ${_getSchoolName(event.schoolId)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              if (event.challengedSchoolName != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.flag,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Menantang: ${event.challengedSchoolName}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (event.challengeDeadline != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      size: 16,
                                      color: isDeadlinePassed ? Colors.red : Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Deadline: ${event.challengeDeadline!.day}/${event.challengeDeadline!.month}/${event.challengeDeadline!.year}',
                                      style: TextStyle(
                                        color: isDeadlinePassed ? Colors.red : Colors.orange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 12),
                              
                              // Voting Progress
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.how_to_vote,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Status Voting',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: LinearProgressIndicator(
                                            value: acceptVotes / 14,
                                            backgroundColor: Colors.grey[300],
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              acceptVotes >= 14 ? Colors.green : Colors.blue,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '$acceptVotes/14',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      acceptVotes >= 14 
                                          ? 'Tantangan diterima!' 
                                          : 'Butuh ${14 - acceptVotes} vote lagi untuk menerima tantangan',
                                      style: TextStyle(
                                        color: acceptVotes >= 14 ? Colors.green : Colors.grey[600],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Voting Buttons
                              if (_currentSchoolId == event.challengedSchoolId && !isDeadlinePassed) ...[
                                if (!hasVoted) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _voteForEvent(event, 'accept'),
                                          icon: const Icon(Icons.check, size: 16),
                                          label: const Text('Terima Tantangan'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _voteForEvent(event, 'reject'),
                                          icon: const Icon(Icons.close, size: 16),
                                          label: const Text('Tolak Tantangan'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: userVoteType == 'accept' ? Colors.green[50] : Colors.red[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: userVoteType == 'accept' ? Colors.green : Colors.red,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          userVoteType == 'accept' ? Icons.check_circle : Icons.cancel,
                                          color: userVoteType == 'accept' ? Colors.green : Colors.red,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          userVoteType == 'accept' 
                                              ? 'Anda telah menerima tantangan' 
                                              : 'Anda telah menolak tantangan',
                                          style: TextStyle(
                                            color: userVoteType == 'accept' ? Colors.green : Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ] else if (_currentSchoolId != event.challengedSchoolId) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.grey,
                                        size: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Hanya sekolah yang ditantang yang bisa memberikan vote',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else if (isDeadlinePassed) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.timer_off,
                                        color: Colors.red,
                                        size: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Waktu voting telah berakhir',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}