/// Normalizes a metadata value returned by `epub_parser`.
///
/// `epub_parser` reports missing metadata as an empty string rather than null:
/// `EpubReader` builds the title with `Titles.firstWhere(..., orElse: () => '')`
/// and the author with `AuthorList.join(', ')`. A plain `?? fallback` therefore
/// never fires, which surfaces as a blank book title and an empty author row.
///
/// Returns null when [raw] is null, empty, or whitespace-only, so callers can
/// use `??` to apply their own fallback.
String? normalizeMetadata(String? raw) {
  final trimmed = raw?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
