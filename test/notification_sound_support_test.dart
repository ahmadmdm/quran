import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_app/core/utils/notification_sound_support.dart';

void main() {
  group('normalizeNotificationSound', () {
    test('returns system for null and unknown values', () {
      expect(normalizeNotificationSound(null), 'system');
      expect(normalizeNotificationSound('unknown'), 'system');
    });

    test('returns silent for silent value', () {
      expect(normalizeNotificationSound('silent'), 'silent');
    });

    test('respects azan support flag', () {
      final normalized = normalizeNotificationSound('azan');
      if (kHasBundledAzanSound) {
        expect(normalized, 'azan');
      } else {
        expect(normalized, 'system');
      }
    });
  });

  group('availableNotificationSounds', () {
    test('always includes system and silent', () {
      final values = availableNotificationSounds();
      expect(values.contains('system'), isTrue);
      expect(values.contains('silent'), isTrue);
    });

    test('contains azan only when bundled sound is enabled', () {
      final values = availableNotificationSounds();
      expect(values.contains('azan'), kHasBundledAzanSound);
    });
  });
}
