import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/sleep_stage.dart';
import 'sleep_tracker_service.dart';

class AlarmService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final SleepTrackerService _sleepTracker;
  Timer? _checkTimer;
  AlarmSettings? _currentSettings;

  AlarmService(this._sleepTracker);

  // راه‌اندازی سرویس آلارم
  Future<void> initialize() async {
    // تنظیم اولیه اعلان‌ها
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);
  }

  // تنظیم آلارم جدید
  void setAlarm(AlarmSettings settings) {
    _currentSettings = settings;

    if (_checkTimer != null) {
      _checkTimer!.cancel();
    }

    // شروع ردیابی خواب
    _sleepTracker.startTracking();

    // تایمر برای بررسی شرایط آلارم هر 30 ثانیه
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkAlarmConditions();
    });
  }

  // لغو آلارم فعلی
  void cancelAlarm() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _currentSettings = null;
    _sleepTracker.stopTracking();
    _notificationsPlugin.cancelAll();
  }

  // بررسی شرایط برای فعال کردن آلارم
  void _checkAlarmConditions() {
    if (_currentSettings == null || !_currentSettings!.isEnabled) {
      return;
    }

    if (_sleepTracker.isTimeToWakeUp(_currentSettings!)) {
      _triggerAlarm();
    }
  }

  // فعال کردن آلارم
  Future<void> _triggerAlarm() async {
    // تنظیم اعلان هشدار
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'alarm_channel',
      'Smart Alarm',
      channelDescription: 'Channel for Smart Alarm notifications',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      playSound: true,
      ongoing: true,
      autoCancel: false,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    String stageName = 'نامشخص';
    SleepStage currentStage = _sleepTracker.getCurrentSleepStage();

    switch (currentStage) {
      case SleepStage.nrem1:
        stageName = 'NREM1';
        break;
      case SleepStage.nrem2:
        stageName = 'NREM2';
        break;
      case SleepStage.nrem3:
        stageName = 'NREM3';
        break;
      case SleepStage.rem:
        stageName = 'REM';
        break;
      case SleepStage.awake:
        stageName = 'بیدار';
        break;
      default:
        stageName = 'نامشخص';
    }

    await _notificationsPlugin.show(
      0,
      'زمان بیدار شدن',
      'مرحله خواب فعلی: $stageName - زمان مناسب برای بیدار شدن!',
      platformDetails,
    );

    // متوقف کردن ردیابی
    cancelAlarm();
  }
}
