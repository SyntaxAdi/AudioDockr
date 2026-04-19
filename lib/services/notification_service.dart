import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../settings/app_preferences.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  int _downloadNotificationGeneration = 0;

  static const String _downloadChannelId = 'download_channel_v11';
  static const String _downloadChannelName = 'Downloads';
  static const String _downloadChannelDescription =
      'Silent notifications for track download progress';
  static const String _downloadContentTitle = 'Downloading Song';
  static const String _completionChannelId = 'download_complete_channel_v4';
  static const String _completionChannelName = 'Download Complete';
  static const String _completionChannelDescription =
      'Heads-up notifications for completed downloads';

  // Specific IDs for notifications
  static const int downloadNotificationId = 888;
  static const int downloadCompleteNotificationId = 889;

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(initSettings);

    // Create channel for Android
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _downloadChannelId,
          _downloadChannelName,
          description: _downloadChannelDescription,
          importance: Importance.defaultImportance,
          showBadge: false,
          playSound: false,
          enableVibration: false,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _completionChannelId,
          _completionChannelName,
          description: _completionChannelDescription,
          importance: Importance.max,
          showBadge: false,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
  }

  Future<void> showDownloadProgress({
    required String title,
    required int progress, // 0 to 100
    bool isCompleted = false,
  }) async {
    final generation = _downloadNotificationGeneration;
    final isEnabled = await AppPreferences.loadDownloadOngoingNotifications();
    if (!isEnabled) return;
    if (generation != _downloadNotificationGeneration) return;

    final safeProgress = progress.clamp(0, 99).toInt();
    final androidDetails = AndroidNotificationDetails(
      _downloadChannelId,
      _downloadChannelName,
      channelDescription: _downloadChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      silent: true,
      onlyAlertOnce: true, // Don't alert on every progress update
      playSound: false,
      enableVibration: false,
      showProgress: !isCompleted,
      indeterminate: false,
      maxProgress: 100,
      progress: safeProgress,
      ongoing: !isCompleted, // FLAG_ONGOING_EVENT
      autoCancel: isCompleted,
      showWhen: true,
      subText: isCompleted ? null : '$safeProgress%',
      category: AndroidNotificationCategory.progress,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      downloadNotificationId,
      isCompleted ? 'Download Complete' : _downloadContentTitle,
      isCompleted ? 'File has been added to your library' : null,
      notificationDetails,
    );
  }

  Future<void> showPlaylistProgress({
    required String playlistName,
    required int totalTracks,
    required int completedTracks,
    required int averageProgress, // 0 to 100
  }) async {
    final generation = _downloadNotificationGeneration;
    final isEnabled = await AppPreferences.loadDownloadOngoingNotifications();
    if (!isEnabled) return;
    if (generation != _downloadNotificationGeneration) return;

    final bool isFinished = completedTracks == totalTracks;
    final safeProgress = averageProgress.clamp(0, 99).toInt();

    final androidDetails = AndroidNotificationDetails(
      _downloadChannelId,
      _downloadChannelName,
      channelDescription: _downloadChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      silent: true,
      onlyAlertOnce: true,
      playSound: false,
      enableVibration: false,
      showProgress: !isFinished,
      maxProgress: 100,
      progress: safeProgress,
      ongoing: !isFinished, // FLAG_ONGOING_EVENT
      autoCancel: isFinished,
      showWhen: true,
      subText: isFinished ? null : '$safeProgress%',
      category: AndroidNotificationCategory.progress,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      downloadNotificationId,
      isFinished ? 'Playlist Download Complete' : _downloadContentTitle,
      isFinished ? 'All tracks added to your library' : null,
      notificationDetails,
    );
  }

  Future<void> showAllDownloadsCompletedAlert() async {
    await cancelDownloadNotification();

    final isEnabled = await AppPreferences.loadDownloadCompletedNotifications();
    if (!isEnabled) return;

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _completionChannelId,
          _completionChannelName,
          description: _completionChannelDescription,
          importance: Importance.max,
          showBadge: false,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    const androidDetails = AndroidNotificationDetails(
      _completionChannelId,
      _completionChannelName,
      channelDescription: _completionChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: false,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      downloadCompleteNotificationId,
      'Downloads Complete',
      null,
      notificationDetails,
    );
  }

  Future<void> cancelDownloadNotification() async {
    _downloadNotificationGeneration++;
    await _notificationsPlugin.cancel(downloadNotificationId);
  }
}
