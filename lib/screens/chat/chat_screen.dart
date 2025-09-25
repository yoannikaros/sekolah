import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/chat_models.dart';
import '../../services/chat_service.dart';
import '../../widgets/chat/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatScreen({super.key, required this.chatRoom});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  Timer? _typingTimer;
  bool _isTyping = false;
  String? _editingMessageId;
  String? _replyToMessageId;
  Message? _replyToMessage;
  bool _isEditing = false;
  Message? _editingMessage;

  @override
  void initState() {
    super.initState();
    _markAllMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    if (_isTyping) {
      _chatService.sendTypingStatus(widget.chatRoom.id, false);
    }
    super.dispose();
  }

  void _markAllMessagesAsRead() {
    _chatService.markAllMessagesAsRead(widget.chatRoom.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatRoom.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${widget.chatRoom.participants.length} anggota',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue[600],
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => _showChatRoomInfo(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Typing Indicator
          StreamBuilder<List<TypingStatus>>(
            stream: _chatService.getTypingStatus(widget.chatRoom.id),
            builder: (context, snapshot) {
              final typingUsers = snapshot.data ?? [];
              if (typingUsers.isEmpty) return const SizedBox.shrink();
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.blue[50],
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      typingUsers.length == 1
                          ? '${typingUsers.first.userName} sedang mengetik...'
                          : '${typingUsers.length} orang sedang mengetik...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Edit/Cancel button
          if (_isEditing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Text(
                    'Edit: ${_editingMessage?.content ?? ""}',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _cancelEditing,
                    child: const Text('Batal'),
                  ),
                ],
              ),
            ),

          // Reply Preview
          if (_replyToMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(color: Colors.blue[400]!, width: 4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Membalas ${_replyToMessage!.senderName}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _replyToMessage!.content,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() {
                      _replyToMessage = null;
                      _replyToMessageId = null;
                    }),
                  ),
                ],
              ),
            ),

          // Messages List
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessages(widget.chatRoom.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Terjadi kesalahan',
                          style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada pesan',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mulai percakapan dengan mengirim pesan',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                // Auto scroll to bottom when new message arrives
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _chatService.currentUserId;
                    
                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                      currentUserId: _chatService.currentUserId,
                      onEdit: isMe && !message.isDeleted 
                          ? () => _startEditing(message)
                          : null,
                      onDelete: isMe 
                          ? () => _deleteMessage(message)
                          : null,
                      onReply: () {
                        setState(() {
                          _replyToMessage = message;
                          _replyToMessageId = message.id;
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _editingMessageId != null 
                            ? 'Edit pesan...' 
                            : 'Ketik pesan...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: _onMessageChanged,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Cancel Edit Button
                if (_editingMessageId != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: _cancelEditing,
                  ),
                
                // Send Button
                IconButton(
                  icon: Icon(
                    _isEditing ? Icons.check : Icons.send,
                    color: Colors.blue[600],
                  ),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onMessageChanged(String text) {
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      _chatService.sendTypingStatus(widget.chatRoom.id, true);
    } else if (text.isEmpty && _isTyping) {
      _isTyping = false;
      _chatService.sendTypingStatus(widget.chatRoom.id, false);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        _chatService.sendTypingStatus(widget.chatRoom.id, false);
      }
    });
  }

  void _clearReply() {
    setState(() {
      _replyToMessage = null;
      _replyToMessageId = null;
    });
  }

  void _startEditing(Message message) {
    setState(() {
      _isEditing = true;
      _editingMessage = message;
      _messageController.text = message.content;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _editingMessage = null;
      _messageController.clear();
    });
  }

  Future<void> _editMessage(String newContent) async {
    if (_editingMessage == null) return;

    try {
      await _chatService.editMessage(_editingMessage!.id, newContent);
      _cancelEditing();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengedit pesan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMessage(Message message) async {
    try {
      await _chatService.deleteMessage(message.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesan berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus pesan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      if (_isEditing && _editingMessage != null) {
        // Edit existing message
        await _editMessage(content);
      } else {
        // Send new message
        await _chatService.sendMessage(
          chatRoomId: widget.chatRoom.id,
          content: content,
          replyToMessageId: _replyToMessageId,
        );

        _messageController.clear();
        _clearReply();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim pesan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showChatRoomInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.chatRoom.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.chatRoom.description != null)
              Text('Deskripsi: ${widget.chatRoom.description}'),
            Text('Anggota: ${widget.chatRoom.participants.length}'),
            Text('Dibuat: ${widget.chatRoom.createdAt}'),
            Text('Tipe: ${widget.chatRoom.type}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}