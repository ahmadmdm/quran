import 'dart:io';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../providers/prayer_provider.dart';

class QiblaPage extends ConsumerStatefulWidget {
  const QiblaPage({super.key});

  @override
  ConsumerState<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends ConsumerState<QiblaPage>
    with TickerProviderStateMixin {
  double _heading = 0;
  double _targetHeading = 0;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  StreamSubscription<CompassEvent>? _compassSubscription;

  // Calibration state
  bool _isCalibrating = false;
  bool _needsCalibration = false;
  double _calibrationProgress = 0;

  // Accuracy indicator
  double _accuracy = 0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Listen to compass events
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (mounted) {
        setState(() {
          // Use true heading if available, otherwise magnetic heading
          final heading = event.heading ?? event.headingForCameraMode ?? 0;

          // Update accuracy
          final accuracy = event.accuracy ?? 0;

          if (Platform.isAndroid) {
            // Android: 3=High, 2=Medium, 1=Low, 0=Unreliable
            if (accuracy >= 3) {
              _accuracy = 0.9; // High
              _needsCalibration = false;
            } else if (accuracy >= 2) {
              _accuracy = 0.6; // Medium
              _needsCalibration = false;
            } else if (accuracy >= 1) {
              _accuracy = 0.3; // Low
              _needsCalibration = true;
            } else {
              _accuracy = 0.1; // Unreliable
              _needsCalibration = true;
            }
          } else {
            // iOS: Degrees (lower is better)
            if (accuracy < 0) {
              _accuracy = 0.1; // Invalid/Unreliable
              _needsCalibration = true;
            } else if (accuracy < 15) {
              _accuracy = 0.9; // High
              _needsCalibration = false;
            } else if (accuracy < 45) {
              _accuracy = 0.6; // Medium
              _needsCalibration = false;
            } else {
              _accuracy = 0.3; // Low
              _needsCalibration = true;
            }
          }

          _targetHeading = heading;

          // Adaptive smoothing
          double diff = _targetHeading - _heading;
          // Normalize to -180 to 180
          if (diff > 180) diff -= 360;
          if (diff < -180) diff += 360;

          double alpha = 0.1; // Default
          if (diff.abs() > 20) {
            alpha = 0.4; // Fast turn
          } else if (diff.abs() < 2) {
            alpha = 0.05; // Filter jitter when stable
          }

          _heading += diff * alpha;

          // Normalize heading
          if (_heading < 0) _heading += 360;
          if (_heading >= 360) _heading -= 360;
        });
      }
    });
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _startCalibration() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('معايرة البوصلة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.screen_rotation, size: 60, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'حرك هاتفك في الهواء على شكل رقم 8 (∞) عدة مرات لمعايرة البوصلة وتحسين الدقة.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qiblaAsync = ref.watch(qiblaDirectionProvider);
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.cardColor.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.secondary.withValues(alpha: 0.2),
                      theme.scaffoldBackgroundColor,
                    ],
                  ),
                ),
              ),
              title: Text(
                'اتجاه القبلة',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
            ),
          ),

          // Content
          SliverFillRemaining(
            hasScrollBody: false,
            child: qiblaAsync.when(
              data: (qiblaDir) => _buildQiblaContent(context, qiblaDir),
              loading: () => _buildLoadingState(context),
              error: (err, _) => _buildErrorState(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQiblaContent(BuildContext context, double qiblaDir) {
    final theme = Theme.of(context);
    final diff = (qiblaDir - _heading).abs();
    final isAligned = diff < 3 || diff > 357;

    if (isAligned) {
      HapticFeedback.selectionClick();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Accuracy Indicator
          _buildAccuracyIndicator(context),

          const SizedBox(height: 30),

          // Main Compass
          _buildCompass(context, qiblaDir, isAligned),

          const SizedBox(height: 30),

          // Direction Info
          _buildDirectionInfo(context, qiblaDir, isAligned),

          const SizedBox(height: 20),

          // Calibration Button (if needed)
          if (_needsCalibration && !_isCalibrating)
            _buildCalibrationButton(context),

          // Calibration Progress
          if (_isCalibrating) _buildCalibrationProgress(context),

          const SizedBox(height: 20),

          // Tips Card
          _buildTipsCard(context),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAccuracyIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final accuracyColor = _accuracy > 0.7
        ? Colors.green
        : _accuracy > 0.4
        ? Colors.orange
        : Colors.red;

    // Calculate accuracy percentage
    final accuracyPercent = (_accuracy * 100).toInt();

    // Determine accuracy description
    String accuracyText;
    String accuracyDetail;
    if (_accuracy > 0.8) {
      accuracyText = 'دقة ممتازة';
      accuracyDetail = '±2°';
    } else if (_accuracy > 0.7) {
      accuracyText = 'دقة عالية';
      accuracyDetail = '±5°';
    } else if (_accuracy > 0.5) {
      accuracyText = 'دقة متوسطة';
      accuracyDetail = '±10°';
    } else if (_accuracy > 0.3) {
      accuracyText = 'دقة منخفضة';
      accuracyDetail = '±15°';
    } else {
      accuracyText = 'يرجى المعايرة';
      accuracyDetail = 'غير دقيق';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: accuracyColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Accuracy icon with animated glow
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accuracyColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _accuracy > 0.7
                  ? Icons.gps_fixed
                  : _accuracy > 0.4
                  ? Icons.gps_not_fixed
                  : Icons.gps_off,
              color: accuracyColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                accuracyText,
                style: TextStyle(
                  color: accuracyColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'الدقة: $accuracyPercent% ($accuracyDetail)',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Progress bar
          SizedBox(
            width: 70,
            child: Column(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _accuracy,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accuracyColor.withOpacity(0.7),
                            accuracyColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompass(BuildContext context, double qiblaDir, bool isAligned) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isAligned ? _pulseAnimation.value : 1.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow when aligned
              if (isAligned)
                Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),

              // Compass Background
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.cardColor,
                      theme.cardColor.withValues(alpha: 0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),

              // Compass Rose (rotates with device)
              Transform.rotate(
                angle: -_heading * (math.pi / 180),
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Cardinal directions
                      _buildCardinalDirection('N', 'ش', 0, theme),
                      _buildCardinalDirection('E', 'شر', 90, theme),
                      _buildCardinalDirection('S', 'ج', 180, theme),
                      _buildCardinalDirection('W', 'غ', 270, theme),

                      // Degree ticks
                      ...List.generate(36, (index) {
                        return Transform.rotate(
                          angle: (index * 10) * (math.pi / 180),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: index % 3 == 0 ? 2 : 1,
                              height: index % 3 == 0 ? 15 : 8,
                              margin: const EdgeInsets.only(top: 5),
                              decoration: BoxDecoration(
                                color: index % 3 == 0
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.3,
                                      ),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Qibla Direction Indicator
              Transform.rotate(
                angle: (qiblaDir - _heading) * (math.pi / 180),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Kaaba Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isAligned
                            ? Colors.green
                            : theme.colorScheme.secondary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isAligned
                                        ? Colors.green
                                        : theme.colorScheme.secondary)
                                    .withValues(alpha: 0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mosque,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    // Arrow pointing to Kaaba
                    Container(
                      width: 4,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            isAligned
                                ? Colors.green
                                : theme.colorScheme.secondary,
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),

              // Center pivot
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
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

  Widget _buildCardinalDirection(
    String letter,
    String arabic,
    double angle,
    ThemeData theme,
  ) {
    return Transform.rotate(
      angle: angle * (math.pi / 180),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 25),
          child: Transform.rotate(
            angle: -angle * (math.pi / 180),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  arabic,
                  style: TextStyle(
                    color: letter == 'N'
                        ? Colors.red
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionInfo(
    BuildContext context,
    double qiblaDir,
    bool isAligned,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
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
          // Heading display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                context,
                'اتجاهك',
                '${_heading.toStringAsFixed(0)}°',
                Icons.explore,
              ),
              Container(
                width: 1,
                height: 40,
                color: theme.dividerColor.withValues(alpha: 0.3),
              ),
              _buildInfoItem(
                context,
                'القبلة',
                '${qiblaDir.toStringAsFixed(0)}°',
                Icons.mosque,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Alignment status
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isAligned
                  ? Colors.green.withValues(alpha: 0.15)
                  : theme.colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isAligned
                    ? Colors.green
                    : theme.colorScheme.secondary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAligned ? Icons.check_circle : Icons.rotate_right,
                  color: isAligned ? Colors.green : theme.colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  isAligned ? 'أنت تواجه القبلة ✓' : 'أدر جهازك نحو القبلة',
                  style: TextStyle(
                    color: isAligned
                        ? Colors.green
                        : theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.secondary, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildCalibrationButton(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _startCalibration,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sync, color: Colors.orange),
            const SizedBox(width: 8),
            const Text(
              'معايرة البوصلة',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationProgress(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'جاري المعايرة...',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text('حرك جهازك على شكل رقم 8', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _calibrationProgress,
            backgroundColor: theme.dividerColor.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.secondary,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: theme.colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'نصائح للدقة',
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem(context, 'أمسك الجهاز بشكل أفقي'),
          _buildTipItem(context, 'ابتعد عن الأجهزة المعدنية'),
          _buildTipItem(context, 'تأكد من تفعيل خدمات الموقع'),
        ],
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String text) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: theme.colorScheme.secondary.withValues(alpha: 0.7),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.secondary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'جاري تحديد اتجاه القبلة...',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى الانتظار',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'خطأ في تحديد الموقع',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'يرجى التأكد من تفعيل خدمات الموقع والسماح للتطبيق بالوصول إليها',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Retry
                ref.invalidate(qiblaDirectionProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
