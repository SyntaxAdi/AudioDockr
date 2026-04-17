import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _downloadChannelId = 'download_channel_v6';
  static const String _downloadChannelName = 'Downloads';
  static const String _downloadChannelDescription =
      'Notifications for track download progress';

  // Specific IDs for notifications
  static const int downloadNotificationId = 888;

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(initSettings);

    // Create channel for Android
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _downloadChannelId,
          _downloadChannelName,
          description: _downloadChannelDescription,
          importance: Importance.defaultImportance,
          showBadge: false,
          playSound: false,
        ),
      );
    }
  }

  Future<void> showDownloadProgress({
    required String title,
    required int progress, // 0 to 100
    bool isCompleted = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _downloadChannelId,
      _downloadChannelName,
      channelDescription: _downloadChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      onlyAlertOnce: true,
      playSound: false,
      enableVibration: false,
      showProgress: !isCompleted,
      maxProgress: 100,
      progress: progress,
      ongoing: !isCompleted,
      autoCancel: isCompleted,
      showWhen: true,
      subText: isCompleted ? null : '$progress%',
      category: AndroidNotificationCategory.progress,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      downloadNotificationId,
      isCompleted ? 'Download Complete' : 'Downloading $title',
      isCompleted ? title : null,
      notificationDetails,
    );
  }

  Future<void> showPlaylistProgress({
    required String playlistName,
    required int totalTracks,
    required int completedTracks,
    required int averageProgress, // 0 to 100
  }) async {
    final bool isFinished = completedTracks == totalTracks;

    final androidDetails = AndroidNotificationDetails(
      _downloadChannelId,
      _downloadChannelName,
      channelDescription: _downloadChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      onlyAlertOnce: true,
      playSound: false,
      enableVibration: false,
      showProgress: !isFinished,
      maxProgress: 100,
      progress: averageProgress,
      ongoing: !isFinished,
      autoCancel: isFinished,
      showWhen: true,
      subText: isFinished ? null : '$averageProgress%',
      category: AndroidNotificationCategory.progress,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      downloadNotificationId,
      isFinished 
          ? 'Playlist Download Complete' 
          : 'Downloading $playlistName',
      isFinished 
          ? playlistName 
          : null,
      notificationDetails,
    );
  }

  Future<void> cancelDownloadNotification() async {
    await _notificationsPlugin.cancel(downloadNotificationId);
  }
}
