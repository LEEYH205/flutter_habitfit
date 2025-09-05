import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import '../providers/auth_provider.dart';
import '../features/notifications/notifications_page.dart';
import '../features/settings/settings_page.dart';

class AppBarWithNotifications extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final bool showNotifications;
  final bool showProfile;

  const AppBarWithNotifications({
    super.key,
    required this.title,
    this.showNotifications = true,
    this.showProfile = true,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider =
        provider.Provider.of<AuthProvider>(context, listen: true);
    final currentUser = authProvider.user;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        if (showNotifications) ...[
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationsPage(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black,
                ),
              ),
              // Red dot for unread notifications
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (showProfile) ...[
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: currentUser?.photoURL != null
                    ? NetworkImage(currentUser!.photoURL!)
                    : null,
                child: authProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.grey,
                        ),
                      )
                    : currentUser?.photoURL == null
                        ? const Icon(
                            Icons.person,
                            size: 20,
                            color: Colors.grey,
                          )
                        : null,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
