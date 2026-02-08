import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_localizations.dart';
import '../providers/prayer_provider.dart';
import '../providers/settings_provider.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final locationAsync = ref.watch(userLocationProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(localizations.translate('calendar')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildCalendar(localizations),
          const SizedBox(height: 16),
          Expanded(
            child: locationAsync.when(
              data: (position) {
                return _buildDayDetails(
                  context,
                  position.latitude,
                  position.longitude,
                  settings.calculationMethod,
                  settings.madhab,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: TableCalendar(
        locale: localizations.locale.languageCode,
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          }
        },
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          weekendTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) => _buildCell(day),
          selectedBuilder: (context, day, focusedDay) =>
              _buildCell(day, isSelected: true),
          todayBuilder: (context, day, focusedDay) =>
              _buildCell(day, isToday: true),
          outsideBuilder: (context, day, focusedDay) => const SizedBox.shrink(),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: Theme.of(context).colorScheme.secondary,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCell(
    DateTime day, {
    bool isSelected = false,
    bool isToday = false,
  }) {
    final localizations = AppLocalizations.of(context)!;
    HijriCalendar.setLocal(localizations.locale.languageCode);
    final hijri = HijriCalendar.fromDate(day);
    final theme = Theme.of(context);
    final isAr = localizations.locale.languageCode == 'ar';

    String formatNum(int n) =>
        isAr ? NumberFormat.decimalPattern('ar').format(n) : n.toString();

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary
            : (isToday
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : Colors.transparent),
        borderRadius: BorderRadius.circular(12),
        border: isToday && !isSelected
            ? Border.all(color: theme.colorScheme.primary)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            formatNum(day.day),
            style: TextStyle(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatNum(hijri.hDay),
            style: TextStyle(
              color: isSelected
                  ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                  : theme.colorScheme.secondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayDetails(
    BuildContext context,
    double lat,
    double lng,
    CalculationMethod method,
    Madhab madhab,
  ) {
    if (_selectedDay == null) return const SizedBox.shrink();

    final date = DateComponents.from(_selectedDay!);
    final params = method.getParameters();
    params.madhab = madhab;
    final coordinates = Coordinates(lat, lng);
    final prayerTimes = PrayerTimes(coordinates, date, params);

    final hijriDate = HijriCalendar.fromDate(_selectedDay!);
    final localizations = AppLocalizations.of(context)!;
    HijriCalendar.setLocal(localizations.locale.languageCode);
    final use24h = ref.watch(settingsProvider).use24hFormat;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat.yMMMMd(
                      localizations.locale.languageCode,
                    ).format(_selectedDay!),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hijriDate.toFormat("dd MMMM yyyy"),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildPrayerRow(
                  localizations.translate('fajr'),
                  prayerTimes.fajr,
                  use24h,
                ),
                _buildPrayerRow(
                  localizations.translate('sunrise'),
                  prayerTimes.sunrise,
                  use24h,
                ),
                _buildPrayerRow(
                  localizations.translate('dhuhr'),
                  prayerTimes.dhuhr,
                  use24h,
                ),
                _buildPrayerRow(
                  localizations.translate('asr'),
                  prayerTimes.asr,
                  use24h,
                ),
                _buildPrayerRow(
                  localizations.translate('maghrib'),
                  prayerTimes.maghrib,
                  use24h,
                ),
                _buildPrayerRow(
                  localizations.translate('isha'),
                  prayerTimes.isha,
                  use24h,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerRow(String name, DateTime time, bool use24h) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            use24h
                ? DateFormat('HH:mm').format(time)
                : DateFormat.jm().format(time),
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
