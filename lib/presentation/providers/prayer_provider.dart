import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import '../../core/utils/location_service.dart';
import 'settings_provider.dart';

part 'prayer_provider.g.dart';

@riverpod
Future<Position> userLocation(UserLocationRef ref) async {
  final service = LocationService();
  return await service.determinePosition();
}

@riverpod
Future<PrayerTimes> prayerTimes(PrayerTimesRef ref) async {
  final position = await ref.watch(userLocationProvider.future);
  final settings = ref.watch(settingsProvider);

  final myCoordinates = Coordinates(position.latitude, position.longitude);
  final params = settings.calculationMethod.getParameters();
  params.madhab = settings.madhab;

  final prayerTimes = PrayerTimes.today(myCoordinates, params);
  return prayerTimes;
}

@riverpod
Future<double> qiblaDirection(QiblaDirectionRef ref) async {
  final position = await ref.watch(userLocationProvider.future);
  final myCoordinates = Coordinates(position.latitude, position.longitude);
  return Qibla(myCoordinates).direction;
}

@riverpod
Future<String?> cityName(CityNameRef ref) async {
  final position = await ref.watch(userLocationProvider.future);
  final service = LocationService();
  return await service.getCityName(position);
}
