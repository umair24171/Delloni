// import 'dart:developer';
// import 'package:arabicmarketplace/controller/notification_service.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class NotificationHelpers {
//   static final NotificationService _notificationService = NotificationService();
//   static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // Send notification when someone follows a user
//   static Future<void> sendFollowerNotification({
//     required String followedUserId,
//     required String followerName,
//     required String followerId,
//   }) async {
//     try {
//       await _notificationService.sendNotificationToUser(
//         userId: followedUserId,
//         title: 'New Follower',
//         body: '$followerName started following you',
//         type: 'newFollower',
//         data: {
//           'followerId': followerId,
//           'followerName': followerName,
//         },
//       );
//     } catch (e) {
//       log('Error sending follower notification: $e');
//     }
//   }

//   // Send notification when an item is sold
//   static Future<void> sendItemSoldNotification({
//     required String sellerId,
//     required String itemTitle,
//     required String buyerName,
//     required String itemId,
//     required double price,
//   }) async {
//     try {
//       await _notificationService.sendNotificationToUser(
//         userId: sellerId,
//         title: 'Item Sold!',
//         body: 'Your "$itemTitle" was sold to $buyerName for \$${price.toStringAsFixed(2)}',
//         type: 'itemSold',
//         data: {
//           'itemId': itemId,
//           'itemTitle': itemTitle,
//           'buyerName': buyerName,
//           'price': price,
//         },
//       );
//     } catch (e) {
//       log('Error sending item sold notification: $e');
//     }
//   }

//   // Send notification for new message
//   static Future<void> sendNewMessageNotification({
//     required String recipientId,
//     required String senderName,
//     required String senderId,
//     required String messagePreview,
//     required String chatId,
//   }) async {
//     try {
//       await _notificationService.sendNotificationToUser(
//         userId: recipientId,
//         title: 'New Message',
//         body: '$senderName: $messagePreview',
//         type: 'newMessage',
//         data: {
//           'senderId': senderId,
//           'senderName': senderName,
//           'chatId': chatId,
//         },
//       );
//     } catch (e) {
//       log('Error sending new message notification: $e');
//     }
//   }

//   // Send notification when price is reduced
//   static Future<void> sendPriceReductionNotification({
//     required String itemId,
//     required String itemTitle,
//     required double oldPrice,
//     required double newPrice,
//     required List<String> watcherIds,
//   }) async {
//     try {
//       final reductionPercentage = ((oldPrice - newPrice) / oldPrice * 100).round();
      
//       for (String watcherId in watcherIds) {
//         await _notificationService.sendNotificationToUser(
//           userId: watcherId,
//           title: 'Price Drop Alert!',
//           body: '$itemTitle price reduced by $reductionPercentage% to \$${newPrice.toStringAsFixed(2)}',
//           type: 'priceReduction',
//           data: {
//             'itemId': itemId,
//             'itemTitle': itemTitle,
//             'oldPrice': oldPrice,
//             'newPrice': newPrice,
//             'reductionPercentage': reductionPercentage,
//           },
//         );
//       }
//     } catch (e) {
//       log('Error sending price reduction notification: $e');
//     }
//   }

//   // Send notification when item is about to expire
//   static Future<void> sendItemExpiringNotification({
//     required String sellerId,
//     required String itemId,
//     required String itemTitle,
//     required int daysLeft,
//   }) async {
//     try {
//       await _notificationService.sendNotificationToUser(
//         userId: sellerId,
//         title: 'Listing Expiring Soon',
//         body: 'Your "$itemTitle" listing expires in $daysLeft days',
//         type: 'itemExpiring',
//         data: {
//           'itemId': itemId,
//           'itemTitle': itemTitle,
//           'daysLeft': daysLeft,
//         },
//       );
//     } catch (e) {
//       log('Error sending item expiring notification: $e');
//     }
//   }

//   // Send notification when new item is posted in user's interested categories
//   static Future<void> sendNewItemInCategoryNotification({
//     required String category,
//     required String itemId,
//     required String itemTitle,
//     required double price,
//     required String location,
//   }) async {
//     try {
//       // Get users who have enabled notifications for this category
//       QuerySnapshot usersWithCategoryEnabled = await _firestore
//           .collectionGroup('settings')
//           .where(category, isEqualTo: true)
//           .get();

//       for (DocumentSnapshot userSetting in usersWithCategoryEnabled.docs) {
//         // Extract user ID from document path
//         String userId = userSetting.reference.parent.parent!.id;
        
//         await _notificationService.sendNotificationToUser(
//           userId: userId,
//           title: 'New ${_getCategoryDisplayName(category)} Item',
//           body: '$itemTitle posted for \$${price.toStringAsFixed(2)} in $location',
//           type: category,
//           data: {
//             'itemId': itemId,
//             'itemTitle': itemTitle,
//             'price': price,
//             'location': location,
//             'category': category,
//           },
//         );
//       }
//     } catch (e) {
//       log('Error sending category notification: $e');
//     }
//   }

//   // Send notification for item inquiry
//   static Future<void> sendItemInquiryNotification({
//     required String sellerId,
//     required String inquirerName,
//     required String inquirerId,
//     required String itemTitle,
//     required String itemId,
//     required String message,
//   }) async {
//     try {
//       await _notificationService.sendNotificationToUser(
//         userId: sellerId,
//         title: 'New Inquiry',
//         body: '$inquirerName is interested in your "$itemTitle"',
//         type: 'newMessage',
//         data: {
//           'inquirerId': inquirerId,
//           'inquirerName': inquirerName,
//           'itemId': itemId,
//           'itemTitle': itemTitle,
//           'message': message,
//         },
//       );
//     } catch (e) {
//       log('Error sending inquiry notification: $e');
//     }
//   }

//   // Send notification when item is liked
//   static Future<void> sendItemLikedNotification({
//     required String sellerId,
//     required String likerName,
//     required String likerId,
//     required String itemTitle,
//     required String itemId,
//   }) async {
//     try {
//       await _notificationService.sendNotificationToUser(
//         userId: sellerId,
//         title: 'Item Liked',
//         body: '$likerName liked your "$itemTitle"',
//         type: 'itemLiked',
//         data: {
//           'likerId': likerId,
//           'likerName': likerName,
//           'itemId': itemId,
//           'itemTitle': itemTitle,
//         },
//       );
//     } catch (e) {
//       log('Error sending item liked notification: $e');
//     }
//   }

//   // Send welcome notification to new users
//   static Future<void> sendWelcomeNotification(String userId, String userName) async {
//     try {
//       await _notificationService.sendNotificationToUser(
//         userId: userId,
//         title: 'Welcome to Delloni!',
//         body: 'Hi $userName! Start exploring amazing deals in your area.',
//         type: 'welcome',
//         data: {
//           'userName': userName,
//         },
//       );
//     } catch (e) {
//       log('Error sending welcome notification: $e');
//     }
//   }

//   // Send bulk notifications for app updates or announcements
//   static Future<void> sendAnnouncementNotification({
//     required String title,
//     required String body,
//     required Map<String, dynamic> data,
//   }) async {
//     try {
//       // This would typically be done from your backend server
//       await _notificationService.sendCategoryNotification(
//         category: 'announcement',
//         title: title,
//         body: body,
//         data: data,
//       );
//     } catch (e) {
//       log('Error sending announcement: $e');
//     }
//   }

//   // Auto-cleanup old notifications for all users (background task)
//   static Future<void> cleanupOldNotificationsForAllUsers() async {
//     try {
//       // This should be run as a scheduled cloud function
//       QuerySnapshot users = await _firestore.collection('users').get();
      
//       for (DocumentSnapshot user in users.docs) {
//         await _notificationService.cleanupOldNotifications(user.id);
//       }
      
//       log('Cleanup completed for ${users.docs.length} users');
//     } catch (e) {
//       log('Error in bulk cleanup: $e');
//     }
//   }

//   // Get category display name
//   static String _getCategoryDisplayName(String category) {
//     switch (category) {
//       case 'mobile':
//         return 'Mobile & Accessories';
//       case 'cars':
//         return 'Cars & Vehicles';
//       case 'electronics':
//         return 'Electronics';
//       case 'furniture':
//         return 'Furniture';
//       case 'clothing':
//         return 'Clothing & Fashion';
//       case 'books':
//         return 'Books';
//       case 'sports':
//         return 'Sports & Outdoors';
//       case 'beauty':
//         return 'Beauty & Personal Care';
//       case 'home':
//         return 'Home & Garden';
//       case 'toys':
//         return 'Toys & Games';
//       default:
//         return category.toUpperCase();
//     }
//   }

//   // Send notification when offer is received
//   static Future<void> sendOfferReceivedNotification({
//     required String sellerId,
//     required String buyerName,
//     required String buyerId,
//     required String itemTitle,
//     required String itemId,
//     required double offerAmount,
//     required double originalPrice,
//   }) async {
//     try {
//       final discountPercentage = ((originalPrice - offerAmount) / originalPrice * 100).round();
      
//       await _notificationService.sendNotificationToUser(
//         userId: sellerId,
//         title: 'New Offer Received',
//         body: '$buyerName offered \$${offerAmount.toStringAsFixed(2)} for "$itemTitle" (${discountPercentage}% off)',
//         type: 'offerReceived',
//         data: {
//           'buyerId': buyerId,
//           'buyerName': buyerName,
//           'itemId': itemId,
//           'itemTitle': itemTitle,
//           'offerAmount': offerAmount,
//           'originalPrice': originalPrice,
//           'discountPercentage': discountPercentage,
//         },
//       );
//     } catch (e) {
//       log('Error sending offer notification: $e');
//     }
//   }

//   // Send notification when offer is accepted/rejected
//   static Future<void> sendOfferResponseNotification({
//     required String buyerId,
//     required String sellerName,
//     required String sellerId,
//     required String itemTitle,
//     required String itemId,
//     required bool accepted,
//     required double offerAmount,
//   }) async {
//     try {
//       await _notificationService.sendNotificationToUser(
//         userId: buyerId,
//         title: accepted ? 'Offer Accepted!' : 'Offer Declined',
//         body: accepted 
//             ? '$sellerName accepted your offer of \${offerAmount.toStringAsFixed(2)} for "$itemTitle"'
//             : '$sellerName declined your offer for "$itemTitle"',
//         type: accepted ? 'offerAccepted' : 'offerDeclined',
//         data: {
//           'sellerId': sellerId,
//           'sellerName': sellerName,
//           'itemId': itemId,
//           'itemTitle': itemTitle,
//           'offerAmount': offerAmount,
//           'accepted': accepted,
//         },
//       );
//     } catch (e) {
//       log('Error sending offer response notification: $e');
//     }
//   }

//   // Send notification when user receives a review
//   static Future<void> sendReviewReceivedNotification({
//     required String revieweeId,
//     required String reviewerName,
//     required String itemTitle,
//     required double rating,
//   }) async {
//     try {
//       String ratingText = '';
//       if (rating <= 2) ratingText = 'poor';
//       else if (rating <= 3) ratingText = 'fair';
//       else if (rating <= 4) ratingText = 'good';
//       else ratingText = 'excellent';

//       await _notificationService.sendNotificationToUser(
//         userId: revieweeId,
//         title: 'New Review Received',
//         body: '$reviewerName left you an $ratingText review (${rating.toStringAsFixed(1)} stars) for "$itemTitle"',
//         type: 'reviewReceived',
//         data: {
//           'reviewerName': reviewerName,
//           'itemTitle': itemTitle,
//           'rating': rating,
//           'ratingText': ratingText,
//         },
//       );
//     } catch (e) {
//       log('Error sending review notification: $e');
//     }
//   }
// }