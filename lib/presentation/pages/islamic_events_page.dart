import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../core/localization/app_localizations.dart';

class IslamicEventsPage extends StatelessWidget {
  const IslamicEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final events = _getEvents();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(localizations.translate('islamic_events')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return _buildEventCard(context, event, localizations);
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getEvents() {
    final now = HijriCalendar.now();
    final currentYear = now.hYear;

    // Simple static list for demonstration
    // In a real app, logic would calculate exact Gregorian dates for these Hijri dates
    return [
      {
        'title': 'Ramadan',
        'hijri_date': '1 Ramadan',
        'year': currentYear,
        'days_left': _calculateDaysLeft(9, 1),
      },
      {
        'title': 'Eid al-Fitr',
        'hijri_date': '1 Shawwal',
        'year': currentYear,
        'days_left': _calculateDaysLeft(10, 1),
      },
      {
        'title': 'Arafah',
        'hijri_date': '9 Dhu al-Hijjah',
        'year': currentYear,
        'days_left': _calculateDaysLeft(12, 9),
      },
      {
        'title': 'Eid al-Adha',
        'hijri_date': '10 Dhu al-Hijjah',
        'year': currentYear,
        'days_left': _calculateDaysLeft(12, 10),
      },
      {
        'title': 'Islamic New Year',
        'hijri_date': '1 Muharram',
        'year': currentYear + 1,
        'days_left': _calculateDaysLeft(1, 1, nextYear: true),
      },
      {
        'title': 'Ashura',
        'hijri_date': '10 Muharram',
        'year': currentYear + 1,
        'days_left': _calculateDaysLeft(1, 10, nextYear: true),
      },
    ];
  }

  int _calculateDaysLeft(int month, int day, {bool nextYear = false}) {
    // This is a rough approximation as Hijri months vary (29/30 days)
    final now = HijriCalendar.now();
    int currentMonth = now.hMonth;
    int currentDay = now.hDay;

    int totalDays = 0;

    if (nextYear) {
      totalDays +=
          (12 - currentMonth) * 30 +
          (30 - currentDay); // Remaining days in current year
      totalDays += (month - 1) * 30 + day; // Days in next year
    } else {
      if (currentMonth < month || (currentMonth == month && currentDay < day)) {
        totalDays += (month - currentMonth) * 30 + (day - currentDay);
      } else {
        // Passed this year, so calculate for next year
        totalDays += (12 - currentMonth) * 30 + (30 - currentDay);
        totalDays += (month - 1) * 30 + day;
      }
    }

    return totalDays;
  }

  Widget _buildEventCard(
    BuildContext context,
    Map<String, dynamic> event,
    AppLocalizations localizations,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${event['days_left']}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                Text(
                  'Days',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${event['hijri_date']} ${event['year']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
