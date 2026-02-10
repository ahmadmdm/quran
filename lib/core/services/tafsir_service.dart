import 'dart:convert';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';

class TafsirResult {
  final String text;
  final String source;
  final bool fromCache;

  const TafsirResult({
    required this.text,
    required this.source,
    required this.fromCache,
  });
}

class TafsirService {
  TafsirService._();

  static const String _cacheKey = 'tafsir_cache_v1';
  static const Duration _timeout = Duration(seconds: 12);
  static const Duration _cacheValidity = Duration(days: 30);

  static Future<TafsirResult> getTafsir({
    required int surahNumber,
    required int verseNumber,
  }) async {
    final key = '$surahNumber:$verseNumber';
    final now = DateTime.now();

    final box = Hive.box('settings');
    final rawCache = box.get(_cacheKey, defaultValue: <String, dynamic>{});
    final cache = Map<String, dynamic>.from(rawCache as Map);
    final cachedEntryRaw = cache[key];

    if (cachedEntryRaw is Map) {
      final cachedEntry = Map<String, dynamic>.from(cachedEntryRaw);
      final text = (cachedEntry['text'] as String?)?.trim() ?? '';
      final source =
          (cachedEntry['source'] as String?)?.trim().isNotEmpty == true
          ? cachedEntry['source'] as String
          : 'التفسير الميسر';
      final fetchedAtIso = cachedEntry['fetched_at'] as String?;
      if (text.isNotEmpty && fetchedAtIso != null) {
        final fetchedAt = DateTime.tryParse(fetchedAtIso);
        if (fetchedAt != null && now.difference(fetchedAt) <= _cacheValidity) {
          return TafsirResult(text: text, source: source, fromCache: true);
        }
      }
    }

    final fetched = await _fetchFromApi(
      surahNumber: surahNumber,
      verseNumber: verseNumber,
    );
    cache[key] = <String, dynamic>{
      'text': fetched.text,
      'source': fetched.source,
      'fetched_at': now.toIso8601String(),
    };
    await box.put(_cacheKey, cache);
    return fetched;
  }

  static Future<TafsirResult> _fetchFromApi({
    required int surahNumber,
    required int verseNumber,
  }) async {
    final uri = Uri.parse(
      'https://api.alquran.cloud/v1/ayah/$surahNumber:$verseNumber/ar.muyassar',
    );
    final client = HttpClient()..connectionTimeout = _timeout;

    try {
      final request = await client.getUrl(uri).timeout(_timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(_timeout);

      if (response.statusCode != 200) {
        throw const HttpException('tafsir request failed');
      }

      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        throw const FormatException('invalid tafsir payload');
      }

      final data = decoded['data'];
      if (data is! Map) {
        throw const FormatException('missing tafsir data');
      }

      final text = (data['text'] as String?)?.trim() ?? '';
      if (text.isEmpty) {
        throw const FormatException('empty tafsir text');
      }

      final editionRaw = data['edition'];
      String source = 'التفسير الميسر';
      if (editionRaw is Map) {
        final name = (editionRaw['name'] as String?)?.trim();
        if (name != null && name.isNotEmpty) {
          source = name;
        }
      }

      return TafsirResult(text: text, source: source, fromCache: false);
    } finally {
      client.close(force: true);
    }
  }
}
