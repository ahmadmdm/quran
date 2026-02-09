import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/localization/app_localizations.dart';
import 'quran_reader_page.dart';
import 'daily_wird_page.dart';

class QuranIndexPage extends StatefulWidget {
  const QuranIndexPage({super.key});

  @override
  State<QuranIndexPage> createState() => _QuranIndexPageState();
}

class _QuranIndexPageState extends State<QuranIndexPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  final Map<int, (int surah, int verse)> _pageStartCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Custom App Bar with Quran Header
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: isDark
                  ? const Color(0xFF1A1F38)
                  : const Color(0xFF2C3E50),
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
                      right: -50,
                      top: -50,
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 250,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Content
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 60,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'القرآن الكريم',
                            style: GoogleFonts.amiri(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'فهرس السور والأجزاء',
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
                    tabs: [
                      Tab(text: localizations.translate('surah')),
                      Tab(text: localizations.translate('juz')),
                      Tab(text: localizations.translate('favorites')),
                      Tab(text: localizations.translate('bookmarks_tab')),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Last Read Card
            _buildLastReadCard(context, localizations),

            // Daily Wird & Khatma Button
            _buildDailyWirdButton(context, theme),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _buildSearchBar(context, localizations),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSurahList(context, theme, localizations),
                  _buildJuzList(context, theme, localizations),
                  _buildFavoritesList(context, theme, localizations),
                  _buildBookmarksList(context, theme, localizations),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastReadCard(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final theme = Theme.of(context);

    return ValueListenableBuilder(
      valueListenable: Hive.box(
        'settings',
      ).listenable(keys: ['last_read_surah', 'last_read_verse']),
      builder: (context, Box box, child) {
        final lastSurah =
            box.get('last_read_surah', defaultValue: null) as int?;
        final lastVerse = box.get('last_read_verse', defaultValue: 1) as int;

        if (lastSurah == null) return const SizedBox.shrink();

        final isAr = localizations.locale.languageCode == 'ar';

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuranReaderPage(
                    initialSurahNumber: lastSurah,
                    initialVerseNumber: lastVerse,
                  ),
                ),
              );
            },
            child: Container(
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.bookmark_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.translate('last_read'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAr
                              ? quran.getSurahNameArabic(lastSurah)
                              : quran.getSurahName(lastSurah),
                          style: GoogleFonts.amiri(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'الآية $lastVerse',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDailyWirdButton(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DailyWirdPage()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF1A5F7A), const Color(0xFF159895)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A5F7A).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الورد اليومي والختمة',
                      style: GoogleFonts.amiri(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'تتبع قراءتك اليومية وختماتك',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, AppLocalizations localizations) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: localizations.translate('search_surah'),
          hintStyle: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: theme.colorScheme.secondary,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          filled: true,
          fillColor: theme.cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSurahList(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    final isAr = localizations.locale.languageCode == 'ar';

    // Filter surahs
    final filteredSurahs = List.generate(114, (index) => index + 1).where((
      surahNumber,
    ) {
      final nameEn = quran.getSurahName(surahNumber).toLowerCase();
      final nameAr = quran.getSurahNameArabic(surahNumber);
      final query = _searchQuery.toLowerCase();
      return nameEn.contains(query) ||
          nameAr.contains(query) ||
          surahNumber.toString().contains(query);
    }).toList();

    return ListView.builder(
      itemCount: filteredSurahs.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final surahNumber = filteredSurahs[index];
        final place = quran.getPlaceOfRevelation(surahNumber);
        final isMeccan = place == 'Makkah';
        final verseCount = quran.getVerseCount(surahNumber);

        return _buildSurahCard(
          context,
          theme,
          surahNumber: surahNumber,
          nameAr: quran.getSurahNameArabic(surahNumber),
          nameEn: quran.getSurahName(surahNumber),
          isMeccan: isMeccan,
          verseCount: verseCount,
          isAr: isAr,
          localizations: localizations,
        );
      },
    );
  }

  Widget _buildSurahCard(
    BuildContext context,
    ThemeData theme, {
    required int surahNumber,
    required String nameAr,
    required String nameEn,
    required bool isMeccan,
    required int verseCount,
    required bool isAr,
    required AppLocalizations localizations,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    QuranReaderPage(initialSurahNumber: surahNumber),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Surah Number Badge
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.secondary.withValues(alpha: 0.2),
                        theme.colorScheme.secondary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '$surahNumber',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Surah Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? nameAr : nameEn,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: isAr
                              ? GoogleFonts.amiri().fontFamily
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildInfoChip(
                            context,
                            icon: isMeccan ? Icons.location_city : Icons.mosque,
                            label: isMeccan
                                ? localizations.translate('revelation_mecca')
                                : localizations.translate('revelation_medina'),
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            context,
                            icon: Icons.format_list_numbered,
                            label:
                                '$verseCount ${localizations.translate('verses')}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arabic Name (if showing English)
                if (!isAr)
                  Text(
                    nameAr,
                    style: GoogleFonts.amiri(
                      fontSize: 22,
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.dividerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJuzList(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return ListView.builder(
      itemCount: 30,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final juzNumber = index + 1;
        final map = quran.getSurahAndVersesFromJuz(juzNumber);
        final surahNumber = map.keys.first;
        final verseNumber = map[surahNumber]!.first;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Juz Number Badge
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.2),
                            theme.colorScheme.primary.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          '$juzNumber',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Juz Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${localizations.translate('juz')} $juzNumber',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'يبدأ من سورة ${quran.getSurahNameArabic(surahNumber)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: theme.disabledColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoritesList(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return ValueListenableBuilder(
      valueListenable: Hive.box(
        'settings',
      ).listenable(keys: ['favorite_surahs']),
      builder: (context, Box box, child) {
        final favorites =
            (box.get('favorite_surahs', defaultValue: <int>[]) as List)
                .cast<int>();

        if (favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border_rounded,
                  size: 80,
                  color: theme.disabledColor.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد سور مفضلة',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.disabledColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'اضغط على أيقونة القلب في صفحة القراءة لإضافة سورة للمفضلة',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.disabledColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final isAr = localizations.locale.languageCode == 'ar';

        return ListView.builder(
          itemCount: favorites.length,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemBuilder: (context, index) {
            final surahNumber = favorites[index];
            final place = quran.getPlaceOfRevelation(surahNumber);
            final isMeccan = place == 'Makkah';
            final verseCount = quran.getVerseCount(surahNumber);

            return _buildSurahCard(
              context,
              theme,
              surahNumber: surahNumber,
              nameAr: quran.getSurahNameArabic(surahNumber),
              nameEn: quran.getSurahName(surahNumber),
              isMeccan: isMeccan,
              verseCount: verseCount,
              isAr: isAr,
              localizations: localizations,
            );
          },
        );
      },
    );
  }

  Widget _buildBookmarksList(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return ValueListenableBuilder(
      valueListenable: Hive.box(
        'settings',
      ).listenable(keys: ['verse_bookmarks', 'page_bookmarks']),
      builder: (context, Box box, child) {
        final verseBookmarks =
            (box.get('verse_bookmarks', defaultValue: <String>[]) as List)
                .cast<String>();
        final pageBookmarks =
            (box.get('page_bookmarks', defaultValue: <int>[]) as List)
                .cast<int>()
              ..sort();

        if (verseBookmarks.isEmpty && pageBookmarks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border_rounded,
                  size: 80,
                  color: theme.disabledColor.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد فواصل محفوظة',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.disabledColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'استخدم زر فاصل الصفحة أو أيقونة حفظ الآية داخل صفحة القراءة',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.disabledColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final isAr = localizations.locale.languageCode == 'ar';

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            if (pageBookmarks.isNotEmpty) ...[
              Text(
                'فواصل الصفحات',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...pageBookmarks.map((pageNumber) {
                final start = _findFirstVerseForPage(pageNumber);
                final surahNumber = start.$1;
                final verseNumber = start.$2;
                return _buildBookmarkCard(
                  context: context,
                  theme: theme,
                  title: 'صفحة $pageNumber',
                  subtitle:
                      'تبدأ من ${quran.getSurahNameArabic(surahNumber)} - آية $verseNumber',
                  badgeText: '$pageNumber',
                  onTap: () {
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
                  onDelete: () {
                    pageBookmarks.remove(pageNumber);
                    box.put('page_bookmarks', pageBookmarks);
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
            if (verseBookmarks.isNotEmpty) ...[
              Text(
                'فواصل الآيات',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...verseBookmarks.map((bookmark) {
                final parts = bookmark.split(':');
                final surahNumber = int.parse(parts[0]);
                final verseNumber = int.parse(parts[1]);
                return _buildBookmarkCard(
                  context: context,
                  theme: theme,
                  title: isAr
                      ? quran.getSurahNameArabic(surahNumber)
                      : quran.getSurahName(surahNumber),
                  subtitle: '${localizations.translate('verse')} $verseNumber',
                  badgeText: '$verseNumber',
                  onTap: () {
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
                  onDelete: () {
                    verseBookmarks.remove(bookmark);
                    box.put('verse_bookmarks', verseBookmarks);
                  },
                );
              }),
            ],
          ],
        );
      },
    );
  }

  (int, int) _findFirstVerseForPage(int pageNumber) {
    final cached = _pageStartCache[pageNumber];
    if (cached != null) return (cached.$1, cached.$2);

    for (int s = 1; s <= 114; s++) {
      final verseCount = quran.getVerseCount(s);
      for (int v = 1; v <= verseCount; v++) {
        final page = quran.getPageNumber(s, v);
        if (page == pageNumber) {
          _pageStartCache[pageNumber] = (s, v);
          return (s, v);
        }
      }
    }
    return (1, 1);
  }

  Widget _buildBookmarkCard({
    required BuildContext context,
    required ThemeData theme,
    required String title,
    required String subtitle,
    required String badgeText,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.secondary.withValues(alpha: 0.2),
                        theme.colorScheme.secondary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.amiri(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
