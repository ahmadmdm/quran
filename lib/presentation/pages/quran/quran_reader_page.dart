import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quran/quran.dart' as quran;
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/tafsir_service.dart';
import '../../../core/localization/app_localizations.dart';

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
  static const String _readerFontSizeKey = 'quran_reader_font_size';
  static const String _readerShowTranslationKey =
      'quran_reader_show_translation';
  static const String _readerTopOptionsExpandedKey =
      'quran_reader_top_options_expanded';
  static const String _readerFoldStretchPageKey = 'quranFoldStretchPage';
  static const String _readerReciterKey = 'quran_reader_reciter';
  static const String _readerAutoFollowAudioKey =
      'quran_reader_auto_follow_audio';
  static const String _audioWeekKeyStorage = 'quran_audio_week_key';
  static const String _audioWeekSecondsStorage = 'quran_audio_week_seconds';
  static const String _audioWeekVersesStorage = 'quran_audio_week_verses';

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
  bool _isTopOptionsExpanded = true;
  bool _foldStretchPage = false;
  bool _autoFollowAudio = true;
  String _selectedReciter = 'Alafasy_128kbps';
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _audioPlayerState = PlayerState.stopped;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;
  String _audioWeekKey = '';
  int _weeklyListeningSeconds = 0;
  int _weeklyListeningVerses = 0;
  final Set<String> _countedVerseKeys = <String>{};
  int? _playingSurahNumber;
  int? _playingVerseNumber;

  Timer? _focusTimer;
  int _focusTotalSeconds = 0;
  int _focusRemainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadReaderPreferences();
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

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _audioPlayerState = state;
        if (state != PlayerState.playing) {
          _audioPosition = Duration.zero;
        }
      });
    });
    _audioPlayer.onPositionChanged.listen((position) {
      final deltaMs = position.inMilliseconds - _audioPosition.inMilliseconds;
      if (deltaMs > 0) {
        _trackListeningDelta(delta: Duration(milliseconds: deltaMs));
      }
      if (!mounted) return;
      setState(() {
        _audioPosition = position;
      });
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() {
        _audioDuration = duration;
      });
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      _handleAudioComplete();
    });

    _saveLastRead();
    _checkFavorite();
    _loadWeeklyAudioStats();
  }

  void _loadReaderPreferences() {
    final box = Hive.box('settings');
    final storedFontSize = (box.get(_readerFontSizeKey) as num?)?.toDouble();
    if (storedFontSize != null) {
      _fontSize = storedFontSize.clamp(18.0, 40.0);
    }
    _showTranslation =
        (box.get(_readerShowTranslationKey, defaultValue: false) as bool?) ??
        false;
    _isTopOptionsExpanded =
        (box.get(_readerTopOptionsExpandedKey, defaultValue: true) as bool?) ??
        true;
    _foldStretchPage =
        (box.get(_readerFoldStretchPageKey, defaultValue: false) as bool?) ??
        false;
    _selectedReciter =
        (box.get(_readerReciterKey, defaultValue: 'Alafasy_128kbps')
            as String?) ??
        'Alafasy_128kbps';
    _autoFollowAudio =
        (box.get(_readerAutoFollowAudioKey, defaultValue: true) as bool?) ??
        true;
  }

  Future<void> _saveReaderPreferences() async {
    final box = Hive.box('settings');
    await box.put(_readerFontSizeKey, _fontSize);
    await box.put(_readerShowTranslationKey, _showTranslation);
    await box.put(_readerTopOptionsExpandedKey, _isTopOptionsExpanded);
    await box.put(_readerFoldStretchPageKey, _foldStretchPage);
    await box.put(_readerReciterKey, _selectedReciter);
    await box.put(_readerAutoFollowAudioKey, _autoFollowAudio);
  }

  String _currentWeekKey() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final day = startOfWeek.day.toString().padLeft(2, '0');
    final month = startOfWeek.month.toString().padLeft(2, '0');
    return '${startOfWeek.year}-$month-$day';
  }

  void _loadWeeklyAudioStats() {
    final box = Hive.box('settings');
    final currentWeek = _currentWeekKey();
    final storedWeek =
        (box.get(_audioWeekKeyStorage, defaultValue: currentWeek) as String?) ??
        currentWeek;
    if (storedWeek != currentWeek) {
      box.put(_audioWeekKeyStorage, currentWeek);
      box.put(_audioWeekSecondsStorage, 0);
      box.put(_audioWeekVersesStorage, 0);
      _audioWeekKey = currentWeek;
      _weeklyListeningSeconds = 0;
      _weeklyListeningVerses = 0;
      return;
    }
    _audioWeekKey = storedWeek;
    _weeklyListeningSeconds =
        (box.get(_audioWeekSecondsStorage, defaultValue: 0) as int?) ?? 0;
    _weeklyListeningVerses =
        (box.get(_audioWeekVersesStorage, defaultValue: 0) as int?) ?? 0;
  }

  Future<void> _trackListeningDelta({required Duration delta}) async {
    if (_audioPlayerState != PlayerState.playing) return;
    final deltaSeconds = delta.inSeconds;
    if (deltaSeconds <= 0) return;
    final box = Hive.box('settings');
    if (_audioWeekKey != _currentWeekKey()) {
      _loadWeeklyAudioStats();
    }
    _weeklyListeningSeconds += deltaSeconds;
    await box.put(_audioWeekSecondsStorage, _weeklyListeningSeconds);
  }

  Future<void> _recordVersePlayback(_PageVerse verse) async {
    final key = '${verse.surahNumber}:${verse.verseNumber}';
    if (_countedVerseKeys.contains(key)) return;
    _countedVerseKeys.add(key);
    final box = Hive.box('settings');
    if (_audioWeekKey != _currentWeekKey()) {
      _loadWeeklyAudioStats();
    }
    _weeklyListeningVerses += 1;
    await box.put(_audioWeekVersesStorage, _weeklyListeningVerses);
  }

  Future<void> _resumeLastReadingPosition() async {
    final box = Hive.box('settings');
    final surah = (box.get('last_read_surah', defaultValue: 1) as int?) ?? 1;
    final verse = (box.get('last_read_verse', defaultValue: 1) as int?) ?? 1;
    final page = quran.getPageNumber(surah, verse);
    if (!mounted) return;
    setState(() {
      _currentSurahNumber = surah;
      _currentVisibleVerse = verse;
      _currentVisiblePage = page;
    });
    if (_pageController.hasClients) {
      await _pageController.animateToPage(
        (page - 1).clamp(0, 603),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _setFontSize(double newSize) async {
    final clamped = newSize.clamp(18.0, 40.0);
    if ((clamped - _fontSize).abs() < 0.01) return;
    if (!mounted) return;
    setState(() {
      _fontSize = clamped;
    });
    await _saveReaderPreferences();
  }

  Future<void> _setTopOptionsExpanded(bool expanded) async {
    if (_isTopOptionsExpanded == expanded) return;
    if (!mounted) return;
    setState(() {
      _isTopOptionsExpanded = expanded;
    });
    await _saveReaderPreferences();
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
    final detailsRaw = box.get(
      'verse_bookmark_details',
      defaultValue: <String, dynamic>{},
    );
    final details = Map<String, dynamic>.from(
      detailsRaw is Map ? detailsRaw : <String, dynamic>{},
    );

    if (bookmarks.contains(key)) {
      bookmarks.remove(key);
      details.remove(key);
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
      final extra = await _showBookmarkDetailsDialog();
      if (extra == null) return;
      if (!mounted) return;
      bookmarks.add(key);
      details[key] = {
        'note': extra.$1,
        'tags': extra.$2,
        'createdAt': DateTime.now().toIso8601String(),
      };
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
    await box.put('verse_bookmark_details', details);
    setState(() {});
  }

  Future<(String, List<String>)?> _showBookmarkDetailsDialog() async {
    final noteController = TextEditingController();
    final tagsController = TextEditingController();
    return await showDialog<(String, List<String>)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفاصيل الفاصل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'ملاحظة (اختياري)',
                hintText: 'مثال: آية للتدبر',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: tagsController,
              decoration: const InputDecoration(
                labelText: 'وسوم (اختياري)',
                hintText: 'مثال: حفظ،تدبر،مراجعة',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ('', <String>[])),
            child: const Text('تخطي'),
          ),
          FilledButton(
            onPressed: () {
              final note = noteController.text.trim();
              final tags = tagsController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toSet()
                  .toList();
              Navigator.pop(context, (note, tags));
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
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
    unawaited(_audioPlayer.stop());
    _audioPlayer.dispose();
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
    final media = MediaQuery.of(context);
    final hasVerticalFold = media.displayFeatures.any((feature) {
      final featureType = feature.type.toString().toLowerCase();
      final isFoldLike =
          featureType.contains('hinge') || featureType.contains('fold');
      return isFoldLike && feature.bounds.height >= media.size.height * 0.5;
    });
    final applyFoldStretch = hasVerticalFold && _foldStretchPage;
    final isReaderCollapsed = !_isTopOptionsExpanded;
    final pageBottomInset = isReaderCollapsed ? 124.0 : 142.0;

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
              if (!isReaderCollapsed)
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
                      onPressed: () => _setFontSize(_fontSize + 2),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.text_decrease_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => _setFontSize(_fontSize - 2),
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
                    borderRadius: isReaderCollapsed
                        ? BorderRadius.zero
                        : const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      if (!isReaderCollapsed) _buildReaderOptionsBar(theme),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            applyFoldStretch ? 2 : (isReaderCollapsed ? 8 : 12),
                            isReaderCollapsed ? 0 : 6,
                            applyFoldStretch ? 2 : (isReaderCollapsed ? 8 : 12),
                            pageBottomInset,
                          ),
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
                                  isCompact: isReaderCollapsed,
                                  stretchInFold: applyFoldStretch,
                                );
                              }
                              return _buildMushafPage(
                                context,
                                theme,
                                pageNumber: pageNumber,
                                isDark: isDark,
                                isCompact: isReaderCollapsed,
                                stretchInFold: applyFoldStretch,
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
            left: 10,
            right: 10,
            bottom: isReaderCollapsed ? 64 : 82,
            child: _buildRecitationBar(theme),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavigation(
              context,
              theme,
              isCompact: isReaderCollapsed,
            ),
          ),
          if (isReaderCollapsed)
            Positioned(
              left: 8,
              right: 8,
              top: 0,
              child: _buildCollapsedTopOverlay(theme),
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
    final lineHeight = size >= 34
        ? 1.82
        : size >= 30
        ? 1.9
        : size >= 26
        ? 1.98
        : 2.05;
    return GoogleFonts.amiriQuran(
      fontSize: size,
      color: color,
      fontWeight: FontWeight.w400,
      height: lineHeight,
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
              text: _normalizeQuranTextForDisplay(quran.getVerse(surah, verse)),
            ),
          );
        }
      }
    }
    _pageVersesCache[pageNumber] = verses;
    return verses;
  }

  String _normalizeQuranTextForDisplay(String input) {
    // Quran package may contain U+065E in places where common mushaf UIs expect
    // a visible dammatan mark (U+064C). Normalize it for consistent rendering.
    return input.replaceAll('\u065E', '\u064C');
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

  Future<void> _showVerseActionsSheet(_PageVerse verse, ThemeData theme) async {
    unawaited(_publishFoldLiveVerse(verse));
    final isBookmarked = _isVerseBookmarked(
      verse.surahNumber,
      verse.verseNumber,
    );

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${quran.getSurahNameArabic(verse.surahNumber)} - آية ${verse.verseNumber}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Icon(
                    isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_add_rounded,
                    color: theme.colorScheme.secondary,
                  ),
                  title: Text(
                    isBookmarked ? 'إزالة الفاصل' : 'إضافة إلى الفواصل',
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _toggleVerseBookmark(
                      verse.surahNumber,
                      verse.verseNumber,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.menu_book_rounded),
                  title: const Text('تفسير الآية'),
                  onTap: () {
                    Navigator.pop(context);
                    _showTafsirSheet(verse, theme);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.play_circle_fill_rounded),
                  title: const Text('تشغيل التلاوة من هذه الآية'),
                  onTap: () {
                    Navigator.pop(context);
                    _playVerseAudio(verse);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy_rounded),
                  title: const Text('نسخ الآية'),
                  onTap: () {
                    Navigator.pop(context);
                    _copyVerse(verse.surahNumber, verse.verseNumber);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share_rounded),
                  title: const Text('مشاركة الآية'),
                  onTap: () {
                    Navigator.pop(context);
                    _shareVerse(verse.surahNumber, verse.verseNumber);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _publishFoldLiveVerse(_PageVerse verse) async {
    final box = Hive.box('settings');
    await box.put('fold_live_surah', verse.surahNumber);
    await box.put('fold_live_verse', verse.verseNumber);
    await box.put('fold_live_text', verse.text);
    await box.put('fold_live_updated_at', DateTime.now().toIso8601String());
  }

  String _buildVerseAudioUrl({
    required int surahNumber,
    required int verseNumber,
  }) {
    final surah = surahNumber.toString().padLeft(3, '0');
    final verse = verseNumber.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$_selectedReciter/$surah$verse.mp3';
  }

  bool _isPlayingVerse(_PageVerse verse) {
    return _playingSurahNumber == verse.surahNumber &&
        _playingVerseNumber == verse.verseNumber;
  }

  Future<void> _playVerseAudio(_PageVerse verse) async {
    final url = _buildVerseAudioUrl(
      surahNumber: verse.surahNumber,
      verseNumber: verse.verseNumber,
    );
    try {
      setState(() {
        _playingSurahNumber = verse.surahNumber;
        _playingVerseNumber = verse.verseNumber;
        _audioPosition = Duration.zero;
        _audioDuration = Duration.zero;
      });
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
      await _recordVersePlayback(verse);
      unawaited(_publishFoldLiveVerse(verse));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر تشغيل التلاوة الآن، حاول مرة أخرى'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleCurrentRecitation() async {
    if (_audioPlayerState == PlayerState.playing) {
      await _audioPlayer.pause();
      return;
    }
    if (_audioPlayerState == PlayerState.paused) {
      await _audioPlayer.resume();
      return;
    }

    final verses = _getVersesForPage(_currentVisiblePage);
    if (verses.isEmpty) return;
    final verse = verses.firstWhere(
      (v) =>
          v.surahNumber == _currentSurahNumber &&
          v.verseNumber == _currentVisibleVerse,
      orElse: () => verses.first,
    );
    await _playVerseAudio(verse);
  }

  (_PageVerse? current, _PageVerse? previous) _currentAndPreviousVerse() {
    final currentSurah = _playingSurahNumber ?? _currentSurahNumber;
    final currentVerse = _playingVerseNumber ?? _currentVisibleVerse;

    if (currentVerse > 1) {
      final previous = _PageVerse(
        surahNumber: currentSurah,
        verseNumber: currentVerse - 1,
        text: _normalizeQuranTextForDisplay(
          quran.getVerse(currentSurah, currentVerse - 1),
        ),
      );
      final current = _PageVerse(
        surahNumber: currentSurah,
        verseNumber: currentVerse,
        text: _normalizeQuranTextForDisplay(
          quran.getVerse(currentSurah, currentVerse),
        ),
      );
      return (current, previous);
    }

    if (currentSurah <= 1) {
      final current = _PageVerse(
        surahNumber: 1,
        verseNumber: 1,
        text: _normalizeQuranTextForDisplay(quran.getVerse(1, 1)),
      );
      return (current, null);
    }

    final previousSurah = currentSurah - 1;
    final previousVerseNumber = quran.getVerseCount(previousSurah);
    final previous = _PageVerse(
      surahNumber: previousSurah,
      verseNumber: previousVerseNumber,
      text: _normalizeQuranTextForDisplay(
        quran.getVerse(previousSurah, previousVerseNumber),
      ),
    );
    final current = _PageVerse(
      surahNumber: currentSurah,
      verseNumber: currentVerse,
      text: _normalizeQuranTextForDisplay(
        quran.getVerse(currentSurah, currentVerse),
      ),
    );
    return (current, previous);
  }

  _PageVerse? _nextVerse(_PageVerse current) {
    final maxVerse = quran.getVerseCount(current.surahNumber);
    if (current.verseNumber < maxVerse) {
      final nextVerseNumber = current.verseNumber + 1;
      return _PageVerse(
        surahNumber: current.surahNumber,
        verseNumber: nextVerseNumber,
        text: _normalizeQuranTextForDisplay(
          quran.getVerse(current.surahNumber, nextVerseNumber),
        ),
      );
    }
    if (current.surahNumber >= 114) return null;
    return _PageVerse(
      surahNumber: current.surahNumber + 1,
      verseNumber: 1,
      text: _normalizeQuranTextForDisplay(
        quran.getVerse(current.surahNumber + 1, 1),
      ),
    );
  }

  Future<void> _playNextVerse() async {
    final current = _PageVerse(
      surahNumber: _playingSurahNumber ?? _currentSurahNumber,
      verseNumber: _playingVerseNumber ?? _currentVisibleVerse,
      text: '',
    );
    final next = _nextVerse(current);
    if (next == null) return;
    if (_autoFollowAudio) {
      final targetPage = quran.getPageNumber(
        next.surahNumber,
        next.verseNumber,
      );
      if (_currentVisiblePage != targetPage) {
        await _jumpToPage(targetPage);
      }
      if (mounted) {
        setState(() {
          _currentSurahNumber = next.surahNumber;
          _currentVisibleVerse = next.verseNumber;
        });
      }
    }
    await _playVerseAudio(next);
  }

  Future<void> _playPreviousVerse() async {
    final (current, previous) = _currentAndPreviousVerse();
    if (current == null || previous == null) return;
    if (_autoFollowAudio) {
      final targetPage = quran.getPageNumber(
        previous.surahNumber,
        previous.verseNumber,
      );
      if (_currentVisiblePage != targetPage) {
        await _jumpToPage(targetPage);
      }
      if (mounted) {
        setState(() {
          _currentSurahNumber = previous.surahNumber;
          _currentVisibleVerse = previous.verseNumber;
        });
      }
    }
    await _playVerseAudio(previous);
  }

  Future<void> _handleAudioComplete() async {
    final currentSurah = _playingSurahNumber;
    final currentVerse = _playingVerseNumber;
    if (currentSurah == null || currentVerse == null) return;
    final next = _nextVerse(
      _PageVerse(
        surahNumber: currentSurah,
        verseNumber: currentVerse,
        text: '',
      ),
    );
    if (next == null) {
      if (!mounted) return;
      setState(() {
        _audioPosition = Duration.zero;
      });
      return;
    }
    await _playNextVerse();
  }

  Future<void> _showTafsirSheet(_PageVerse verse, ThemeData theme) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          top: false,
          child: FractionallySizedBox(
            heightFactor: 0.82,
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'تفسير ${quran.getSurahNameArabic(verse.surahNumber)} - آية ${verse.verseNumber}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: FutureBuilder<TafsirResult>(
                      future: TafsirService.getTafsir(
                        surahNumber: verse.surahNumber,
                        verseNumber: verse.verseNumber,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError || !snapshot.hasData) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Text(
                                'تعذر تحميل التفسير الآن. تأكد من الاتصال بالإنترنت ثم أعد المحاولة.',
                                style: theme.textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        final tafsir = snapshot.data!;
                        return ScrollConfiguration(
                          behavior: const _NoGlowScrollBehavior(),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    verse.text,
                                    textAlign: TextAlign.justify,
                                    textDirection: TextDirection.rtl,
                                    style: GoogleFonts.amiriQuran(
                                      fontSize: (_fontSize - 2).clamp(
                                        18.0,
                                        32.0,
                                      ),
                                      height: 2.0,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  tafsir.text,
                                  textAlign: TextAlign.justify,
                                  textDirection: TextDirection.rtl,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontSize: 19,
                                    height: 1.9,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'المصدر: ${tafsir.source}${tafsir.fromCache ? ' (محفوظ محليًا)' : ''}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
    bool isCompact = false,
    bool stretchInFold = false,
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
      margin: EdgeInsets.only(bottom: isCompact ? 2 : 8),
      padding: EdgeInsets.fromLTRB(
        stretchInFold ? 8 : (isCompact ? 12 : 16),
        isCompact ? 10 : 16,
        stretchInFold ? 8 : (isCompact ? 12 : 16),
        isCompact ? 8 : 10,
      ),
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
    bool isCompact = false,
    bool stretchInFold = false,
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
    final verseStyle = _medinaVerseStyle(_fontSize, verseTextColor);
    final verseSpans = <InlineSpan>[];
    for (var i = 0; i < verses.length; i++) {
      final verse = verses[i];
      final isPlaying = _isPlayingVerse(verse);
      final style = isPlaying
          ? verseStyle.copyWith(
              color: theme.colorScheme.secondary,
              backgroundColor: theme.colorScheme.secondary.withValues(
                alpha: 0.14,
              ),
              fontWeight: FontWeight.w700,
            )
          : verseStyle;
      verseSpans.add(
        TextSpan(
          text: '${verse.text}  ﴿${verse.verseNumber}﴾',
          style: style,
          recognizer: TapGestureRecognizer()
            ..onTap = () => _showVerseActionsSheet(verse, theme),
        ),
      );
      if (i != verses.length - 1) {
        verseSpans.add(const TextSpan(text: '  '));
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: isCompact ? 2 : 8),
      padding: EdgeInsets.fromLTRB(
        stretchInFold ? 8 : (isCompact ? 12 : 18),
        isCompact ? 10 : 16,
        stretchInFold ? 8 : (isCompact ? 12 : 18),
        isCompact ? 8 : 10,
      ),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final painter = TextPainter(
                  text: TextSpan(text: pageText, style: verseStyle),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.justify,
                  textWidthBasis: TextWidthBasis.parent,
                )..layout(maxWidth: constraints.maxWidth);
                final fits = painter.height <= constraints.maxHeight - 6;

                final textWidget = RichText(
                  text: TextSpan(children: verseSpans),
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                );

                if (fits) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: textWidget,
                  );
                }

                return ScrollConfiguration(
                  behavior: const _NoGlowScrollBehavior(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: textWidget,
                  ),
                );
              },
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
              children: [
                Text(
                  'خيارات القراءة',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _setTopOptionsExpanded(false),
                  icon: const Icon(Icons.unfold_less_rounded, size: 18),
                  label: const Text('تقليص'),
                ),
              ],
            ),
            const SizedBox(height: 6),
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
                _buildTopOptionAction(
                  theme: theme,
                  icon: Icons.restore_page_rounded,
                  label: 'استئناف',
                  onTap: _resumeLastReadingPosition,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedTopOverlay(ThemeData theme) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            _buildMiniTopButton(
              theme: theme,
              icon: Icons.arrow_back_ios_rounded,
              label: 'رجوع',
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(width: 6),
            _buildMiniTopButton(
              theme: theme,
              icon: Icons.text_decrease_rounded,
              label: 'A-',
              onTap: () => _setFontSize(_fontSize - 2),
            ),
            const SizedBox(width: 6),
            _buildMiniTopButton(
              theme: theme,
              icon: Icons.text_increase_rounded,
              label: 'A+',
              onTap: () => _setFontSize(_fontSize + 2),
            ),
            const Spacer(),
            _buildMiniTopButton(
              theme: theme,
              icon: Icons.unfold_more_rounded,
              label: 'تمدد',
              onTap: () => _setTopOptionsExpanded(true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecitationBar(ThemeData theme) {
    final isPlaying = _audioPlayerState == PlayerState.playing;
    final hasSelection =
        _playingSurahNumber != null && _playingVerseNumber != null;
    final label = hasSelection
        ? '${quran.getSurahNameArabic(_playingSurahNumber!)} - آية $_playingVerseNumber'
        : 'ابدأ التلاوة من أي آية';
    final maxMs = _audioDuration.inMilliseconds <= 0
        ? 1
        : _audioDuration.inMilliseconds;
    final progress = (_audioPosition.inMilliseconds / maxMs)
        .clamp(0.0, 1.0)
        .toDouble();

    return Material(
      color: theme.cardColor.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _playPreviousVerse,
                  icon: const Icon(Icons.skip_previous_rounded),
                  tooltip: 'الآية السابقة',
                ),
                IconButton(
                  onPressed: _toggleCurrentRecitation,
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                  ),
                  tooltip: isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
                ),
                IconButton(
                  onPressed: _playNextVerse,
                  icon: const Icon(Icons.skip_next_rounded),
                  tooltip: 'الآية التالية',
                ),
              ],
            ),
            LinearProgressIndicator(
              value: hasSelection ? progress : 0,
              minHeight: 3,
              backgroundColor: theme.dividerColor.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'هذا الأسبوع: ${(_weeklyListeningSeconds / 60).floor()} دقيقة • $_weeklyListeningVerses آية',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTopButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: theme.cardColor.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.secondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
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

  Widget _buildBottomNavigation(
    BuildContext context,
    ThemeData theme, {
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        isCompact ? 4 : 8,
        14,
        isCompact ? 8 : 14,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isCompact ? 14 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: isCompact ? 10 : 14,
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
              compact: isCompact,
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 14,
                vertical: isCompact ? 5 : 7,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
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
              compact: isCompact,
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
    bool compact = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: compact ? 40 : 44,
          height: compact ? 36 : 40,
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
                            final next = (_fontSize - 2).clamp(18.0, 40.0);
                            _setFontSize(next);
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
                            setSheetState(() {});
                            setState(() {
                              _fontSize = value;
                            });
                          },
                          onChangeEnd: (value) {
                            _setFontSize(value);
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          if (_fontSize < 40) {
                            final next = (_fontSize + 2).clamp(18.0, 40.0);
                            _setFontSize(next);
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
                      _saveReaderPreferences();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('تمدد الصفحة في وضع الفولد'),
                    subtitle: const Text(
                      'تقليل الهوامش لعرض أوسع على أجهزة الفولد',
                    ),
                    value: _foldStretchPage,
                    activeThumbColor: theme.colorScheme.secondary,
                    onChanged: (value) {
                      setSheetState(() => _foldStretchPage = value);
                      setState(() {});
                      _saveReaderPreferences();
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'القارئ',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedReciter,
                    items: const [
                      DropdownMenuItem(
                        value: 'Alafasy_128kbps',
                        child: Text('العفاسي'),
                      ),
                      DropdownMenuItem(
                        value: 'Abdurrahmaan_As-Sudais_192kbps',
                        child: Text('السديس'),
                      ),
                      DropdownMenuItem(
                        value: 'Maher_AlMuaiqly_64kbps',
                        child: Text('ماهر المعيقلي'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setSheetState(() => _selectedReciter = value);
                      setState(() {});
                      _saveReaderPreferences();
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('تتبع الصوت مع القراءة'),
                    subtitle: const Text(
                      'الانتقال تلقائيًا للآية/الصفحة التالية مع التلاوة',
                    ),
                    value: _autoFollowAudio,
                    activeThumbColor: theme.colorScheme.secondary,
                    onChanged: (value) {
                      setSheetState(() => _autoFollowAudio = value);
                      setState(() {});
                      _saveReaderPreferences();
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

class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
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
