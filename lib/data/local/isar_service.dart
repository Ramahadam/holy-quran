import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:holy_quran_app/domain/models/verse.dart';
import 'package:holy_quran_app/domain/models/surah.dart';
import 'package:holy_quran_app/domain/models/bookmark.dart';
import 'package:holy_quran_app/domain/models/reading_position.dart';

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
      [VerseSchema, SurahSchema, BookmarkSchema, ReadingPositionSchema],
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
