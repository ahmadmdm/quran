const bool kHasBundledAzanSound = bool.fromEnvironment(
  'HAS_AZAN_SOUND',
  defaultValue: false,
);

List<String> availableNotificationSounds() {
  if (kHasBundledAzanSound) return const ['azan', 'system', 'silent'];
  return const ['system', 'silent'];
}

String normalizeNotificationSound(String? sound) {
  if (sound == 'azan') {
    return kHasBundledAzanSound ? 'azan' : 'system';
  }
  if (sound == 'silent') return 'silent';
  return 'system';
}
