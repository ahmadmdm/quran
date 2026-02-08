import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';
import '../../core/localization/app_localizations.dart';

class MissedPrayersPage extends StatefulWidget {
  const MissedPrayersPage({super.key});

  @override
  State<MissedPrayersPage> createState() => _MissedPrayersPageState();
}

class _MissedPrayersPageState extends State<MissedPrayersPage> {
  late Box _box;
  bool _isLoading = true;

  final Map<String, int> _missedCounts = {
    'fajr': 0,
    'dhuhr': 0,
    'asr': 0,
    'maghrib': 0,
    'isha': 0,
  };

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    _box = await Hive.openBox('missed_prayers');
    setState(() {
      _missedCounts['fajr'] = _box.get('fajr', defaultValue: 0);
      _missedCounts['dhuhr'] = _box.get('dhuhr', defaultValue: 0);
      _missedCounts['asr'] = _box.get('asr', defaultValue: 0);
      _missedCounts['maghrib'] = _box.get('maghrib', defaultValue: 0);
      _missedCounts['isha'] = _box.get('isha', defaultValue: 0);
      _isLoading = false;
    });
  }

  void _updateCount(String prayer, int change) {
    setState(() {
      int current = _missedCounts[prayer] ?? 0;
      int newValue = current + change;
      if (newValue < 0) newValue = 0;

      _missedCounts[prayer] = newValue;
      _box.put(prayer, newValue);

      if (change > 0) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    });
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
        title: Text(localizations.translate('missed_prayers')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildPrayerCounter(
            localizations,
            'fajr',
            'missed_fajr',
            Colors.blue,
          ),
          _buildPrayerCounter(
            localizations,
            'dhuhr',
            'missed_dhuhr',
            Colors.orange,
          ),
          _buildPrayerCounter(localizations, 'asr', 'missed_asr', Colors.amber),
          _buildPrayerCounter(
            localizations,
            'maghrib',
            'missed_maghrib',
            Colors.red,
          ),
          _buildPrayerCounter(
            localizations,
            'isha',
            'missed_isha',
            Colors.indigo,
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerCounter(
    AppLocalizations localizations,
    String key,
    String labelKey,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.access_time_filled, color: color),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate(labelKey),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${_missedCounts[key]} Pending',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _buildActionButton(Icons.remove, () => _updateCount(key, -1)),
              const SizedBox(width: 12),
              _buildActionButton(Icons.add, () => _updateCount(key, 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
        ),
      ),
    );
  }
}
