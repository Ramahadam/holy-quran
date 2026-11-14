import 'dart:convert';
import 'dart:io';

import '../../domain/models/tafsir.dart';
import 'tafsir_repository.dart';

/// Keeps fetched tafsir on the device so revisits work offline.
///
/// Quran Foundation terms forbid storing their content for more than a week,
/// so entries expire after [maxAge] and are deleted, never served.
class CachingTafsirRepository implements TafsirRepository {
  static const maxAge = Duration(days: 7);

  final TafsirRepository inner;
  final Future<Directory> Function() directory;
  final DateTime Function() clock;
  final int maxBytes;
  bool _pruned = false;

  CachingTafsirRepository({
    required this.inner,
    required this.directory,
    this.clock = DateTime.now,
    this.maxBytes = 10 * 1024 * 1024,
  });

  @override
  Future<List<TafsirSource>> getSources() async {
    final cached = await _read('sources.json');
    if (cached is List) {
      try {
        return cached.map(_sourceFromJson).toList(growable: false);
      } catch (_) {
        // Fall through to the network.
      }
    }
    final sources = await inner.getSources();
    await _write('sources.json', [
      for (final source in sources)
        {
          'id': source.id,
          'name': source.name,
          'authorName': source.authorName,
          'languageName': source.languageName,
          'slug': source.slug,
        },
    ]);
    return sources;
  }

  @override
  Future<TafsirPassage> getTafsir({
    required String verseKey,
    required TafsirSource source,
  }) async {
    final name = 'tafsir_${source.id}_${verseKey.replaceAll(':', '_')}.json';
    final cached = await _read(name);
    if (cached is Map && cached['text'] is String) {
      return TafsirPassage(source: source, text: cached['text'] as String);
    }
    final passage = await inner.getTafsir(verseKey: verseKey, source: source);
    await _write(name, {'text': passage.text});
    return passage;
  }

  Future<Object?> _read(String name) async {
    try {
      await _pruneOnce();
      final file = File('${(await directory()).path}/$name');
      if (!await file.exists()) return null;
      if (_isExpired(await file.lastModified())) {
        await file.delete();
        return null;
      }
      return jsonDecode(await file.readAsString());
    } catch (_) {
      return null;
    }
  }

  // The cache is best effort: a full or unwritable disk only costs a refetch.
  Future<void> _write(String name, Object value) async {
    try {
      final dir = await directory();
      await dir.create(recursive: true);
      final file = File('${dir.path}/$name');
      await file.writeAsString(jsonEncode(value), flush: true);
      await file.setLastModified(clock());
      await _prune(dir);
    } catch (_) {
      // Ignore cache write failures.
    }
  }

  Future<void> _pruneOnce() async {
    if (_pruned) return;
    _pruned = true;
    final dir = await directory();
    if (await dir.exists()) await _prune(dir);
  }

  /// Deletes expired entries, then the oldest ones until under [maxBytes].
  Future<void> _prune(Directory dir) async {
    final entries = <(File, FileStat)>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final stat = await entity.stat();
      if (_isExpired(stat.modified)) {
        await entity.delete();
      } else {
        entries.add((entity, stat));
      }
    }
    entries.sort((a, b) => a.$2.modified.compareTo(b.$2.modified));
    var total = entries.fold<int>(0, (sum, entry) => sum + entry.$2.size);
    for (final (file, stat) in entries) {
      if (total <= maxBytes) break;
      await file.delete();
      total -= stat.size;
    }
  }

  bool _isExpired(DateTime modified) => clock().difference(modified) >= maxAge;
}

TafsirSource _sourceFromJson(Object? value) {
  final map = value as Map;
  return TafsirSource(
    id: map['id'] as int,
    name: map['name'] as String,
    authorName: map['authorName'] as String,
    languageName: map['languageName'] as String,
    slug: map['slug'] as String,
  );
}
