import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// GPS Accuracy levels for location fetching
enum GpsAccuracyLevel {
  low, // Fast but less accurate (100m)
  medium, // Balanced (10-100m)
  high, // More accurate (0-10m)
  best, // Best possible accuracy (may take longer)
}

class LocationService {
  /// Default accuracy level
  static GpsAccuracyLevel _accuracyLevel = GpsAccuracyLevel.high;

  /// Set the GPS accuracy level
  static void setAccuracyLevel(GpsAccuracyLevel level) {
    _accuracyLevel = level;
  }

  /// Get current accuracy level
  static GpsAccuracyLevel get accuracyLevel => _accuracyLevel;

  /// Convert accuracy level to Geolocator's LocationAccuracy
  LocationAccuracy _getLocationAccuracy() {
    switch (_accuracyLevel) {
      case GpsAccuracyLevel.low:
        return LocationAccuracy.low;
      case GpsAccuracyLevel.medium:
        return LocationAccuracy.medium;
      case GpsAccuracyLevel.high:
        return LocationAccuracy.high;
      case GpsAccuracyLevel.best:
        return LocationAccuracy.best;
    }
  }

  /// Get timeout based on accuracy level
  Duration _getTimeout() {
    switch (_accuracyLevel) {
      case GpsAccuracyLevel.low:
        return const Duration(seconds: 5);
      case GpsAccuracyLevel.medium:
        return const Duration(seconds: 10);
      case GpsAccuracyLevel.high:
        return const Duration(seconds: 15);
      case GpsAccuracyLevel.best:
        return const Duration(seconds: 30);
    }
  }

  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: _getLocationAccuracy(),
      timeLimit: _getTimeout(),
    );
  }

  /// Get position with specific accuracy level (override default)
  Future<Position> determinePositionWithAccuracy(
    GpsAccuracyLevel accuracy,
  ) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    LocationAccuracy geoAccuracy;
    Duration timeout;

    switch (accuracy) {
      case GpsAccuracyLevel.low:
        geoAccuracy = LocationAccuracy.low;
        timeout = const Duration(seconds: 5);
        break;
      case GpsAccuracyLevel.medium:
        geoAccuracy = LocationAccuracy.medium;
        timeout = const Duration(seconds: 10);
        break;
      case GpsAccuracyLevel.high:
        geoAccuracy = LocationAccuracy.high;
        timeout = const Duration(seconds: 15);
        break;
      case GpsAccuracyLevel.best:
        geoAccuracy = LocationAccuracy.best;
        timeout = const Duration(seconds: 30);
        break;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: geoAccuracy,
      timeLimit: timeout,
    );
  }

  Future<String?> getCityName(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        // Try locality (city) first, then administrativeArea (state/province), then country
        return placemarks.first.locality ??
            placemarks.first.subAdministrativeArea ??
            placemarks.first.administrativeArea;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get accuracy description in Arabic
  static String getAccuracyDescription(GpsAccuracyLevel level) {
    switch (level) {
      case GpsAccuracyLevel.low:
        return 'منخفضة (سريع)';
      case GpsAccuracyLevel.medium:
        return 'متوسطة';
      case GpsAccuracyLevel.high:
        return 'عالية';
      case GpsAccuracyLevel.best:
        return 'أفضل دقة';
    }
  }

  /// Get accuracy range description
  static String getAccuracyRange(GpsAccuracyLevel level) {
    switch (level) {
      case GpsAccuracyLevel.low:
        return '~100 متر';
      case GpsAccuracyLevel.medium:
        return '10-100 متر';
      case GpsAccuracyLevel.high:
        return '0-10 متر';
      case GpsAccuracyLevel.best:
        return 'أقل من 5 متر';
    }
  }
}
