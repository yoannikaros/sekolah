import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/social_media_models.dart';
import '../../services/social_media_service.dart';
import '../../services/auth_service.dart';
class CreatePostScreen extends StatefulWidget {
  final SocialMediaPost? editPost;

  const CreatePostScreen({super.key, this.editPost});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final SocialMediaService _socialMediaService = SocialMediaService();
  final AuthService _authService = AuthService();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  
  PostType _selectedType = PostType.status;
  bool _isLoading = false;
  int _characterCount = 0;
  String? _currentClassCode;
  static const int _maxCharacters = 280;

  bool get _isEditing => widget.editPost != null;

  @override
  void initState() {
    super.initState();
    _loadUserClassCode();
    if (_isEditing) {
      _contentController.text = widget.editPost!.originalContent;
      _selectedType = widget.editPost!.type;
      _characterCount = _contentController.text.length;
    }
    _contentController.addListener(_updateCharacterCount);
    
    // Auto focus pada text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contentFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadUserClassCode() async {
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      setState(() {
        _currentClassCode = userProfile?.classCode;
      });
    } catch (e) {
      debugPrint('Error loading class code: $e');
    }
  }

  void _updateCharacterCount() {
    setState(() {
      _characterCount = _contentController.text.length;
    });
  }

  Future<void> _submitPost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konten postingan tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_characterCount > _maxCharacters) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konten terlalu panjang'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        await _socialMediaService.updatePost(
          postId: widget.editPost!.id,
          newContent: _contentController.text.trim(),
        );
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Postingan berhasil diperbarui'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _socialMediaService.createPost(
          content: _contentController.text.trim(),
          type: _selectedType,
          classCode: _currentClassCode,
        );
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Postingan berhasil dibuat'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(
                    LucideIcons.x,
                    color: Color(0xFF6B7280),
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.all(8),
                  child: ElevatedButton(
                    onPressed: _isLoading || _contentController.text.trim().isEmpty
                        ? null
                        : _submitPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _contentController.text.trim().isEmpty
                          ? Colors.grey[300]
                          : const Color(0xFF667EEA),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _isEditing ? 'Perbarui' : 'Posting',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF667EEA),
                                      Color(0xFF764BA2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  LucideIcons.edit3,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isEditing ? 'Edit Postingan' : 'Buat Postingan',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    Text(
                                      _isEditing ? 'Perbarui konten postingan' : 'Bagikan pemikiran Anda',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF6B7280),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
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
            ),
          ];
        },
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernUserInfo(),
              const SizedBox(height: 20),
              if (!_isEditing) _buildModernPostTypeSelector(),
              if (!_isEditing) const SizedBox(height: 20),
              _buildModernContentInput(),
              const SizedBox(height: 16),
              _buildModernCharacterCounter(),
              const SizedBox(height: 24),
              _buildModernGuidelines(),
              const SizedBox(height: 20),
              _buildModernBottomActions(),
              const SizedBox(height: 40), // Extra space for safe area
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernUserInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667EEA),
                  Color(0xFF764BA2),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _socialMediaService.currentUserName.isNotEmpty
                    ? _socialMediaService.currentUserName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _socialMediaService.currentUserName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _selectedType == PostType.topic
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Sedang membuat ${_selectedType == PostType.topic ? 'topik' : 'status'}',
                    style: TextStyle(
                      color: _selectedType == PostType.topic
                          ? const Color(0xFF166534)
                          : const Color(0xFF92400E),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _selectedType == PostType.topic
                  ? LucideIcons.messageSquare
                  : LucideIcons.heart,
              color: const Color(0xFF667EEA),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPostTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Pilih Jenis Postingan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedType = PostType.topic),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _selectedType == PostType.topic
                            ? const Color(0xFF667EEA)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedType == PostType.topic
                              ? const Color(0xFF667EEA)
                              : const Color(0xFFE5E7EB),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _selectedType == PostType.topic
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : const Color(0xFF667EEA).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              LucideIcons.messageSquare,
                              color: _selectedType == PostType.topic
                                  ? Colors.white
                                  : const Color(0xFF667EEA),
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Topik',
                            style: TextStyle(
                              color: _selectedType == PostType.topic
                                  ? Colors.white
                                  : const Color(0xFF1F2937),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Diskusi & Pertanyaan',
                            style: TextStyle(
                              color: _selectedType == PostType.topic
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : const Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedType = PostType.status),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _selectedType == PostType.status
                            ? const Color(0xFF667EEA)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedType == PostType.status
                              ? const Color(0xFF667EEA)
                              : const Color(0xFFE5E7EB),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _selectedType == PostType.status
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : const Color(0xFF667EEA).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              LucideIcons.heart,
                              color: _selectedType == PostType.status
                                  ? Colors.white
                                  : const Color(0xFF667EEA),
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Status',
                            style: TextStyle(
                              color: _selectedType == PostType.status
                                  ? Colors.white
                                  : const Color(0xFF1F2937),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pemikiran & Perasaan',
                            style: TextStyle(
                              color: _selectedType == PostType.status
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : const Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernContentInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              'Tulis Postingan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _contentFocusNode.hasFocus
                      ? const Color(0xFF667EEA)
                      : const Color(0xFFE5E7EB),
                  width: 2,
                ),
              ),
              child: TextField(
                controller: _contentController,
                focusNode: _contentFocusNode,
                maxLines: null,
                minLines: 8,
                maxLength: _maxCharacters,
                decoration: InputDecoration(
                  hintText: _selectedType == PostType.topic
                      ? 'Apa yang ingin kamu diskusikan hari ini?'
                      : 'Apa yang sedang kamu pikirkan?',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                  counterText: '',
                ),
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Color(0xFF1F2937),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCharacterCounter() {
    final isOverLimit = _characterCount > _maxCharacters;
    final isNearLimit = _characterCount > _maxCharacters * 0.8;
    final progress = _characterCount / _maxCharacters;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isOverLimit
                ? const Color(0xFFFEE2E2)
                : isNearLimit
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isOverLimit
                  ? const Color(0xFFEF4444)
                  : isNearLimit
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF3B82F6),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: progress > 1 ? 1 : progress,
                  strokeWidth: 3,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverLimit
                        ? const Color(0xFFEF4444)
                        : isNearLimit
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF3B82F6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$_characterCount/$_maxCharacters',
                style: TextStyle(
                  color: isOverLimit
                      ? const Color(0xFFEF4444)
                      : isNearLimit
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF3B82F6),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernGuidelines() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.shield,
                  size: 20,
                  color: Color(0xFF166534),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Panduan Komunitas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildModernGuidelineItem(
            LucideIcons.heart,
            'Gunakan bahasa yang sopan dan menghormati',
            const Color(0xFF667EEA),
          ),
          _buildModernGuidelineItem(
            LucideIcons.users,
            'Hindari konten yang mengandung SARA',
            const Color(0xFFEF4444),
          ),
          _buildModernGuidelineItem(
            LucideIcons.target,
            'Pastikan konten relevan dengan komunitas',
            const Color(0xFF10B981),
          ),
          _buildModernGuidelineItem(
            LucideIcons.eye,
            'Konten akan dimoderasi secara otomatis',
            const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildModernGuidelineItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Siap untuk berbagi?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Postingan Anda akan terlihat oleh ${_currentClassCode != null ? 'teman sekelas dan ' : ''}komunitas SeKangkatan.',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, size: 18),
                  label: const Text('Batal'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isLoading || _contentController.text.trim().isEmpty
                      ? null
                      : _submitPost,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(LucideIcons.send, size: 18),
                  label: Text(_isEditing ? 'Perbarui' : 'Posting'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}