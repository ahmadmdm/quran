import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../core/localization/app_localizations.dart';
import '../providers/prayer_provider.dart';

class QiblaMapPage extends ConsumerStatefulWidget {
  const QiblaMapPage({super.key});

  @override
  ConsumerState<QiblaMapPage> createState() => _QiblaMapPageState();
}

class _QiblaMapPageState extends ConsumerState<QiblaMapPage> {
  static const LatLng _mecca = LatLng(21.4225, 39.8262);
  final MapController _mapController = MapController();
  StreamSubscription<CompassEvent>? _compassSubscription;
  double _heading = 0;

  @override
  void initState() {
    super.initState();
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      final h = event.heading ?? event.headingForCameraMode ?? 0;
      setState(() => _heading = h);
      try {
        _mapController.rotate(h);
      } catch (_) {
        // Map might not be ready in first frames.
      }
    });
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final locationAsync = ref.watch(userLocationProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(localizations.translate('qibla_map')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: locationAsync.when(
        data: (coordinates) {
          final userLocation = LatLng(
            coordinates.latitude,
            coordinates.longitude,
          );

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userLocation,
              initialZoom: 6.0,
              initialRotation: _heading,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.luxury.prayer',
              ),
              PolylineLayer(
                polylines: <Polyline<Object>>[
                  Polyline<Object>(
                    points: [userLocation, _mecca],
                    strokeWidth: 4.0,
                    color: Theme.of(context).colorScheme.secondary,
                    pattern: const StrokePattern.dotted(),
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: userLocation,
                    width: 40,
                    height: 40,
                    child: Transform.rotate(
                      angle: _heading * (math.pi / 180),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.navigation,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  Marker(
                    point: _mecca,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.mosque,
                      color: Colors.black,
                      size: 40,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    'اتجاه الجوال: ${_heading.toStringAsFixed(0)}°',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: FloatingActionButton.small(
                    heroTag: 'qibla_map_recenter',
                    onPressed: () {
                      _mapController.move(userLocation, _mapController.camera.zoom);
                      _mapController.rotate(_heading);
                    },
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}
