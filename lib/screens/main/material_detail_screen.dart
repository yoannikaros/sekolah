import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/materi_models.dart';
import '../../services/materi_service.dart';

class MaterialDetailScreen extends StatefulWidget {
  final Materi material;

  const MaterialDetailScreen({
    super.key,
    required this.material,
  });

  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen> with TickerProviderStateMixin {
  final MateriService _materiService = MateriService();
  MateriWithDetails? _materialWithDetails;
  bool _isLoading = true;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _bounceController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _bounceAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    _loadMaterialDetails();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterialDetails() async {
    try {
      setState(() => _isLoading = true);
      
      if (kDebugMode) {
        print('Loading material details for ID: ${widget.material.id}');
      }

      final materialDetails = await _materiService.getMateriWithDetails(widget.material.id);
      
      setState(() {
        _materialWithDetails = materialDetails;
      });

      // Start animations after loading
      if (_materialWithDetails != null) {
        _fadeController.forward();
        _slideController.forward();
        _bounceController.forward();
      }

      if (kDebugMode) {
        print('Loaded material details: ${materialDetails?.materi.judul}');
        print('Details count: ${materialDetails?.details.length ?? 0}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading material details: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Get dynamic colors based on subject
  Color _getSubjectColor(String subjectName) {
    final colors = [
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    
    final index = subjectName.hashCode % colors.length;
    return colors[index.abs()];
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka link: $e')),
        );
      }
    }
  }

  Widget _buildYouTubeEmbed(String embedCode) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Container(
            width: double.infinity,
            height: 220,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[400]!, Colors.red[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  spreadRadius: 2,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background pattern
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                // Content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated play button
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1000),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, bounceValue, child) {
                          return Transform.scale(
                            scale: 1.0 + (0.1 * (1 - bounceValue)),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.play_arrow,
                                size: 40,
                                color: Colors.red[600],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '🎬 Video Pembelajaran',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Tap untuk menonton di YouTube',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachment(String attachmentUrl) {
    final fileName = attachmentUrl.split('/').last;
    final isImage = attachmentUrl.toLowerCase().contains(RegExp(r'\.(jpg|jpeg|png|gif|bmp|webp)'));
    
    if (isImage) {
      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 500),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.9 + (0.1 * value),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.network(
                      attachmentUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.purple[100]!, Colors.purple[200]!],
                            ),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey[200]!, Colors.grey[300]!],
                            ),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('📷 Gambar tidak dapat dimuat', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Overlay with emoji
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('🖼️', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else {
      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[50]!, Colors.blue[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[200]!, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => _launchUrl(attachmentUrl),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[400]!, Colors.blue[600]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.attach_file,
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
                              '📎 $fileName',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Tap untuk membuka',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.open_in_new,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.material.judul,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1500),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: value * 2 * 3.14159,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue[300]!, Colors.blue[500]!],
                              ),
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.school,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[50]!, Colors.blue[100]!],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue[200]!, width: 2),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '📖 Sedang Memuat...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tunggu sebentar ya! ⏳',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _materialWithDetails == null
              ? Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1000),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.rotate(
                              angle: value * 2 * 3.14159,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.orange[300]!, Colors.orange[500]!],
                                  ),
                                  borderRadius: BorderRadius.circular(40),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withValues(alpha: 0.3),
                                      spreadRadius: 2,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.error_outline,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.orange[50]!, Colors.orange[100]!],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.orange[200]!, width: 2),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '😔 Oops!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Materi tidak ditemukan',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Materi mungkin telah dihapus atau tidak tersedia',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMaterialDetails,
                  color: _getSubjectColor(_materialWithDetails!.subjectName),
                  backgroundColor: Colors.white,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Enhanced Material Header with animations
                        SlideTransition(
                          position: _slideAnimation,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getSubjectColor(_materialWithDetails!.subjectName).withValues(alpha: 0.8),
                                  _getSubjectColor(_materialWithDetails!.subjectName),
                                  _getSubjectColor(_materialWithDetails!.subjectName).withValues(alpha: 0.9),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _getSubjectColor(_materialWithDetails!.subjectName).withValues(alpha: 0.3),
                                  spreadRadius: 3,
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ScaleTransition(
                                      scale: _bounceAnimation,
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            '📚',
                                            style: TextStyle(fontSize: 28),
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
                                            _materialWithDetails!.materi.judul,
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              shadows: [
                                                Shadow(
                                                  offset: Offset(1, 1),
                                                  blurRadius: 3,
                                                  color: Colors.black26,
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (_materialWithDetails!.materi.description?.isNotEmpty == true) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(15),
                                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                              ),
                                              child: Text(
                                                _materialWithDetails!.materi.description!,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Info cards with emojis
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    _buildInfoCard(
                                      '👨‍🏫 ${_materialWithDetails!.teacherName}',
                                      Icons.person,
                                    ),
                                    _buildInfoCard(
                                      '📖 ${_materialWithDetails!.subjectName}',
                                      Icons.subject,
                                    ),
                                    _buildInfoCard(
                                      '📅 ${_formatDate(_materialWithDetails!.materi.createdAt)}',
                                      Icons.access_time,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Material Details with enhanced design
                        if (_materialWithDetails!.details.isNotEmpty) ...[
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.purple[400]!, Colors.purple[600]!],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.library_books,
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
                                        '📖 Konten Materi',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple[800],
                                        ),
                                      ),
                                      Text(
                                        'Mari belajar bersama! ✨',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.purple[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          ..._materialWithDetails!.details.asMap().entries.map((entry) {
                            final index = entry.key;
                            final detail = entry.value;
                            
                            return TweenAnimationBuilder<double>(
                              duration: Duration(milliseconds: 300 + (index * 100)),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 30 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 24),
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            _getSubjectColor(_materialWithDetails!.subjectName).withValues(alpha: 0.1),
                                            _getSubjectColor(_materialWithDetails!.subjectName).withValues(alpha: 0.05),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: _getSubjectColor(_materialWithDetails!.subjectName).withValues(alpha: 0.3),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _getSubjectColor(_materialWithDetails!.subjectName).withValues(alpha: 0.1),
                                            spreadRadius: 1,
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Enhanced Detail Header
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  _getSubjectColor(_materialWithDetails!.subjectName).withValues(alpha: 0.8),
                                                  _getSubjectColor(_materialWithDetails!.subjectName),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '${index + 1}️⃣',
                                                      style: const TextStyle(fontSize: 18),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    detail.judul,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                      shadows: [
                                                        Shadow(
                                                          offset: Offset(1, 1),
                                                          blurRadius: 2,
                                                          color: Colors.black26,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(height: 16),

                                          // Enhanced Content Container
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.grey[200]!),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Detail Content
                                                if (detail.paragrafMateri.isNotEmpty) ...[
                                                  Text(
                                                    detail.paragrafMateri,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      height: 1.6,
                                                      color: Colors.grey[800],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                ],

                                                // YouTube Embed
                                                if (detail.embedYoutube != null && detail.embedYoutube!.isNotEmpty) ...[
                                                  InkWell(
                                                    onTap: () => _launchUrl(detail.embedYoutube!),
                                                    child: _buildYouTubeEmbed(detail.embedYoutube!),
                                                  ),
                                                ],

                                                // Enhanced Detail Image
                                                if (detail.imageUrl != null && detail.imageUrl!.isNotEmpty) ...[
                                                  TweenAnimationBuilder<double>(
                                                    duration: const Duration(milliseconds: 500),
                                                    tween: Tween(begin: 0.0, end: 1.0),
                                                    builder: (context, value, child) {
                                                      return Transform.scale(
                                                        scale: 0.9 + (0.1 * value),
                                                        child: Container(
                                                          margin: const EdgeInsets.symmetric(vertical: 16),
                                                          decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.circular(16),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors.grey.withValues(alpha: 0.3),
                                                                spreadRadius: 2,
                                                                blurRadius: 8,
                                                                offset: const Offset(0, 4),
                                                              ),
                                                            ],
                                                          ),
                                                          child: ClipRRect(
                                                            borderRadius: BorderRadius.circular(16),
                                                            child: Stack(
                                                              children: [
                                                                Image.network(
                                                                  detail.imageUrl!,
                                                                  width: double.infinity,
                                                                  fit: BoxFit.cover,
                                                                  loadingBuilder: (context, child, loadingProgress) {
                                                                    if (loadingProgress == null) return child;
                                                                    return Container(
                                                                      height: 200,
                                                                      decoration: BoxDecoration(
                                                                        gradient: LinearGradient(
                                                                          colors: [Colors.blue[100]!, Colors.blue[200]!],
                                                                        ),
                                                                      ),
                                                                      child: const Center(
                                                                        child: CircularProgressIndicator(
                                                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                                                        ),
                                                                      ),
                                                                    );
                                                                  },
                                                                  errorBuilder: (context, error, stackTrace) {
                                                                    return Container(
                                                                      height: 200,
                                                                      decoration: BoxDecoration(
                                                                        gradient: LinearGradient(
                                                                          colors: [Colors.grey[200]!, Colors.grey[300]!],
                                                                        ),
                                                                      ),
                                                                      child: const Center(
                                                                        child: Column(
                                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                                          children: [
                                                                            Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                                                            SizedBox(height: 8),
                                                                            Text('🖼️ Gambar tidak dapat dimuat', style: TextStyle(color: Colors.grey)),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                                Positioned(
                                                                  top: 12,
                                                                  right: 12,
                                                                  child: Container(
                                                                    padding: const EdgeInsets.all(8),
                                                                    decoration: BoxDecoration(
                                                                      color: Colors.white.withValues(alpha: 0.9),
                                                                      borderRadius: BorderRadius.circular(20),
                                                                    ),
                                                                    child: const Text('🖼️', style: TextStyle(fontSize: 16)),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],

                                                // Enhanced Attachments
                                                if (detail.attachments?.isNotEmpty == true) ...[
                                                  Container(
                                                    padding: const EdgeInsets.all(16),
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [Colors.blue[50]!, Colors.blue[100]!],
                                                      ),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: Colors.blue[200]!),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Container(
                                                              width: 40,
                                                              height: 40,
                                                              decoration: BoxDecoration(
                                                                gradient: LinearGradient(
                                                                  colors: [Colors.blue[400]!, Colors.blue[600]!],
                                                                ),
                                                                borderRadius: BorderRadius.circular(10),
                                                              ),
                                                              child: const Icon(
                                                                Icons.attachment,
                                                                color: Colors.white,
                                                                size: 20,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 12),
                                                            Text(
                                                              '📎 Lampiran (${detail.attachments!.length})',
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.blue[800],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 12),
                                                        ...detail.attachments!.map((attachment) => _buildAttachment(attachment)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ] else ...[
                          // Enhanced No details available
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Center(
                              child: TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 800),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: 0.8 + (0.2 * value),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(32),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.blue[50]!, Colors.blue[100]!],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.blue[200]!, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withValues(alpha: 0.1),
                                            spreadRadius: 2,
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          const Text(
                                            '📝',
                                            style: TextStyle(fontSize: 64),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Konten Belum Tersedia',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue[800],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Detail materi belum ditambahkan oleh guru',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.blue[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Konten akan segera ditambahkan! 🚀',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.blue[500],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoCard(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
                   'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}