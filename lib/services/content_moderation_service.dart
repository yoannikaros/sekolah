import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContentModerationService {
  static final ContentModerationService _instance = ContentModerationService._internal();
  factory ContentModerationService() => _instance;
  ContentModerationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kata-kata sensitif dalam berbagai kategori
  final Map<String, List<String>> _sensitiveWordsCategories = {
    'profanity_indonesian': [
      'anjing', 'babi', 'bangsat', 'brengsek', 'bodoh', 'tolol', 'goblok',
      'kampret', 'tai', 'sial', 'sialan', 'keparat', 'kontol', 'memek',
      'ngentot', 'jancuk', 'cuk', 'asu', 'bajingan', 'sundel', 'pelacur',
      'lonte', 'jablay', 'perek', 'bitch', 'fuck', 'shit', 'damn',
      'asshole', 'stupid', 'idiot', 'moron', 'dumb'
    ],
    'hate_speech': [
      'benci', 'hate', 'bunuh', 'kill', 'mati', 'die', 'death', 'suicide',
      'racist', 'rasis', 'diskriminasi', 'discrimination', 'teroris', 'terrorist'
    ],
    'bullying': [
      'jelek', 'ugly', 'gemuk', 'fat', 'kurus', 'skinny', 'pendek', 'short',
      'tinggi', 'tall', 'miskin', 'poor', 'kaya', 'rich', 'loser', 'pecundang'
    ],
    'sexual_content': [
      'sex', 'seks', 'porn', 'porno', 'telanjang', 'naked', 'nude',
      'masturbasi', 'masturbation', 'orgasme', 'orgasm', 'vagina', 'penis'
    ],
    'violence': [
      'pukul', 'hit', 'tampar', 'slap', 'tendang', 'kick', 'tusuk', 'stab',
      'tembak', 'shoot', 'ledak', 'explode', 'bom', 'bomb', 'kekerasan', 'violence'
    ]
  };

  // Pattern untuk deteksi spam
  final List<RegExp> _spamPatterns = [
    RegExp(r'(.)\1{4,}'), // Karakter berulang lebih dari 4 kali
    RegExp(r'[A-Z]{5,}'), // Huruf kapital berturut-turut
    RegExp(r'[!@#$%^&*()]{3,}'), // Simbol berturut-turut
    RegExp(r'\b(\w+)\s+\1\s+\1\b'), // Kata yang diulang 3 kali
  ];

  // Kata-kata yang diizinkan meskipun mengandung kata sensitif
  final List<String> _whitelistedWords = [
    'anjing laut', 'babi hutan', 'sial beruntung', 'kampret terbang',
    'education', 'educational', 'discussion', 'diskusi'
  ];

  /// Moderasi konten utama
  ModerationResult moderateContent(String content) {
    if (content.trim().isEmpty) {
      return ModerationResult(
        originalContent: content,
        moderatedContent: content,
        isModerated: false,
        violations: [],
        severity: ModerationSeverity.none,
      );
    }

    String moderatedContent = content;
    List<ModerationViolation> violations = [];
    ModerationSeverity maxSeverity = ModerationSeverity.none;

    // 1. Cek whitelist terlebih dahulu
    if (_isWhitelisted(content)) {
      return ModerationResult(
        originalContent: content,
        moderatedContent: content,
        isModerated: false,
        violations: [],
        severity: ModerationSeverity.none,
      );
    }

    // 2. Deteksi kata-kata sensitif
    final sensitiveWordResult = _detectSensitiveWords(content);
    if (sensitiveWordResult.isNotEmpty) {
      for (final violation in sensitiveWordResult) {
        violations.add(violation);
        moderatedContent = _replaceSensitiveWord(moderatedContent, violation.word);
        if (violation.severity.index > maxSeverity.index) {
          maxSeverity = violation.severity;
        }
      }
    }

    // 3. Deteksi spam
    final spamResult = _detectSpam(content);
    if (spamResult != null) {
      violations.add(spamResult);
      moderatedContent = _cleanSpam(moderatedContent);
      if (spamResult.severity.index > maxSeverity.index) {
        maxSeverity = spamResult.severity;
      }
    }

    // 4. Deteksi link mencurigakan
    final linkResult = _detectSuspiciousLinks(content);
    if (linkResult.isNotEmpty) {
      for (final violation in linkResult) {
        violations.add(violation);
        moderatedContent = _removeSuspiciousLinks(moderatedContent);
        if (violation.severity.index > maxSeverity.index) {
          maxSeverity = violation.severity;
        }
      }
    }

    // 5. Deteksi informasi pribadi
    final personalInfoResult = _detectPersonalInfo(content);
    if (personalInfoResult.isNotEmpty) {
      for (final violation in personalInfoResult) {
        violations.add(violation);
        moderatedContent = _maskPersonalInfo(moderatedContent, violation.word);
        if (violation.severity.index > maxSeverity.index) {
          maxSeverity = violation.severity;
        }
      }
    }

    return ModerationResult(
      originalContent: content,
      moderatedContent: moderatedContent,
      isModerated: violations.isNotEmpty,
      violations: violations,
      severity: maxSeverity,
    );
  }

  /// Deteksi kata-kata sensitif
  List<ModerationViolation> _detectSensitiveWords(String content) {
    List<ModerationViolation> violations = [];
    String lowerContent = content.toLowerCase();

    _sensitiveWordsCategories.forEach((category, words) {
      for (final word in words) {
        if (lowerContent.contains(word.toLowerCase())) {
          violations.add(ModerationViolation(
            type: ModerationViolationType.sensitiveWord,
            word: word,
            category: category,
            severity: _getSeverityForCategory(category),
            position: lowerContent.indexOf(word.toLowerCase()),
          ));
        }
      }
    });

    return violations;
  }

  /// Deteksi spam
  ModerationViolation? _detectSpam(String content) {
    for (final pattern in _spamPatterns) {
      if (pattern.hasMatch(content)) {
        return ModerationViolation(
          type: ModerationViolationType.spam,
          word: pattern.firstMatch(content)?.group(0) ?? '',
          category: 'spam',
          severity: ModerationSeverity.medium,
          position: pattern.firstMatch(content)?.start ?? 0,
        );
      }
    }

    // Deteksi pesan yang terlalu panjang
    if (content.length > 1000) {
      return ModerationViolation(
        type: ModerationViolationType.spam,
        word: 'Pesan terlalu panjang',
        category: 'spam',
        severity: ModerationSeverity.low,
        position: 0,
      );
    }

    return null;
  }

  /// Deteksi link mencurigakan
  List<ModerationViolation> _detectSuspiciousLinks(String content) {
    List<ModerationViolation> violations = [];
    
    // Pattern untuk URL
    final urlPattern = RegExp(
      r'https?://[^\s]+|www\.[^\s]+|[^\s]+\.(com|net|org|id|co\.id)[^\s]*',
      caseSensitive: false,
    );

    final matches = urlPattern.allMatches(content);
    for (final match in matches) {
      final url = match.group(0) ?? '';
      
      // Cek apakah URL mengandung kata-kata mencurigakan
      final suspiciousKeywords = ['porn', 'sex', 'gambling', 'casino', 'bet', 'loan', 'credit'];
      if (suspiciousKeywords.any((keyword) => url.toLowerCase().contains(keyword))) {
        violations.add(ModerationViolation(
          type: ModerationViolationType.suspiciousLink,
          word: url,
          category: 'suspicious_link',
          severity: ModerationSeverity.high,
          position: match.start,
        ));
      }
    }

    return violations;
  }

  /// Deteksi informasi pribadi
  List<ModerationViolation> _detectPersonalInfo(String content) {
    List<ModerationViolation> violations = [];

    // Pattern untuk nomor telepon Indonesia
    final phonePattern = RegExp(r'(\+62|62|0)[0-9]{9,12}');
    final phoneMatches = phonePattern.allMatches(content);
    for (final match in phoneMatches) {
      violations.add(ModerationViolation(
        type: ModerationViolationType.personalInfo,
        word: match.group(0) ?? '',
        category: 'phone_number',
        severity: ModerationSeverity.medium,
        position: match.start,
      ));
    }

    // Pattern untuk email
    final emailPattern = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    final emailMatches = emailPattern.allMatches(content);
    for (final match in emailMatches) {
      violations.add(ModerationViolation(
        type: ModerationViolationType.personalInfo,
        word: match.group(0) ?? '',
        category: 'email',
        severity: ModerationSeverity.medium,
        position: match.start,
      ));
    }

    return violations;
  }

  /// Cek apakah konten masuk whitelist
  bool _isWhitelisted(String content) {
    String lowerContent = content.toLowerCase();
    return _whitelistedWords.any((word) => lowerContent.contains(word.toLowerCase()));
  }

  /// Ganti kata sensitif dengan asterisk
  String _replaceSensitiveWord(String content, String word) {
    final regex = RegExp(word, caseSensitive: false);
    return content.replaceAll(regex, '*' * word.length);
  }

  /// Bersihkan spam
  String _cleanSpam(String content) {
    String cleaned = content;
    
    // Hapus karakter berulang berlebihan
    cleaned = cleaned.replaceAll(RegExp(r'(.)\1{4,}'), r'$1$1$1');
    
    // Batasi huruf kapital berturut-turut
    cleaned = cleaned.replaceAllMapped(RegExp(r'[A-Z]{5,}'), (Match match) {
      String matchStr = match.group(0) ?? '';
      if (matchStr.length > 4) {
        return matchStr.substring(0, 4) + matchStr.substring(4).toLowerCase();
      }
      return matchStr;
    });
    
    // Batasi simbol berturut-turut
    cleaned = cleaned.replaceAll(RegExp(r'[!@#$%^&*()]{3,}'), '***');
    
    return cleaned;
  }

  /// Hapus link mencurigakan
  String _removeSuspiciousLinks(String content) {
    final urlPattern = RegExp(
      r'https?://[^\s]+|www\.[^\s]+|[^\s]+\.(com|net|org|id|co\.id)[^\s]*',
      caseSensitive: false,
    );
    
    return content.replaceAll(urlPattern, '[Link dihapus]');
  }

  /// Mask informasi pribadi
  String _maskPersonalInfo(String content, String info) {
    return content.replaceAll(info, '[Info pribadi disembunyikan]');
  }

  /// Dapatkan severity berdasarkan kategori
  ModerationSeverity _getSeverityForCategory(String category) {
    switch (category) {
      case 'profanity_indonesian':
        return ModerationSeverity.high;
      case 'hate_speech':
        return ModerationSeverity.critical;
      case 'bullying':
        return ModerationSeverity.high;
      case 'sexual_content':
        return ModerationSeverity.critical;
      case 'violence':
        return ModerationSeverity.critical;
      default:
        return ModerationSeverity.medium;
    }
  }

  /// Simpan log moderasi ke Firestore
  Future<void> logModerationAction(ModerationResult result, String userId, String chatRoomId) async {
    if (!result.isModerated) return;

    try {
      await _firestore.collection('moderation_logs').add({
        'userId': userId,
        'chatRoomId': chatRoomId,
        'originalContent': result.originalContent,
        'moderatedContent': result.moderatedContent,
        'violations': result.violations.map((v) => v.toMap()).toList(),
        'severity': result.severity.toString(),
        'timestamp': DateTime.now(),
      });
    } catch (e) {
      // Silently handle logging errors
    }
  }

  /// Dapatkan statistik moderasi
  Future<ModerationStats> getModerationStats(String chatRoomId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      Query query = _firestore
          .collection('moderation_logs')
          .where('chatRoomId', isEqualTo: chatRoomId);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      
      Map<String, int> violationCounts = {};
      Map<String, int> severityCounts = {};
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final violations = List<Map<String, dynamic>>.from(data['violations'] ?? []);
        final severity = data['severity'] ?? '';
        
        for (final violation in violations) {
          final category = violation['category'] ?? 'unknown';
          violationCounts[category] = (violationCounts[category] ?? 0) + 1;
        }
        
        severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
      }

      return ModerationStats(
        totalViolations: snapshot.docs.length,
        violationsByCategory: violationCounts,
        violationsBySeverity: severityCounts,
        period: DateRange(startDate ?? DateTime.now().subtract(Duration(days: 30)), endDate ?? DateTime.now()),
      );
    } catch (e) {
      return ModerationStats(
        totalViolations: 0,
        violationsByCategory: {},
        violationsBySeverity: {},
        period: DateRange(DateTime.now(), DateTime.now()),
      );
    }
  }
}

// ==================== DATA CLASSES ====================

class ModerationResult {
  final String originalContent;
  final String moderatedContent;
  final bool isModerated;
  final List<ModerationViolation> violations;
  final ModerationSeverity severity;

  ModerationResult({
    required this.originalContent,
    required this.moderatedContent,
    required this.isModerated,
    required this.violations,
    required this.severity,
  });
}

class ModerationViolation {
  final ModerationViolationType type;
  final String word;
  final String category;
  final ModerationSeverity severity;
  final int position;

  ModerationViolation({
    required this.type,
    required this.word,
    required this.category,
    required this.severity,
    required this.position,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'word': word,
      'category': category,
      'severity': severity.toString(),
      'position': position,
    };
  }
}

class ModerationStats {
  final int totalViolations;
  final Map<String, int> violationsByCategory;
  final Map<String, int> violationsBySeverity;
  final DateRange period;

  ModerationStats({
    required this.totalViolations,
    required this.violationsByCategory,
    required this.violationsBySeverity,
    required this.period,
  });
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange(this.start, this.end);
}

enum ModerationViolationType {
  sensitiveWord,
  spam,
  suspiciousLink,
  personalInfo,
}

enum ModerationSeverity {
  none,
  low,
  medium,
  high,
  critical,
}