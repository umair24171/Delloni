import 'package:arabicmarketplace/controller/notification_provider.dart';
import 'package:arabicmarketplace/screens/chat/view/chat_screen.dart';
import 'package:arabicmarketplace/screens/notifications/view/notification_saved_search_page.dart';
import 'package:arabicmarketplace/screens/product_detail/view/product_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:arabicmarketplace/utills/AppLocalizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Simplified NotificationsPage - Only Messages & Saved Searches
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load notification preferences when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotificationPreferences();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).colorScheme.onBackground,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.notifications.tr(),
          style: GoogleFonts.jost(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onBackground,
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xff014700),
          tabs: [
            Tab(text: AppLocalizations.settings.tr()), // Add .tr()
            Tab(text: AppLocalizations.history.tr()), // Add .tr()
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPreferencesTab(), _buildHistoryTab()],
      ),
    );
  }

  Widget _buildPreferencesTab() {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        if (notificationProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (notificationProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: ${notificationProvider.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      notificationProvider.loadNotificationPreferences(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification Types Section
            Text(
              'Notification Settings'.tr(),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
              // TODO: Replace with AppLocalizations.notificationSettings.tr() if _buildSectionTitle is updated
              const SizedBox(height: 16),

              // ONLY Message Notifications
              _buildNotificationTile(
                icon: Icons.message,
                title: AppLocalizations.messageNotifications.tr(),
                subtitle: AppLocalizations.getNotifiedMessages.tr(),
                value: notificationProvider.newMessageNotifications,
                onChanged: (value) => notificationProvider
                    .updateNotificationPreference('newMessage', value),
              ),

              const SizedBox(height: 20),

              // ONLY Saved Search Notifications
              _buildNotificationTile(
                icon: Icons.bookmark,
                title: AppLocalizations.savedSearchAlert.tr(),
                subtitle: AppLocalizations.savedSearchAlert.tr(),
                value: notificationProvider.savedSearchNotifications,
                onChanged: (value) => notificationProvider
                    .updateNotificationPreference('savedSearch', value),
              ),

              const SizedBox(height: 40),

              // Saved Searches Management Button
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SavedSearchesPage(),
                      ),
                    );
                  },
                  icon: Icon(Icons.bookmark_border),
                  label: Text('Manage Saved Searches'.tr()),
                  // TODO: Replace with AppLocalizations.manageSavedSearches.tr() if needed
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff014700),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Info section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can adjust these settings anytime to control what notifications you receive.'
                            .tr(),
                        // TODO: Replace with AppLocalizations.adjustSettingsAnytime.tr() if needed
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .collection('notifications')
              .orderBy('createdAt', descending: true)
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.noNotificationsYet.tr(),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.youllSeeNotificationsHere.tr(),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final notification = snapshot.data!.docs[index];
                final data = notification.data() as Map<String, dynamic>;

                return _buildNotificationHistoryItem(
                  title: data['title'] ?? '',
                  body: data['body'] ?? '',
                  type: data['type'] ?? '',
                  createdAt:
                      (data['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime.now(),
                  isRead: data['read'] ?? false,
                  onTap: () {
                    // Mark as read and handle tap
                    _handleNotificationTap(notification.id, data);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationHistoryItem({
    required String title,
    required String body,
    required String type,
    required DateTime createdAt,
    required bool isRead,
    required VoidCallback onTap,
  }) {
    IconData icon;
    Color iconColor;

    switch (type) {
      case 'newMessage':
        icon = Icons.message;
        iconColor = Colors.blue;
        break;
      case 'savedSearch':
        icon = Icons.bookmark;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRead ? Colors.grey[300]! : Colors.blue[200]!,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(
    String notificationId,
    Map<String, dynamic> data,
  ) {
    // Mark notification as read
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});

    // Handle navigation based on notification type
    switch (data['type']) {
      case 'newMessage':
        // Navigate to chat
        final chatId = data['data']?['chatId'];
        if (chatId != null) {
          // Navigate to individual chat page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatPage()),
          );
        }
        break;
      case 'savedSearch':
        // Navigate to search results or item details
        final itemId = data['data']?['itemId'];
        if (itemId != null) {
          // Navigate to item details page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: itemId),
            ),
          );
        }
        break;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return AppLocalizations.justNow.tr();
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}${AppLocalizations.mAgo.tr()}';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}${AppLocalizations.hAgo.tr()}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}${AppLocalizations.dAgo.tr()}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xff014700).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 24, color: const Color(0xff014700)),
          ),
          const SizedBox(width: 16),
          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.tr(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle.tr(),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Toggle switch
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xff014700),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }
}
