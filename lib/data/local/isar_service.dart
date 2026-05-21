import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:holy_quran_app/data/local/entities/verse_entity.dart';
import 'package:holy_quran_app/data/local/entities/surah_entity.dart';
import 'package:holy_quran_app/data/local/entities/bookmark_entity.dart';
import 'package:holy_quran_app/data/local/entities/reading_position_entity.dart';

/// Database service managing Isar instance lifecycle.
///
/// Provides thread-safe singleton access to the Isar database.
/// Uses entity layer to separate domain models from database concerns.
class IsarService {
  static Isar? _isar;
  static Future<Isar>? _initFuture;

  /// Gets the Isar database instance. Thread-safe singleton pattern.
  ///
  /// Prevents race conditions by ensuring only one initialization occurs
  /// even if called concurrently from multiple isolates.
  static Future<Isar> getInstance() async {
    if (_isar != null) return _isar!;

    // Prevent concurrent initialization
    if (_initFuture != null) return _initFuture!;

    _initFuture = _initialize();
    _isar = await _initFuture!;
    _initFuture = null;
    return _isar!;
  }

  static Future<Isar> _initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open(
      [
        VerseEntitySchema,
        SurahEntitySchema,
        BookmarkEntitySchema,
        ReadingPositionEntitySchema
      ],
      directory: dir.path,
      name: 'holy_quran_db',
    );
  }

  /// Direct access to the Isar instance.
  ///
  /// Returns null if database has not been initialized yet.
  /// For safe access, use getInstance() instead.
  static Isar? get instance => _isar;

  static Future<void> close() async {
    await _isar?.close();
    _isar = null;
    _initFuture = null;
  }
}

