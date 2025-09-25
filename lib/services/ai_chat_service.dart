import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ai_chat_models.dart';

class AIChatService {
  static final AIChatService _instance = AIChatService._internal();
  factory AIChatService() => _instance;
  AIChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String _aiChatConfigCollection = 'ai_chat_config';
  static const String _aiChatMessagesCollection = 'ai_chat_messages';
  static const String _aiChatSessionsCollection = 'ai_chat_sessions';

  String get currentUserId => _auth.currentUser?.uid ?? '';
  String get currentUserName => _auth.currentUser?.displayName ?? 'Student';

  // ==================== CONFIG OPERATIONS ====================

  /// Get active AI chat configuration
  Future<AIChatConfig?> getActiveConfig() async {
    try {
      final querySnapshot = await _firestore
          .collection(_aiChatConfigCollection)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return AIChatConfig.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting AI chat config: $e');
      return null;
    }
  }

  /// Create or update AI chat configuration (Admin only)
  Future<String?> saveConfig(AIChatConfig config) async {
    try {
      if (config.id.isEmpty) {
        // Create new config
        final docRef = await _firestore
            .collection(_aiChatConfigCollection)
            .add(config.toFirestore());
        return docRef.id;
      } else {
        // Update existing config
        await _firestore
            .collection(_aiChatConfigCollection)
            .doc(config.id)
            .update(config.toFirestore());
        return config.id;
      }
    } catch (e) {
      debugPrint('Error saving AI chat config: $e');
      return null;
    }
  }

  /// Get all AI chat configurations (Admin only)
  Future<List<AIChatConfig>> getAllConfigs() async {
    try {
      final querySnapshot = await _firestore
          .collection(_aiChatConfigCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AIChatConfig.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting all AI chat configs: $e');
      return [];
    }
  }

  /// Delete AI chat configuration (Admin only)
  Future<bool> deleteConfig(String configId) async {
    try {
      await _firestore
          .collection(_aiChatConfigCollection)
          .doc(configId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting AI chat config: $e');
      return false;
    }
  }

  // ==================== CHAT OPERATIONS ====================

  /// Send message to AI and get response
  Future<String?> sendMessageToAI(String message) async {
    try {
      final config = await getActiveConfig();
      if (config == null) {
        throw Exception('Konfigurasi AI Chat tidak ditemukan. Silakan hubungi admin.');
      }

      if (config.apiKey.isEmpty) {
        throw Exception('API Key tidak tersedia. Silakan hubungi admin.');
      }

      // Prepare the request to OpenAI API
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${config.apiKey}',
        },
        body: jsonEncode({
          'model': config.model,
          'messages': [
            {
              'role': 'system',
              'content': config.systemPrompt,
            },
            {
              'role': 'user',
              'content': message,
            },
          ],
          'max_tokens': config.maxTokens,
          'temperature': config.temperature,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'];
        
        // Save the conversation to Firestore
        await _saveConversation(message, aiResponse);
        
        return aiResponse;
      } else {
        debugPrint('OpenAI API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Terjadi kesalahan saat berkomunikasi dengan AI. Silakan coba lagi.');
      }
    } catch (e) {
      debugPrint('Error sending message to AI: $e');
      rethrow;
    }
  }

  /// Save conversation to Firestore
  Future<void> _saveConversation(String message, String response) async {
    try {
      final aiMessage = AIChatMessage(
        id: '',
        userId: currentUserId,
        userName: currentUserName,
        message: message,
        response: response,
        createdAt: DateTime.now(),
        type: _categorizeMessage(message),
      );

      await _firestore
          .collection(_aiChatMessagesCollection)
          .add(aiMessage.toFirestore());
    } catch (e) {
      debugPrint('Error saving conversation: $e');
    }
  }

  /// Categorize message type based on content
  AIChatMessageType _categorizeMessage(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('belajar') || 
        lowerMessage.contains('study') || 
        lowerMessage.contains('tugas') ||
        lowerMessage.contains('ujian') ||
        lowerMessage.contains('nilai')) {
      return AIChatMessageType.studyTips;
    } else if (lowerMessage.contains('bully') || 
               lowerMessage.contains('diganggu') ||
               lowerMessage.contains('diejek') ||
               lowerMessage.contains('intimidasi')) {
      return AIChatMessageType.antiBullying;
    } else if (lowerMessage.contains('medsos') || 
               lowerMessage.contains('media sosial') ||
               lowerMessage.contains('instagram') ||
               lowerMessage.contains('tiktok') ||
               lowerMessage.contains('facebook') ||
               lowerMessage.contains('hoax') ||
               lowerMessage.contains('berita palsu')) {
      return AIChatMessageType.socialMediaLiteracy;
    }
    
    return AIChatMessageType.general;
  }

  /// Get user's chat history
  Future<List<AIChatMessage>> getUserChatHistory({int limit = 50}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_aiChatMessagesCollection)
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => AIChatMessage.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user chat history: $e');
      return [];
    }
  }

  /// Get all chat messages (Admin only)
  Future<List<AIChatMessage>> getAllChatMessages({int limit = 100}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_aiChatMessagesCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => AIChatMessage.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting all chat messages: $e');
      return [];
    }
  }

  /// Stream user's chat history
  Stream<List<AIChatMessage>> streamUserChatHistory({int limit = 50}) {
    return _firestore
        .collection(_aiChatMessagesCollection)
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AIChatMessage.fromFirestore(doc))
            .toList());
  }

  /// Delete chat message
  Future<bool> deleteChatMessage(String messageId) async {
    try {
      await _firestore
          .collection(_aiChatMessagesCollection)
          .doc(messageId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting chat message: $e');
      return false;
    }
  }

  /// Clear user's chat history
  Future<bool> clearUserChatHistory() async {
    try {
      final querySnapshot = await _firestore
          .collection(_aiChatMessagesCollection)
          .where('userId', isEqualTo: currentUserId)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      return true;
    } catch (e) {
      debugPrint('Error clearing user chat history: $e');
      return false;
    }
  }

  // ==================== SESSION OPERATIONS ====================

  /// Create new chat session
  Future<String?> createChatSession() async {
    try {
      final session = AIChatSession(
        id: '',
        userId: currentUserId,
        userName: currentUserName,
        startedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection(_aiChatSessionsCollection)
          .add(session.toFirestore());
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating chat session: $e');
      return null;
    }
  }

  /// End chat session
  Future<bool> endChatSession(String sessionId) async {
    try {
      await _firestore
          .collection(_aiChatSessionsCollection)
          .doc(sessionId)
          .update({
        'endedAt': DateTime.now(),
        'isActive': false,
      });
      return true;
    } catch (e) {
      debugPrint('Error ending chat session: $e');
      return false;
    }
  }

  /// Get user's active session
  Future<AIChatSession?> getUserActiveSession() async {
    try {
      final querySnapshot = await _firestore
          .collection(_aiChatSessionsCollection)
          .where('userId', isEqualTo: currentUserId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return AIChatSession.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user active session: $e');
      return null;
    }
  }

  // ==================== ANALYTICS ====================

  /// Get chat statistics (Admin only)
  Future<Map<String, dynamic>> getChatStatistics() async {
    try {
      final messagesSnapshot = await _firestore
          .collection(_aiChatMessagesCollection)
          .get();

      final sessionsSnapshot = await _firestore
          .collection(_aiChatSessionsCollection)
          .get();

      final totalMessages = messagesSnapshot.docs.length;
      final totalSessions = sessionsSnapshot.docs.length;
      
      // Count messages by type
      final messagesByType = <String, int>{};
      for (final doc in messagesSnapshot.docs) {
        final message = AIChatMessage.fromFirestore(doc);
        final type = message.type.toString().split('.').last;
        messagesByType[type] = (messagesByType[type] ?? 0) + 1;
      }

      // Count unique users
      final uniqueUsers = messagesSnapshot.docs
          .map((doc) => doc.data()['userId'])
          .toSet()
          .length;

      return {
        'totalMessages': totalMessages,
        'totalSessions': totalSessions,
        'uniqueUsers': uniqueUsers,
        'messagesByType': messagesByType,
      };
    } catch (e) {
      debugPrint('Error getting chat statistics: $e');
      return {};
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Check if AI chat is available
  Future<bool> isAIChatAvailable() async {
    final config = await getActiveConfig();
    return config != null && config.isActive && config.apiKey.isNotEmpty;
  }

  /// Get suggested questions for students
  List<String> getSuggestedQuestions() {
    return [
      'Bagaimana cara belajar yang efektif?',
      'Tips mengatur waktu belajar dan bermain',
      'Apa yang harus dilakukan jika di-bully teman?',
      'Bagaimana cara menggunakan media sosial dengan bijak?',
      'Tips mengatasi stress saat ujian',
      'Cara menghindari berita hoax di internet',
      'Bagaimana cara membangun kepercayaan diri?',
      'Tips berkomunikasi yang baik dengan teman',
    ];
  }
}