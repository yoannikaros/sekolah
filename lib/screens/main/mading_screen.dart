import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import '../../models/mading_models.dart';
import '../../services/mading_service.dart';
import 'mading_upload_screen.dart';
import 'mading_detail_screen.dart';

class MadingScreen extends StatefulWidget {
  final String schoolId;
  final String currentUserId;
  final String currentUserRole;

  const MadingScreen({
    super.key,
    required this.schoolId,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<MadingScreen> createState() => _MadingScreenState();
}

class _MadingScreenState extends State<MadingScreen>
    with SingleTickerProviderStateMixin {
  final MadingService _madingService = MadingService();
  late TabController _tabController;
  String? _selectedSubjectId;
  List<Subject> _subjects = [];

  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(length: 2, vsync: this);
    _loadSubjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadSubjects() {
    _madingService.getSubjectsBySchool(widget.schoolId).listen(
      (subjects) {
        setState(() {
          _subjects = subjects;
        });
      },
      onError: (error) {
        // Handle error silently or show user-friendly message
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Mading Digital',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF2D3748),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        surfaceTintColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.tune_rounded,
                color: Color(0xFF667EEA),
                size: 22,
              ),
              onPressed: _showFilterDialog,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF667EEA),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.grid_view_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Semua Karya'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.subject_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Mata Pelajaran'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllPostsTab(),
          _buildSubjectsTab(),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MadingUploadScreen(
                  schoolId: widget.schoolId,
                  currentUserId: widget.currentUserId,
                  currentUserRole: widget.currentUserRole,
                  subjects: _subjects,
                ),
              ),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(
            Icons.add_photo_alternate_rounded,
            color: Colors.white,
            size: 22,
          ),
          label: const Text(
            'Upload Karya',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllPostsTab() {
    return StreamBuilder<List<MadingPost>>(
      stream: _selectedSubjectId == null
          ? _madingService.getMadingPostsBySchool(widget.schoolId)
          : _madingService.getMadingPostsBySubject(widget.schoolId, _selectedSubjectId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[400]),
                ),
                const SizedBox(height: 16),
                Text(
                  'Terjadi kesalahan',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.photo_library_outlined, 
                    size: 64, 
                    color: const Color(0xFF667EEA),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Belum ada karya yang dipublikasikan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Jadilah yang pertama untuk berbagi karya!',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          color: const Color(0xFF667EEA),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildStickyNoteCard(posts[index], index);
                    },
                    childCount: posts.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubjectsTab() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildSubjectCard(_subjects[index]);
              },
              childCount: _subjects.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStickyNoteCard(MadingPost post, int index) {
    final isLiked = post.likedBy.contains(widget.currentUserId);
    
    // Generate random colors for sticky note effect
    final colors = [
      const Color(0xFFFFF2CC), // Yellow
      const Color(0xFFE1F5FE), // Light Blue
      const Color(0xFFF3E5F5), // Light Purple
      const Color(0xFFE8F5E8), // Light Green
      const Color(0xFFFFE0E6), // Light Pink
      const Color(0xFFFFF3E0), // Light Orange
    ];
    
    final stickyColor = colors[index % colors.length];
    
    // Random rotation for sticky note effect
    final rotation = (math.Random(index).nextDouble() - 0.5) * 0.1;
    
    return Transform.rotate(
      angle: rotation,
      child: Container(
        decoration: BoxDecoration(
          color: stickyColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToDetail(post),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with avatar and name
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            post.studentName.isNotEmpty ? post.studentName[0].toUpperCase() : 'S',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.studentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF2D3748),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              post.studentClass,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Image with rounded corners
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Hero(
                          tag: 'post_image_${post.id}',
                          child: CachedNetworkImage(
                            imageUrl: post.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.error_rounded, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Description
                  if (post.description.isNotEmpty)
                    Text(
                      post.description,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        color: Color(0xFF4A5568),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Actions row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _toggleLike(post.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLiked ? Colors.red[50] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isLiked ? Colors.red : Colors.grey[600],
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post.likesCount}',
                                style: TextStyle(
                                  color: isLiked ? Colors.red : Colors.grey[600],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      GestureDetector(
                        onTap: () => _navigateToDetail(post, autoFocusComment: true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: Colors.grey[600],
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post.commentsCount}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Subject badge
                      // if (post.subjectId != null)
                      //   Container(
                      //     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      //     decoration: BoxDecoration(
                      //       color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                      //       borderRadius: BorderRadius.circular(8),
                      //     ),
                      //     child: Text(
                      //       _getSubjectName(post.subjectId!),
                      //       style: const TextStyle(
                      //         color: Color(0xFF667EEA),
                      //         fontSize: 8,
                      //         fontWeight: FontWeight.w600,
                      //       ),
                      //       maxLines: 1,
                      //       overflow: TextOverflow.ellipsis,
                      //     ),
                      //   ),
                      
                      // Menu button
                      if (post.studentId == widget.currentUserId || widget.currentUserRole == 'teacher')
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deletePost(post.id);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_rounded, color: Colors.red, size: 16),
                                  SizedBox(width: 8),
                                  Text('Hapus', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.more_vert_rounded, 
                              color: Colors.grey[600], 
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(MadingPost post, {bool autoFocusComment = false}) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => MadingDetailScreen(
          post: post,
          currentUserId: widget.currentUserId,
          currentUserRole: widget.currentUserRole,
          autoFocusComment: autoFocusComment,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildSubjectCard(Subject subject) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _selectedSubjectId = subject.id;
              _tabController.animateTo(0);
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getSubjectColor(subject.color),
                        _getSubjectColor(subject.color).withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _getSubjectColor(subject.color).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.book_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (subject.description != null)
                        Text(
                          subject.description!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF667EEA),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Mata Pelajaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Semua Mata Pelajaran'),
              leading: Radio<String?>(
                value: null,
                groupValue: _selectedSubjectId,
                onChanged: (value) {
                  setState(() {
                    _selectedSubjectId = value;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ..._subjects.map((subject) => ListTile(
              title: Text(subject.name),
              leading: Radio<String?>(
                value: subject.id,
                groupValue: _selectedSubjectId,
                onChanged: (value) {
                  setState(() {
                    _selectedSubjectId = value;
                  });
                  Navigator.pop(context);
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _toggleLike(String postId) {
    _madingService.toggleLikePost(postId, widget.currentUserId);
  }

  void _deletePost(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Karya'),
        content: const Text('Apakah Anda yakin ingin menghapus karya ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _madingService.deletePost(postId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Karya berhasil dihapus')),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getSubjectColor(String? colorHex) {
    if (colorHex != null && colorHex.isNotEmpty) {
      try {
        return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
      } catch (e) {
        return Colors.indigo;
      }
    }
    return Colors.indigo;
  }


}