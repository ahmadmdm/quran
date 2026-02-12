import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/widget_service.dart';

class WidgetCustomizationPage extends ConsumerStatefulWidget {
  const WidgetCustomizationPage({super.key});

  @override
  ConsumerState<WidgetCustomizationPage> createState() =>
      _WidgetCustomizationPageState();
}

class _WidgetCustomizationPageState
    extends ConsumerState<WidgetCustomizationPage> {
  Color _backgroundColor = const Color(0xFF0F1629);
  Color _textColor = const Color(0xFFFFFFFF);
  Color _accentColor = const Color(0xFFC9A24D);
  double _opacity = 1.0;
  String _selectedWidget = 'Minimal';
  String _selectedFontStyle = 'default';
  double _selectedFontSize = 56;
  bool _isRunningCreativeTest = false;

  final List<Color> _backgroundColors = [
    const Color(0xFF0F1629), // Dark Blue (Default)
    const Color(0xFF000000), // Black
    const Color(0xFF1A1F38), // Navy
    const Color(0xFF2C3E50), // Dark Slate
    const Color(0xFF1E3A5F), // Deep Blue
    const Color(0xFF2D1B4E), // Deep Purple
    const Color(0xFF1B3D2F), // Deep Green
  ];

  final List<Color> _accentColors = [
    const Color(0xFFC9A24D), // Gold (Default)
    const Color(0xFFD4AF37), // Bright Gold
    const Color(0xFF3498DB), // Blue
    const Color(0xFF2ECC71), // Green
    const Color(0xFFE74C3C), // Red
    const Color(0xFF9B59B6), // Purple
    const Color(0xFFE67E22), // Orange
  ];

  // Widget types with descriptions
  final List<Map<String, dynamic>> _widgetTypes = [
    {
      'id': 'Minimal',
      'name': 'بسيط',
      'description': 'ويدجت صغير يعرض الصلاة القادمة',
      'icon': Icons.crop_square,
      'size': '2x2',
    },
    {
      'id': 'Smart Card',
      'name': 'البطاقة الذكية',
      'description': 'بطاقة تعرض جميع أوقات الصلاة',
      'icon': Icons.view_agenda,
      'size': '4x2',
    },
    {
      'id': 'Premium Clock',
      'name': 'الساعة المميزة',
      'description': 'ساعة مع العد التنازلي',
      'icon': Icons.watch,
      'size': '3x3',
    },
    {
      'id': 'Glass Card',
      'name': 'البطاقة الزجاجية',
      'description': 'تصميم زجاجي عصري',
      'icon': Icons.blur_on,
      'size': '4x2',
    },
    {
      'id': 'Quran Verse',
      'name': 'آية قرآنية',
      'description': 'آية يومية متجددة',
      'icon': Icons.menu_book,
      'size': '4x2',
    },
    {
      'id': 'Hijri Date',
      'name': 'التاريخ الهجري',
      'description': 'التاريخ الهجري والميلادي',
      'icon': Icons.calendar_today,
      'size': '3x3',
    },
    {
      'id': 'Creative',
      'name': 'الإبداعي',
      'description': 'تصميم شامل ومميز',
      'icon': Icons.auto_awesome,
      'size': '4x3',
    },
    {
      'id': 'Calligraphy',
      'name': 'مخطوطة اليوم',
      'description': 'ويدجت تاريخ بخط عربي يدعم التشكيل والتحجيم',
      'icon': Icons.edit_note,
      'size': '2x2 .. 4x2',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await WidgetService.getWidgetSettings(_selectedWidget);
    if (mounted) {
      setState(() {
        _backgroundColor = Color(settings['backgroundColor']);
        _textColor = Color(settings['textColor']);
        _accentColor = Color(settings['accentColor']);
        _opacity = settings['opacity'];
        _selectedFontStyle = settings['fontStyle'];
        _selectedFontSize = (settings['fontSize'] as num?)?.toDouble() ?? 56;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(localizations.translate('widget_customization')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveSettings),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Preview Area with gradient background
            Container(
              height: 320,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.scaffoldBackgroundColor,
                    theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Simulated wallpaper pattern
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.withValues(alpha: 0.1),
                            Colors.purple.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(child: _buildPreview()),
                ],
              ),
            ),

            // Controls
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Widget Type Selector with Preview Cards
                  _buildSectionTitle(theme, 'اختر نوع الويدجت'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _widgetTypes.length,
                      itemBuilder: (context, index) {
                        final widget = _widgetTypes[index];
                        return _buildWidgetTypeCard(widget);
                      },
                    ),
                  ),
                  const SizedBox(height: 28),

                  if (_selectedWidget == 'Calligraphy') ...[
                    _buildSectionTitle(theme, 'نمط الخط'),
                    const SizedBox(height: 12),
                    _buildFontStyleSelector(),
                    const SizedBox(height: 16),
                    _buildSectionTitle(theme, 'حجم الخط'),
                    Slider(
                      value: _selectedFontSize,
                      min: 36,
                      max: 82,
                      divisions: 23,
                      label: _selectedFontSize.round().toString(),
                      onChanged: (value) {
                        setState(() => _selectedFontSize = value);
                      },
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Background Color
                  _buildSectionTitle(theme, 'لون الخلفية'),
                  const SizedBox(height: 12),
                  _buildColorPicker(_backgroundColors, _backgroundColor, (
                    color,
                  ) {
                    setState(() => _backgroundColor = color);
                  }),
                  const SizedBox(height: 28),

                  // Accent Color
                  _buildSectionTitle(theme, 'اللون المميز'),
                  const SizedBox(height: 12),
                  _buildColorPicker(_accentColors, _accentColor, (color) {
                    setState(() => _accentColor = color);
                  }),
                  const SizedBox(height: 28),

                  // Opacity
                  _buildSectionTitle(theme, 'الشفافية'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: _accentColor,
                            thumbColor: _accentColor,
                            overlayColor: _accentColor.withValues(alpha: 0.2),
                            inactiveTrackColor: theme.dividerColor,
                          ),
                          child: Slider(
                            value: _opacity,
                            min: 0.3,
                            max: 1.0,
                            divisions: 7,
                            onChanged: (value) =>
                                setState(() => _opacity = value),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(_opacity * 100).round()}%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Text Color
                  _buildSectionTitle(theme, 'لون النص'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTextColorOption(Colors.white, 'أبيض'),
                      const SizedBox(width: 16),
                      _buildTextColorOption(Colors.black, 'أسود'),
                    ],
                  ),
                  const SizedBox(height: 28),

                  _buildSectionTitle(theme, 'مختبر الإبداع'),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _accentColor.withValues(alpha: 0.16),
                          _backgroundColor.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _accentColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'اختبر تأثيرات حيّة على الويدجت بدون فقدان إعداداتك.',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isRunningCreativeTest
                                    ? null
                                    : _runQuickPulseForSelectedWidget,
                                icon: const Icon(Icons.bolt, size: 18),
                                label: const Text('نبضة سريعة'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _isRunningCreativeTest
                                    ? null
                                    : _runCreativeWidgetLab,
                                icon: const Icon(Icons.auto_awesome, size: 18),
                                label: const Text('عرض حي شامل'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildSectionTitle(theme, 'إجراءات سريعة'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isRunningCreativeTest
                              ? null
                              : _applyThemeToAllWidgets,
                          icon: const Icon(Icons.copy_all, size: 18),
                          label: const Text('نسخ النمط للجميع'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isRunningCreativeTest
                              ? null
                              : _resetSelectedWidgetToDefault,
                          icon: const Icon(Icons.restart_alt, size: 18),
                          label: const Text('إعادة الافتراضي'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: _accentColor.withValues(alpha: 0.4),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.widgets, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'تطبيق على الويدجت',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildWidgetTypeCard(Map<String, dynamic> widget) {
    final theme = Theme.of(context);
    final isSelected = _selectedWidget == widget['id'];

    return GestureDetector(
      onTap: () {
        setState(() => _selectedWidget = widget['id']);
        _loadSettings();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? _accentColor.withValues(alpha: 0.15)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _accentColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _accentColor.withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildWidgetShapePreview(widget['id'] as String),
            const SizedBox(height: 10),
            // Widget Name
            Text(
              widget['name'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected
                    ? _accentColor
                    : theme.textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            // Widget Size
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget['size'],
                style: TextStyle(
                  fontSize: 10,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Description
            Text(
              widget['description'],
              style: TextStyle(
                fontSize: 9,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetShapePreview(String widgetId) {
    double width = 74;
    double height = 52;
    switch (widgetId) {
      case 'Minimal':
      case 'Calligraphy':
        width = 52;
        height = 52;
        break;
      case 'Premium Clock':
      case 'Hijri Date':
        width = 64;
        height = 64;
        break;
      case 'Creative':
        width = 74;
        height = 56;
        break;
      default:
        width = 74;
        height = 48;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _backgroundColor.withValues(alpha: _opacity),
            _backgroundColor.withValues(alpha: _opacity * 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accentColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          _widgetTypes.firstWhere((e) => e['id'] == widgetId)['icon']
              as IconData,
          color: _accentColor,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildFontStyleSelector() {
    final styles = [
      {'id': 'default', 'name': 'افتراضي', 'sample': 'اَلْيَوْمُ'},
      {'id': 'serif', 'name': 'نسخي', 'sample': 'اَلْأَحَدُ'},
      {'id': 'cursive', 'name': 'ديواني', 'sample': 'اَلْجُمُعَةُ'},
      {'id': 'monospace', 'name': 'كوفي', 'sample': 'اَلثُّلَاثَاءُ'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: styles.map((style) {
          final isSelected = _selectedFontStyle == style['id'];
          return GestureDetector(
            onTap: () => setState(() => _selectedFontStyle = style['id']!),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? _accentColor.withValues(alpha: 0.15)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? _accentColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    style['sample']!,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: _getFontFamilyForStyle(style['id']!),
                      color: isSelected
                          ? _accentColor
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    style['name']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildColorPicker(
    List<Color> colors,
    Color selectedColor,
    Function(Color) onSelect,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: colors.map((color) {
          final isSelected = selectedColor == color;
          return GestureDetector(
            onTap: () => onSelect(color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              width: isSelected ? 48 : 40,
              height: isSelected ? 48 : 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? _accentColor
                      : Colors.grey.withValues(alpha: 0.3),
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: color.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                      size: 20,
                    )
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextColorOption(Color color, String label) {
    final theme = Theme.of(context);
    final isSelected = _textColor == color;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _textColor = color),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? _accentColor.withValues(alpha: 0.1)
                : theme.dividerColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _accentColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    switch (_selectedWidget) {
      case 'Minimal':
        return _buildMinimalPreview();
      case 'Smart Card':
        return _buildSmartCardPreview();
      case 'Premium Clock':
        return _buildPremiumClockPreview();
      case 'Glass Card':
        return _buildGlassCardPreview();
      case 'Quran Verse':
        return _buildQuranVersePreview();
      case 'Hijri Date':
        return _buildHijriDatePreview();
      case 'Creative':
        return _buildCreativePreview();
      case 'Calligraphy':
        return _buildCalligraphyPreview();
      default:
        return _buildMinimalPreview();
    }
  }

  Widget _buildCalligraphyPreview() {
    return Container(
      width: 180,
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _backgroundColor.withValues(alpha: _opacity),
            _backgroundColor.withValues(alpha: _opacity * 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'الأحد',
            style: TextStyle(
              color: _textColor,
              fontSize: (_selectedFontSize * 0.84).clamp(26, 64),
              fontWeight: FontWeight.bold,
              fontFamily: _getFontFamilyForStyle(_selectedFontStyle),
              height: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '٢٠ شعبان، ١٤٤٧',
            style: TextStyle(
              color: _textColor.withValues(alpha: 0.8),
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  String? _getFontFamilyForStyle(String style) {
    switch (style) {
      case 'serif':
        return 'serif';
      case 'cursive':
        return 'cursive';
      case 'monospace':
        return 'monospace';
      default:
        return null;
    }
  }

  Widget _buildMinimalPreview() {
    return Container(
      width: 160,
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _backgroundColor.withValues(alpha: _opacity),
            _backgroundColor.withValues(alpha: _opacity * 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'الصلاة القادمة',
            style: TextStyle(
              color: _textColor.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'العصر',
            style: TextStyle(
              color: _accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '-02:45',
            style: TextStyle(
              color: _textColor,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '03:30 PM',
            style: TextStyle(
              color: _textColor.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartCardPreview() {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _backgroundColor.withValues(alpha: _opacity),
            _backgroundColor.withValues(alpha: _opacity * 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الصلاة القادمة',
                    style: TextStyle(
                      color: _textColor.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'العصر',
                    style: TextStyle(
                      color: _accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              Text(
                '-02:45',
                style: TextStyle(
                  color: _textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPrayerTimeItem('الفجر', '04:30'),
              _buildPrayerTimeItem('الظهر', '12:15'),
              _buildPrayerTimeItem('العصر', '03:30', isActive: true),
              _buildPrayerTimeItem('المغرب', '06:00'),
              _buildPrayerTimeItem('العشاء', '07:30'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimeItem(
    String name,
    String time, {
    bool isActive = false,
  }) {
    return Column(
      children: [
        Text(
          name,
          style: TextStyle(
            color: isActive ? _accentColor : _textColor.withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            color: isActive ? _accentColor : _textColor,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumClockPreview() {
    return Container(
      width: 200,
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _backgroundColor.withValues(alpha: _opacity),
            _backgroundColor.withValues(alpha: _opacity * 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '03:30',
            style: TextStyle(
              color: _textColor,
              fontWeight: FontWeight.w200,
              fontSize: 48,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'العصر - 02:45',
              style: TextStyle(
                color: _accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCardPreview() {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'العصر',
                style: TextStyle(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              Text(
                '02:45',
                style: TextStyle(
                  color: _textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '03:30 PM',
            style: TextStyle(
              color: _textColor.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuranVersePreview() {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _backgroundColor.withValues(alpha: _opacity),
            _backgroundColor.withValues(alpha: _opacity * 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.format_quote,
            color: _accentColor.withValues(alpha: 0.5),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            style: TextStyle(
              color: _textColor,
              fontSize: 18,
              fontFamily: 'Amiri',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'سورة الفاتحة - آية 1',
            style: TextStyle(color: _accentColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHijriDatePreview() {
    return Container(
      width: 200,
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _backgroundColor.withValues(alpha: _opacity),
            _backgroundColor.withValues(alpha: _opacity * 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('الخميس', style: TextStyle(color: _textColor, fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '15',
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 42,
                  fontWeight: FontWeight.w200,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'رجب',
                    style: TextStyle(color: _textColor, fontSize: 16),
                  ),
                  Text(
                    '1447 هـ',
                    style: TextStyle(
                      color: _textColor.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: 60,
            height: 1,
            color: _accentColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            '5 فبراير 2026',
            style: TextStyle(
              color: _textColor.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreativePreview() {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _backgroundColor.withValues(alpha: _opacity),
            _backgroundColor.withValues(alpha: _opacity * 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Circular progress
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _accentColor.withValues(alpha: 0.3),
                    width: 3,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'العصر',
                      style: TextStyle(
                        color: _accentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '02:45',
                      style: TextStyle(color: _textColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Time and date
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '03:30',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                  Text(
                    '15 رجب 1447',
                    style: TextStyle(
                      color: _textColor.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: _accentColor.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPrayerTimeItem('الفجر', '04:30'),
              _buildPrayerTimeItem('الظهر', '12:15'),
              _buildPrayerTimeItem('العصر', '03:30', isActive: true),
              _buildPrayerTimeItem('المغرب', '06:00'),
              _buildPrayerTimeItem('العشاء', '07:30'),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _runQuickPulseForSelectedWidget() async {
    if (_isRunningCreativeTest) return;
    setState(() => _isRunningCreativeTest = true);

    final savedWidget = _selectedWidget;
    final backup = await WidgetService.getWidgetSettings(savedWidget);
    final demoPalettes = _creativePalettes();

    try {
      for (final palette in demoPalettes.take(3)) {
        await WidgetService.updateWidgetColors(
          backgroundColor: palette['backgroundColor'] as Color,
          textColor: palette['textColor'] as Color,
          accentColor: palette['accentColor'] as Color,
          opacity: (palette['opacity'] as num).toDouble(),
          fontStyle: savedWidget == 'Calligraphy'
              ? palette['fontStyle'] as String
              : null,
          fontSize: savedWidget == 'Calligraphy'
              ? (palette['fontSize'] as num).toDouble()
              : null,
          widgetType: savedWidget,
        );
        if (!mounted) return;
        setState(() {
          _backgroundColor = palette['backgroundColor'] as Color;
          _textColor = palette['textColor'] as Color;
          _accentColor = palette['accentColor'] as Color;
          _opacity = (palette['opacity'] as num).toDouble();
          if (savedWidget == 'Calligraphy') {
            _selectedFontStyle = palette['fontStyle'] as String;
            _selectedFontSize = (palette['fontSize'] as num).toDouble();
          }
        });
        await Future.delayed(const Duration(milliseconds: 320));
      }
    } finally {
      await _restoreWidgetSettings(savedWidget, backup);
      if (mounted) {
        setState(() => _isRunningCreativeTest = false);
        await _loadSettings();
      }
    }
  }

  Future<void> _runCreativeWidgetLab() async {
    if (_isRunningCreativeTest) return;
    setState(() => _isRunningCreativeTest = true);

    final previousWidget = _selectedWidget;
    final widgetIds = _widgetTypes.map((e) => e['id'] as String).toList();
    final backups = <String, Map<String, dynamic>>{};
    final palettes = _creativePalettes();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('بدأ عرض حي للويدجت...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      for (var i = 0; i < widgetIds.length; i++) {
        final widgetId = widgetIds[i];
        backups[widgetId] = await WidgetService.getWidgetSettings(widgetId);
        final palette = palettes[i % palettes.length];

        await WidgetService.updateWidgetColors(
          backgroundColor: palette['backgroundColor'] as Color,
          textColor: palette['textColor'] as Color,
          accentColor: palette['accentColor'] as Color,
          opacity: (palette['opacity'] as num).toDouble(),
          fontStyle: widgetId == 'Calligraphy'
              ? palette['fontStyle'] as String
              : null,
          fontSize: widgetId == 'Calligraphy'
              ? (palette['fontSize'] as num).toDouble()
              : null,
          widgetType: widgetId,
        );

        if (!mounted) return;
        setState(() {
          _selectedWidget = widgetId;
          _backgroundColor = palette['backgroundColor'] as Color;
          _textColor = palette['textColor'] as Color;
          _accentColor = palette['accentColor'] as Color;
          _opacity = (palette['opacity'] as num).toDouble();
          if (widgetId == 'Calligraphy') {
            _selectedFontStyle = palette['fontStyle'] as String;
            _selectedFontSize = (palette['fontSize'] as num).toDouble();
          }
        });

        await Future.delayed(const Duration(milliseconds: 360));
      }
    } finally {
      for (final widgetId in widgetIds) {
        final backup = backups[widgetId];
        if (backup != null) {
          await _restoreWidgetSettings(widgetId, backup);
        }
      }
      await WidgetService.forceRefreshAllWidgets();
      if (mounted) {
        setState(() => _selectedWidget = previousWidget);
        await _loadSettings();
        if (mounted) {
          setState(() => _isRunningCreativeTest = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('انتهى العرض وتمت استعادة إعداداتك الأصلية'),
            ),
          );
        }
      }
    }
  }

  Future<void> _restoreWidgetSettings(
    String widgetType,
    Map<String, dynamic> backup,
  ) async {
    await WidgetService.updateWidgetColors(
      backgroundColor: Color(backup['backgroundColor'] as int),
      textColor: Color(backup['textColor'] as int),
      accentColor: Color(backup['accentColor'] as int),
      opacity: (backup['opacity'] as num?)?.toDouble() ?? 1.0,
      fontStyle: widgetType == 'Calligraphy'
          ? (backup['fontStyle'] as String? ?? 'default')
          : null,
      fontSize: widgetType == 'Calligraphy'
          ? (backup['fontSize'] as num?)?.toDouble() ?? 56
          : null,
      widgetType: widgetType,
    );
  }

  List<Map<String, dynamic>> _creativePalettes() {
    return const [
      {
        'backgroundColor': Color(0xFF102A43),
        'textColor': Color(0xFFF6F9FC),
        'accentColor': Color(0xFFFFB703),
        'opacity': 1.0,
        'fontStyle': 'serif',
        'fontSize': 62.0,
      },
      {
        'backgroundColor': Color(0xFF3A0CA3),
        'textColor': Color(0xFFFFFFFF),
        'accentColor': Color(0xFF4CC9F0),
        'opacity': 0.95,
        'fontStyle': 'cursive',
        'fontSize': 66.0,
      },
      {
        'backgroundColor': Color(0xFF1B4332),
        'textColor': Color(0xFFE9F5DB),
        'accentColor': Color(0xFFFFD166),
        'opacity': 0.92,
        'fontStyle': 'default',
        'fontSize': 58.0,
      },
      {
        'backgroundColor': Color(0xFF2B2D42),
        'textColor': Color(0xFFFFFFFF),
        'accentColor': Color(0xFFEF233C),
        'opacity': 0.9,
        'fontStyle': 'monospace',
        'fontSize': 60.0,
      },
    ];
  }

  Future<void> _applyThemeToAllWidgets() async {
    if (_isRunningCreativeTest) return;
    setState(() => _isRunningCreativeTest = true);
    try {
      await WidgetService.applyThemeToAllWidgets(
        backgroundColor: _backgroundColor,
        textColor: _textColor,
        accentColor: _accentColor,
        opacity: _opacity,
        calligraphyFontStyle: _selectedFontStyle,
        calligraphyFontSize: _selectedFontSize,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تطبيق نفس النمط على جميع الويدجت')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر نسخ النمط: $e')));
    } finally {
      if (mounted) setState(() => _isRunningCreativeTest = false);
    }
  }

  Future<void> _resetSelectedWidgetToDefault() async {
    if (_isRunningCreativeTest) return;
    setState(() => _isRunningCreativeTest = true);
    try {
      await WidgetService.resetWidgetToDefaults(_selectedWidget);
      if (!mounted) return;
      await _loadSettings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تمت إعادة $_selectedWidget للوضع الافتراضي')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر إعادة الافتراضي: $e')));
    } finally {
      if (mounted) setState(() => _isRunningCreativeTest = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      await WidgetService.updateWidgetColors(
        backgroundColor: _backgroundColor,
        textColor: _textColor,
        accentColor: _accentColor,
        opacity: _opacity,
        fontStyle: _selectedWidget == 'Calligraphy' ? _selectedFontStyle : null,
        fontSize: _selectedWidget == 'Calligraphy' ? _selectedFontSize : null,
        widgetType: _selectedWidget, // Pass selected widget type
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('تم تحديث الويدجت بنجاح'),
              ],
            ),
            backgroundColor: _accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
