import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/services/app_analytics_service.dart';
import '../../core/services/feature_flags_service.dart';

class InnovationLabPage extends StatefulWidget {
  const InnovationLabPage({super.key});

  @override
  State<InnovationLabPage> createState() => _InnovationLabPageState();
}

class _InnovationLabPageState extends State<InnovationLabPage> {
  final FeatureFlagsService _flags = FeatureFlagsService();
  final AppAnalyticsService _analytics = AppAnalyticsService();
  final Box _box = Hive.box('settings');

  static const String _profilesKey = 'profiles';
  static const String _activeProfileIdKey = 'active_profile_id';

  @override
  void initState() {
    super.initState();
    _ensureDefaultProfile();
  }

  Future<void> _ensureDefaultProfile() async {
    final profiles = _readProfiles();
    if (profiles.isEmpty) {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      await _box.put(_profilesKey, [
        {'id': id, 'name': 'الملف الأساسي', 'createdAt': DateTime.now().toIso8601String()},
      ]);
      await _box.put(_activeProfileIdKey, id);
    } else {
      final active = _box.get(_activeProfileIdKey) as String?;
      if (active == null || !profiles.any((p) => p['id'] == active)) {
        await _box.put(_activeProfileIdKey, profiles.first['id']);
      }
    }
    if (mounted) setState(() {});
  }

  List<Map<String, dynamic>> _readProfiles() {
    final raw = (_box.get(_profilesKey, defaultValue: <Map>[]) as List).cast<dynamic>();
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _addProfile() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة ملف شخصي'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'اسم الملف'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    final profiles = _readProfiles();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    profiles.add({'id': id, 'name': name, 'createdAt': DateTime.now().toIso8601String()});
    await _box.put(_profilesKey, profiles);
    await _box.put(_activeProfileIdKey, id);
    await _analytics.logEvent('profile_created', params: {'name': name});
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _switchProfile(String id) async {
    await _box.put(_activeProfileIdKey, id);
    await _analytics.logEvent('profile_switched', params: {'id': id});
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تبديل الملف الشخصي'), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _exportBackup() async {
    final data = _box.toMap().map((key, value) => MapEntry(key.toString(), value));
    final json = const JsonEncoder.withIndent('  ').convert(data);
    await Clipboard.setData(ClipboardData(text: json));
    await _analytics.logEvent('backup_exported', params: {'size': json.length});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ النسخة الاحتياطية إلى الحافظة'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _importBackup() async {
    final controller = TextEditingController();
    final payload = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استيراد نسخة احتياطية'),
        content: TextField(
          controller: controller,
          maxLines: 12,
          decoration: const InputDecoration(hintText: 'ألصق JSON هنا'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('استيراد'),
          ),
        ],
      ),
    );

    if (payload == null || payload.isEmpty) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) throw Exception('invalid json');
      if (!mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تأكيد الاستيراد'),
          content: const Text('سيتم استبدال الإعدادات الحالية بالكامل. هل تريد المتابعة؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('متابعة')),
          ],
        ),
      );

      if (confirm != true) return;

      await _box.clear();
      for (final entry in decoded.entries) {
        await _box.put(entry.key.toString(), entry.value);
      }

      await _analytics.logEvent('backup_imported', params: {'keys': decoded.length});
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم استيراد النسخة بنجاح'), behavior: SnackBarBehavior.floating),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('النسخة غير صالحة'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profiles = _readProfiles();
    final activeProfile = _box.get(_activeProfileIdKey) as String?;
    final featureFlags = _flags.getAll();
    final events = _analytics.getRecentEvents(limit: 12);

    return Scaffold(
      appBar: AppBar(title: const Text('Innovation Lab')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Feature Flags', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...featureFlags.entries.map(
            (e) => SwitchListTile(
              title: Text(appFeatureLabels[e.key] ?? e.key.name),
              subtitle: Text(e.key.name),
              value: e.value,
              onChanged: (v) async {
                await _flags.setEnabled(e.key, v);
                await _analytics.logEvent('feature_flag_toggled', params: {'flag': e.key.name, 'value': v});
                if (!mounted) return;
                setState(() {});
              },
            ),
          ),
          const Divider(height: 28),
          Row(
            children: [
              Expanded(
                child: Text('Profiles', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              FilledButton.icon(
                onPressed: _addProfile,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('إضافة'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...profiles.map(
            (profile) => ListTile(
              leading: Icon(
                profile['id'] == activeProfile ? Icons.person_pin_circle : Icons.person_outline,
                color: profile['id'] == activeProfile ? theme.colorScheme.secondary : null,
              ),
              title: Text('${profile['name']}'),
              subtitle: Text('ID: ${profile['id']}'),
              trailing: profile['id'] == activeProfile
                  ? const Chip(label: Text('نشط'))
                  : TextButton(
                      onPressed: () => _switchProfile(profile['id'] as String),
                      child: const Text('تفعيل'),
                    ),
            ),
          ),
          const Divider(height: 28),
          Text('Backup & Restore', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('تصدير نسخة احتياطية (JSON -> Clipboard)'),
            onTap: _exportBackup,
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('استيراد نسخة احتياطية (JSON)'),
            onTap: _importBackup,
          ),
          const Divider(height: 28),
          Row(
            children: [
              Expanded(
                child: Text('Local Analytics', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () async {
                  await _analytics.clearEvents();
                  if (!mounted) return;
                  setState(() {});
                },
                child: const Text('مسح'),
              ),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.bolt_rounded),
            title: const Text('إضافة حدث تجريبي'),
            onTap: () async {
              await _analytics.logEvent('manual_test_event', params: {'screen': 'innovation_lab'});
              if (!mounted) return;
              setState(() {});
            },
          ),
          ...events.map(
            (e) => ListTile(
              dense: true,
              leading: const Icon(Icons.analytics_outlined, size: 18),
              title: Text('${e['name']}'),
              subtitle: Text('${e['ts']}\n${jsonEncode(e['params'])}'),
            ),
          ),
        ],
      ),
    );
  }
}
