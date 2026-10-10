import '../models/photo_entry.dart';

/// Whether [left] and [right] hold the same [PhotoEntry] instances in the
/// same order.
///
/// Identity-based: a scan that produced new instances for files that did not
/// change counts as a change. Both sources — the folder scanner and the
/// MediaStore poll — reuse instances for untouched files, so a replaced file
/// (new instance) is reported as a change by either source, and a stable
/// scan reports no change at all (issue 16).
bool isSamePhotoList(List<PhotoEntry> left, List<PhotoEntry> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (!identical(left[i], right[i])) return false;
  }
  return true;
}