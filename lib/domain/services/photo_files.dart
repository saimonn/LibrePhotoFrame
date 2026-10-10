/// File-name helpers shared by every photo source (folder scan, MediaStore,
/// WebDAV sync, local folder counts), so the set of supported formats lives in
/// exactly one place (issue 16).
library;

/// Image formats the frame accepts as photos.
const Set<String> _imageExtensions = {'.jpg', '.jpeg', '.png', '.webp'};

/// Whether [path] names an image of a supported format, case-insensitively.
bool isImageFile(String path) {
  final lower = path.toLowerCase();
  return _imageExtensions.any(lower.endsWith);
}