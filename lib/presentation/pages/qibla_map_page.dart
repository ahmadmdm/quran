import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:adhan/adhan.dart';
import '../../core/localization/app_localizations.dart';
import '../providers/prayer_provider.dart';

class QiblaMapPage extends ConsumerStatefulWidget {
  const QiblaMapPage({super.key});

  @override
  ConsumerState<QiblaMapPage> createState() => _QiblaMapPageState();
}

class _QiblaMapPageState extends ConsumerState<QiblaMapPage> {
  static const LatLng _mecca = LatLng(21.4225, 39.8262);

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
          final qibla = Qibla(
            Coordinates(coordinates.latitude, coordinates.longitude),
          );

          return FlutterMap(
            options: MapOptions(initialCenter: userLocation, initialZoom: 4.0),
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
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 40,
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
