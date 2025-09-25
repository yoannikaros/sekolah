import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_models.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String _chatRoomsCollection = 'chat_rooms';
  static const String _messagesCollection = 'messages';
  static const String _typingStatusCollection = 'typing_status';

  // Kata-kata sensitif untuk moderasi
  final List<String> _sensitiveWords = [
    'bodoh', 'tolol', 'goblok', 'anjing', 'babi', 'bangsat', 'kampret',
    'tai', 'sial', 'sialan', 'brengsek', 'keparat', 'kontol', 'memek',
    'ngentot', 'fuck', 'shit', 'damn', 'bitch', 'asshole', 'stupid',
    'idiot', 'moron', 'dumb', 'hate', 'kill', 'die', 'death'
  ];

  String get currentUserId => _auth.currentUser?.uid ?? '';
  String get currentUserName => _auth.currentUser?.displayName ?? 'Unknown User';

  // ==================== CHAT ROOM OPERATIONS ====================

  /// Membuat chat room baru
  Future<String> createChatRoom({
    required String name,
    String? description,
    required List<String> participants,
    String type = 'group',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final chatRoom = ChatRoom(
        id: '',
        name: name,
        description: description,
        participants: participants,
        createdBy: currentUserId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        type: type,
        metadata: metadata,
      );

      final docRef = await _firestore
          .collection(_chatRoomsCollection)
          .add(chatRoom.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Gagal membuat chat room: $e');
    }
  }

  /// Mendapatkan daftar chat room untuk user
  Stream<List<ChatRoom>> getChatRooms() {
    return _firestore
        .collection(_chatRoomsCollection)
        .where('participants', arrayContains: currentUserId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final chatRooms = snapshot.docs
              .map((doc) => ChatRoom.fromFirestore(doc))
              .toList();
          
          // Sort manually to avoid composite index requirement
          chatRooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return chatRooms;
        });
  }

  /// Mendapatkan chat room berdasarkan ID
  Future<ChatRoom?> getChatRoom(String chatRoomId) async {
    try {
      final doc = await _firestore
          .collection(_chatRoomsCollection)
          .doc(chatRoomId)
          .get();

      if (doc.exists) {
        return ChatRoom.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mendapatkan chat room: $e');
    }
  }

  /// Mendapatkan private chat room antara dua user
  Future<ChatRoom?> getPrivateChatRoom(String userId1, String userId2) async {
    try {
      final querySnapshot = await _firestore
          .collection(_chatRoomsCollection)
          .where('type', isEqualTo: 'private')
          .where('participants', arrayContains: userId1)
          .where('isActive', isEqualTo: true)
          .get();

      for (final doc in querySnapshot.docs) {
        final chatRoom = ChatRoom.fromFirestore(doc);
        if (chatRoom.participants.contains(userId2) && 
            chatRoom.participants.length == 2) {
          return chatRoom;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mendapatkan private chat room: $e');
    }
  }

  /// Menambah participant ke chat room
  Future<void> addParticipant(String chatRoomId, String userId) async {
    try {
      await _firestore
          .collection(_chatRoomsCollection)
          .doc(chatRoomId)
          .update({
        'participants': FieldValue.arrayUnion([userId]),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Gagal menambah participant: $e');
    }
  }

  /// Menghapus participant dari chat room
  Future<void> removeParticipant(String chatRoomId, String userId) async {
    try {
      await _firestore
          .collection(_chatRoomsCollection)
          .doc(chatRoomId)
          .update({
        'participants': FieldValue.arrayRemove([userId]),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Gagal menghapus participant: $e');
    }
  }

  // ==================== MESSAGE OPERATIONS ====================

  /// Mengirim pesan
  Future<String> sendMessage({
    required String chatRoomId,
    required String content,
    MessageType type = MessageType.text,
    List<String>? attachments,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Moderasi konten
      final moderatedContent = _moderateContent(content);
      final isModerated = moderatedContent != content;

      // Buat pesan
      final message = Message(
        id: '',
        chatRoomId: chatRoomId,
        senderId: currentUserId,
        senderName: currentUserName,
        content: moderatedContent,
        originalContent: content,
        type: type,
        createdAt: DateTime.now(),
        isModerated: isModerated,
        attachments: attachments,
        replyToMessageId: replyToMessageId,
        metadata: metadata,
      );

      // Simpan pesan
      final docRef = await _firestore
          .collection(_messagesCollection)
          .add(message.toFirestore());

      // Update last message di chat room
      await _updateLastMessage(chatRoomId, moderatedContent, currentUserId);

      return docRef.id;
    } catch (e) {
      throw Exception('Gagal mengirim pesan: $e');
    }
  }

  /// Mendapatkan pesan dalam chat room
  Stream<List<Message>> getMessages(String chatRoomId, {int limit = 50}) {
    return _firestore
        .collection(_messagesCollection)
        .where('chatRoomId', isEqualTo: chatRoomId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => Message.fromFirestore(doc))
              .toList();
          
          // Sort manually to avoid composite index requirement
          messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          // Apply limit manually
          return messages.take(limit).toList();
        });
  }

  /// Edit pesan
  Future<void> editMessage(String messageId, String newContent) async {
    try {
      final moderatedContent = _moderateContent(newContent);
      final isModerated = moderatedContent != newContent;

      await _firestore
          .collection(_messagesCollection)
          .doc(messageId)
          .update({
        'content': moderatedContent,
        'originalContent': newContent,
        'isEdited': true,
        'isModerated': isModerated,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Gagal mengedit pesan: $e');
    }
  }

  /// Hapus pesan
  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore
          .collection(_messagesCollection)
          .doc(messageId)
          .update({
        'isDeleted': true,
        'content': 'Pesan telah dihapus',
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Gagal menghapus pesan: $e');
    }
  }

  // ==================== READ STATUS OPERATIONS ====================

  /// Menandai pesan sebagai sudah dibaca
  Future<void> markMessageAsRead(String messageId, String userId) async {
    try {
      final readStatus = MessageReadStatus(
        isRead: true,
        readAt: DateTime.now(),
        isDelivered: true,
        deliveredAt: DateTime.now(),
      );

      await _firestore
          .collection(_messagesCollection)
          .doc(messageId)
          .update({
        'readStatus.$userId': readStatus.toMap(),
      });
    } catch (e) {
      throw Exception('Gagal menandai pesan sebagai dibaca: $e');
    }
  }

  /// Menandai semua pesan dalam chat room sebagai sudah dibaca
  Future<void> markAllMessagesAsRead(String chatRoomId) async {
    try {
      final batch = _firestore.batch();
      final messages = await _firestore
          .collection(_messagesCollection)
          .where('chatRoomId', isEqualTo: chatRoomId)
          .where('senderId', isNotEqualTo: currentUserId)
          .get();

      final readStatus = MessageReadStatus(
        isRead: true,
        readAt: DateTime.now(),
        isDelivered: true,
        deliveredAt: DateTime.now(),
      );

      for (final doc in messages.docs) {
        batch.update(doc.reference, {
          'readStatus.$currentUserId': readStatus.toMap(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Gagal menandai semua pesan sebagai dibaca: $e');
    }
  }

  /// Mendapatkan jumlah pesan yang belum dibaca
  Stream<int> getUnreadMessageCount(String chatRoomId) {
    return _firestore
        .collection(_messagesCollection)
        .where('chatRoomId', isEqualTo: chatRoomId)
        .where('senderId', isNotEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      int unreadCount = 0;
      for (final doc in snapshot.docs) {
        final message = Message.fromFirestore(doc);
        final readStatus = message.readStatus[currentUserId];
        if (readStatus == null || !readStatus.isRead) {
          unreadCount++;
        }
      }
      return unreadCount;
    });
  }

  // ==================== TYPING INDICATOR ====================

  /// Mengirim status typing
  Future<void> sendTypingStatus(String chatRoomId, bool isTyping) async {
    try {
      final docId = '${chatRoomId}_$currentUserId';
      
      if (isTyping) {
        final typingStatus = TypingStatus(
          userId: currentUserId,
          userName: currentUserName,
          chatRoomId: chatRoomId,
          timestamp: DateTime.now(),
        );

        await _firestore
            .collection(_typingStatusCollection)
            .doc(docId)
            .set(typingStatus.toFirestore());
      } else {
        await _firestore
            .collection(_typingStatusCollection)
            .doc(docId)
            .delete();
      }
    } catch (e) {
      // Ignore typing status errors
    }
  }

  /// Mendapatkan status typing
  Stream<List<TypingStatus>> getTypingStatus(String chatRoomId) {
    return _firestore
        .collection(_typingStatusCollection)
        .where('chatRoomId', isEqualTo: chatRoomId)
        .where('userId', isNotEqualTo: currentUserId)
        .where('timestamp', isGreaterThan: DateTime.now().subtract(Duration(seconds: 5)))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TypingStatus.fromFirestore(doc))
            .toList());
  }

  // ==================== HELPER METHODS ====================

  /// Moderasi konten untuk kata-kata sensitif
  String _moderateContent(String content) {
    String moderatedContent = content;
    
    for (final word in _sensitiveWords) {
      final regex = RegExp(word, caseSensitive: false);
      moderatedContent = moderatedContent.replaceAll(regex, '*' * word.length);
    }
    
    return moderatedContent;
  }

  /// Update last message di chat room
  Future<void> _updateLastMessage(String chatRoomId, String message, String senderId) async {
    try {
      await _firestore
          .collection(_chatRoomsCollection)
          .doc(chatRoomId)
          .update({
        'lastMessage': message,
        'lastMessageTime': DateTime.now(),
        'lastMessageSenderId': senderId,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      // Ignore update errors
    }
  }

  /// Membersihkan typing status yang sudah expired
  Future<void> cleanupExpiredTypingStatus() async {
    try {
      final expiredTime = DateTime.now().subtract(Duration(seconds: 10));
      final expiredDocs = await _firestore
          .collection(_typingStatusCollection)
          .where('timestamp', isLessThan: expiredTime)
          .get();

      final batch = _firestore.batch();
      for (final doc in expiredDocs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  /// Mendapatkan statistik chat room
  Future<Map<String, dynamic>> getChatRoomStats(String chatRoomId) async {
    try {
      final messagesSnapshot = await _firestore
          .collection(_messagesCollection)
          .where('chatRoomId', isEqualTo: chatRoomId)
          .where('isDeleted', isEqualTo: false)
          .get();

      final totalMessages = messagesSnapshot.docs.length;
      final moderatedMessages = messagesSnapshot.docs
          .where((doc) => (doc.data()['isModerated'] ?? false) == true)
          .length;

      return {
        'totalMessages': totalMessages,
        'moderatedMessages': moderatedMessages,
        'moderationRate': totalMessages > 0 ? (moderatedMessages / totalMessages) * 100 : 0,
      };
    } catch (e) {
      return {
        'totalMessages': 0,
        'moderatedMessages': 0,
        'moderationRate': 0,
      };
    }
  }

  /// Mencari pesan
  Future<List<Message>> searchMessages(String chatRoomId, String query) async {
    try {
      final snapshot = await _firestore
          .collection(_messagesCollection)
          .where('chatRoomId', isEqualTo: chatRoomId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      final messages = snapshot.docs
          .map((doc) => Message.fromFirestore(doc))
          .where((message) => message.content.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return messages;
    } catch (e) {
      throw Exception('Gagal mencari pesan: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    // Clean up any subscriptions or resources
  }
}