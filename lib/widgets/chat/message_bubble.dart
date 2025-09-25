import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/chat_models.dart';
import 'message_options_dialog.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final String currentUserId;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReply;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.currentUserId,
    this.onEdit,
    this.onDelete,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisAlignment: isMe 
              ? MainAxisAlignment.end 
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar for other users
            if (!isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
                child: Text(
                  message.senderName.isNotEmpty 
                      ? message.senderName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            
            // Message content
            Flexible(
              child: Column(
                crossAxisAlignment: isMe 
                    ? CrossAxisAlignment.end 
                    : CrossAxisAlignment.start,
                children: [
                  // Sender name for group chats
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  
                  _buildMessageContent(),
                ],
              ),
            ),
            
            // Avatar placeholder for own messages (for alignment)
            if (isMe) const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe ? Colors.blue[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.blue[300]! : Colors.grey[400]!,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Membalas pesan',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.replyToMessageId != null ? 'Membalas pesan' : 'Pesan tidak tersedia',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    if (message.isDeleted) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: _getBorderRadius(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.block,
              size: 16,
              color: Colors.grey[500],
            ),
            const SizedBox(width: 6),
            Text(
              'Pesan telah dihapus',
              style: TextStyle(
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBubbleColor(),
        borderRadius: _getBorderRadius(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reply preview
          if (message.replyToMessageId != null) ...[
            _buildReplyPreview(),
            const SizedBox(height: 8),
          ],
          
          // Message text
          Text(
            message.content,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 15,
            ),
          ),
          
          // Bottom row with timestamp and status
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edited indicator
                 if (message.isEdited) ...[
                   Text(
                     'diedit',
                     style: TextStyle(
                       fontSize: 11,
                       color: isMe 
                           ? Colors.white.withValues(alpha: 0.7)
                           : Colors.grey[500],
                       fontStyle: FontStyle.italic,
                     ),
                   ),
                   const SizedBox(width: 8),
                 ],
                 
                 // Timestamp
                 Text(
                   DateFormat('HH:mm').format(message.createdAt),
                   style: TextStyle(
                     fontSize: 11,
                     color: isMe 
                         ? Colors.white.withValues(alpha: 0.7)
                         : Colors.grey[500],
                   ),
                 ),
                
                // Read status for own messages
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildReadStatusIcon(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadStatusIcon() {
    if (message.readStatus.isEmpty) {
      return Icon(
        Icons.access_time,
        size: 12,
        color: Colors.white.withValues(alpha: 0.7),
      );
    }

    bool isRead = message.readStatus.values.any((status) => status.isRead);
    bool isDelivered = message.readStatus.values.any((status) => status.isDelivered);

    if (isRead) {
      return Icon(
        Icons.done_all,
        size: 12,
        color: Colors.blue,
      );
    } else if (isDelivered) {
      return Icon(
        Icons.done_all,
        size: 12,
        color: Colors.white.withValues(alpha: 0.7),
      );
    } else {
      return Icon(
        Icons.check,
        size: 12,
        color: Colors.white.withValues(alpha: 0.7),
      );
    }
  }

  Color _getBubbleColor() {
    if (message.isDeleted) {
      return Colors.grey.withValues(alpha: 0.3);
    }
    return isMe ? Colors.blue[600]! : Colors.grey[200]!;
  }

  BorderRadius _getBorderRadius() {
    return BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMe ? 16 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 16),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => MessageOptionsDialog(
        message: message,
        isOwnMessage: isMe,
        onEdit: message.isDeleted ? null : onEdit,
        onDelete: onDelete,
        onReply: onReply,
      ),
    );
  }
}

// Widget for system messages (user joined, left, etc.)
class SystemMessageBubble extends StatelessWidget {
  final String message;
  final DateTime timestamp;

  const SystemMessageBubble({
    super.key,
    required this.message,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(timestamp),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget for date separator
class DateSeparator extends StatelessWidget {
  final DateTime date;

  const DateSeparator({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Text(
            _formatDate(date),
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Hari ini';
    } else if (messageDate == yesterday) {
      return 'Kemarin';
    } else {
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    }
  }
}