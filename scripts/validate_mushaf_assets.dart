import 'dart:convert';
import 'dart:io';

const _firstPage = 1;
const _lastPage = 604;
const _imageDirectory = 'assets/mushaf/madani-images';
const _coordinatesPath =
    'assets/mushaf/madani-svg-sample/coordinates.sample.json';

void main(List<String> args) {
  final allowSample = args.contains('--allow-sample');
  final missingImages = _missingImagePages();
  final coordinateErrors = _coordinateErrors();

  if (missingImages.isEmpty && coordinateErrors.isEmpty) {
    stdout.writeln('Mushaf assets validated for $_lastPage pages.');
    return;
  }

  if (allowSample && missingImages.isNotEmpty) {
    stdout.writeln(
      'Sample Mushaf assets validated. Full image set is not installed.',
    );
    _printCoordinateErrors(coordinateErrors);
    if (coordinateErrors.isEmpty) return;
  }

  if (missingImages.isNotEmpty) {
    stderr.writeln('Missing ${missingImages.length} Mushaf page images.');
    stderr.writeln('First missing pages: ${missingImages.take(20).join(', ')}');
  }
  _printCoordinateErrors(coordinateErrors);

  exitCode = 1;
}

List<String> _missingImagePages() {
  final missing = <String>[];
  for (var page = _firstPage; page <= _lastPage; page += 1) {
    final pageName = page.toString().padLeft(3, '0');
    final png = File('$_imageDirectory/$pageName.png');
    if (!png.existsSync()) {
      missing.add(pageName);
    }
  }
  return missing;
}

List<String> _coordinateErrors() {
  final file = File(_coordinatesPath);
  if (!file.existsSync()) {
    return ['Coordinate file is missing: $_coordinatesPath'];
  }

  final errors = <String>[];
  final root = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  final pages = root['pages'];
  if (pages is! List) {
    return ['Coordinate file does not contain a pages list.'];
  }

  for (final pageData in pages) {
    if (pageData is! Map<String, Object?>) {
      errors.add('Coordinate page entry is not an object.');
      continue;
    }

    final page = pageData['page'];
    if (page is! num || page < _firstPage || page > _lastPage) {
      errors.add('Coordinate page is outside 1-604: $page');
    }

    final items = pageData['items'];
    if (items is! List || items.isEmpty) {
      errors.add('Coordinate page $page has no hit regions.');
    }
  }

  return errors;
}

void _printCoordinateErrors(List<String> errors) {
  if (errors.isEmpty) return;
  stderr.writeln('Coordinate errors:');
  for (final error in errors) {
    stderr.writeln('- $error');
  }
}
