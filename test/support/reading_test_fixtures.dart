import 'package:holy_quran_app/data/feedback/feedback_prompt_service.dart';
import 'package:holy_quran_app/data/repositories/reading_position_repository.dart';
import 'package:holy_quran_app/domain/models/reading_position.dart';
import 'package:holy_quran_app/domain/models/surah.dart';
import 'package:holy_quran_app/domain/models/verse.dart';

const classicSurah1 = Surah(
  surahNumber: 1,
  nameArabic: 'الفاتحة',
  nameEnglish: 'The Opening',
  numberOfVerses: 7,
);

const classicSurah112 = Surah(
  surahNumber: 112,
  nameArabic: 'الإخلاص',
  nameEnglish: 'Sincerity',
  numberOfVerses: 4,
);

const classicVerse1 = Verse(
  verseId: '1:1',
  surahNumber: 1,
  verseNumber: 1,
  arabicText: 'بِسْمِ اللَّهِ',
  translation: 'In the name of Allah',
);

const classicVerse2 = Verse(
  verseId: '1:2',
  surahNumber: 1,
  verseNumber: 2,
  arabicText: 'ٱلْحَمْدُ لِلَّهِ',
  translation: 'Praise be to Allah',
);

const classicVerse112 = Verse(
  verseId: '112:1',
  surahNumber: 112,
  verseNumber: 1,
  arabicText: 'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
  page: 604,
);

const classicBismillah = 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ';

List<Verse> classicSurahVerses(int count) => List.generate(
  count,
  (index) => Verse(
    verseId: '1:${index + 1}',
    surahNumber: 1,
    verseNumber: index + 1,
    arabicText: 'آية ${index + 1}',
    translation: 'Verse ${index + 1}',
  ),
);

class FakeReadingPositionRepository implements ReadingPositionRepository {
  ReadingPosition? savedPosition;

  @override
  Future<void> clearPosition() async {
    savedPosition = null;
  }

  @override
  Future<ReadingPosition?> getLastPosition() async => savedPosition;

  @override
  Future<void> savePosition(ReadingPosition position) async {
    savedPosition = position;
  }
}

class FakeFeedbackPromptService implements FeedbackPromptController {
  int recordedSessions = 0;

  @override
  Future<void> dismissPrompt({DateTime? now}) async {}

  @override
  Future<void> markFeedbackSubmitted({DateTime? now}) async {}

  @override
  Future<void> recordReadingSession({DateTime? now}) async {
    recordedSessions++;
  }

  @override
  Future<bool> shouldPrompt({DateTime? now}) async => false;
}
