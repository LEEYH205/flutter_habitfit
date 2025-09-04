import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      icon: Icons.fitness_center,
      iconColor: Colors.blue,
      title: 'Hi! It\'s Bogo',
      message:
          'It\'s time to your daily Outdoor Walk. Take 30 minutes now to complete it',
      time: '7d',
      isUnread: true,
    ),
    NotificationItem(
      icon: Icons.eco,
      iconColor: Colors.green,
      title: 'Hello! It\'s Sunny',
      message: 'Great job on your workout today! Keep up the momentum.',
      time: '6h',
      isUnread: true,
    ),
    NotificationItem(
      icon: Icons.fitness_center,
      iconColor: Colors.orange,
      title: 'Workout Reminder',
      message: 'Don\'t forget your evening workout session.',
      time: '5h',
      isUnread: false,
    ),
    NotificationItem(
      icon: Icons.menu_book,
      iconColor: Colors.blue,
      title: 'Daily Reading',
      message: 'Time for your daily reading habit. 15 minutes to go!',
      time: '4h',
      isUnread: false,
    ),
    NotificationItem(
      icon: Icons.water_drop,
      iconColor: Colors.cyan,
      title: 'Hydration Check',
      message: 'You\'ve reached 75% of your daily water goal.',
      time: '3h',
      isUnread: false,
    ),
    NotificationItem(
      icon: Icons.bedtime,
      iconColor: Colors.purple,
      title: 'Sleep Reminder',
      message: 'It\'s time to wind down for better sleep quality.',
      time: '2h',
      isUnread: false,
    ),
    NotificationItem(
      icon: Icons.celebration,
      iconColor: Colors.amber,
      title: 'Achievement Unlocked!',
      message:
          'Congratulations! You\'ve completed 7 days of consistent workouts.',
      time: '1h',
      isUnread: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Search Bar
            _buildSearchBar(),

            // Notifications List
            Expanded(
              child: _buildNotificationsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            color: Colors.black,
          ),
          const Expanded(
            child: Text(
              'Notifications',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              'Mark all as read',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Search any notifications..',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LAST 7 DAYS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: notification.iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              notification.icon,
              color: notification.iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Time and unread indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                notification.time,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              if (notification.isUnread)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isUnread = false;
      }
    });
  }
}

class NotificationItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String time;
  bool isUnread;

  NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.time,
    required this.isUnread,
  });
}
