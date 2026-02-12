import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quran/quran.dart' as quran;
import 'package:adhan/adhan.dart' as adhan;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'core/services/app_analytics_service.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/quran/quran_index_page.dart';
import 'presentation/pages/quran/quran_reader_page.dart';
import 'presentation/pages/quran/daily_wird_page.dart';
import 'presentation/pages/settings_page.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/tafsir_service.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/prayer_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await AppAnalyticsService().logEvent('app_open');

  // Start the app immediately without waiting for location
  runApp(const ProviderScope(child: PrayerApp()));

  // Request location permission in background (non-blocking)
  _requestLocationPermissionInBackground();
}

/// Request location permission in background without blocking app startup
Future<void> _requestLocationPermissionInBackground() async {
  try {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return; // Location services disabled, will handle in UI
    }

    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request permission in background
      await Geolocator.requestPermission();
    }
  } catch (e) {
    // Silently handle errors - location will be requested again when needed
    debugPrint('Background location permission request failed: $e');
  }
}

class PrayerApp extends ConsumerWidget {
  const PrayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    final largeText = ref.watch(settingsProvider.select((s) => s.largeText));
    final foldPaneMode = ref.watch(
      settingsProvider.select((s) => s.foldPaneMode),
    );

    return MaterialApp(
      title: 'Luxury Prayer App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final ui.TextDirection textDirection =
            Directionality.maybeOf(context) ??
            (locale.languageCode == 'ar'
                ? ui.TextDirection.rtl
                : ui.TextDirection.ltr);

        dynamic verticalHinge;
        for (final feature in media.displayFeatures) {
          final featureType = feature.type.toString().toLowerCase();
          final isFoldLike =
              featureType.contains('hinge') || featureType.contains('fold');
          final isVerticalHinge =
              isFoldLike && feature.bounds.height >= media.size.height * 0.5;
          if (isVerticalHinge) {
            verticalHinge = feature;
            break;
          }
        }

        Widget resolvedChild = child ?? const SizedBox.shrink();
        if (verticalHinge != null && foldPaneMode == FoldPaneMode.span) {
          final hinge = verticalHinge.bounds as Rect;
          final leftPaneWidth = hinge.left;
          final rightPaneWidth = media.size.width - hinge.right;
          final contentOnRight = textDirection == ui.TextDirection.rtl;
          final contentPane = SizedBox(
            width: contentOnRight ? rightPaneWidth : leftPaneWidth,
            child: resolvedChild,
          );
          final companionPane = SizedBox(
            width: contentOnRight ? leftPaneWidth : rightPaneWidth,
            child: const _FoldCompanionPane(),
          );

          resolvedChild = Row(
            children: [
              if (contentOnRight) companionPane else contentPane,
              SizedBox(width: hinge.width),
              if (contentOnRight) contentPane else companionPane,
            ],
          );
        } else if (verticalHinge != null) {
          final hinge = verticalHinge.bounds;
          final useRightPane = textDirection == ui.TextDirection.rtl;
          final leftPaneWidth = hinge.left;
          final rightPaneWidth = media.size.width - hinge.right;
          final paneWidth = useRightPane ? rightPaneWidth : leftPaneWidth;

          if (paneWidth > 0) {
            resolvedChild = Align(
              alignment: useRightPane ? Alignment.topRight : Alignment.topLeft,
              child: Padding(
                padding: useRightPane
                    ? EdgeInsets.only(left: hinge.right)
                    : EdgeInsets.only(right: media.size.width - hinge.left),
                child: SizedBox(width: paneWidth, child: resolvedChild),
              ),
            );
          }
        }

        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(largeText ? 1.15 : 1.0),
          ),
          child: resolvedChild,
        );
      },
      home: const HomePage(),
    );
  }
}

class _FoldCompanionPane extends ConsumerStatefulWidget {
  const _FoldCompanionPane();

  @override
  ConsumerState<_FoldCompanionPane> createState() => _FoldCompanionPaneState();
}

class _FoldCompanionPaneState extends ConsumerState<_FoldCompanionPane>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final Timer _ticker;
  final TextEditingController _pageController = TextEditingController();
  final TextEditingController _surahController = TextEditingController();
  final TextEditingController _verseController = TextEditingController();
  final TextEditingController _tafsirSurahController = TextEditingController();
  final TextEditingController _tafsirVerseController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  Future<TafsirResult>? _tafsirFuture;
  Timer? _focusTimer;
  int _focusRemainingSeconds = 0;
  TimeOfDay _now = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _now = TimeOfDay.now();
    _loadInitialInputs();
    _loadTodayNote();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = TimeOfDay.now();
      });
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    _focusTimer?.cancel();
    _tabController.dispose();
    _pageController.dispose();
    _surahController.dispose();
    _verseController.dispose();
    _tafsirSurahController.dispose();
    _tafsirVerseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _loadInitialInputs() {
    final box = Hive.box('settings');
    final lastSurah =
        (box.get('last_read_surah', defaultValue: 1) as int?) ?? 1;
    final lastVerse =
        (box.get('last_read_verse', defaultValue: 1) as int?) ?? 1;
    final lastPage = quran.getPageNumber(lastSurah, lastVerse);
    _pageController.text = '$lastPage';
    _surahController.text = '$lastSurah';
    _verseController.text = '$lastVerse';
    _tafsirSurahController.text = '$lastSurah';
    _tafsirVerseController.text = '$lastVerse';
  }

  String get _todayKey =>
      'fold_note_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';

  void _loadTodayNote() {
    final box = Hive.box('settings');
    final note = (box.get(_todayKey, defaultValue: '') as String?) ?? '';
    _noteController.text = note;
  }

  Future<void> _saveTodayNote() async {
    final box = Hive.box('settings');
    await box.put(_todayKey, _noteController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم حفظ ملاحظة التدبر اليوم')));
  }

  (int surah, int verse) _getStartForPage(int pageNumber) {
    final safePage = pageNumber.clamp(1, 604);
    for (int s = 1; s <= 114; s++) {
      final verseCount = quran.getVerseCount(s);
      for (int v = 1; v <= verseCount; v++) {
        if (quran.getPageNumber(s, v) == safePage) {
          return (s, v);
        }
      }
    }
    return (1, 1);
  }

  Future<void> _openFromPage() async {
    final page = int.tryParse(_pageController.text.trim());
    if (page == null || page < 1 || page > 604) {
      _showError('أدخل رقم صفحة صحيح من 1 إلى 604');
      return;
    }
    final start = _getStartForPage(page);
    if (!mounted) return;
    await _pushScreen(
      QuranReaderPage(
        initialSurahNumber: start.$1,
        initialVerseNumber: start.$2,
      ),
    );
  }

  Future<void> _openFromSurahVerse() async {
    final surah = int.tryParse(_surahController.text.trim());
    final verse = int.tryParse(_verseController.text.trim());
    if (surah == null || surah < 1 || surah > 114) {
      _showError('رقم السورة يجب أن يكون من 1 إلى 114');
      return;
    }
    final verseCount = quran.getVerseCount(surah);
    if (verse == null || verse < 1 || verse > verseCount) {
      _showError('رقم الآية في هذه السورة من 1 إلى $verseCount');
      return;
    }
    if (!mounted) return;
    await _pushScreen(
      QuranReaderPage(initialSurahNumber: surah, initialVerseNumber: verse),
    );
  }

  Future<void> _openLastRead() async {
    final box = Hive.box('settings');
    final lastSurah =
        (box.get('last_read_surah', defaultValue: 1) as int?) ?? 1;
    final lastVerse =
        (box.get('last_read_verse', defaultValue: 1) as int?) ?? 1;
    if (!mounted) return;
    await _pushScreen(
      QuranReaderPage(
        initialSurahNumber: lastSurah,
        initialVerseNumber: lastVerse,
      ),
    );
  }

  Future<void> _openVerseInReader(int surah, int verse) async {
    await _pushScreen(
      QuranReaderPage(initialSurahNumber: surah, initialVerseNumber: verse),
    );
  }

  Future<void> _pushScreen(Widget page) async {
    if (!mounted) return;
    await Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => page));
  }

  int _asInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  String _normalizeQuranTextForFold(String input) {
    return input.replaceAll('\u065E', '\u064C');
  }

  void _loadTafsirInFold() {
    final surah = int.tryParse(_tafsirSurahController.text.trim());
    final verse = int.tryParse(_tafsirVerseController.text.trim());
    if (surah == null || surah < 1 || surah > 114) {
      _showError('أدخل سورة صحيحة للتفسير');
      return;
    }
    final maxVerse = quran.getVerseCount(surah);
    if (verse == null || verse < 1 || verse > maxVerse) {
      _showError('رقم آية غير صحيح في السورة المختارة');
      return;
    }
    setState(() {
      _tafsirFuture = TafsirService.getTafsir(
        surahNumber: surah,
        verseNumber: verse,
      );
    });
  }

  void _startFocusSession(int minutes) {
    _focusTimer?.cancel();
    setState(() {
      _focusRemainingSeconds = minutes * 60;
    });
    _focusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_focusRemainingSeconds <= 1) {
        timer.cancel();
        _focusTimer = null;
        setState(() {
          _focusRemainingSeconds = 0;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('انتهت جلسة التركيز')));
        return;
      }
      setState(() {
        _focusRemainingSeconds--;
      });
    });
  }

  void _stopFocusSession() {
    _focusTimer?.cancel();
    _focusTimer = null;
    setState(() {
      _focusRemainingSeconds = 0;
    });
  }

  String _formatFocusCountdown() {
    final m = (_focusRemainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_focusRemainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  String _prayerNameAr(adhan.Prayer prayer) {
    return switch (prayer) {
      adhan.Prayer.fajr => 'الفجر',
      adhan.Prayer.sunrise => 'الشروق',
      adhan.Prayer.dhuhr => 'الظهر',
      adhan.Prayer.asr => 'العصر',
      adhan.Prayer.maghrib => 'المغرب',
      adhan.Prayer.isha => 'العشاء',
      adhan.Prayer.none => 'لا يوجد',
    };
  }

  (adhan.Prayer prayer, DateTime? time) _nextPrayerInfo(
    adhan.PrayerTimes times,
  ) {
    final now = DateTime.now();
    adhan.Prayer next = times.nextPrayer();
    DateTime? nextTime = times.timeForPrayer(next);
    if (next == adhan.Prayer.none ||
        nextTime == null ||
        !nextTime.isAfter(now)) {
      final params = ref
          .read(settingsProvider)
          .calculationMethod
          .getParameters();
      params.madhab = ref.read(settingsProvider).madhab;
      final tomorrow = adhan.PrayerTimes(
        times.coordinates,
        adhan.DateComponents.from(DateTime.now().add(const Duration(days: 1))),
        params,
      );
      next = adhan.Prayer.fajr;
      nextTime = tomorrow.fajr;
    }
    return (next, nextTime);
  }

  String _formatRemaining(Duration diff) {
    if (diff.isNegative) return '00:00:00';
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = _now.format(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'لوحة الفولد',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'الوقت الآن: $now',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyLarge?.color?.withValues(
                    alpha: 0.75,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabController,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                isScrollable: true,
                tabs: const [
                  Tab(text: 'التنقل'),
                  Tab(text: 'المصحف'),
                  Tab(text: 'الصلاة'),
                  Tab(text: 'التدبر'),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNavigationTab(theme),
                    _buildQuranTab(theme),
                    _buildPrayerTab(theme),
                    _buildTadabburTab(theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationTab(ThemeData theme) {
    return ListView(
      children: [
        _FoldActionCard(
          icon: Icons.home_rounded,
          title: 'الصفحة الرئيسية',
          subtitle: 'العودة للشاشة الأساسية',
          onTap: () {
            _pushScreen(const HomePage());
          },
        ),
        const SizedBox(height: 10),
        _FoldActionCard(
          icon: Icons.menu_book_rounded,
          title: 'فهرس القرآن',
          subtitle: 'سور، أجزاء، بحث وفواصل',
          onTap: () {
            _pushScreen(const QuranIndexPage());
          },
        ),
        const SizedBox(height: 10),
        _FoldActionCard(
          icon: Icons.auto_stories_rounded,
          title: 'الورد اليومي والختمة',
          subtitle: 'متابعة الإنجاز اليومي',
          onTap: () {
            _pushScreen(const DailyWirdPage());
          },
        ),
        const SizedBox(height: 10),
        _FoldActionCard(
          icon: Icons.settings_rounded,
          title: 'الإعدادات',
          subtitle: 'اللغة، التنبيهات، تخصيص التطبيق',
          onTap: () {
            _pushScreen(const SettingsPage());
          },
        ),
      ],
    );
  }

  Widget _buildQuranTab(ThemeData theme) {
    return ListView(
      children: [
        _buildLiveSyncCard(theme),
        const SizedBox(height: 10),
        _FoldSectionCard(
          title: 'فتح مباشر برقم الصفحة',
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '1 - 604',
                    labelText: 'رقم الصفحة',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _openFromPage, child: const Text('فتح')),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _FoldSectionCard(
          title: 'فتح مباشر سورة / آية',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _surahController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'السورة'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _verseController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'الآية'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openFromSurahVerse,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('انتقال'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openLastRead,
                      icon: const Icon(Icons.bookmark_rounded),
                      label: const Text('آخر قراءة'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildQuickBookmarksCard(theme),
        const SizedBox(height: 10),
        _buildFoldTafsirCard(theme),
      ],
    );
  }

  Widget _buildLiveSyncCard(ThemeData theme) {
    final listenable = Hive.box('settings').listenable(
      keys: [
        'fold_live_surah',
        'fold_live_verse',
        'fold_live_text',
        'fold_live_updated_at',
      ],
    );

    return ValueListenableBuilder<Box>(
      valueListenable: listenable,
      builder: (context, box, _) {
        final surah = _asInt(box.get('fold_live_surah'), fallback: 0);
        final verse = _asInt(box.get('fold_live_verse'), fallback: 0);
        final text = (box.get('fold_live_text') as String?) ?? '';
        final updatedAt = (box.get('fold_live_updated_at') as String?) ?? '';

        if (surah <= 0 || verse <= 0 || text.trim().isEmpty) {
          return _FoldSectionCard(
            title: 'Fold Pro: مزامنة حية',
            child: Text(
              'اضغط على أي آية من شاشة القراءة لعرضها هنا مباشرة.',
              style: theme.textTheme.bodyMedium,
            ),
          );
        }

        return _FoldSectionCard(
          title: 'Fold Pro: مزامنة حية',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${quran.getSurahNameArabic(surah)} - آية $verse',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _normalizeQuranTextForFold(text),
                textDirection: ui.TextDirection.rtl,
                textAlign: TextAlign.justify,
                style: GoogleFonts.amiriQuran(
                  fontSize: 30,
                  height: 1.9,
                  color: theme.textTheme.bodyLarge?.color,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              if (updatedAt.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'آخر تحديث: $updatedAt',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openVerseInReader(surah, verse),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('فتح الآية'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text:
                              '${quran.getSurahNameArabic(surah)} - آية $verse\n$text',
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ الآية')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('نسخ'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      _tafsirSurahController.text = '$surah';
                      _tafsirVerseController.text = '$verse';
                      _loadTafsirInFold();
                    },
                    icon: const Icon(Icons.menu_book_rounded),
                    label: const Text('تفسير فوري'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickBookmarksCard(ThemeData theme) {
    final listenable = Hive.box(
      'settings',
    ).listenable(keys: ['verse_bookmarks']);
    return ValueListenableBuilder<Box>(
      valueListenable: listenable,
      builder: (context, box, _) {
        final verseBookmarks =
            (box.get('verse_bookmarks', defaultValue: <String>[]) as List)
                .cast<String>()
                .take(6)
                .toList();

        if (verseBookmarks.isEmpty) {
          return _FoldSectionCard(
            title: 'فواصل سريعة',
            child: Text(
              'لا توجد فواصل آيات بعد. اضغط على أي آية ثم "إضافة إلى الفواصل".',
              style: theme.textTheme.bodyMedium,
            ),
          );
        }

        return _FoldSectionCard(
          title: 'فواصل سريعة',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: verseBookmarks.map((entry) {
              final parts = entry.contains(':')
                  ? entry.split(':')
                  : entry.split('-');
              if (parts.length != 2) return const SizedBox.shrink();
              final surah = int.tryParse(parts[0]) ?? 1;
              final verse = int.tryParse(parts[1]) ?? 1;
              return ActionChip(
                label: Text('${quran.getSurahNameArabic(surah)}:$verse'),
                onPressed: () => _openVerseInReader(surah, verse),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildFoldTafsirCard(ThemeData theme) {
    return _FoldSectionCard(
      title: 'تفسير فوري (على شاشة الفولد)',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tafsirSurahController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'السورة'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _tafsirVerseController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الآية'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _loadTafsirInFold,
                child: const Text('عرض'),
              ),
            ],
          ),
          if (_tafsirFuture != null) ...[
            const SizedBox(height: 10),
            FutureBuilder<TafsirResult>(
              future: _tafsirFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text('تعذر تحميل التفسير');
                }
                final result = snapshot.data!;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    result.text,
                    textDirection: ui.TextDirection.rtl,
                    textAlign: TextAlign.justify,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.75),
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrayerTab(ThemeData theme) {
    final prayerAsync = ref.watch(prayerTimesProvider);
    return prayerAsync.when(
      data: (prayerTimes) {
        final nextInfo = _nextPrayerInfo(prayerTimes);
        final nextPrayer = nextInfo.$1;
        final nextTime = nextInfo.$2;
        final remaining = nextTime == null
            ? Duration.zero
            : nextTime.difference(DateTime.now());

        Widget prayerRow(String title, DateTime dateTime) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(DateFormat('HH:mm').format(dateTime)),
              ],
            ),
          );
        }

        return ListView(
          children: [
            _FoldSectionCard(
              title: 'الصلاة القادمة',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _prayerNameAr(nextPrayer),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    nextTime == null
                        ? '--:--'
                        : 'الوقت: ${DateFormat('HH:mm').format(nextTime)}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'المتبقي: ${_formatRemaining(remaining)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.invalidate(prayerTimesProvider);
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('تحديث المواقيت'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _FoldSectionCard(
              title: 'مواقيت اليوم',
              child: Column(
                children: [
                  prayerRow('الفجر', prayerTimes.fajr),
                  prayerRow('الظهر', prayerTimes.dhuhr),
                  prayerRow('العصر', prayerTimes.asr),
                  prayerRow('المغرب', prayerTimes.maghrib),
                  prayerRow('العشاء', prayerTimes.isha),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: OutlinedButton.icon(
          onPressed: () => ref.invalidate(prayerTimesProvider),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('تعذر جلب المواقيت - إعادة المحاولة'),
        ),
      ),
    );
  }

  Widget _buildTadabburTab(ThemeData theme) {
    return ListView(
      children: [
        _buildKhatmaOverviewCard(theme),
        const SizedBox(height: 10),
        _buildFocusSessionCard(theme),
        const SizedBox(height: 10),
        _buildQuickRevisionCard(theme),
        const SizedBox(height: 10),
        _FoldSectionCard(
          title: 'ملاحظة تدبر اليوم',
          child: Column(
            children: [
              TextField(
                controller: _noteController,
                maxLines: 6,
                textDirection: ui.TextDirection.rtl,
                decoration: const InputDecoration(
                  hintText: 'اكتب فائدة أو خاطر مرتبط بالآيات...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saveTodayNote,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('حفظ'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _FoldSectionCard(
          title: 'اختصارات إبداعية للفولد',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('• استخدم اللوح الأيمن للتنقل، والأيسر للقراءة المستمرة.'),
              SizedBox(height: 4),
              Text(
                '• افتح المصحف من "فتح مباشر" وأبقِ المتابعة في لوحة الصلاة.',
              ),
              SizedBox(height: 4),
              Text('• دوّن الخواطر فورًا أثناء القراءة بدون مغادرة الشاشة.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFocusSessionCard(ThemeData theme) {
    final isRunning = _focusTimer != null && _focusRemainingSeconds > 0;
    return _FoldSectionCard(
      title: 'جلسة تركيز للفولد',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRunning
                ? 'المتبقي: ${_formatFocusCountdown()}'
                : 'اختر مدة الجلسة:',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('10 دقائق'),
                selected: false,
                onSelected: (_) => _startFocusSession(10),
              ),
              ChoiceChip(
                label: const Text('20 دقيقة'),
                selected: false,
                onSelected: (_) => _startFocusSession(20),
              ),
              ChoiceChip(
                label: const Text('30 دقيقة'),
                selected: false,
                onSelected: (_) => _startFocusSession(30),
              ),
              if (isRunning)
                ActionChip(
                  label: const Text('إيقاف'),
                  onPressed: _stopFocusSession,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickRevisionCard(ThemeData theme) {
    final box = Hive.box('settings');
    final text = ((box.get('fold_live_text') as String?) ?? '').trim();
    if (text.isEmpty) {
      return _FoldSectionCard(
        title: 'مراجعة سريعة',
        child: Text(
          'اختر آية أولًا من شاشة القراءة لبدء مراجعة سريعة.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    final words = text
        .replaceAll(RegExp(r'[^\u0621-\u064A\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    final hiddenIndex = words.length >= 4 ? (words.length ~/ 2) : 0;
    final expected = words.isEmpty ? '' : words[hiddenIndex];
    final promptWords = [...words];
    if (promptWords.isNotEmpty) {
      promptWords[hiddenIndex] = '_____';
    }
    final prompt = promptWords.join(' ');
    String userAnswer = '';

    return _FoldSectionCard(
      title: 'مراجعة سريعة',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            prompt,
            textDirection: ui.TextDirection.rtl,
            textAlign: TextAlign.justify,
            style: GoogleFonts.amiriQuran(
              fontSize: 26,
              height: 1.8,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          StatefulBuilder(
            builder: (context, setInnerState) {
              return TextField(
                textDirection: ui.TextDirection.rtl,
                onChanged: (v) => setInnerState(() {
                  userAnswer = v.trim();
                }),
                decoration: const InputDecoration(
                  labelText: 'أكمل الكلمة الناقصة',
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              final ok = userAnswer.isNotEmpty && userAnswer == expected;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'إجابة صحيحة' : 'الصحيح: $expected'),
                  backgroundColor: ok
                      ? Colors.green.shade700
                      : Colors.orange.shade800,
                ),
              );
            },
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('تحقق'),
          ),
          if (expected.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('الآية قصيرة جدًا للمراجعة السريعة'),
            ),
        ],
      ),
    );
  }

  Widget _buildKhatmaOverviewCard(ThemeData theme) {
    final box = Hive.box('settings');
    final currentPage = _asInt(
      box.get('daily_wird_current_page', defaultValue: 1),
      fallback: 1,
    );
    final dailyPages = _asInt(
      box.get('daily_wird_pages', defaultValue: 5),
      fallback: 5,
    );
    final khatmaList = (box.get('khatma_list', defaultValue: <Map>[]) as List)
        .cast<Map>();
    final active = khatmaList.isNotEmpty
        ? Map<String, dynamic>.from(khatmaList.first)
        : null;
    final activeCurrent = _asInt(
      active?['current_page'],
      fallback: 1,
    ).clamp(1, 604);
    final activeProgress = active == null
        ? 0.0
        : (activeCurrent / 604).clamp(0.0, 1.0);

    return _FoldSectionCard(
      title: 'تقدم الورد والختمة',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الورد اليومي: صفحة $currentPage (هدف يومي $dailyPages صفحات)'),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (currentPage / 604).clamp(0.0, 1.0),
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 12),
          if (active == null)
            Text('لا توجد ختمة مضافة بعد', style: theme.textTheme.bodyMedium)
          else ...[
            Text(
              'الختمة: ${active['name'] ?? 'ختمة'} - صفحة $activeCurrent من 604',
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: activeProgress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              _pushScreen(const DailyWirdPage());
            },
            icon: const Icon(Icons.auto_stories_rounded),
            label: const Text('فتح شاشة الورد والختمة'),
          ),
        ],
      ),
    );
  }
}

class _FoldActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FoldActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.secondary),
              const SizedBox(width: 10),
              _FoldActionCardBody(
                theme: theme,
                title: title,
                subtitle: subtitle,
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoldSectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _FoldSectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _FoldActionCardBody extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final String subtitle;

  const _FoldActionCardBody({
    required this.theme,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
