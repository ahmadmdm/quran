import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

class AppAnalyticsService {
  static const String _eventsKey = 'analytics_events';
  static const int _maxEvents = 300;

  Box get _box => Hive.box('settings');

  Future<void> logEvent(String name, {Map<String, dynamic>? params}) async {
    final raw = (_box.get(_eventsKey, defaultValue: <Map>[]) as List).cast<dynamic>();
    final events = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    events.add({
      'ts': DateTime.now().toIso8601String(),
      'name': name,
      'params': params ?? <String, dynamic>{},
    });

    if (events.length > _maxEvents) {
      events.removeRange(0, events.length - _maxEvents);
    }

    await _box.put(_eventsKey, events);
  }

  List<Map<String, dynamic>> getRecentEvents({int limit = 30}) {
    final raw = (_box.get(_eventsKey, defaultValue: <Map>[]) as List).cast<dynamic>();
    final events = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    if (events.isEmpty) return const [];
    final start = events.length - limit < 0 ? 0 : events.length - limit;
    return events.sublist(start).reversed.toList();
  }

  Future<void> clearEvents() async {
    await _box.put(_eventsKey, <Map>[]);
  }

  String exportEventsJson() {
    return jsonEncode(getRecentEvents(limit: _maxEvents));
  }
}
