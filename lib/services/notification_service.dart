import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _downloadChannelId = 'download_channel_v7';
  static const String _downloadChannelName = 'Downloads';
  static const String _downloadChannelDescription =
      'Silent notifications for track download progress';

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
          importance: Importance.low, // LOW importance prevents pop-up/sound
          showBadge: false,
          playSound: false,
          enableVibration: false,
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
      importance: Importance.low, // Silent
      priority: Priority.low,     // Quiet
      onlyAlertOnce: true,        // Don't alert on every progress update
      playSound: false,
      enableVibration: false,
      showProgress: !isCompleted,
      maxProgress: 100,
      progress: progress,
      ongoing: !isCompleted,      // FLAG_ONGOING_EVENT
      autoCancel: isCompleted,
      showWhen: true,
      subText: isCompleted ? null : '$progress%',
      category: AndroidNotificationCategory.progress,
      styleInformation: const BigTextStyleInformation(''), 
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      downloadNotificationId,
      isCompleted ? 'Download Complete' : 'Downloading $title',
      null, 
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
      importance: Importance.low, // Silent
      priority: Priority.low,     // Quiet
      onlyAlertOnce: true,
      playSound: false,
      enableVibration: false,
      showProgress: !isFinished,
      maxProgress: 100,
      progress: averageProgress,
      ongoing: !isFinished,      // FLAG_ONGOING_EVENT
      autoCancel: isFinished,
      showWhen: true,
      subText: isFinished ? null : '$averageProgress%',
      category: AndroidNotificationCategory.progress,
      styleInformation: const BigTextStyleInformation(''),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      downloadNotificationId,
      isFinished 
          ? 'Playlist Download Complete' 
          : 'Downloading $playlistName',
      null, 
      notificationDetails,
    );
  }

  Future<void> cancelDownloadNotification() async {
    await _notificationsPlugin.cancel(downloadNotificationId);
  }
}
