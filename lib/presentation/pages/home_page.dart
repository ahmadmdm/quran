import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/widget_service.dart';
import '../providers/prayer_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/settings_provider.dart';
import 'settings_page.dart';
import 'qibla_page.dart';
import 'calendar_page.dart';
import 'tasbih_page.dart';
import 'azkar_page.dart';
import 'names_of_allah_page.dart';
import 'prayer_tracker_page.dart';
import 'dua_page.dart';
import 'qibla_map_page.dart';
import 'zakat_page.dart';
import 'islamic_events_page.dart';
import 'missed_prayers_page.dart';
import 'quran/quran_index_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  late AnimationController _pulseController;
  bool _showAllFeatureCards = false;
  bool _mosqueModeActive = false;
  String? _mosqueModeBackupSound;
  bool? _mosqueModeBackupVibration;
  DateTime? _mosqueModeAnchorPrayerTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize notifications (channels, permissions) on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).init();
      WidgetService.initializeDefaultSettings();
      unawaited(Hive.openBox('tasbih'));
      unawaited(Hive.openBox('prayer_tracker'));
      unawaited(_runNotificationGuardCheck());
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_runNotificationGuardCheck());
      ref.invalidate(prayerTimesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prayerAsync = ref.watch(prayerTimesProvider);

    // Listen for prayer time updates to schedule notifications
    ref.listen<AsyncValue<PrayerTimes>>(prayerTimesProvider, (previous, next) {
      next.whenData((prayerTimes) {
        final settings = ref.read(settingsProvider);
        final notificationService = ref.read(notificationServiceProvider);

        // Schedule Notifications
        final enabledPrayers = <Prayer>{
          if (settings.fajrNotificationsEnabled) Prayer.fajr,
          if (settings.dhuhrNotificationsEnabled) Prayer.dhuhr,
          if (settings.asrNotificationsEnabled) Prayer.asr,
          if (settings.maghribNotificationsEnabled) Prayer.maghrib,
          if (settings.ishaNotificationsEnabled) Prayer.isha,
        };
        notificationService.schedulePrayers(
          prayerTimes,
          notificationsEnabled: settings.areNotificationsEnabled,
          prayerTimeNotificationsEnabled:
              settings.prayerTimeNotificationsEnabled,
          prePrayerRemindersEnabled: settings.prePrayerRemindersEnabled,
          preAzanReminderOffset: settings.preAzanReminderOffset,
          notificationSound: settings.notificationSound,
          vibrationEnabled: settings.vibrationEnabled,
          enabledPrayers: enabledPrayers,
          multiLevelRemindersEnabled: settings.multiLevelRemindersEnabled,
          suppressImmediateRemindersWindowMinutes: 20,
        );

        // Update Widget Data
        // Get next prayer
        Prayer nextPrayer = prayerTimes.nextPrayer();
        DateTime? nextPrayerTime = prayerTimes.timeForPrayer(nextPrayer);

        // Handle case where next prayer is tomorrow's Fajr (after Isha)
        if (nextPrayer == Prayer.none) {
          nextPrayer = Prayer.fajr;
          // Calculate tomorrow's prayer times
          final tomorrow = DateTime.now().add(const Duration(days: 1));
          final tomorrowParams = settings.calculationMethod.getParameters();
          tomorrowParams.madhab = settings.madhab;
          final tomorrowPrayerTimes = PrayerTimes(
            prayerTimes.coordinates,
            DateComponents.from(tomorrow),
            tomorrowParams,
          );
          nextPrayerTime = tomorrowPrayerTimes.fajr;
        }

        // Logic for skipping Sunrise if needed (already present but needs to be robust)
        bool isSunrise = nextPrayer == Prayer.sunrise;
        if (isSunrise) {
          nextPrayer = Prayer.dhuhr;
          nextPrayerTime = prayerTimes.dhuhr;
        }

        Prayer widgetNextPrayer = nextPrayer;
        DateTime? widgetNextPrayerTime = nextPrayerTime;

        final now = DateTime.now();
        final diff = widgetNextPrayerTime?.difference(now) ?? Duration.zero;
        final contextMode = _computeWidgetContextMode(
          now: now,
          nextPrayerTime: widgetNextPrayerTime,
          smartStackEnabled: settings.smartWidgetStackEnabled,
        );
        final contextMessage = _buildWidgetContextMessage(contextMode);
        final dhikrProgress = _readDhikrProgress();
        final prayerProgress = _readPrayerProgress(now);

        // Prepare data for widget
        final localizations = AppLocalizations.of(context)!;
        final use24h = settings.use24hFormat;

        // Only include the 5 main prayers (excluding Sunrise)
        final prayerNames = [
          localizations.translate('fajr'),
          localizations.translate('dhuhr'),
          localizations.translate('asr'),
          localizations.translate('maghrib'),
          localizations.translate('isha'),
        ];

        final prayerTimesList = [
          prayerTimes.fajr,
          prayerTimes.dhuhr,
          prayerTimes.asr,
          prayerTimes.maghrib,
          prayerTimes.isha,
        ];

        final prayerTimeStrings = prayerTimesList
            .map(
              (time) => use24h
                  ? DateFormat('HH:mm').format(time)
                  : DateFormat.jm().format(time),
            )
            .toList();

        final prayerTimeMillis = prayerTimesList
            .map((time) => time.millisecondsSinceEpoch)
            .toList();

        String formatDuration(Duration d) {
          final hours = d.inHours.toString().padLeft(2, '0');
          final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
          return '-$hours:$minutes';
        }

        // Get city name for widget
        final cityName = ref.read(cityNameProvider).valueOrNull;

        // Calculate next prayer index
        int nextPrayerIndex = -1;
        switch (widgetNextPrayer) {
          case Prayer.fajr:
            nextPrayerIndex = 0;
            break;
          case Prayer.dhuhr:
            nextPrayerIndex = 1;
            break;
          case Prayer.asr:
            nextPrayerIndex = 2;
            break;
          case Prayer.maghrib:
            nextPrayerIndex = 3;
            break;
          case Prayer.isha:
            nextPrayerIndex = 4;
            break;
          default:
            nextPrayerIndex = -1;
        }

        WidgetService.updateWidgetData(
          nextPrayerName: _getPrayerName(context, widgetNextPrayer),
          nextPrayerTime: widgetNextPrayerTime != null
              ? (use24h
                    ? DateFormat('HH:mm').format(widgetNextPrayerTime)
                    : DateFormat.jm().format(widgetNextPrayerTime))
              : '--:--',
          timeRemaining: formatDuration(diff),
          nextPrayerTimeMillis:
              widgetNextPrayerTime?.millisecondsSinceEpoch ?? 0,
          nextPrayerIndex: nextPrayerIndex,
          prayerNames: prayerNames,
          prayerTimes: prayerTimeStrings,
          prayerTimeMillis: prayerTimeMillis,
          location: cityName,
          isSunrise: isSunrise,
          sunriseTime: use24h
              ? DateFormat('HH:mm').format(prayerTimes.sunrise)
              : DateFormat.jm().format(prayerTimes.sunrise),
          smartStackEnabled: settings.smartWidgetStackEnabled,
          widgetContextMode: contextMode,
          widgetContextMessage: contextMessage,
          dailyDhikrCount: dhikrProgress.$1,
          dailyDhikrGoal: dhikrProgress.$2,
          prayerCompletedToday: prayerProgress,
        );

        unawaited(
          _handleAutoMosqueMode(prayerTimes: prayerTimes, settings: settings),
        );
      });
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: prayerAsync.when(
          data: (prayerTimes) => _buildMainContent(context, prayerTimes),
          loading: () => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'جاري تحميل مواقيت الصلاة...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'حدث خطأ في تحميل البيانات',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    ref.invalidate(userLocationProvider);
                    ref.invalidate(prayerTimesProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, PrayerTimes prayerTimes) {
    final settings = ref.watch(settingsProvider);
    final resolvedNext = _resolveNextPrayer(prayerTimes, settings);
    final next = resolvedNext.$1;
    final nextTime = resolvedNext.$2;
    final localizations = AppLocalizations.of(context)!;
    final use24h = settings.use24hFormat;
    final showAllFeatures =
        settings.alwaysShowHomeCards || _showAllFeatureCards;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxContentWidth = screenWidth >= 1200
        ? 980.0
        : (screenWidth >= 900 ? 860.0 : double.infinity);
    final centeredInset =
        maxContentWidth.isFinite && screenWidth > maxContentWidth
        ? (screenWidth - maxContentWidth) / 2
        : 0.0;
    final horizontalPadding = 20.0 + centeredInset;
    final gridColumns = screenWidth >= 1200 ? 4 : (screenWidth >= 900 ? 3 : 2);
    final childAspectRatio = screenWidth >= 1200
        ? 1.25
        : (screenWidth >= 900 ? 1.18 : 1.1);

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              16,
              horizontalPadding,
              0,
            ),
            child: _buildHeader(context),
          ),
        ),

        // Hero Card: Next Prayer
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              20,
              horizontalPadding,
              0,
            ),
            child: _buildHeroCard(
              context,
              next,
              nextTime,
              localizations,
              use24h,
            ),
          ),
        ),

        // Prayer Times Card (Below Hero)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              16,
              horizontalPadding,
              0,
            ),
            child: _buildPrayerTimesCard(
              context,
              prayerTimes,
              next,
              localizations,
            ),
          ),
        ),

        if (!settings.alwaysShowHomeCards)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                0,
              ),
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _showAllFeatureCards = !_showAllFeatureCards;
                  });
                },
                icon: Icon(
                  showAllFeatures ? Icons.expand_less : Icons.expand_more,
                ),
                label: Text(
                  showAllFeatures
                      ? 'إخفاء الخيارات الإضافية'
                      : 'إظهار باقي الخيارات',
                ),
              ),
            ),
          ),

        // Features Grid
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            20,
            horizontalPadding,
            20,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridColumns,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
            ),
            delegate: SliverChildListDelegate([
              _buildFeatureCard(
                context,
                title: localizations.translate('quran'),
                icon: Icons.menu_book_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFFB8860B), Color(0xFFDAA520)],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuranIndexPage()),
                ),
              ),
              _buildFeatureCard(
                context,
                title: localizations.translate('qibla'),
                icon: Icons.explore_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QiblaPage()),
                ),
              ),
              _buildFeatureCard(
                context,
                title: localizations.translate('azkar'),
                icon: Icons.auto_stories_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1ABC9C), Color(0xFF16A085)],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AzkarPage()),
                ),
              ),
              _buildFeatureCard(
                context,
                title: localizations.translate('tasbih'),
                icon: Icons.touch_app_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFFE67E22), Color(0xFFD35400)],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TasbihPage()),
                ),
              ),
              if (showAllFeatures) ...[
                _buildFeatureCard(
                  context,
                  title: localizations.translate('calendar'),
                  icon: Icons.calendar_month_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8E44AD), Color(0xFF9B59B6)],
                  ),
                  subtitle: HijriCalendar.now().toFormat("dd MMMM"),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CalendarPage()),
                  ),
                ),
                _buildFeatureCard(
                  context,
                  title: localizations.translate('names_of_allah'),
                  icon: Icons.star_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C3483), Color(0xFF8E44AD)],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NamesOfAllahPage()),
                  ),
                ),
                _buildFeatureCard(
                  context,
                  title: localizations.translate('dua'),
                  icon: Icons.volunteer_activism_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DuaPage()),
                  ),
                ),
                _buildFeatureCard(
                  context,
                  title: localizations.translate('prayer_tracker'),
                  icon: Icons.check_circle_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrayerTrackerPage(),
                    ),
                  ),
                ),
                _buildFeatureCard(
                  context,
                  title: localizations.translate('qibla_map'),
                  icon: Icons.map_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF34495E), Color(0xFF2C3E50)],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QiblaMapPage()),
                  ),
                ),
                _buildFeatureCard(
                  context,
                  title: localizations.translate('zakat_calculator'),
                  icon: Icons.calculate_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD35400), Color(0xFFE67E22)],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ZakatPage()),
                  ),
                ),
                _buildFeatureCard(
                  context,
                  title: localizations.translate('missed_prayers'),
                  icon: Icons.history_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7F8C8D), Color(0xFF95A5A6)],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MissedPrayersPage(),
                    ),
                  ),
                ),
                _buildFeatureCard(
                  context,
                  title: localizations.translate('islamic_events'),
                  icon: Icons.event_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF16A085), Color(0xFF1ABC9C)],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const IslamicEventsPage(),
                    ),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final hijriToday = HijriCalendar.now().toFormat("dd MMMM yyyy");
    final cityAsync = ref.watch(cityNameProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, d MMMM').format(_currentTime),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hijriToday,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              cityAsync.when(
                data: (city) {
                  if (city == null) return const SizedBox.shrink();
                  return Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          city,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        Row(
          children: [
            _buildHeaderButton(
              icon: Icons.my_location,
              tooltip: 'تحديث الموقع',
              onPressed: () {
                ref.invalidate(userLocationProvider);
                ref.invalidate(prayerTimesProvider);
              },
            ),
            _buildHeaderButton(
              icon: settings.areNotificationsEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              tooltip: 'الإشعارات',
              isActive: settings.areNotificationsEnabled,
              onPressed: () async {
                final nextValue = !settings.areNotificationsEnabled;
                await ref
                    .read(settingsProvider.notifier)
                    .setNotificationsEnabled(nextValue);
                final prayerTimes = ref.read(prayerTimesProvider).value;
                if (prayerTimes != null) {
                  await _scheduleNotificationsWithSettings(
                    prayerTimes: prayerTimes,
                    settings: ref.read(settingsProvider),
                    suppressWindowMinutes: 20,
                  );
                }
              },
            ),
            _buildHeaderButton(
              icon: settings.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
              tooltip: 'تغيير المظهر',
              onPressed: () {
                final nextMode = settings.themeMode == ThemeMode.dark
                    ? ThemeMode.light
                    : ThemeMode.dark;
                ref.read(settingsProvider.notifier).setThemeMode(nextMode);
              },
            ),
            _buildHeaderButton(
              icon: Icons.settings,
              tooltip: 'الإعدادات',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = true,
  }) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(
        icon,
        color: isActive
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        size: 22,
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    Prayer next,
    DateTime? nextTime,
    AppLocalizations localizations,
    bool use24h,
  ) {
    final remaining = nextTime != null
        ? nextTime.difference(_currentTime)
        : Duration.zero;
    final hours = remaining.inHours.toString().padLeft(2, '0');
    final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: AppTheme.getPrayerGradient(next),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getPrayerGradient(
              next,
            ).colors.first.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative pattern
          Positioned(
            right: -30,
            top: -30,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1 + (_pulseController.value * 0.1),
                  child: Opacity(
                    opacity: 0.1,
                    child: Icon(
                      _getPrayerIcon(next),
                      size: 180,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.translate('next_prayer'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getPrayerName(context, next),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getPrayerIcon(next),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$hours:$minutes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 8,
                        left: 4,
                        right: 4,
                      ),
                      child: Text(
                        ':$seconds',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (nextTime != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          use24h
                              ? DateFormat('HH:mm').format(nextTime)
                              : DateFormat.jm().format(nextTime),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _computeWidgetContextMode({
    required DateTime now,
    required DateTime? nextPrayerTime,
    required bool smartStackEnabled,
  }) {
    if (!smartStackEnabled) return 'next_prayer';
    if (nextPrayerTime != null &&
        nextPrayerTime.difference(now).inMinutes <= 20 &&
        nextPrayerTime.isAfter(now)) {
      return 'prayer_focus';
    }
    final hour = now.hour;
    if (hour >= 5 && hour < 11) return 'morning_azkar';
    if (hour >= 17 && hour < 23) return 'evening_azkar';
    return 'next_prayer';
  }

  String _buildWidgetContextMessage(String mode) {
    switch (mode) {
      case 'morning_azkar':
        return 'وقت أذكار الصباح';
      case 'evening_azkar':
        return 'وقت أذكار المساء';
      case 'prayer_focus':
        return 'تهيأ للصلاة القادمة';
      default:
        return 'تابع خطتك اليومية';
    }
  }

  (int, int) _readDhikrProgress() {
    if (!Hive.isBoxOpen('tasbih')) return (0, 100);
    final box = Hive.box('tasbih');
    final count = (box.get('count', defaultValue: 0) as int?) ?? 0;
    return (count, 100);
  }

  int _readPrayerProgress(DateTime now) {
    if (!Hive.isBoxOpen('prayer_tracker')) return 0;
    final box = Hive.box('prayer_tracker');
    final key = DateFormat('yyyy-MM-dd').format(now);
    final dayData = box.get(key, defaultValue: <String, dynamic>{});
    if (dayData is! Map) return 0;
    var completed = 0;
    for (final prayer in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
      if (dayData[prayer] == true) completed++;
    }
    return completed;
  }

  Future<void> _runNotificationGuardCheck() async {
    // Disabled by user request: do not show any auto-repair banners/snackbars.
    return;
  }

  Future<void> _handleAutoMosqueMode({
    required PrayerTimes prayerTimes,
    required SettingsState settings,
  }) async {
    if (!settings.autoMosqueModeEnabled) return;
    final resolved = _resolveNextPrayer(prayerTimes, settings);
    final nextPrayerTime = resolved.$2;
    if (nextPrayerTime == null) return;

    final now = DateTime.now();
    final leadAt = nextPrayerTime.subtract(
      Duration(minutes: settings.autoMosqueModeLeadMinutes),
    );
    final restoreAt = nextPrayerTime.add(
      Duration(minutes: settings.autoMosqueModeRestoreMinutes),
    );

    if (!_mosqueModeActive &&
        now.isAfter(leadAt) &&
        now.isBefore(restoreAt) &&
        (_mosqueModeAnchorPrayerTime == null ||
            _mosqueModeAnchorPrayerTime != nextPrayerTime)) {
      _mosqueModeActive = true;
      _mosqueModeAnchorPrayerTime = nextPrayerTime;
      _mosqueModeBackupSound = settings.notificationSound;
      _mosqueModeBackupVibration = settings.vibrationEnabled;
      await ref.read(settingsProvider.notifier).setNotificationSound('silent');
      await ref.read(settingsProvider.notifier).setVibrationEnabled(false);
      await _scheduleNotificationsWithSettings(
        prayerTimes: prayerTimes,
        settings: ref.read(settingsProvider),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تفعيل وضع المسجد تلقائيًا'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (_mosqueModeActive &&
        _mosqueModeAnchorPrayerTime != null &&
        now.isAfter(
          _mosqueModeAnchorPrayerTime!.add(
            Duration(minutes: settings.autoMosqueModeRestoreMinutes),
          ),
        )) {
      _mosqueModeActive = false;
      _mosqueModeAnchorPrayerTime = null;
      await ref
          .read(settingsProvider.notifier)
          .setNotificationSound(_mosqueModeBackupSound ?? 'system');
      await ref
          .read(settingsProvider.notifier)
          .setVibrationEnabled(_mosqueModeBackupVibration ?? true);
      final updatedSettings = ref.read(settingsProvider);
      await _scheduleNotificationsWithSettings(
        prayerTimes: prayerTimes,
        settings: updatedSettings,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنهاء وضع المسجد والعودة للإعدادات الأصلية'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _scheduleNotificationsWithSettings({
    required PrayerTimes prayerTimes,
    required SettingsState settings,
    int suppressWindowMinutes = 0,
  }) async {
    final enabledPrayers = <Prayer>{
      if (settings.fajrNotificationsEnabled) Prayer.fajr,
      if (settings.dhuhrNotificationsEnabled) Prayer.dhuhr,
      if (settings.asrNotificationsEnabled) Prayer.asr,
      if (settings.maghribNotificationsEnabled) Prayer.maghrib,
      if (settings.ishaNotificationsEnabled) Prayer.isha,
    };
    await ref
        .read(notificationServiceProvider)
        .schedulePrayers(
          prayerTimes,
          notificationsEnabled: settings.areNotificationsEnabled,
          prayerTimeNotificationsEnabled:
              settings.prayerTimeNotificationsEnabled,
          prePrayerRemindersEnabled: settings.prePrayerRemindersEnabled,
          preAzanReminderOffset: settings.preAzanReminderOffset,
          notificationSound: settings.notificationSound,
          vibrationEnabled: settings.vibrationEnabled,
          enabledPrayers: enabledPrayers,
          multiLevelRemindersEnabled: settings.multiLevelRemindersEnabled,
          suppressImmediateRemindersWindowMinutes: suppressWindowMinutes,
        );
  }

  (Prayer, DateTime?) _resolveNextPrayer(
    PrayerTimes prayerTimes,
    SettingsState settings,
  ) {
    Prayer nextPrayer = prayerTimes.nextPrayer();
    DateTime? nextPrayerTime = prayerTimes.timeForPrayer(nextPrayer);

    if (nextPrayer == Prayer.none || nextPrayerTime == null) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final params = settings.calculationMethod.getParameters();
      params.madhab = settings.madhab;
      final tomorrowTimes = PrayerTimes(
        prayerTimes.coordinates,
        DateComponents.from(tomorrow),
        params,
      );
      return (Prayer.fajr, tomorrowTimes.fajr);
    }

    if (nextPrayer == Prayer.sunrise) {
      return (Prayer.dhuhr, prayerTimes.dhuhr);
    }

    return (nextPrayer, nextPrayerTime);
  }

  Widget _buildPrayerTimesCard(
    BuildContext context,
    PrayerTimes prayerTimes,
    Prayer nextPrayer,
    AppLocalizations localizations,
  ) {
    final theme = Theme.of(context);
    final use24h = ref.watch(settingsProvider).use24hFormat;

    final prayers = [
      (
        Prayer.fajr,
        prayerTimes.fajr,
        localizations.translate('fajr'),
        Icons.wb_twilight,
      ),
      (
        Prayer.sunrise,
        prayerTimes.sunrise,
        localizations.translate('sunrise'),
        Icons.wb_sunny,
      ),
      (
        Prayer.dhuhr,
        prayerTimes.dhuhr,
        localizations.translate('dhuhr'),
        Icons.wb_sunny_outlined,
      ),
      (
        Prayer.asr,
        prayerTimes.asr,
        localizations.translate('asr'),
        Icons.cloud_queue,
      ),
      (
        Prayer.maghrib,
        prayerTimes.maghrib,
        localizations.translate('maghrib'),
        Icons.nights_stay_outlined,
      ),
      (
        Prayer.isha,
        prayerTimes.isha,
        localizations.translate('isha'),
        Icons.nights_stay,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.access_time_filled,
                color: theme.colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'مواقيت الصلاة',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Prayer times grid
          ...prayers.map((prayer) {
            final isNext = prayer.$1 == nextPrayer;
            final isPast = prayer.$2.isBefore(_currentTime);

            return _buildPrayerTimeRow(
              context,
              name: prayer.$3,
              time: prayer.$2,
              icon: prayer.$4,
              isNext: isNext,
              isPast: isPast && !isNext,
              use24h: use24h,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPrayerTimeRow(
    BuildContext context, {
    required String name,
    required DateTime time,
    required IconData icon,
    required bool isNext,
    required bool isPast,
    required bool use24h,
  }) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () {
        final now = DateTime.now();
        final diff = time.difference(now);
        final isFuture = !diff.isNegative;
        final absDiff = diff.abs();
        final hours = absDiff.inHours;
        final minutes = absDiff.inMinutes % 60;
        final h = localizations.translate('hour_short');
        final m = localizations.translate('minute_short');

        String msg;
        if (isFuture) {
          msg =
              '${localizations.translate('time_remaining_for')} $name: $hours$h $minutes$m';
        } else {
          final isAr = localizations.locale.languageCode == 'ar';
          if (isAr) {
            msg =
                '${localizations.translate('passed')} $name ${localizations.translate('ago')} $hours$h $minutes$m';
          } else {
            msg =
                '$name ${localizations.translate('passed')} $hours$h $minutes$m ${localizations.translate('ago')}';
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: isNext
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.secondary.withValues(alpha: 0.15),
                    theme.colorScheme.secondary.withValues(alpha: 0.05),
                  ],
                )
              : null,
          color: isNext ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isNext
              ? Border.all(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isNext
                    ? theme.colorScheme.secondary.withValues(alpha: 0.2)
                    : theme.dividerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isNext
                    ? theme.colorScheme.secondary
                    : isPast
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isNext
                      ? theme.colorScheme.secondary
                      : isPast
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                      : theme.colorScheme.onSurface,
                  fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            if (isNext)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'التالية',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              use24h
                  ? DateFormat('HH:mm').format(time)
                  : DateFormat.jm().format(time),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isNext
                    ? theme.colorScheme.secondary
                    : isPast
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                    : theme.colorScheme.onSurface,
                fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (gradient as LinearGradient).colors.first.withValues(
                alpha: 0.3,
              ),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              bottom: -20,
              child: Opacity(
                opacity: 0.15,
                child: Icon(icon, size: 100, color: Colors.white),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (subtitle != null) ...[
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPrayerName(BuildContext context, Prayer prayer) {
    final localizations = AppLocalizations.of(context)!;
    switch (prayer) {
      case Prayer.fajr:
        return localizations.translate('fajr');
      case Prayer.sunrise:
        return localizations.translate('sunrise');
      case Prayer.dhuhr:
        return localizations.translate('dhuhr');
      case Prayer.asr:
        return localizations.translate('asr');
      case Prayer.maghrib:
        return localizations.translate('maghrib');
      case Prayer.isha:
        return localizations.translate('isha');
      case Prayer.none:
        return localizations.translate('none');
    }
  }

  IconData _getPrayerIcon(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return Icons.wb_twilight;
      case Prayer.sunrise:
        return Icons.wb_sunny;
      case Prayer.dhuhr:
        return Icons.wb_sunny_outlined;
      case Prayer.asr:
        return Icons.cloud_queue;
      case Prayer.maghrib:
        return Icons.nights_stay_outlined;
      case Prayer.isha:
        return Icons.nights_stay;
      default:
        return Icons.access_time;
    }
  }
}
