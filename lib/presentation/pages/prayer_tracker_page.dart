import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_localizations.dart';

class PrayerTrackerPage extends StatefulWidget {
  const PrayerTrackerPage({super.key});

  @override
  State<PrayerTrackerPage> createState() => _PrayerTrackerPageState();
}

class _PrayerTrackerPageState extends State<PrayerTrackerPage> {
  late Box _trackerBox;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    _trackerBox = await Hive.openBox('prayer_tracker');
    setState(() {
      _isLoading = false;
    });
  }

  String _getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  bool _getPrayerStatus(String prayer) {
    final dateKey = _getDateKey(_selectedDate);
    final dayData = _trackerBox.get(dateKey, defaultValue: {});
    return dayData is Map ? (dayData[prayer] ?? false) : false;
  }

  Future<void> _togglePrayer(String prayer) async {
    final dateKey = _getDateKey(_selectedDate);
    final dayData = Map<String, dynamic>.from(
      _trackerBox.get(dateKey, defaultValue: {}),
    );

    dayData[prayer] = !(dayData[prayer] ?? false);
    await _trackerBox.put(dateKey, dayData);
    setState(() {});
  }

  int _getCompletedCount(DateTime date) {
    final dateKey = _getDateKey(date);
    final dayData = _trackerBox.get(dateKey, defaultValue: {});
    if (dayData is! Map) return 0;

    int count = 0;
    for (var prayer in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
      if (dayData[prayer] == true) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(localizations.translate('prayer_tracker')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildCalendarStrip(),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildPrayerCheckItem(localizations, 'fajr', 'fajr_done'),
                  _buildPrayerCheckItem(localizations, 'dhuhr', 'dhuhr_done'),
                  _buildPrayerCheckItem(localizations, 'asr', 'asr_done'),
                  _buildPrayerCheckItem(
                    localizations,
                    'maghrib',
                    'maghrib_done',
                  ),
                  _buildPrayerCheckItem(localizations, 'isha', 'isha_done'),
                  const SizedBox(height: 30),
                  _buildStatistics(localizations),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarStrip() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse:
            true, // Show latest dates first if RTL, or just easy access to today
        itemCount: 30, // Last 30 days
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final date = DateTime.now().subtract(Duration(days: index));
          final isSelected = _getDateKey(date) == _getDateKey(_selectedDate);
          final completedCount = _getCompletedCount(date);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).dividerColor,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completedCount == 5
                          ? (isSelected ? Colors.white : Colors.green)
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrayerCheckItem(
    AppLocalizations localizations,
    String key,
    String labelKey,
  ) {
    final isDone = _getPrayerStatus(key);

    return GestureDetector(
      onTap: () => _togglePrayer(key),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDone
              ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.transparent,
                border: Border.all(
                  color: isDone
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Text(
              localizations.translate(labelKey),
              style: TextStyle(
                fontSize: 16,
                fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                color: isDone
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (isDone) const Icon(Icons.star, color: Colors.amber, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(AppLocalizations localizations) {
    int weekTotal = 0;
    for (int i = 0; i < 7; i++) {
      weekTotal += _getCompletedCount(
        DateTime.now().subtract(Duration(days: i)),
      );
    }
    final percentage = (weekTotal / 35 * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.translate('statistics'),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.translate('last_7_days'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$weekTotal / 35',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: weekTotal / 35,
                  strokeWidth: 8,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
                Center(
                  child: Text(
                    '$percentage%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
