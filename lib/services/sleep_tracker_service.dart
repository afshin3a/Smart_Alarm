import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/sleep_stage.dart';

class SleepTrackerService {
  // مقادیر برای نگهداری داده‌های سنسورها
  List<double> _accelerometerValues = [0, 0, 0];
  List<SleepData> _sleepDataHistory = [];
  StreamSubscription<dynamic>? _accelerometerSubscription;
  Timer? _analyzeTimer;
  SleepStage _currentSleepStage = SleepStage.unknown;
  int _sleepCycleCount = 0;

  // زمان شروع خواب
  DateTime? _sleepStartTime;

  // پارامترهای الگوریتم تشخیص خواب
  final int _windowSizeSeconds = 60;
  final double _movementThresholdNrem1 = 0.3;
  final double _movementThresholdNrem2 = 0.1;
  final double _movementThresholdNrem3 = 0.05;

  // تابع شروع ردیابی
  Future<void> startTracking() async {
    // پاک کردن تاریخچه قبلی
    _sleepDataHistory = [];
    _sleepCycleCount = 0;
    _sleepStartTime = DateTime.now();

    // شروع جمع‌آوری داده از سنسور شتاب‌سنج
    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      _accelerometerValues = [event.x, event.y, event.z];
    });

    // راه‌اندازی تایمر برای تحلیل داده‌ها هر 30 ثانیه
    _analyzeTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _analyzeSleepStage();
    });
  }

  // توقف ردیابی
  void stopTracking() {
    _accelerometerSubscription?.cancel();
    _analyzeTimer?.cancel();
    _currentSleepStage = SleepStage.unknown;
  }

  // دریافت مرحله فعلی خواب
  SleepStage getCurrentSleepStage() {
    return _currentSleepStage;
  }

  // دریافت تعداد چرخه‌های خواب
  int getSleepCycleCount() {
    return _sleepCycleCount;
  }

  // تحلیل مرحله خواب براساس داده‌های سنسورها
  void _analyzeSleepStage() {
    // محاسبه میزان حرکت در بازه زمانی اخیر
    double movementScore = _calculateMovementScore();
    SleepStage previousStage = _currentSleepStage;

    // تشخیص مرحله خواب براساس میزان حرکت
    if (movementScore > _movementThresholdNrem1) {
      _currentSleepStage = SleepStage.awake;
    } else if (movementScore > _movementThresholdNrem2) {
      _currentSleepStage = SleepStage.nrem1;
    } else if (movementScore > _movementThresholdNrem3) {
      _currentSleepStage = SleepStage.nrem2;
    } else {
      _currentSleepStage = SleepStage.nrem3;
    }

    // ثبت داده‌ها در تاریخچه
    _sleepDataHistory.add(SleepData(
      timestamp: DateTime.now(),
      stage: _currentSleepStage,
      sensorData: {
        'accelerometer': List.from(_accelerometerValues),
        'movementScore': movementScore
      },
    ));

    // محاسبه چرخه‌های خواب
    if (previousStage == SleepStage.nrem3 &&
        _currentSleepStage != SleepStage.nrem3) {
      _sleepCycleCount++;
    }
  }

  // محاسبه امتیاز حرکت براساس داده‌های شتاب‌سنج
  double _calculateMovementScore() {
    // این یک الگوریتم ساده است - در حالت واقعی نیاز به الگوریتم‌های پیچیده‌تر دارد
    double sum = 0;
    for (var value in _accelerometerValues) {
      sum += value.abs();
    }
    return sum / 3; // میانگین ساده شتاب مطلق در سه محور
  }

  // بررسی اینکه آیا زمان مناسب برای فعال شدن آلارم است
  bool isTimeToWakeUp(AlarmSettings settings) {
    // حالت چرت روزانه: اگر وارد NREM3 شد زنگ بزند
    if (settings.mode == AlarmMode.nap &&
        _currentSleepStage == SleepStage.nrem3) {
      return true;
    }

    // حالت خواب شبانه: در چرخه چهارم، اگر در NREM1 یا NREM2 بود زنگ بزند
    if (settings.mode == AlarmMode.nightSleep &&
        _sleepCycleCount >= 4 &&
        (DateTime.now().difference(_sleepStartTime!).inMinutes >=
            settings.maxDurationMinutes * 0.8) &&
        (_currentSleepStage == SleepStage.nrem1 ||
            _currentSleepStage == SleepStage.nrem2)) {
      return true;
    }

    // اگر به زمان نهایی رسیدیم، صرف نظر از مرحله خواب زنگ بزن
    if (DateTime.now().isAfter(settings.targetTime)) {
      return true;
    }

    return false;
  }
}
