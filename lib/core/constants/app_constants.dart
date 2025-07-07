/// Application-wide constants
class AppConstants {
  // Hive box names
  static const String tasksBoxName = 'tasks';
  static const String themeBoxName = 'theme_settings';
  
  // Theme settings
  static const String themeKey = 'is_dark_mode';
  
  // Notification channels
  static const String notificationChannelId = 'scheduled_notifications';
  static const String notificationChannelName = 'Zamanlanmış Bildirimler';
  static const String notificationChannelDescription = 'Zamanlanmış görev bildirimleri';
  
  // Default notification IDs
  static const int reminderOffset = 0;
  static const int dueDateOffset = 1000000; // For due date notifications
  
  // Route names for GetX navigation
  static const String homeRoute = '/';
  static const String addTaskRoute = '/add-task';
  static const String taskDetailRoute = '/task-detail';
  static const String notificationsRoute = '/notifications';
  static const String settingsRoute = '/settings';
}
