import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// A single image entry to place in the fixture's OPF manifest.
typedef FixtureImage = ({String mediaType, List<int> bytes});

/// Builds a minimal but genuinely parsable EPUB 3 archive in memory.
///
/// Defaults to EPUB 3 because `epub_parser`'s EPUB 2 navigation reader requires
/// a full NCX table of contents, while EPUB 3 only needs a `properties="nav"`
/// document — far less boilerplate for a fixture.
///
/// Pass [title] as `null` to omit `<dc:title>` from the OPF entirely, and leave
/// [creators] empty to omit `<dc:creator>`. Those two cases reproduce the
/// real-world EPUBs whose metadata `epub_parser` reports as an empty string.
///
/// [images] maps a manifest `href` (relative to the OPF, e.g. `images/a.webp`)
/// to its declared media type and raw bytes.
///
/// Pass [coverImageHref] — which must be a key of [images] — to emit the legacy
/// `<meta name="cover" content="..."/>` marker in the OPF metadata. That is what
/// makes `epub_parser` go looking for a cover, so it is required to reproduce
/// books whose cover is a format the parser does not classify as an image.
Uint8List buildEpubBytes({
  String version = '3.0',
  String? title = 'Fixture Book',
  List<String> creators = const ['Fixture Author'],
  Map<String, FixtureImage> images = const {},
  Map<String, String> extraManifestEntries = const {},
  String? coverImageHref,
}) {
  const opfDir = 'OEBPS';

  if (coverImageHref != null && !images.containsKey(coverImageHref)) {
    throw ArgumentError.value(
      coverImageHref,
      'coverImageHref',
      'must be one of the keys of `images`',
    );
  }

  // Assigned up front so the cover <meta> below can reference an image by href,
  // even though the manifest entries themselves are written out further down.
  final imageIds = <String, String>{};
  var imageIndex = 0;
  for (final href in images.keys) {
    imageIds[href] = 'img${imageIndex++}';
  }

  final metadata = StringBuffer()
    ..writeln('    <dc:identifier id="pub-id">urn:uuid:fixture</dc:identifier>')
    ..writeln('    <dc:language>en</dc:language>');
  if (title != null) {
    metadata.writeln('    <dc:title>${_escape(title)}</dc:title>');
  }
  for (final creator in creators) {
    metadata.writeln('    <dc:creator>${_escape(creator)}</dc:creator>');
  }
  if (coverImageHref != null) {
    metadata.writeln(
        '    <meta name="cover" content="${imageIds[coverImageHref]}"/>');
  }

  final manifest = StringBuffer()
    ..writeln('    <item id="nav" href="nav.xhtml" '
        'media-type="application/xhtml+xml" properties="nav"/>')
    ..writeln('    <item id="page1" href="page1.xhtml" '
        'media-type="application/xhtml+xml"/>');

  images.forEach((href, image) {
    manifest.writeln('    <item id="${imageIds[href]}" '
        'href="${_escape(href)}" media-type="${_escape(image.mediaType)}"/>');
  });

  var extraIndex = 0;
  extraManifestEntries.forEach((href, mediaType) {
    manifest.writeln('    <item id="extra${extraIndex++}" '
        'href="${_escape(href)}" media-type="${_escape(mediaType)}"/>');
  });

  final opf = '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="$version" unique-identifier="pub-id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
$metadata  </metadata>
  <manifest>
$manifest  </manifest>
  <spine>
    <itemref idref="page1"/>
  </spine>
</package>
''';

  const containerXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="$opfDir/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
''';

  const navXhtml = '''
<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <head><title>Contents</title></head>
  <body>
    <nav epub:type="toc" id="toc">
      <ol><li><a href="page1.xhtml">Page 1</a></li></ol>
    </nav>
  </body>
</html>
''';

  const pageXhtml = '''
<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head><title>Page 1</title></head>
  <body><p>Fixture page.</p></body>
</html>
''';

  final archive = Archive()
    ..addFile(_textFile('mimetype', 'application/epub+zip'))
    ..addFile(_textFile('META-INF/container.xml', containerXml))
    ..addFile(_textFile('$opfDir/content.opf', opf))
    ..addFile(_textFile('$opfDir/nav.xhtml', navXhtml))
    ..addFile(_textFile('$opfDir/page1.xhtml', pageXhtml));

  images.forEach((href, image) {
    archive.addFile(
      ArchiveFile('$opfDir/$href', image.bytes.length, image.bytes),
    );
  });
  extraManifestEntries.forEach((href, _) {
    final bytes = utf8.encode('placeholder');
    archive.addFile(ArchiveFile('$opfDir/$href', bytes.length, bytes));
  });

  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

/// Writes [bytes] to a uniquely named `.epub` inside a temporary directory and
/// returns its path. The directory is removed when [addTearDown] fires.
String writeEpubFixture(
  Uint8List bytes, {
  required void Function(Future<void> Function()) addTearDown,
  String fileName = 'fixture.epub',
}) {
  final dir = Directory.systemTemp.createTempSync('epub_fixture_');
  addTearDown(() async {
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  });
  final file = File('${dir.path}/$fileName')..writeAsBytesSync(bytes);
  return file.path;
}

/// A tiny but valid 1x1 PNG — real bytes so image decoders accept it.
final Uint8List tinyPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// A tiny but valid 1x1 lossy WebP.
final Uint8List tinyWebpBytes = base64Decode(
  'UklGRhoAAABXRUJQVlA4TA0AAAAvAAAAEAcQERGIiP4HAA==',
);

ArchiveFile _textFile(String name, String content) {
  final bytes = utf8.encode(content);
  return ArchiveFile(name, bytes.length, bytes);
}

String _escape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
