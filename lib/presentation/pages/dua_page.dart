import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/localization/app_localizations.dart';

class DuaPage extends StatelessWidget {
  const DuaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // Arabic duas with translations
    final List<Map<String, dynamic>> duaCategories = [
      {
        'title': 'أدعية قرآنية',
        'icon': Icons.menu_book,
        'color': const Color(0xFFC9A24D),
        'duas': [
          {
            'arabic':
                'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
            'translation':
                'ربنا أعطنا في الدنيا خيراً وفي الآخرة خيراً واحفظنا من عذاب النار',
            'reference': 'سورة البقرة - الآية 201',
          },
          {
            'arabic':
                'رَبَّنَا لاَ تُؤَاخِذْنَا إِن نَّسِينَا أَوْ أَخْطَأْنَا',
            'translation': 'ربنا لا تعاقبنا إن نسينا أو أخطأنا',
            'reference': 'سورة البقرة - الآية 286',
          },
          {
            'arabic':
                'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا',
            'translation':
                'ربنا هب لنا من أزواجنا وذرياتنا ما تقر به أعيننا واجعلنا قدوة للمتقين',
            'reference': 'سورة الفرقان - الآية 74',
          },
          {
            'arabic': 'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي',
            'translation': 'رب اشرح لي صدري ويسر لي أمري',
            'reference': 'سورة طه - الآية 25-26',
          },
          {
            'arabic': 'رَبِّ زِدْنِي عِلْمًا',
            'translation': 'رب زدني علماً',
            'reference': 'سورة طه - الآية 114',
          },
        ],
      },
      {
        'title': 'أدعية نبوية',
        'icon': Icons.person,
        'color': const Color(0xFF4CAF50),
        'duas': [
          {
            'arabic':
                'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْبُخْلِ وَالْجُبْنِ، وَضَلَعِ الدَّيْنِ وَغَلَبَةِ الرِّجَالِ',
            'translation':
                'اللهم إني أستعيذ بك من الهم والحزن، والعجز والكسل، والبخل والجبن، وثقل الدين وقهر الرجال',
            'reference': 'صحيح البخاري',
          },
          {
            'arabic':
                'اللَّهُمَّ أَصْلِحْ لِي دِينِي الَّذِي هُوَ عِصْمَةُ أَمْرِي، وَأَصْلِحْ لِي دُنْيَايَ الَّتِي فِيهَا مَعَاشِي، وَأَصْلِحْ لِي آخِرَتِي الَّتِي فِيهَا مَعَادِي',
            'translation': 'اللهم أصلح لي ديني وأصلح لي دنياي وأصلح لي آخرتي',
            'reference': 'صحيح مسلم',
          },
          {
            'arabic':
                'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى',
            'translation': 'اللهم إني أسألك الهداية والتقوى والعفاف والغنى',
            'reference': 'صحيح مسلم',
          },
          {
            'arabic':
                'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
            'translation': 'كان النبي ﷺ يكثر من هذا الدعاء',
            'reference': 'متفق عليه',
          },
        ],
      },
      {
        'title': 'أدعية الصباح والمساء',
        'icon': Icons.wb_twilight,
        'color': const Color(0xFFFF9800),
        'duas': [
          {
            'arabic':
                'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
            'translation': 'دعاء الصباح - يقال عند الاستيقاظ',
            'reference': 'صحيح مسلم',
          },
          {
            'arabic':
                'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ',
            'translation': 'دعاء الصباح',
            'reference': 'سنن الترمذي',
          },
          {
            'arabic':
                'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
            'translation': 'دعاء المساء',
            'reference': 'صحيح مسلم',
          },
          {
            'arabic':
                'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
            'translation': 'يقال ثلاث مرات صباحاً ومساءً',
            'reference': 'سنن أبي داود',
          },
        ],
      },
      {
        'title': 'أدعية السفر',
        'icon': Icons.flight,
        'color': const Color(0xFF2196F3),
        'duas': [
          {
            'arabic':
                'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُونَ',
            'translation': 'دعاء ركوب الدابة والسيارة',
            'reference': 'سورة الزخرف - الآية 13-14',
          },
          {
            'arabic':
                'اللَّهُمَّ إِنَّا نَسْأَلُكَ فِي سَفَرِنَا هَذَا الْبِرَّ وَالتَّقْوَى، وَمِنَ الْعَمَلِ مَا تَرْضَى',
            'translation': 'دعاء السفر',
            'reference': 'صحيح مسلم',
          },
          {
            'arabic':
                'اللَّهُمَّ هَوِّنْ عَلَيْنَا سَفَرَنَا هَذَا وَاطْوِ عَنَّا بُعْدَهُ',
            'translation': 'اللهم سهل علينا سفرنا واطو عنا بعده',
            'reference': 'صحيح مسلم',
          },
        ],
      },
      {
        'title': 'أدعية متنوعة',
        'icon': Icons.favorite,
        'color': const Color(0xFFE91E63),
        'duas': [
          {
            'arabic':
                'لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
            'translation': 'دعاء ذي النون - دعاء الكرب',
            'reference': 'سورة الأنبياء - الآية 87',
          },
          {
            'arabic': 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
            'translation': 'حسبنا الله ونعم الوكيل',
            'reference': 'سورة آل عمران - الآية 173',
          },
          {
            'arabic':
                'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ',
            'translation': 'اللهم إني أسألك العفو والعافية في الدنيا والآخرة',
            'reference': 'سنن ابن ماجه',
          },
          {
            'arabic':
                'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ',
            'translation': 'دعاء الاستغاثة',
            'reference': 'صحيح الترغيب',
          },
        ],
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'الأدعية',
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
                      Theme.of(
                        context,
                      ).colorScheme.secondary.withValues(alpha: 0.2),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.auto_awesome,
                    size: 60,
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.3),
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
          ),

          // Categories
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final category = duaCategories[index];
                return _buildCategoryCard(context, category);
              }, childCount: duaCategories.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    Map<String, dynamic> category,
  ) {
    final Color categoryColor = category['color'] as Color;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: categoryColor.withValues(alpha: 0.3), width: 1),
      ),
      elevation: 0,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(category['icon'], color: categoryColor, size: 24),
          ),
          title: Text(
            category['title'],
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            '${(category['duas'] as List).length} دعاء',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: (category['duas'] as List).map<Widget>((dua) {
            return _buildDuaItem(context, dua, categoryColor);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDuaItem(
    BuildContext context,
    Map<String, String> dua,
    Color accentColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Arabic Text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              dua['arabic']!,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                fontSize: 22,
                height: 2.0,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Translation
          Text(
            dua['translation']!,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),

          // Reference and Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Reference
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  dua['reference']!,
                  style: TextStyle(
                    fontSize: 11,
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Actions
              Row(
                children: [
                  // Copy Button
                  IconButton(
                    icon: Icon(
                      Icons.copy_rounded,
                      size: 20,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: dua['arabic']!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم نسخ الدعاء'),
                          backgroundColor: accentColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    tooltip: 'نسخ',
                  ),

                  // Share Button
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
                        '${dua['arabic']}\n\n${dua['translation']}\n\n📖 ${dua['reference']}',
                      );
                    },
                    tooltip: 'مشاركة',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
