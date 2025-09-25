import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/event_planner_models.dart';
import '../../services/event_planner_service.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';

class EventPlannerStudentScreen extends StatefulWidget {
  final String? classCode;
  
  const EventPlannerStudentScreen({super.key, this.classCode});

  @override
  State<EventPlannerStudentScreen> createState() => _EventPlannerStudentScreenState();
}

class _EventPlannerStudentScreenState extends State<EventPlannerStudentScreen>
    with TickerProviderStateMixin {
  final EventPlannerService _eventPlannerService = EventPlannerService();
  final AuthService _authService = AuthService();
  final AdminService _adminService = AdminService();
  final TextEditingController _classCodeController = TextEditingController();
  
  List<EventPlanner> _classEvents = [];
  List<EventPlanner> _schoolEvents = [];
  List<EventPlanner> _publicEvents = [];
  bool _isLoading = false;
  bool _hasEnteredClassCode = false;
  String? _currentClassCode;
  String? _currentSchoolId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _cardAnimationController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getCurrentUser();
    _checkSavedClassCode();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _animationController.forward();
  }

  Future<void> _getCurrentUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        // User authenticated
      });
    }
  }

  Future<void> _loadEvents() async {
    if (_currentClassCode == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Get school ID from class code
      await _getSchoolIdFromClassCode();
      
      // Load class events
      final classEvents = await _eventPlannerService.getUpcomingEvents(
        classCode: _currentClassCode,
        limit: 50,
      );
      
      // Load school events if we have school ID
      List<EventPlanner> schoolEvents = [];
      if (_currentSchoolId != null) {
        schoolEvents = await _eventPlannerService.getVisibleEvents(
          schoolId: _currentSchoolId!,
          classCode: _currentClassCode!,
        );
        // Filter to only school-wide events
        schoolEvents = schoolEvents.where((event) => 
          event.visibility == EventVisibility.school && 
          event.classCode != _currentClassCode
        ).toList();
      }
      
      // Load public events
      final publicEvents = await _eventPlannerService.getVisibleEvents(
        schoolId: _currentSchoolId ?? '',
        classCode: _currentClassCode!,
      );
      // Filter to only public events
      final filteredPublicEvents = publicEvents.where((event) => 
        event.visibility == EventVisibility.public
      ).toList();
      
      setState(() {
        _classEvents = classEvents;
        _schoolEvents = schoolEvents;
        _publicEvents = filteredPublicEvents;
        _isLoading = false;
      });
      
      _cardAnimationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _getSchoolIdFromClassCode() async {
    try {
      if (_currentClassCode != null) {
        // Get ClassCode object to access schoolId
        final classCodeObj = await _adminService.getClassCodeById(_currentClassCode!);
        if (classCodeObj != null) {
          setState(() {
            _currentSchoolId = classCodeObj.schoolId;
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting school ID: $e');
    }
  }

  Future<void> _checkSavedClassCode() async {
    try {
      String? savedClassCode;
      
      // Check if class code was passed as parameter first
      if (widget.classCode != null && widget.classCode!.isNotEmpty) {
        savedClassCode = widget.classCode;
      } else {
        // Check Firebase user profile for saved class code
        final userProfile = await _authService.getCurrentUserProfile();
        savedClassCode = userProfile?.classCode;
      }
      
      if (savedClassCode != null && savedClassCode.isNotEmpty) {
        setState(() {
          _currentClassCode = savedClassCode;
          _hasEnteredClassCode = true;
          _classCodeController.text = savedClassCode ?? '';
        });
        _loadEvents();
      }
    } catch (e) {
      // If there's an error, just continue with normal flow
      debugPrint('Error checking saved class code: $e');
    }
  }

  void _submitClassCode() async {
    final classCode = _classCodeController.text.trim();
    if (classCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan kode kelas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Save class code to Firebase user profile
    try {
      await _authService.updateUserClassCode(classCode.toUpperCase());
    } catch (e) {
       debugPrint('Error saving class code: $e');
     }

    setState(() {
      _currentClassCode = classCode;
      _hasEnteredClassCode = true;
    });
    
    _loadEvents();
    
    // Haptic feedback untuk interaksi yang menyenangkan
    HapticFeedback.lightImpact();
  }

  void _changeClassCode() {
    setState(() {
      _hasEnteredClassCode = false;
      _currentClassCode = null;
      _currentSchoolId = null;
      _classEvents.clear();
      _schoolEvents.clear();
      _publicEvents.clear();
    });
    _classCodeController.clear();
    _cardAnimationController.reset();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    _classCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: !_hasEnteredClassCode ? _buildClassCodeInput() : _buildEventsList(),
        ),
      ),
    );
  }

  Widget _buildClassCodeInput() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
          ],
        ),
      ),
      child: Column(
        children: [
          // Header dengan ilustrasi
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ilustrasi SVG sederhana menggunakan Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: const Icon(
                      Icons.event_note_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Event Kelas Saya',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Lihat semua event menarik di kelasmu!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          // Form input kode kelas
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    const Text(
                      'Masukkan Kode Kelas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tanyakan kode kelas kepada guru atau wali kelasmu',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Input field dengan desain menarik
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _classCodeController,
                        decoration: InputDecoration(
                          hintText: 'Contoh: 6A-2024',
                          prefixIcon: const Icon(
                            Icons.class_rounded,
                            color: Color(0xFF6366F1),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        onSubmitted: (_) => _submitClassCode(),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Tombol submit dengan animasi
                    ElevatedButton(
                      onPressed: _submitClassCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_rounded),
                          SizedBox(width: 8),
                          Text(
                            'Lihat Event Kelas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Tips untuk siswa
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            color: Color(0xFF0EA5E9),
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Kode kelas biasanya terdiri dari nama kelas dan tahun, seperti "6A-2024"',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF0369A1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return Column(
      children: [
        // Header dengan kode kelas
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
              ],
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _changeClassCode,
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Event Kelas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _currentClassCode ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _loadEvents,
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Daftar event
        Expanded(
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Memuat event...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                )
              : _hasNoEvents()
                  ? _buildEmptyState()
                  : _buildAllEventsGrid(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                size: 50,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum Ada Event',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Belum ada event yang dijadwalkan untuk kelas ini. Coba periksa lagi nanti!',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadEvents,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Muat Ulang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasNoEvents() {
    return _classEvents.isEmpty && _schoolEvents.isEmpty && _publicEvents.isEmpty;
  }

  Widget _buildAllEventsGrid() {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Class Events Section
              if (_classEvents.isNotEmpty) ...[
                _buildSectionHeader(
                  'Event Kelas',
                  'Event khusus untuk kelas $_currentClassCode',
                  Icons.class_rounded,
                  const Color(0xFF6366F1),
                ),
                const SizedBox(height: 12),
                ..._buildEventsListWidgets(_classEvents, 0),
                const SizedBox(height: 24),
              ],
              
              // School Events Section
              if (_schoolEvents.isNotEmpty) ...[
                _buildSectionHeader(
                  'Event Sekolah',
                  'Event untuk seluruh sekolah',
                  Icons.school_rounded,
                  const Color(0xFF10B981),
                ),
                const SizedBox(height: 12),
                ..._buildEventsListWidgets(_schoolEvents, _classEvents.length),
                const SizedBox(height: 24),
              ],
              
              // Public Events Section
              if (_publicEvents.isNotEmpty) ...[
                _buildSectionHeader(
                  'Event Publik',
                  'Event terbuka untuk umum',
                  Icons.public_rounded,
                  const Color(0xFFF59E0B),
                ),
                const SizedBox(height: 12),
                ..._buildEventsListWidgets(_publicEvents, _classEvents.length + _schoolEvents.length),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEventsListWidgets(List<EventPlanner> events, int startIndex) {
    return events.asMap().entries.map((entry) {
      final index = entry.key;
      final event = entry.value;
      final globalIndex = startIndex + index;
      
      final animationDelay = globalIndex * 0.1;
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _cardAnimationController,
          curve: Interval(
            animationDelay,
            (animationDelay + 0.3).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
      
      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _cardAnimationController,
          curve: Interval(
            animationDelay,
            (animationDelay + 0.3).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      );

      return SlideTransition(
        position: slideAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: _buildEventCard(event),
        ),
      );
    }).toList();
  }

  Widget _buildEventCard(EventPlanner event) {
    final eventColor = _getEventColor(event.type);
    final eventIcon = _getEventIcon(event.type);
    final isUpcoming = event.eventDate.isAfter(DateTime.now());
    final visibilityLabel = _getVisibilityLabel(event.visibility);
    final visibilityColor = _getVisibilityColor(event.visibility);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showEventDetails(event),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  visibilityColor.withValues(alpha: 0.1),
                  visibilityColor.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(
                color: visibilityColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: eventColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        eventIcon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                _getEventTypeLabel(event.type),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: eventColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: visibilityColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  visibilityLabel,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isUpcoming)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Akan Datang',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  event.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(event.eventDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      event.eventTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (event.location != null) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.location!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getVisibilityLabel(EventVisibility visibility) {
    switch (visibility) {
      case EventVisibility.internalClass:
        return 'Kelas';
      case EventVisibility.school:
        return 'Sekolah';
      case EventVisibility.public:
        return 'Publik';
    }
  }

  Color _getVisibilityColor(EventVisibility visibility) {
    switch (visibility) {
      case EventVisibility.internalClass:
        return const Color(0xFF6366F1);
      case EventVisibility.school:
        return const Color(0xFF10B981);
      case EventVisibility.public:
        return const Color(0xFFF59E0B);
    }
  }

  void _showEventDetails(EventPlanner event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEventDetailsModal(event),
    );
  }

  Widget _buildEventDetailsModal(EventPlanner event) {
    final eventColor = _getEventColor(event.type);
    final eventIcon = _getEventIcon(event.type);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  eventColor.withValues(alpha: 0.1),
                  eventColor.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: eventColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    eventIcon,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getEventTypeLabel(event.type),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: eventColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Deskripsi
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Detail waktu dan tempat
                  const Text(
                    'Detail Event',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDetailRow(
                    Icons.calendar_today_rounded,
                    'Tanggal',
                    _formatDate(event.eventDate),
                  ),
                  _buildDetailRow(
                    Icons.access_time_rounded,
                    'Waktu',
                    event.eventTime,
                  ),
                  if (event.location != null)
                    _buildDetailRow(
                      Icons.location_on_rounded,
                      'Lokasi',
                      event.location!,
                    ),
                  _buildDetailRow(
                    Icons.person_rounded,
                    'Dibuat oleh',
                    event.creatorName,
                  ),
                  
                  if (event.notes != null && event.notes!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Catatan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        event.notes!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF6366F1),
          ),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getEventColor(EventType type) {
    switch (type) {
      case EventType.parentMeeting:
        return const Color(0xFF8B5CF6);
      case EventType.interClassCompetition:
        return const Color(0xFFF59E0B);
      case EventType.interSchoolChallenge:
        return const Color(0xFFEF4444);
      case EventType.schoolEvent:
        return const Color(0xFF10B981);
      case EventType.classActivity:
        return const Color(0xFF6366F1);
    }
  }

  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.parentMeeting:
        return Icons.people_rounded;
      case EventType.interClassCompetition:
        return Icons.emoji_events_rounded;
      case EventType.interSchoolChallenge:
        return Icons.school_rounded;
      case EventType.schoolEvent:
        return Icons.event_rounded;
      case EventType.classActivity:
        return Icons.class_rounded;
    }
  }

  String _getEventTypeLabel(EventType type) {
    switch (type) {
      case EventType.parentMeeting:
        return 'Pertemuan Orang Tua';
      case EventType.interClassCompetition:
        return 'Lomba Antar Kelas';
      case EventType.interSchoolChallenge:
        return 'Tantangan Antar Sekolah';
      case EventType.schoolEvent:
        return 'Event Sekolah';
      case EventType.classActivity:
        return 'Kegiatan Kelas';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}