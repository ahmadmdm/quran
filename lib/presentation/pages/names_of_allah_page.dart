import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/localization/app_localizations.dart';

class NamesOfAllahPage extends StatelessWidget {
  const NamesOfAllahPage({super.key});

  final List<Map<String, String>> names = const [
    {'name': 'Allah', 'arabic': 'الله', 'meaning': 'The Greatest Name'},
    {'name': 'Ar-Rahman', 'arabic': 'الرحمن', 'meaning': 'The All-Merciful'},
    {'name': 'Ar-Rahim', 'arabic': 'الرحيم', 'meaning': 'The All-Beneficent'},
    {
      'name': 'Al-Malik',
      'arabic': 'الملك',
      'meaning': 'The King, The Sovereign',
    },
    {'name': 'Al-Quddus', 'arabic': 'القدوس', 'meaning': 'The Most Holy'},
    {
      'name': 'As-Salam',
      'arabic': 'السلام',
      'meaning': 'The Peace and Blessing',
    },
    {'name': 'Al-Mu\'min', 'arabic': 'المؤمن', 'meaning': 'The Guarantor'},
    {'name': 'Al-Muhaymin', 'arabic': 'المهيمن', 'meaning': 'The Guardian'},
    {
      'name': 'Al-Aziz',
      'arabic': 'العزيز',
      'meaning': 'The Almighty, The Self Sufficient',
    },
    {
      'name': 'Al-Jabbar',
      'arabic': 'الجبار',
      'meaning': 'The Powerful, The Irresistible',
    },
    {'name': 'Al-Mutakabbir', 'arabic': 'المتكبر', 'meaning': 'The Tremendous'},
    {'name': 'Al-Khaliq', 'arabic': 'الخالق', 'meaning': 'The Creator'},
  ];

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(localizations.translate('names_of_allah')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: names.length,
        itemBuilder: (context, index) {
          final item = names[index];
          return Card(
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item['arabic']!,
                    style: GoogleFonts.amiri(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['name']!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['meaning']!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
