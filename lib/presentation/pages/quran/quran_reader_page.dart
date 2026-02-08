import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quran/quran.dart' as quran;
import 'package:google_fonts/google_fonts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
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

class _QuranReaderPageState extends State<QuranReaderPage>
    with TickerProviderStateMixin {
  late int _currentSurahNumber;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  // Settings
  double _fontSize = 26.0;
  bool _showTranslation = false;
  bool _isFavorite = false;
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _currentSurahNumber = widget.initialSurahNumber;

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Scroll to initial verse after build
    if (widget.initialVerseNumber != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToVerse(widget.initialVerseNumber!);
      });
    }

    _saveLastRead();
    _checkFavorite();

    // Listen to scroll position to save last read verse
    _itemPositionsListener.itemPositions.addListener(_onScroll);
  }

  void _onScroll() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isNotEmpty) {
      final firstVisible = positions.reduce(
        (a, b) => a.itemLeadingEdge < b.itemLeadingEdge ? a : b,
      );
      int verseNumber = firstVisible.index;
      if (_hasBasmala()) {
        verseNumber = verseNumber > 0 ? verseNumber : 1;
      } else {
        verseNumber = verseNumber + 1;
      }
      _saveLastReadVerse(verseNumber);
    }
  }

  void _scrollToVerse(int verseNumber) {
    int indexToScroll = verseNumber - 1;
    if (_hasBasmala()) {
      indexToScroll += 1;
    }
    _itemScrollController.jumpTo(index: indexToScroll);
  }

  bool _hasBasmala() {
    return _currentSurahNumber != 1 && _currentSurahNumber != 9;
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
          final completedToday = box.get('daily_wird_completed_today', defaultValue: false);
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

  void _nextSurah() {
    if (_currentSurahNumber < 114) {
      setState(() {
        _currentSurahNumber++;
        _saveLastRead();
        _checkFavorite();
      });
      _itemScrollController.jumpTo(index: 0);
    }
  }

  void _previousSurah() {
    if (_currentSurahNumber > 1) {
      setState(() {
        _currentSurahNumber--;
        _saveLastRead();
        _checkFavorite();
      });
      _itemScrollController.jumpTo(index: 0);
    }
  }

  // Check if a verse is bookmarked
  bool _isVerseBookmarked(int verseNumber) {
    final box = Hive.box('settings');
    final bookmarks =
        (box.get('verse_bookmarks', defaultValue: <String>[]) as List)
            .cast<String>();
    final key = '$_currentSurahNumber:$verseNumber';
    return bookmarks.contains(key);
  }

  // Toggle verse bookmark
  Future<void> _toggleVerseBookmark(int verseNumber) async {
    final box = Hive.box('settings');
    final bookmarks =
        (box.get('verse_bookmarks', defaultValue: <String>[]) as List)
            .cast<String>();
    final key = '$_currentSurahNumber:$verseNumber';

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
  Future<void> _shareVerse(int verseNumber) async {
    final verseText = quran.getVerse(_currentSurahNumber, verseNumber);
    final surahName = quran.getSurahNameArabic(_currentSurahNumber);
    final shareText =
        '''
$verseText

📖 سورة $surahName - الآية $verseNumber
''';

    await Share.share(shareText, subject: 'آية من القرآن الكريم');
  }

  // Copy verse to clipboard
  Future<void> _copyVerse(int verseNumber) async {
    final verseText = quran.getVerse(_currentSurahNumber, verseNumber);
    final surahName = quran.getSurahNameArabic(_currentSurahNumber);
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
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isAr = localizations.locale.languageCode == 'ar';
    final isDark = theme.brightness == Brightness.dark;

    // Quran paper colors
    final quranPaperColor = isDark
        ? const Color(0xFF1A1A2E) // Dark mode paper
        : const Color(0xFFFDF8E8); // Classic Quran cream/beige paper
    final quranBorderColor = isDark
        ? const Color(0xFF3D3D5C)
        : const Color(0xFFD4AF37); // Gold border
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
                              style: GoogleFonts.amiri(
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
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Verses List
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F1629)
                        : const Color(0xFFFAF8F5),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 200,
                    child: ScrollablePositionedList.builder(
                      itemScrollController: _itemScrollController,
                      itemPositionsListener: _itemPositionsListener,
                      itemCount:
                          quran.getVerseCount(_currentSurahNumber) +
                          (_hasBasmala() ? 1 : 0),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemBuilder: (context, index) {
                        // Handle Basmala
                        if (_hasBasmala() && index == 0) {
                          return _buildBasmalaCard(context, theme);
                        }

                        final verseIndex = _hasBasmala() ? index : index + 1;
                        final verseNumber = verseIndex;

                        return _buildVerseCard(
                          context,
                          theme,
                          verseNumber: verseNumber,
                          isDark: isDark,
                        );
                      },
                    ),
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
            child: _buildBottomNavigation(context, theme, localizations),
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

  Widget _buildBasmalaCard(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondary.withValues(alpha: 0.1),
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: Text(
          quran.basmala,
          style: GoogleFonts.amiri(
            fontSize: _fontSize * 1.1,
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildVerseCard(
    BuildContext context,
    ThemeData theme, {
    required int verseNumber,
    required bool isDark,
  }) {
    // Quran paper colors
    final quranCardColor = isDark
        ? const Color(0xFF1A1A2E)
        : const Color(0xFFFFFBF0); // Cream/ivory paper color
    final quranBorderColor = isDark
        ? const Color(0xFF3D3D5C)
        : const Color(0xFFD4AF37); // Gold border
    final quranHeaderColor = isDark
        ? const Color(0xFF16213E)
        : const Color(0xFF1B4332); // Dark green (traditional Quran)
    final verseTextColor = isDark
        ? Colors.white.withOpacity(0.9)
        : const Color(0xFF1A1A1A); // Dark text on light paper

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: quranCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: quranBorderColor.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Verse Header with traditional Quran style
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: quranHeaderColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                // Verse number in decorative frame
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37), // Gold
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$verseNumber',
                      style: GoogleFonts.amiri(
                        color: const Color(0xFF1B4332),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _isVerseBookmarked(verseNumber)
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: _isVerseBookmarked(verseNumber)
                        ? const Color(0xFFD4AF37) // Gold
                        : Colors.white.withOpacity(0.8),
                    size: 22,
                  ),
                  onPressed: () => _toggleVerseBookmark(verseNumber),
                ),
                IconButton(
                  icon: Icon(
                    Icons.share_rounded,
                    color: Colors.white.withOpacity(0.8),
                    size: 22,
                  ),
                  onPressed: () => _shareVerse(verseNumber),
                ),
                IconButton(
                  icon: Icon(
                    Icons.copy_rounded,
                    color: Colors.white.withOpacity(0.8),
                    size: 22,
                  ),
                  onPressed: () => _copyVerse(verseNumber),
                ),
              ],
            ),
          ),
          // Verse Text
          // Verse Text with Quran paper styling
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              children: [
                Text(
                  quran.getVerse(
                    _currentSurahNumber,
                    verseNumber,
                    verseEndSymbol: true,
                  ),
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.amiri(
                    fontSize: _fontSize,
                    height: 2.4,
                    color: verseTextColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                if (_showTranslation) ...[
                  const SizedBox(height: 20),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          quranBorderColor.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    quran.getVerseTranslation(_currentSurahNumber, verseNumber),
                    textAlign: TextAlign.left,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: _fontSize * 0.55,
                      height: 1.8,
                      color: verseTextColor.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous Surah
            if (_currentSurahNumber > 1)
              _buildNavButton(
                icon: Icons.arrow_back_ios_rounded,
                label: 'السابقة',
                onTap: _previousSurah,
                theme: theme,
              )
            else
              const SizedBox(width: 100),

            // Surah Counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_currentSurahNumber / 114',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),

            // Next Surah
            if (_currentSurahNumber < 114)
              _buildNavButton(
                icon: Icons.arrow_forward_ios_rounded,
                label: 'التالية',
                onTap: _nextSurah,
                theme: theme,
                isNext: true,
              )
            else
              const SizedBox(width: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isNext = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.secondary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (!isNext) Icon(icon, color: Colors.white, size: 18),
            if (!isNext) const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isNext) const SizedBox(width: 8),
            if (isNext) Icon(icon, color: Colors.white, size: 18),
          ],
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
                    title: const Text('إظهار الترجمة الإنجليزية'),
                    subtitle: const Text('Show English Translation'),
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

/// Custom painter for Quran paper pattern background
class _QuranPaperPatternPainter extends CustomPainter {
  final bool isDark;

  _QuranPaperPatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? const Color(0xFF2D2D4A).withOpacity(0.3)
          : const Color(0xFFD4AF37).withOpacity(0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw decorative border frame
    final borderPaint = Paint()
      ..color = isDark
          ? const Color(0xFF4A4A6A).withOpacity(0.5)
          : const Color(0xFFD4AF37).withOpacity(0.3)
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
