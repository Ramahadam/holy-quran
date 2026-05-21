import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:holy_quran_app/domain/models/verse.dart';
import 'package:holy_quran_app/domain/models/surah.dart';
import 'package:holy_quran_app/domain/models/bookmark.dart';
import 'package:holy_quran_app/domain/models/reading_position.dart';

class IsarService {
  static Isar? _isar;

  static Future<Isar> getInstance() async {
    if (_isar != null) return _isar!;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [VerseSchema, SurahSchema, BookmarkSchema, ReadingPositionSchema],
      directory: dir.path,
      name: 'holy_quran_db',
    );
    return _isar!;
  }

  static Isar? get instance => _isar;

  static Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
