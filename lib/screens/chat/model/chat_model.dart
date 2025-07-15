// models/chat_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
class EnhancedChatModel {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantImages;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String lastMessageSenderId;
  final String? productId;
  final String? productTitle;
  final String? productImage;
  final double? productPrice;
  final String? productOwnerId;
  final Map<String, int> unreadCount;
  final Map<String, bool> isTyping;
  final DateTime createdAt;
  final bool isActive;
  final String chatType;
  final List<String> deletedBy; // Add this field

  EnhancedChatModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantImages,
    required this.lastMessage,
    this.lastMessageTime,
    required this.lastMessageSenderId,
    this.productId,
    this.productTitle,
    this.productImage,
    this.productPrice,
    this.productOwnerId,
    required this.unreadCount,
    required this.isTyping,
    required this.createdAt,
    required this.isActive,
    required this.chatType,
    this.deletedBy = const [], // Initialize empty list
  });

  factory EnhancedChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return EnhancedChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantNames: Map<String, String>.from(data['participantNames'] ?? {}),
      participantImages: Map<String, String>.from(data['participantImages'] ?? {}),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      productId: data['productId'],
      productTitle: data['productTitle'],
      productImage: data['productImage'],
      productPrice: data['productPrice']?.toDouble(),
      productOwnerId: data['productOwnerId'],
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
      isTyping: Map<String, bool>.from(data['isTyping'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      chatType: data['chatType'] ?? 'general',
      deletedBy: List<String>.from(data['deletedBy'] ?? []), // Handle deletedBy field
    );
  }

  // ENHANCED: Better logic for determining if user is buyer or seller
  bool isUserBuying(String userId) {
    if (productOwnerId != null) {
      // If we know who owns the product, user is buying if they don't own it
      return productOwnerId != userId;
    }
    
    // Fallback to existing logic
    return chatType == 'buying' || (productId != null && participants.first != userId);
  }

  bool isUserSelling(String userId) {
    if (productOwnerId != null) {
      // If we know who owns the product, user is selling if they own it
      return productOwnerId == userId;
    }
    
    // Fallback to existing logic
    return chatType == 'selling' || (productId != null && participants.first == userId);
  }

  // Get other participant ID
  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  // Get other participant name
  String getOtherParticipantName(String currentUserId) {
    final otherUserId = getOtherParticipantId(currentUserId);
    return participantNames[otherUserId] ?? 'Unknown User';
  }

  // Get other participant image
  String getOtherParticipantImage(String currentUserId) {
    final otherUserId = getOtherParticipantId(currentUserId);
    return participantImages[otherUserId] ?? '';
  }

  // Get unread count for user
  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  // Check if other user is typing
  bool isOtherUserTyping(String currentUserId) {
    final otherUserId = getOtherParticipantId(currentUserId);
    return isTyping[otherUserId] ?? false;
  }

  // Get formatted time
  String getFormattedTime() {
    if (lastMessageTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(lastMessageTime!);
    
    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return DateFormat('EEE').format(lastMessageTime!);
      } else {
        return DateFormat('MMM dd').format(lastMessageTime!);
      }
    } else if (difference.inHours > 0) {
      return DateFormat('HH:mm').format(lastMessageTime!);
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Now';
    }
  }

  // Get formatted price
  String getFormattedPrice() {
    if (productPrice == null) return '';
    return 'PKR ${productPrice!.toStringAsFixed(0)}';
  }

  Map<String, dynamic> toJson() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'participantImages': participantImages,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null 
          ? Timestamp.fromDate(lastMessageTime!) 
          : null,
      'lastMessageSenderId': lastMessageSenderId,
      'productId': productId,
      'productTitle': productTitle,
      'productImage': productImage,
      'productPrice': productPrice,
      'productOwnerId': productOwnerId, // NEW
      'unreadCount': unreadCount,
      'isTyping': isTyping,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'chatType': chatType,
    };
  }
}

// models/message_model.dart
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String message;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final List<String>? imageUrls;
  final Map<String, dynamic>? metadata;
  final String? replyToMessageId;
  final MessageStatus status;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.imageUrls,
    this.metadata,
    this.replyToMessageId,
    this.status = MessageStatus.sent,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      message: data['message'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${data['type']}',
        orElse: () => MessageType.text,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      imageUrls: data['imageUrls'] != null ? List<String>.from(data['imageUrls']) : null,
      metadata: data['metadata'],
      replyToMessageId: data['replyToMessageId'],
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${data['status']}',
        orElse: () => MessageStatus.sent,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'imageUrls': imageUrls,
      'metadata': metadata,
      'replyToMessageId': replyToMessageId,
      'status': status.toString().split('.').last,
    };
  }

  String getFormattedTime() {
    final now = DateTime.now();
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));

    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  bool isToday() {
    final now = DateTime.now();
    return timestamp.year == now.year &&
           timestamp.month == now.month &&
           timestamp.day == now.day;
  }
}

enum MessageType {
  text,
  image,
  file,
  location,
  product,
  system,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

// models/chat_participant_model.dart
class ChatParticipantModel {
  final String id;
  final String name;
  final String? profileImageUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final String type; // 'individual' or 'company'
  final DateTime createdAt;

  ChatParticipantModel({
    required this.id,
    required this.name,
    this.profileImageUrl,
    this.isOnline = false,
    this.lastSeen,
    required this.type,
    required this.createdAt,
  });

  factory ChatParticipantModel.fromUserModel(Map<String, dynamic> userData) {
    return ChatParticipantModel(
      id: userData['uid'] ?? '',
      name: userData['companyName'] ?? userData['name'] ?? 'Unknown User',
      profileImageUrl: userData['profileImage'],
      isOnline: userData['isOnline'] ?? false,
      lastSeen: userData['lastSeen'] != null 
          ? (userData['lastSeen'] as Timestamp).toDate()
          : null,
      type: userData['type'] ?? 'individual',
      createdAt: userData['createdAt'] != null
          ? (userData['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory ChatParticipantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatParticipantModel.fromUserModel({...data, 'uid': doc.id});
  }

  // Get online status text
  String getOnlineStatus() {
    if (isOnline) {
      return 'Online';
    } else if (lastSeen != null) {
      final now = DateTime.now();
      final difference = now.difference(lastSeen!);
      
      if (difference.inMinutes < 1) {
        return 'Last seen just now';
      } else if (difference.inMinutes < 60) {
        return 'Last seen ${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return 'Last seen ${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return 'Last seen ${difference.inDays}d ago';
      } else {
        return 'Last seen ${DateFormat('MMM dd').format(lastSeen!)}';
      }
    } else {
      return 'Last seen recently';
    }
  }

  // Get display name based on type
  String getDisplayName() {
    return name.isNotEmpty ? name : 'Unknown User';
  }

  // Get member since formatted
  String getMemberSinceFormatted() {
    return DateFormat('MMM yyyy').format(createdAt);
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': id,
      'name': name,
      'profileImage': profileImageUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ChatParticipantModel copyWith({
    String? id,
    String? name,
    String? profileImageUrl,
    bool? isOnline,
    DateTime? lastSeen,
    String? type,
    DateTime? createdAt,
  }) {
    return ChatParticipantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// models/typing_indicator_model.dart
class TypingIndicatorModel {
  final String chatId;
  final String userId;
  final String userName;
  final DateTime timestamp;

  TypingIndicatorModel({
    required this.chatId,
    required this.userId,
    required this.userName,
    required this.timestamp,
  });

  factory TypingIndicatorModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TypingIndicatorModel(
      chatId: data['chatId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'userId': userId,
      'userName': userName,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  bool isRecent() {
    return DateTime.now().difference(timestamp).inSeconds < 5;
  }
}