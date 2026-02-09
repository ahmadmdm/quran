import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_app/core/utils/widget_service.dart';

void main() {
  group('WidgetService.parseWidgetColorHex', () {
    test('parses #AARRGGBB correctly', () {
      expect(
        WidgetService.parseWidgetColorHex('#FF112233', 0x00000000),
        0xFF112233,
      );
    });

    test('parses AARRGGBB without hash', () {
      expect(
        WidgetService.parseWidgetColorHex('80112233', 0x00000000),
        0x80112233,
      );
    });

    test('falls back for null or malformed values', () {
      expect(WidgetService.parseWidgetColorHex(null, 0xFFABCDEF), 0xFFABCDEF);
      expect(WidgetService.parseWidgetColorHex('', 0xFFABCDEF), 0xFFABCDEF);
      expect(
        WidgetService.parseWidgetColorHex('#112233', 0xFFABCDEF),
        0xFFABCDEF,
      );
      expect(
        WidgetService.parseWidgetColorHex('not_hex', 0xFFABCDEF),
        0xFFABCDEF,
      );
    });
  });
}
