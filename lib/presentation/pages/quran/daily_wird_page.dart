import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:quran/quran.dart' as quran;
import 'quran_reader_page.dart';

class DailyWirdPage extends ConsumerStatefulWidget {
  const DailyWirdPage({super.key});

  @override
  ConsumerState<DailyWirdPage> createState() => _DailyWirdPageState();
}

class _DailyWirdPageState extends ConsumerState<DailyWirdPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _settingsBox = Hive.box('settings');

  // Wird settings
  int _dailyPages = 5; // Default 5 pages per day
  int _khatmaGoalDays = 30; // Complete Quran in 30 days

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSettings();
  }

  void _loadSettings() {
    _dailyPages = _settingsBox.get('daily_wird_pages', defaultValue: 5);
    _khatmaGoalDays = _settingsBox.get('khatma_goal_days', defaultValue: 30);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: isDark
                  ? const Color(0xFF1A1F38)
                  : const Color(0xFF2C3E50),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDark
                              ? [
                                  const Color(0xFF1A1F38),
                                  const Color(0xFF0F1629),
                                ]
                              : [
                                  const Color(0xFF2C3E50),
                                  const Color(0xFF1A252F),
                                ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(
                          Icons.auto_stories,
                          size: 200,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 60,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الورد اليومي والختمة',
                            style: GoogleFonts.amiri(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'تابع تقدمك في قراءة القرآن الكريم',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: theme.colorScheme.secondary,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: theme.colorScheme.secondary,
                    unselectedLabelColor: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.6),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'الورد اليومي'),
                      Tab(text: 'الختمة'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [_buildDailyWirdTab(context), _buildKhatmaTab(context)],
        ),
      ),
    );
  }

  Widget _buildDailyWirdTab(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder(
      valueListenable: _settingsBox.listenable(
        keys: [
          'daily_wird_current_page',
          'daily_wird_completed_today',
          'daily_wird_streak',
          'daily_wird_last_date',
        ],
      ),
      builder: (context, Box box, child) {
        final currentPage = box.get('daily_wird_current_page', defaultValue: 1);
        final completedToday = box.get(
          'daily_wird_completed_today',
          defaultValue: false,
        );
        final streak = box.get('daily_wird_streak', defaultValue: 0);
        final lastDate = box.get('daily_wird_last_date', defaultValue: '');

        // Check if it's a new day
        final today = DateTime.now().toString().split(' ')[0];
        if (lastDate != today && completedToday) {
          // Reset for new day
          box.put('daily_wird_completed_today', false);
        }

        // Calculate progress
        final totalPages = 604; // Total pages in Quran
        final progress = currentPage / totalPages;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Streak Card
              _buildStreakCard(context, streak),

              const SizedBox(height: 20),

              // Today's Progress Card
              _buildTodayProgressCard(context, currentPage, completedToday),

              const SizedBox(height: 20),

              // Overall Progress
              _buildOverallProgressCard(context, currentPage, totalPages),

              const SizedBox(height: 20),

              // Start Reading Button
              _buildStartReadingButton(context, currentPage),

              const SizedBox(height: 20),

              // Settings Card
              _buildWirdSettingsCard(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStreakCard(BuildContext context, int streak) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondary,
            theme.colorScheme.secondary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.secondary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سلسلة المواظبة',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$streak',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'يوم متتالي',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
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

  Widget _buildTodayProgressCard(
    BuildContext context,
    int currentPage,
    bool completedToday,
  ) {
    final theme = Theme.of(context);
    final todayProgress = completedToday ? 1.0 : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ورد اليوم',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: completedToday
                      ? Colors.green.withValues(alpha: 0.1)
                      : theme.colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      completedToday ? Icons.check_circle : Icons.schedule,
                      size: 16,
                      color: completedToday
                          ? Colors.green
                          : theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      completedToday ? 'مكتمل' : 'قيد التنفيذ',
                      style: TextStyle(
                        color: completedToday
                            ? Colors.green
                            : theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الصفحات المطلوبة',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_dailyPages صفحات',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: theme.dividerColor.withValues(alpha: 0.3),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'من صفحة',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currentPage - ${currentPage + _dailyPages - 1}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverallProgressCard(
    BuildContext context,
    int currentPage,
    int totalPages,
  ) {
    final theme = Theme.of(context);
    final progress = currentPage / totalPages;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'التقدم الكلي',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: theme.dividerColor.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'صفحة $currentPage من $totalPages',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
              Text(
                'باقي ${totalPages - currentPage} صفحة',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStartReadingButton(BuildContext context, int currentPage) {
    final theme = Theme.of(context);

    // Find surah and verse for current page
    int surahNumber = 1;
    int verseNumber = 1;

    // Calculate surah from page number
    for (int i = 1; i <= 114; i++) {
      final pages = quran.getSurahPages(i);
      if (pages.contains(currentPage)) {
        surahNumber = i;
        break;
      }
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuranReaderPage(
                initialSurahNumber: surahNumber,
                initialVerseNumber: verseNumber,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: theme.colorScheme.secondary.withValues(alpha: 0.4),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 24),
            SizedBox(width: 8),
            Text(
              'ابدأ القراءة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWirdSettingsCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings,
                color: theme.colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'إعدادات الورد',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('عدد الصفحات اليومية'),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_dailyPages > 1) {
                        setState(() => _dailyPages--);
                        _settingsBox.put('daily_wird_pages', _dailyPages);
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                    color: theme.colorScheme.secondary,
                  ),
                  Text(
                    '$_dailyPages',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_dailyPages < 20) {
                        setState(() => _dailyPages++);
                        _settingsBox.put('daily_wird_pages', _dailyPages);
                      }
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    color: theme.colorScheme.secondary,
                  ),
                ],
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إعادة تعيين التقدم'),
              TextButton(
                onPressed: () => _showResetDialog(context),
                child: Text('إعادة تعيين', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKhatmaTab(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder(
      valueListenable: _settingsBox.listenable(
        keys: ['khatma_list', 'current_khatma_id'],
      ),
      builder: (context, Box box, child) {
        final khatmaList =
            (box.get('khatma_list', defaultValue: <Map>[]) as List).cast<Map>();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // New Khatma Button
              _buildNewKhatmaButton(context),

              const SizedBox(height: 20),

              // Active Khatmas
              if (khatmaList.isNotEmpty) ...[
                _buildSectionHeader(context, 'الختمات النشطة'),
                const SizedBox(height: 12),
                ...khatmaList.map(
                  (khatma) => _buildKhatmaCard(context, khatma),
                ),
              ] else
                _buildEmptyKhatmaState(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewKhatmaButton(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showNewKhatmaDialog(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.secondary.withValues(alpha: 0.1),
              theme.colorScheme.secondary.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.secondary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle,
              color: theme.colorScheme.secondary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'بدء ختمة جديدة',
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildKhatmaCard(BuildContext context, Map khatma) {
    final theme = Theme.of(context);
    final progress = (khatma['current_page'] ?? 1) / 604;
    final startDate = khatma['start_date'] ?? '';
    final goalDays = khatma['goal_days'] ?? 30;
    final name = khatma['name'] ?? 'ختمة';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: theme.dividerColor.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الهدف: $goalDays يوم',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
              Text(
                'بدأت: $startDate',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to reading
                final currentPage = khatma['current_page'] ?? 1;
                int surahNumber = 1;
                for (int i = 1; i <= 114; i++) {
                  final pages = quran.getSurahPages(i);
                  if (pages.contains(currentPage)) {
                    surahNumber = i;
                    break;
                  }
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        QuranReaderPage(initialSurahNumber: surahNumber),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('متابعة القراءة'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyKhatmaState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 80,
            color: theme.disabledColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد ختمات نشطة',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ ختمة جديدة لتتبع تقدمك في قراءة القرآن الكريم',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.disabledColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showNewKhatmaDialog(BuildContext context) {
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    int selectedDays = 30;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('ختمة جديدة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الختمة',
                  hintText: 'مثال: ختمة رمضان',
                ),
              ),
              const SizedBox(height: 20),
              const Text('الهدف (عدد الأيام)'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [7, 14, 30, 60].map((days) {
                  final isSelected = selectedDays == days;
                  return ChoiceChip(
                    label: Text('$days يوم'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setDialogState(() => selectedDays = days);
                    },
                    selectedColor: theme.colorScheme.secondary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final khatmaList =
                    (_settingsBox.get('khatma_list', defaultValue: <Map>[])
                            as List)
                        .cast<Map>();

                khatmaList.add({
                  'id': DateTime.now().millisecondsSinceEpoch,
                  'name': nameController.text.isEmpty
                      ? 'ختمة ${khatmaList.length + 1}'
                      : nameController.text,
                  'goal_days': selectedDays,
                  'current_page': 1,
                  'start_date': DateTime.now().toString().split(' ')[0],
                });

                _settingsBox.put('khatma_list', khatmaList);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
              ),
              child: const Text('بدء الختمة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة تعيين التقدم'),
        content: const Text(
          'هل أنت متأكد من إعادة تعيين تقدم الورد اليومي؟ سيتم البدء من الصفحة الأولى.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              _settingsBox.put('daily_wird_current_page', 1);
              _settingsBox.put('daily_wird_streak', 0);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );
  }
}
