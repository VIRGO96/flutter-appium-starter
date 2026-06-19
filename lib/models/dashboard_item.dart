import 'package:flutter/material.dart';

/// Model representing a single item on the dashboard grid.
class DashboardItem {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const DashboardItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// Sample data used to populate the dashboard.
final List<DashboardItem> sampleDashboardItems = [
  DashboardItem(
    id: '1',
    title: 'Analytics',
    description: 'View your performance metrics and insights.',
    icon: Icons.bar_chart_rounded,
    color: Colors.indigo,
  ),
  DashboardItem(
    id: '2',
    title: 'Messages',
    description: '3 unread messages from your team.',
    icon: Icons.chat_bubble_rounded,
    color: Colors.teal,
  ),
  DashboardItem(
    id: '3',
    title: 'Tasks',
    description: '5 tasks pending review this week.',
    icon: Icons.task_alt_rounded,
    color: Colors.orange,
  ),
  DashboardItem(
    id: '4',
    title: 'Calendar',
    description: 'Next meeting at 2:00 PM today.',
    icon: Icons.calendar_month_rounded,
    color: Colors.pink,
  ),
  DashboardItem(
    id: '5',
    title: 'Files',
    description: 'Browse and manage your documents.',
    icon: Icons.folder_rounded,
    color: Colors.amber,
  ),
  DashboardItem(
    id: '6',
    title: 'Settings',
    description: 'Configure your account preferences.',
    icon: Icons.settings_rounded,
    color: Colors.blueGrey,
  ),
  DashboardItem(
    id: '7',
    title: 'Notifications',
    description: '2 new alerts require your attention.',
    icon: Icons.notifications_rounded,
    color: Colors.deepPurple,
  ),
  DashboardItem(
    id: '8',
    title: 'Help Center',
    description: 'Documentation, guides, and support.',
    icon: Icons.help_rounded,
    color: Colors.green,
  ),
];
