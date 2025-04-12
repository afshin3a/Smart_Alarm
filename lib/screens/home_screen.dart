import 'package:flutter/material.dart';
import '../models/sleep_stage.dart';
import '../services/alarm_service.dart';
import '../services/sleep_tracker_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SleepTrackerService _sleepTracker = SleepTrackerService();
  late AlarmService _alarmService;
  AlarmMode _selectedMode = AlarmMode.nap;
  DateTime _targetTime = DateTime.now().add(const Duration(hours: 8));
  bool _isAlarmSet = false;
  int _napDuration = 30; // به دقیقه
  int _nightSleepDuration = 480; // 8 ساعت به دقیقه

  @override
  void initState() {
    super.initState();
    _alarmService = AlarmService(_sleepTracker);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _alarmService.initialize();
  }

  void _setAlarm() {
    final DateTime now = DateTime.now();
    int durationMinutes =
        _selectedMode == AlarmMode.nap ? _napDuration : _nightSleepDuration;

    AlarmSettings settings = AlarmSettings(
      mode: _selectedMode,
      targetTime: now.add(Duration(minutes: durationMinutes)),
      maxDurationMinutes: durationMinutes,
    );

    _alarmService.setAlarm(settings);

    setState(() {
      _isAlarmSet = true;
      _targetTime = settings.targetTime;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(_selectedMode == AlarmMode.nap
              ? 'آلارم چرت روزانه برای $_napDuration دقیقه تنظیم شد'
              : 'آلارم خواب شبانه برای ${_nightSleepDuration ~/ 60} ساعت تنظیم شد')),
    );
  }

  void _cancelAlarm() {
    _alarmService.cancelAlarm();
    setState(() {
      _isAlarmSet = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('آلارم لغو شد')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('آلارم هوشمند خواب'),
        backgroundColor: Colors.indigo,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // انتخاب حالت آلارم
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'حالت آلارم:',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<AlarmMode>(
                              title: const Text('چرت روزانه'),
                              value: AlarmMode.nap,
                              groupValue: _selectedMode,
                              onChanged: _isAlarmSet
                                  ? null
                                  : (AlarmMode? value) {
                                      setState(() {
                                        _selectedMode = value!;
                                      });
                                    },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<AlarmMode>(
                              title: const Text('خواب شبانه'),
                              value: AlarmMode.nightSleep,
                              groupValue: _selectedMode,
                              onChanged: _isAlarmSet
                                  ? null
                                  : (AlarmMode? value) {
                                      setState(() {
                                        _selectedMode = value!;
                                      });
                                    },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // تنظیمات زمان
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تنظیمات زمان:',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      if (_selectedMode == AlarmMode.nap)
                        Row(
                          children: [
                            Text('مدت چرت: $_napDuration دقیقه'),
                            Expanded(
                              child: Slider(
                                value: _napDuration.toDouble(),
                                min: 10,
                                max: 90,
                                divisions: 8,
                                label: '$_napDuration دقیقه',
                                onChanged: _isAlarmSet
                                    ? null
                                    : (double value) {
                                        setState(() {
                                          _napDuration = value.round();
                                        });
                                      },
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Text('مدت خواب: ${_nightSleepDuration ~/ 60} ساعت'),
                            Expanded(
                              child: Slider(
                                value: (_nightSleepDuration ~/ 60).toDouble(),
                                min: 3,
                                max: 12,
                                divisions: 9,
                                label: '${_nightSleepDuration ~/ 60} ساعت',
                                onChanged: _isAlarmSet
                                    ? null
                                    : (double value) {
                                        setState(() {
                                          _nightSleepDuration =
                                              (value.round() * 60);
                                        });
                                      },
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // راهنمای عملکرد
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نحوه عملکرد:',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (_selectedMode == AlarmMode.nap)
                        const Text(
                            'در حالت چرت روزانه، آلارم قبل از ورود به مرحله خواب عمیق (NREM3) فعال می‌شود تا سرحال بیدار شوید.')
                      else
                        const Text(
                            'در حالت خواب شبانه، آلارم در چرخه چهارم خواب و فقط در مرحله NREM1 یا NREM2 فعال می‌شود تا بهترین زمان بیدار شدن را تجربه کنید.'),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // وضعیت آلارم
              if (_isAlarmSet)
                Center(
                  child: Column(
                    children: [
                      Text(
                        'آلارم تنظیم شده تا: ${_targetTime.hour.toString().padLeft(2, '0')}:${_targetTime.minute.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'حداکثر تا این زمان بیدار خواهید شد،\nممکن است زودتر و در زمان مناسب‌تری بیدار شوید.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // دکمه تنظیم/لغو آلارم
              Center(
                child: ElevatedButton(
                  onPressed: _isAlarmSet ? _cancelAlarm : _setAlarm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAlarmSet ? Colors.red : Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                  child: Text(
                    _isAlarmSet ? 'لغو آلارم' : 'تنظیم آلارم',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
