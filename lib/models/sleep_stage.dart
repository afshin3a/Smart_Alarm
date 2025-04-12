enum SleepStage { awake, nrem1, nrem2, nrem3, rem, unknown }

class SleepData {
  final DateTime timestamp;
  final SleepStage stage;
  final Map<String, dynamic> sensorData;

  SleepData({
    required this.timestamp,
    required this.stage,
    required this.sensorData,
  });
}

enum AlarmMode {
  nap, // حالت چرت روزانه
  nightSleep // حالت خواب شبانه
}

class AlarmSettings {
  final AlarmMode mode;
  final DateTime targetTime;
  final int maxDurationMinutes;
  final bool isEnabled;

  AlarmSettings({
    required this.mode,
    required this.targetTime,
    required this.maxDurationMinutes,
    this.isEnabled = true,
  });
}
