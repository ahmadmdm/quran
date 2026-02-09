import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quran/quran.dart' as quran;
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/localization/app_localizations.dart';

class QuranReaderPage extends StatefulWidget {
  final int initialSurahNumber;
  final int? initialVerseNumber;
  final bool isWirdMode;
  final int? khatmaId;

  const QuranReaderPage({
    super.key,
    required this.initialSurahNumber,
    this.initialVerseNumber,
    this.isWirdMode = false,
    this.khatmaId,
  });

  @override
  State<QuranReaderPage> createState() => _QuranReaderPageState();
}

enum ReaderMode { reading, hifz }

class _QuranReaderPageState extends State<QuranReaderPage>
    with TickerProviderStateMixin {
  late int _currentSurahNumber;
  late final PageController _pageController;
  final Map<int, List<_PageVerse>> _pageVersesCache = {};

  // Settings
  double _fontSize = 26.0;
  bool _showTranslation = false;
  bool _isFavorite = false;
  late AnimationController _fabAnimationController;
  int _currentVisibleVerse = 1;
  int _currentVisiblePage = 1;
  ReaderMode _readerMode = ReaderMode.reading;
  int _selectedHifzVerseIndex = 0;
  bool _hideHifzVerseText = false;

  Timer? _focusTimer;
  int _focusTotalSeconds = 0;
  int _focusRemainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _currentSurahNumber = widget.initialSurahNumber;
    _currentVisibleVerse = widget.initialVerseNumber ?? 1;
    _currentVisiblePage = quran.getPageNumber(
      _currentSurahNumber,
      _currentVisibleVerse,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pageController = PageController(initialPage: _currentVisiblePage - 1);

    _saveLastRead();
    _checkFavorite();
  }

  Future<void> _saveLastRead() async {
    final box = Hive.box('settings');
    await box.put('last_read_surah', _currentSurahNumber);
  }

  Future<void> _saveLastReadVerse(int verse) async {
    final box = Hive.box('settings');
    await box.put('last_read_verse', verse);

    // Update Wird/Khatma progress
    final pageNumber = quran.getPageNumber(_currentSurahNumber, verse);

    if (widget.isWirdMode) {
      await _updateWirdProgress(box, pageNumber);
    }

    if (widget.khatmaId != null) {
      await _updateKhatmaProgress(box, pageNumber);
    }
  }

  Future<void> _updateWirdProgress(Box box, int pageNumber) async {
    final currentWirdPage = box.get('daily_wird_current_page', defaultValue: 1);
    final lastDate = box.get('daily_wird_last_date', defaultValue: '');
    final today = DateTime.now().toString().split(' ')[0];

    // Check if new day, update start page if needed
    var startPage = box.get('daily_wird_start_page');
    if (lastDate != today) {
      startPage = currentWirdPage;
      await box.put('daily_wird_last_date', today);
      await box.put('daily_wird_start_page', startPage);
      await box.put('daily_wird_completed_today', false);
    } else if (startPage == null) {
      startPage = currentWirdPage;
      await box.put('daily_wird_start_page', startPage);
    }

    // Only update if we moved forward
    if (pageNumber > currentWirdPage) {
      await box.put('daily_wird_current_page', pageNumber);

      // Update completion status if goal reached
      final dailyPages = box.get('daily_wird_pages', defaultValue: 5);

      // If we read enough pages
      if (pageNumber >= startPage + dailyPages) {
        final completedToday = box.get(
          'daily_wird_completed_today',
          defaultValue: false,
        );
        if (!completedToday) {
          await box.put('daily_wird_completed_today', true);
          // Increment streak if completed today
          final streak = box.get('daily_wird_streak', defaultValue: 0);
          await box.put('daily_wird_streak', streak + 1);
        }
      }
    }
  }

  Future<void> _updateKhatmaProgress(Box box, int pageNumber) async {
    final khatmaList = (box.get('khatma_list', defaultValue: <Map>[]) as List)
        .cast<Map>();
    final index = khatmaList.indexWhere((k) => k['id'] == widget.khatmaId);

    if (index != -1) {
      final khatma = Map<String, dynamic>.from(khatmaList[index]);
      final currentKhatmaPage = khatma['current_page'] ?? 1;

      if (pageNumber > currentKhatmaPage) {
        khatma['current_page'] = pageNumber;
        khatmaList[index] = khatma;
        await box.put('khatma_list', khatmaList);
      }
    }
  }

  Future<void> _checkFavorite() async {
    final box = Hive.box('settings');
    final favorites =
        (box.get('favorite_surahs', defaultValue: <int>[]) as List).cast<int>();
    setState(() {
      _isFavorite = favorites.contains(_currentSurahNumber);
    });
  }

  Future<void> _toggleFavorite() async {
    final box = Hive.box('settings');
    final favorites =
        (box.get('favorite_surahs', defaultValue: <int>[]) as List).cast<int>();

    if (_isFavorite) {
      favorites.remove(_currentSurahNumber);
    } else {
      favorites.add(_currentSurahNumber);
    }

    await box.put('favorite_surahs', favorites);
    if (!mounted) return;

    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite ? 'تمت الإضافة للمفضلة' : 'تمت الإزالة من المفضلة',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  bool get _isFocusRunning => _focusTimer != null;

  String _formatFocusDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startFocusSession(int minutes) {
    _focusTimer?.cancel();
    setState(() {
      _focusTotalSeconds = minutes * 60;
      _focusRemainingSeconds = _focusTotalSeconds;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('انتهت جلسة التركيز، تقبل الله منك'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        setState(() {
          _focusRemainingSeconds -= 1;
        });
      }
    });
  }

  void _stopFocusSession() {
    _focusTimer?.cancel();
    _focusTimer = null;
    setState(() {
      _focusTotalSeconds = 0;
      _focusRemainingSeconds = 0;
    });
  }

  Future<void> _showFocusModeSheet(ThemeData theme) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Focus Mode',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'جلسات قراءة مركزة بدون مشتتات',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.75,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildFocusPreset(theme, minutes: 10),
                  _buildFocusPreset(theme, minutes: 20),
                  _buildFocusPreset(theme, minutes: 30),
                ],
              ),
              const SizedBox(height: 14),
              if (_isFocusRunning)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_rounded,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'متبقي ${_formatFocusDuration(_focusRemainingSeconds)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _stopFocusSession,
                        child: const Text('إيقاف'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFocusPreset(ThemeData theme, {required int minutes}) {
    return OutlinedButton.icon(
      onPressed: () => _startFocusSession(minutes),
      icon: const Icon(Icons.play_arrow_rounded),
      label: Text('$minutes دقيقة'),
    );
  }

  bool _isCurrentPageBookmarked() {
    final box = Hive.box('settings');
    final pageBookmarks =
        (box.get('page_bookmarks', defaultValue: <int>[]) as List).cast<int>();
    return pageBookmarks.contains(_currentVisiblePage);
  }

  Future<void> _toggleCurrentPageBookmark() async {
    final box = Hive.box('settings');
    final pageBookmarks =
        (box.get('page_bookmarks', defaultValue: <int>[]) as List).cast<int>();
    final page = _currentVisiblePage;

    if (pageBookmarks.contains(page)) {
      pageBookmarks.remove(page);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إزالة فاصل الصفحة $page'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } else {
      pageBookmarks.add(page);
      pageBookmarks.sort();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ فاصل الصفحة $page'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }

    await box.put('page_bookmarks', pageBookmarks);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showJumpToPageDialog() async {
    final controller = TextEditingController(text: '$_currentVisiblePage');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('الانتقال إلى صفحة'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'أدخل رقم الصفحة (1 - 604)',
            ),
            onSubmitted: (_) => Navigator.pop(dialogContext),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('انتقال'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    final page = int.tryParse(controller.text.trim());
    if (page == null || page < 1 || page > 604) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('رقم الصفحة غير صالح. اختر من 1 إلى 604'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    await _jumpToPage(page);
  }

  // Check if a verse is bookmarked
  bool _isVerseBookmarked(int surahNumber, int verseNumber) {
    final box = Hive.box('settings');
    final bookmarks =
        (box.get('verse_bookmarks', defaultValue: <String>[]) as List)
            .cast<String>();
    final key = '$surahNumber:$verseNumber';
    return bookmarks.contains(key);
  }

  // Toggle verse bookmark
  Future<void> _toggleVerseBookmark(int surahNumber, int verseNumber) async {
    final box = Hive.box('settings');
    final bookmarks =
        (box.get('verse_bookmarks', defaultValue: <String>[]) as List)
            .cast<String>();
    final key = '$surahNumber:$verseNumber';

    if (bookmarks.contains(key)) {
      bookmarks.remove(key);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم إزالة الفاصل'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      bookmarks.add(key);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم حفظ الفاصل'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    await box.put('verse_bookmarks', bookmarks);
    setState(() {});
  }

  // Share verse
  Future<void> _shareVerse(int surahNumber, int verseNumber) async {
    final verseText = quran.getVerse(surahNumber, verseNumber);
    final surahName = quran.getSurahNameArabic(surahNumber);
    final shareText =
        '''
$verseText

📖 سورة $surahName - الآية $verseNumber
''';

    await Share.share(shareText, subject: 'آية من القرآن الكريم');
  }

  // Copy verse to clipboard
  Future<void> _copyVerse(int surahNumber, int verseNumber) async {
    final verseText = quran.getVerse(surahNumber, verseNumber);
    final surahName = quran.getSurahNameArabic(surahNumber);
    final copyText =
        '''
$verseText

📖 سورة $surahName - الآية $verseNumber
''';

    await Clipboard.setData(ClipboardData(text: copyText));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم نسخ الآية'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Quran paper colors
    final quranPaperColor = isDark
        ? const Color(0xFF1A1A2E) // Dark mode paper
        : const Color(0xFFFDF8E8); // Classic Quran cream/beige paper
    final quranHeaderColor = isDark
        ? const Color(0xFF16213E)
        : const Color(0xFF1B4332); // Dark green header (traditional Quran)

    return Scaffold(
      backgroundColor: quranPaperColor,
      body: Stack(
        children: [
          // Decorative Quran paper pattern background
          Positioned.fill(
            child: CustomPaint(
              painter: _QuranPaperPatternPainter(isDark: isDark),
            ),
          ),
          // Main Content
          CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 140,
                floating: false,
                pinned: true,
                backgroundColor: quranHeaderColor,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.text_increase_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_fontSize < 40) _fontSize += 2;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.text_decrease_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_fontSize > 18) _fontSize -= 2;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => _showSettingsSheet(context),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient Background
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
                      // Decorative Pattern
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Opacity(
                          opacity: 0.08,
                          child: Icon(
                            Icons.auto_stories_rounded,
                            size: 180,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Surah Info
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              quran.getSurahNameArabic(_currentSurahNumber),
                              style: GoogleFonts.amiriQuran(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSurahInfoChip(
                                  quran.getPlaceOfRevelation(
                                            _currentSurahNumber,
                                          ) ==
                                          'Makkah'
                                      ? localizations.translate(
                                          'revelation_mecca',
                                        )
                                      : localizations.translate(
                                          'revelation_medina',
                                        ),
                                ),
                                const SizedBox(width: 8),
                                _buildSurahInfoChip(
                                  '${quran.getVerseCount(_currentSurahNumber)} ${localizations.translate('verses')}',
                                ),
                                const SizedBox(width: 8),
                                _buildSurahInfoChip(
                                  'صفحة $_currentVisiblePage',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverFillRemaining(
                hasScrollBody: false,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F1629)
                        : const Color(0xFFFAF8F5),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildReaderOptionsBar(theme),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 78),
                          child: PageView.builder(
                            controller: _pageController,
                            reverse:
                                Directionality.of(context) == TextDirection.ltr,
                            onPageChanged: (index) =>
                                _handlePageChanged(index + 1),
                            itemCount: 604,
                            itemBuilder: (context, index) {
                              final pageNumber = index + 1;
                              if (_readerMode == ReaderMode.hifz) {
                                return _buildHifzPage(
                                  context,
                                  theme,
                                  pageNumber: pageNumber,
                                  isDark: isDark,
                                );
                              }
                              return _buildMushafPage(
                                context,
                                theme,
                                pageNumber: pageNumber,
                                isDark: isDark,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavigation(context, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }

  TextStyle _medinaVerseStyle(double size, Color color) {
    return GoogleFonts.amiriQuran(
      fontSize: size,
      color: color,
      fontWeight: FontWeight.w400,
      height: 2.15,
      letterSpacing: 0.1,
    );
  }

  List<_PageVerse> _getVersesForPage(int pageNumber) {
    final cached = _pageVersesCache[pageNumber];
    if (cached != null) return cached;

    final verses = <_PageVerse>[];
    for (int surah = 1; surah <= 114; surah++) {
      final verseCount = quran.getVerseCount(surah);
      for (int verse = 1; verse <= verseCount; verse++) {
        if (quran.getPageNumber(surah, verse) == pageNumber) {
          verses.add(
            _PageVerse(
              surahNumber: surah,
              verseNumber: verse,
              text: quran.getVerse(surah, verse),
            ),
          );
        }
      }
    }
    _pageVersesCache[pageNumber] = verses;
    return verses;
  }

  Future<void> _jumpToPage(int pageNumber) async {
    final clampedPage = pageNumber.clamp(1, 604);
    final verses = _getVersesForPage(clampedPage);
    if (verses.isEmpty) return;

    final firstVerse = verses.first;
    setState(() {
      _currentVisiblePage = clampedPage;
      _currentSurahNumber = firstVerse.surahNumber;
      _currentVisibleVerse = firstVerse.verseNumber;
      _selectedHifzVerseIndex = 0;
      _hideHifzVerseText = false;
    });

    await _saveLastRead();
    await _saveLastReadVerse(firstVerse.verseNumber);
    await _checkFavorite();

    if (_pageController.hasClients) {
      await _pageController.animateToPage(
        clampedPage - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _handlePageChanged(int pageNumber) async {
    final verses = _getVersesForPage(pageNumber);
    if (verses.isEmpty) return;
    final firstVerse = verses.first;

    if (!mounted) return;
    setState(() {
      _currentVisiblePage = pageNumber;
      _currentSurahNumber = firstVerse.surahNumber;
      _currentVisibleVerse = firstVerse.verseNumber;
      _selectedHifzVerseIndex = 0;
      _hideHifzVerseText = false;
    });

    await _saveLastRead();
    await _saveLastReadVerse(firstVerse.verseNumber);
    await _checkFavorite();
  }

  Future<void> _showPageVersesSheet(int pageNumber, ThemeData theme) async {
    final verses = _getVersesForPage(pageNumber);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'آيات الصفحة $pageNumber',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: verses.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: theme.dividerColor.withValues(alpha: 0.35),
                  ),
                  itemBuilder: (context, index) {
                    final verse = verses[index];
                    final isBookmarked = _isVerseBookmarked(
                      verse.surahNumber,
                      verse.verseNumber,
                    );
                    return ListTile(
                      title: Text(
                        verse.text,
                        textDirection: TextDirection.rtl,
                        style: _medinaVerseStyle(
                          (_fontSize - 6).clamp(18, 30).toDouble(),
                          theme.textTheme.bodyLarge?.color ??
                              theme.colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        '${quran.getSurahNameArabic(verse.surahNumber)} - آية ${verse.verseNumber}',
                      ),
                      trailing: Wrap(
                        spacing: 2,
                        children: [
                          IconButton(
                            icon: Icon(
                              isBookmarked
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                            ),
                            onPressed: () async {
                              await _toggleVerseBookmark(
                                verse.surahNumber,
                                verse.verseNumber,
                              );
                              if (mounted) {
                                setState(() {});
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.share_rounded),
                            onPressed: () => _shareVerse(
                              verse.surahNumber,
                              verse.verseNumber,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded),
                            onPressed: () => _copyVerse(
                              verse.surahNumber,
                              verse.verseNumber,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _normalizeArabicText(String input) {
    final noTashkeel = input.replaceAll(
      RegExp(r'[\u064B-\u0652\u0670\u0640]'),
      '',
    );
    final cleaned = noTashkeel
        .replaceAll(RegExp(r'[^\u0621-\u063A\u0641-\u064A0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned;
  }

  Future<void> _showHifzQuickTest(_PageVerse verse, ThemeData theme) async {
    final normalized = _normalizeArabicText(verse.text);
    final words = normalized.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length < 4) {
      return;
    }

    final hiddenIndex = (words.length / 2).floor().clamp(1, words.length - 2);
    final expected = words[hiddenIndex];
    final promptWords = [...words]..[hiddenIndex] = '_____';
    final prompt = promptWords.join(' ');

    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('اختبار سريع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('أكمل الكلمة الناقصة:', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(
                prompt,
                textDirection: TextDirection.rtl,
                style: _medinaVerseStyle(24, theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  hintText: 'اكتب الكلمة الناقصة',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('تحقق'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    final answer = _normalizeArabicText(controller.text);
    final isCorrect = answer == expected;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? 'إجابة صحيحة ممتاز' : 'الصحيح: $expected'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildHifzPage(
    BuildContext context,
    ThemeData theme, {
    required int pageNumber,
    required bool isDark,
  }) {
    final verses = _getVersesForPage(pageNumber);
    if (verses.isEmpty) return const SizedBox.shrink();

    final safeIndex = _selectedHifzVerseIndex.clamp(0, verses.length - 1);
    final verse = verses[safeIndex];
    final cardColor = isDark
        ? const Color(0xFF1A1A2E)
        : const Color(0xFFFFFBF0);
    final textColor = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : const Color(0xFF1A1A1A);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Text(
            'وضع الحفظ - صفحة $pageNumber',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: verses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == safeIndex;
                return ChoiceChip(
                  label: Text('آية ${verses[index].verseNumber}'),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedHifzVerseIndex = index;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  _hideHifzVerseText ? '••••••••••••••' : verse.text,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: _medinaVerseStyle(_fontSize + 2, textColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _hideHifzVerseText = !_hideHifzVerseText;
                    });
                  },
                  icon: Icon(
                    _hideHifzVerseText
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  label: Text(_hideHifzVerseText ? 'إظهار النص' : 'إخفاء النص'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _showHifzQuickTest(verse, theme),
                  icon: const Icon(Icons.quiz_rounded),
                  label: const Text('اختبار سريع'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMushafPage(
    BuildContext context,
    ThemeData theme, {
    required int pageNumber,
    required bool isDark,
  }) {
    final verses = _getVersesForPage(pageNumber);
    if (verses.isEmpty) {
      return const SizedBox.shrink();
    }

    final quranCardColor = isDark
        ? const Color(0xFF1A1A2E)
        : const Color(0xFFFFFBF0);
    final quranBorderColor = isDark
        ? const Color(0xFF3D3D5C)
        : const Color(0xFFD4AF37);
    final verseTextColor = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : const Color(0xFF1A1A1A);
    final pageText = verses
        .map((v) => '${v.text}  ﴿${v.verseNumber}﴾')
        .join('  ');
    final firstSurah = verses.first.surahNumber;
    final showBasmala =
        verses.first.verseNumber == 1 && firstSurah != 1 && firstSurah != 9;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      decoration: BoxDecoration(
        color: quranCardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: quranBorderColor.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            quran.getSurahNameArabic(firstSurah),
            style: GoogleFonts.amiriQuran(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
            ),
          ),
          if (showBasmala)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                quran.basmala,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.amiriQuran(
                  fontSize: _fontSize * 0.95,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                pageText,
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                style: _medinaVerseStyle(_fontSize, verseTextColor),
              ),
            ),
          ),
          if (_showTranslation)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'الترجمة متاحة من "خيارات الصفحة"',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: verseTextColor.withValues(alpha: 0.75),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'صفحة $pageNumber',
                style: GoogleFonts.amiri(
                  fontSize: 18,
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.menu_book_rounded),
                onPressed: () => _showPageVersesSheet(pageNumber, theme),
                tooltip: 'آيات الصفحة',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReaderOptionsBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.secondary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('وضع القراءة'),
                  selected: _readerMode == ReaderMode.reading,
                  onSelected: (_) {
                    setState(() {
                      _readerMode = ReaderMode.reading;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('وضع الحفظ'),
                  selected: _readerMode == ReaderMode.hifz,
                  onSelected: (_) {
                    setState(() {
                      _readerMode = ReaderMode.hifz;
                    });
                  },
                ),
                const SizedBox(width: 10),
                if (_isFocusRunning)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_formatFocusDuration(_focusRemainingSeconds)} (${(((_focusTotalSeconds - _focusRemainingSeconds) / (_focusTotalSeconds == 0 ? 1 : _focusTotalSeconds)) * 100).round()}%)',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTopOptionAction(
                  theme: theme,
                  icon: _isCurrentPageBookmarked()
                      ? Icons.bookmark_added_rounded
                      : Icons.bookmark_add_rounded,
                  label: _isCurrentPageBookmarked()
                      ? 'إزالة الفاصل'
                      : 'حفظ فاصل',
                  onTap: _toggleCurrentPageBookmark,
                ),
                _buildTopOptionAction(
                  theme: theme,
                  icon: Icons.find_in_page_rounded,
                  label: 'انتقال',
                  onTap: _showJumpToPageDialog,
                ),
                _buildTopOptionAction(
                  theme: theme,
                  icon: Icons.list_alt_rounded,
                  label: 'خيارات الصفحة',
                  onTap: () => _showPageVersesSheet(_currentVisiblePage, theme),
                ),
                _buildTopOptionAction(
                  theme: theme,
                  icon: _isFocusRunning
                      ? Icons.pause_circle_filled_rounded
                      : Icons.timer_rounded,
                  label: 'تركيز',
                  onTap: () => _showFocusModeSheet(theme),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopOptionAction({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.secondary),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: _currentVisiblePage > 1
                  ? () => _jumpToPage(_currentVisiblePage - 1)
                  : null,
              tooltip: 'التالي',
              theme: theme,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'صفحة $_currentVisiblePage',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildNavIconButton(
              icon: Icons.arrow_forward_ios_rounded,
              onTap: _currentVisiblePage < 604
                  ? () => _jumpToPage(_currentVisiblePage + 1)
                  : null,
              tooltip: 'السابق',
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIconButton({
    required IconData icon,
    required VoidCallback? onTap,
    required String tooltip,
    required ThemeData theme,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 40,
          decoration: BoxDecoration(
            color: onTap == null
                ? theme.disabledColor.withValues(alpha: 0.15)
                : theme.colorScheme.secondary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 18,
            color: onTap == null
                ? theme.disabledColor
                : theme.colorScheme.secondary,
          ),
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'إعدادات القراءة',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Font Size
                  Text(
                    'حجم الخط',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (_fontSize > 18) {
                            setSheetState(() => _fontSize -= 2);
                            setState(() {});
                          }
                        },
                      ),
                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 18,
                          max: 40,
                          divisions: 11,
                          activeColor: theme.colorScheme.secondary,
                          onChanged: (value) {
                            setSheetState(() => _fontSize = value);
                            setState(() {});
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          if (_fontSize < 40) {
                            setSheetState(() => _fontSize += 2);
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Translation Toggle
                  SwitchListTile(
                    title: const Text('إظهار الترجمة'),
                    subtitle: const Text('عرض معنى الآية بلغة أخرى'),
                    value: _showTranslation,
                    activeThumbColor: theme.colorScheme.secondary,
                    onChanged: (value) {
                      setSheetState(() => _showTranslation = value);
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PageVerse {
  final int surahNumber;
  final int verseNumber;
  final String text;

  const _PageVerse({
    required this.surahNumber,
    required this.verseNumber,
    required this.text,
  });
}

/// Custom painter for Quran paper pattern background
class _QuranPaperPatternPainter extends CustomPainter {
  final bool isDark;

  _QuranPaperPatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? const Color(0xFF2D2D4A).withValues(alpha: 0.3)
          : const Color(0xFFD4AF37).withValues(alpha: 0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw decorative border frame
    final borderPaint = Paint()
      ..color = isDark
          ? const Color(0xFF4A4A6A).withValues(alpha: 0.5)
          : const Color(0xFFD4AF37).withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Outer border
    final outerRect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    canvas.drawRect(outerRect, borderPaint);

    // Inner border
    final innerRect = Rect.fromLTWH(16, 16, size.width - 32, size.height - 32);
    canvas.drawRect(innerRect, borderPaint..strokeWidth = 1);

    // Draw subtle corner decorations
    _drawCornerDecoration(canvas, 20, 20, paint);
    _drawCornerDecoration(canvas, size.width - 20, 20, paint, flipX: true);
    _drawCornerDecoration(canvas, 20, size.height - 20, paint, flipY: true);
    _drawCornerDecoration(
      canvas,
      size.width - 20,
      size.height - 20,
      paint,
      flipX: true,
      flipY: true,
    );
  }

  void _drawCornerDecoration(
    Canvas canvas,
    double x,
    double y,
    Paint paint, {
    bool flipX = false,
    bool flipY = false,
  }) {
    final path = Path();
    final dx = flipX ? -1.0 : 1.0;
    final dy = flipY ? -1.0 : 1.0;

    // Simple Islamic geometric corner pattern
    path.moveTo(x, y);
    path.lineTo(x + 15 * dx, y);
    path.moveTo(x, y);
    path.lineTo(x, y + 15 * dy);
    path.moveTo(x + 5 * dx, y + 5 * dy);
    path.lineTo(x + 12 * dx, y + 5 * dy);
    path.moveTo(x + 5 * dx, y + 5 * dy);
    path.lineTo(x + 5 * dx, y + 12 * dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
