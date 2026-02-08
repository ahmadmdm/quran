import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/localization/app_localizations.dart';

class AzkarPage extends StatefulWidget {
  const AzkarPage({super.key});

  @override
  State<AzkarPage> createState() => _AzkarPageState();
}

class _AzkarPageState extends State<AzkarPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Track counts for each dhikr
  final Map<String, int> _counts = {};

  final List<Map<String, dynamic>> morningAzkar = [
    {
      'id': 'morning_1',
      'arabic':
          'أَصْـبَحْنا وَأَصْـبَحَ المُـلْكُ لله وَالحَمدُ لله ، لا إلهَ إلاّ اللّهُ وَحدَهُ لا شَريكَ لهُ، لهُ المُـلْكُ ولهُ الحَمْـد، وهُوَ على كلّ شَيءٍ قدير.',
      'transliteration':
          'أصبحنا وأصبح الملك لله والحمد لله، لا إله إلا الله وحده لا شريك له، له الملك وله الحمد، وهو على كل شيء قدير.',
      'benefit': 'من قالها حين يصبح فقد أدى شكر يومه',
      'count': 1,
    },
    {
      'id': 'morning_2',
      'arabic':
          'اللّهُـمَّ بِكَ أَصْـبَحْنا وَبِكَ أَمْسَـينا ، وَبِكَ نَحْـيا وَبِكَ نَمُـوتُ وَإِلَـيْكَ النُّـشُور.',
      'transliteration':
          'اللهم بك أصبحنا وبك أمسينا، وبك نحيا وبك نموت وإليك النشور.',
      'benefit': 'التوكل على الله في جميع الأمور',
      'count': 1,
    },
    {
      'id': 'morning_3',
      'arabic':
          'سُبْحـانَ اللهِ وَبِحَمْـدِهِ عَدَدَ خَلْـقِه ، وَرِضـا نَفْسِـه ، وَزِنَـةَ عَـرْشِـه ، وَمِـدادَ كَلِمـاتِـه.',
      'transliteration':
          'سبحان الله وبحمده عدد خلقه، ورضا نفسه، وزنة عرشه، ومداد كلماته.',
      'benefit': 'أجرها عظيم يفوق التسبيح العادي',
      'count': 3,
    },
    {
      'id': 'morning_4',
      'arabic':
          'اللّهُـمَّ عافِـني في بَدَنـي ، اللّهُـمَّ عافِـني في سَمْـعي ، اللّهُـمَّ عافِـني في بَصَـري ، لا إلهَ إلاّ أَنْـتَ.',
      'transliteration':
          'اللهم عافني في بدني، اللهم عافني في سمعي، اللهم عافني في بصري، لا إله إلا أنت.',
      'benefit': 'طلب العافية في الجسد والحواس',
      'count': 3,
    },
    {
      'id': 'morning_5',
      'arabic':
          'اللّهُـمَّ إِنِّـي أَعـوذُ بِكَ مِنَ الْكُـفر ، وَالفَـقْر ، وَأَعـوذُ بِكَ مِنْ عَذابِ القَـبْر ، لا إلهَ إلاّ أَنْـتَ.',
      'transliteration':
          'اللهم إني أعوذ بك من الكفر، والفقر، وأعوذ بك من عذاب القبر، لا إله إلا أنت.',
      'benefit': 'الاستعاذة من أعظم الشرور',
      'count': 3,
    },
    {
      'id': 'morning_6',
      'arabic':
          'بِسـمِ اللهِ الذي لا يَضُـرُّ مَعَ اسمِـهِ شَيءٌ في الأرْضِ وَلا في السّمـاءِ وَهـوَ السّمـيعُ العَلـيم.',
      'transliteration':
          'بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء وهو السميع العليم.',
      'benefit': 'حفظ من كل سوء طوال اليوم',
      'count': 3,
    },
    {
      'id': 'morning_7',
      'arabic':
          'رَضيـتُ بِاللهِ رَبَّـاً وَبِالإسْلامِ ديـناً وَبِمُحَـمَّدٍ صلى الله عليه وسلم نَبِيّـاً.',
      'transliteration': 'رضيت بالله رباً وبالإسلام ديناً وبمحمد ﷺ نبياً.',
      'benefit':
          'من قالها حين يصبح ويمسي كان حقاً على الله أن يرضيه يوم القيامة',
      'count': 3,
    },
    {
      'id': 'morning_8',
      'arabic':
          'يا حَـيُّ يا قَيّـومُ بِـرَحْمَـتِكَ أَسْتَـغـيث ، أَصْلِـحْ لي شَـأْنـي كُلَّـه ، وَلا تَكِلْـني إِلى نَفْـسي طَـرْفَةَ عَـين.',
      'transliteration':
          'يا حي يا قيوم برحمتك أستغيث، أصلح لي شأني كله، ولا تكلني إلى نفسي طرفة عين.',
      'benefit': 'طلب الإصلاح والتوفيق من الله',
      'count': 1,
    },
    {
      'id': 'morning_9',
      'arabic':
          'أَصْبَـحْـنا عَلَى فِطْرَةِ الإسْلاَمِ، وَعَلَى كَلِمَةِ الإِخْلاَصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ صَلَّى اللهُ عَلَيْهِ وَسَلَّمَ، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ حَنِيفاً مُسْلِماً وَمَا كَانَ مِنَ الْمُشْرِكِينَ.',
      'transliteration':
          'أصبحنا على فطرة الإسلام، وعلى كلمة الإخلاص، وعلى دين نبينا محمد ﷺ، وعلى ملة أبينا إبراهيم حنيفاً مسلماً وما كان من المشركين.',
      'benefit': 'التمسك بالإسلام والتوحيد',
      'count': 1,
    },
    {
      'id': 'morning_10',
      'arabic': 'سُبْحـانَ اللهِ وَبِحَمْـدِهِ.',
      'transliteration': 'سبحان الله وبحمده.',
      'benefit':
          'من قالها مائة مرة حين يصبح وحين يمسي لم يأت أحد يوم القيامة بأفضل مما جاء به',
      'count': 100,
    },
    {
      'id': 'morning_11',
      'arabic':
          'لا إلهَ إلاّ اللّهُ وحْـدَهُ لا شَـريكَ لهُ، لهُ المُـلْكُ ولهُ الحَمْـد، وهُوَ على كُلّ شَيءٍ قَدير.',
      'transliteration':
          'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد، وهو على كل شيء قدير.',
      'benefit':
          'كانت له عدل عشر رقاب، وكتبت له مائة حسنة، ومحيت عنه مائة سيئة',
      'count': 10,
    },
    {
      'id': 'morning_12',
      'arabic': 'أَسْتَغْفِرُ اللهَ وَأَتُوبُ إِلَيْهِ.',
      'transliteration': 'أستغفر الله وأتوب إليه.',
      'benefit': 'الاستغفار يمحو الذنوب ويجلب الرزق',
      'count': 100,
    },
  ];

  final List<Map<String, dynamic>> eveningAzkar = [
    {
      'id': 'evening_1',
      'arabic':
          'أَمْسَيْـنا وَأَمْسـى المـلكُ لله وَالحَمدُ لله ، لا إلهَ إلاّ اللّهُ وَحدَهُ لا شَريكَ لهُ، لهُ المُـلْكُ ولهُ الحَمْـد، وهُوَ على كلّ شَيءٍ قدير.',
      'transliteration':
          'أمسينا وأمسى الملك لله والحمد لله، لا إله إلا الله وحده لا شريك له، له الملك وله الحمد، وهو على كل شيء قدير.',
      'benefit': 'من قالها حين يمسي فقد أدى شكر ليلته',
      'count': 1,
    },
    {
      'id': 'evening_2',
      'arabic':
          'اللّهُـمَّ بِكَ أَمْسَـينا وَبِكَ أَصْـبَحْنا، وَبِكَ نَحْـيا وَبِكَ نَمُـوتُ وَإِلَـيْكَ الْمَصِير.',
      'transliteration':
          'اللهم بك أمسينا وبك أصبحنا، وبك نحيا وبك نموت وإليك المصير.',
      'benefit': 'التوكل على الله في جميع الأمور',
      'count': 1,
    },
    {
      'id': 'evening_3',
      'arabic':
          'أَعـوذُ بِكَلِمـاتِ اللّهِ التّـامّـاتِ مِنْ شَـرِّ ما خَلَـق.',
      'transliteration': 'أعوذ بكلمات الله التامات من شر ما خلق.',
      'benefit': 'من قالها ثلاث مرات حين يمسي لم تضره حمة تلك الليلة',
      'count': 3,
    },
    {
      'id': 'evening_4',
      'arabic':
          'اللّهُـمَّ عافِـني في بَدَنـي ، اللّهُـمَّ عافِـني في سَمْـعي ، اللّهُـمَّ عافِـني في بَصَـري ، لا إلهَ إلاّ أَنْـتَ.',
      'transliteration':
          'اللهم عافني في بدني، اللهم عافني في سمعي، اللهم عافني في بصري، لا إله إلا أنت.',
      'benefit': 'طلب العافية في الجسد والحواس',
      'count': 3,
    },
    {
      'id': 'evening_5',
      'arabic':
          'اللّهُـمَّ إِنِّـي أَعـوذُ بِكَ مِنَ الْكُـفر ، وَالفَـقْر ، وَأَعـوذُ بِكَ مِنْ عَذابِ القَـبْر ، لا إلهَ إلاّ أَنْـتَ.',
      'transliteration':
          'اللهم إني أعوذ بك من الكفر، والفقر، وأعوذ بك من عذاب القبر، لا إله إلا أنت.',
      'benefit': 'الاستعاذة من أعظم الشرور',
      'count': 3,
    },
    {
      'id': 'evening_6',
      'arabic':
          'بِسـمِ اللهِ الذي لا يَضُـرُّ مَعَ اسمِـهِ شَيءٌ في الأرْضِ وَلا في السّمـاءِ وَهـوَ السّمـيعُ العَلـيم.',
      'transliteration':
          'بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء وهو السميع العليم.',
      'benefit': 'حفظ من كل سوء طوال الليل',
      'count': 3,
    },
    {
      'id': 'evening_7',
      'arabic':
          'رَضيـتُ بِاللهِ رَبَّـاً وَبِالإسْلامِ ديـناً وَبِمُحَـمَّدٍ صلى الله عليه وسلم نَبِيّـاً.',
      'transliteration': 'رضيت بالله رباً وبالإسلام ديناً وبمحمد ﷺ نبياً.',
      'benefit':
          'من قالها حين يصبح ويمسي كان حقاً على الله أن يرضيه يوم القيامة',
      'count': 3,
    },
    {
      'id': 'evening_8',
      'arabic':
          'يا حَـيُّ يا قَيّـومُ بِـرَحْمَـتِكَ أَسْتَـغـيث ، أَصْلِـحْ لي شَـأْنـي كُلَّـه ، وَلا تَكِلْـني إِلى نَفْـسي طَـرْفَةَ عَـين.',
      'transliteration':
          'يا حي يا قيوم برحمتك أستغيث، أصلح لي شأني كله، ولا تكلني إلى نفسي طرفة عين.',
      'benefit': 'طلب الإصلاح والتوفيق من الله',
      'count': 1,
    },
    {
      'id': 'evening_9',
      'arabic':
          'أَمْسَيْنَا عَلَى فِطْرَةِ الإسْلاَمِ، وَعَلَى كَلِمَةِ الإِخْلاَصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ صَلَّى اللهُ عَلَيْهِ وَسَلَّمَ، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ حَنِيفاً مُسْلِماً وَمَا كَانَ مِنَ الْمُشْرِكِينَ.',
      'transliteration':
          'أمسينا على فطرة الإسلام، وعلى كلمة الإخلاص، وعلى دين نبينا محمد ﷺ، وعلى ملة أبينا إبراهيم حنيفاً مسلماً وما كان من المشركين.',
      'benefit': 'التمسك بالإسلام والتوحيد',
      'count': 1,
    },
    {
      'id': 'evening_10',
      'arabic': 'سُبْحـانَ اللهِ وَبِحَمْـدِهِ.',
      'transliteration': 'سبحان الله وبحمده.',
      'benefit':
          'من قالها مائة مرة حين يصبح وحين يمسي لم يأت أحد يوم القيامة بأفضل مما جاء به',
      'count': 100,
    },
    {
      'id': 'evening_11',
      'arabic':
          'لا إلهَ إلاّ اللّهُ وحْـدَهُ لا شَـريكَ لهُ، لهُ المُـلْكُ ولهُ الحَمْـد، وهُوَ على كُلّ شَيءٍ قَدير.',
      'transliteration':
          'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد، وهو على كل شيء قدير.',
      'benefit':
          'كانت له عدل عشر رقاب، وكتبت له مائة حسنة، ومحيت عنه مائة سيئة',
      'count': 10,
    },
    {
      'id': 'evening_12',
      'arabic': 'أَسْتَغْفِرُ اللهَ وَأَتُوبُ إِلَيْهِ.',
      'transliteration': 'أستغفر الله وأتوب إليه.',
      'benefit': 'الاستغفار يمحو الذنوب ويجلب الرزق',
      'count': 100,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _incrementCount(String id, int maxCount) {
    setState(() {
      int current = _counts[id] ?? 0;
      if (current < maxCount) {
        _counts[id] = current + 1;
        if (_counts[id] == maxCount) {
          HapticFeedback.heavyImpact();
        } else {
          HapticFeedback.lightImpact();
        }
      }
    });
  }

  void _resetCount(String id) {
    setState(() {
      _counts[id] = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isMorning = DateTime.now().hour < 12;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'الأذكار',
                style: GoogleFonts.cairo(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (isMorning ? Colors.orange : Colors.indigo).withValues(
                        alpha: 0.3,
                      ),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    isMorning ? Icons.wb_sunny : Icons.nightlight_round,
                    size: 60,
                    color: (isMorning ? Colors.orange : Colors.indigo)
                        .withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.secondary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).colorScheme.secondary,
              indicatorWeight: 3,
              labelColor: Theme.of(context).colorScheme.secondary,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              labelStyle: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              tabs: [
                Tab(icon: Icon(Icons.wb_sunny, size: 20), text: 'أذكار الصباح'),
                Tab(
                  icon: Icon(Icons.nightlight_round, size: 20),
                  text: 'أذكار المساء',
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAzkarList(morningAzkar, Colors.orange),
            _buildAzkarList(eveningAzkar, Colors.indigo),
          ],
        ),
      ),
    );
  }

  Widget _buildAzkarList(List<Map<String, dynamic>> azkar, Color accentColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: azkar.length,
      itemBuilder: (context, index) {
        final item = azkar[index];
        final String id = item['id'];
        final int maxCount = item['count'];
        final int currentCount = _counts[id] ?? 0;
        final bool isCompleted = currentCount >= maxCount;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: isCompleted
              ? accentColor.withValues(alpha: 0.1)
              : Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isCompleted
                  ? accentColor.withValues(alpha: 0.5)
                  : Theme.of(context).dividerColor.withValues(alpha: 0.3),
              width: isCompleted ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () => _incrementCount(id, maxCount),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Progress indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isCompleted)
                              Icon(
                                Icons.check_circle,
                                color: accentColor,
                                size: 18,
                              )
                            else
                              Text(
                                '$currentCount / $maxCount',
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Actions
                      Row(
                        children: [
                          if (currentCount > 0)
                            IconButton(
                              icon: Icon(
                                Icons.refresh,
                                size: 20,
                                color: accentColor,
                              ),
                              onPressed: () => _resetCount(id),
                              tooltip: 'إعادة',
                            ),
                          IconButton(
                            icon: Icon(
                              Icons.share_rounded,
                              size: 20,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            onPressed: () {
                              Share.share(
                                '${item['arabic']}\n\n📖 ${item['benefit']}',
                              );
                            },
                            tooltip: 'مشاركة',
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Arabic Text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item['arabic']!,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.amiri(
                        fontSize: 20,
                        height: 2.0,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Benefit
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: accentColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['benefit']!,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tap hint
                  if (!isCompleted)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'اضغط للعد',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
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
}
