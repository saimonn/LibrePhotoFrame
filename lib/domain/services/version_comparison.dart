/// Semantic versioning helpers, used to decide whether a release is newer than
/// the running build.

/// Compares two versions following the semantic versioning precedence.
///
/// Returns a negative number when [a] is older than [b], zero when both are
/// the same release, and a positive number when [a] is newer. Build metadata
/// (`+28`) is ignored and a prerelease (`1.14.0-beta.2`) ranks below its
/// release (`1.14.0`).
int compareVersions(String a, String b) {
  final coreA = _core(a);
  final coreB = _core(b);
  final length = coreA.length > coreB.length ? coreA.length : coreB.length;
  for (var i = 0; i < length; i++) {
    final x = i < coreA.length ? coreA[i] : 0;
    final y = i < coreB.length ? coreB[i] : 0;
    if (x != y) return x.compareTo(y);
  }

  final preA = _prerelease(a);
  final preB = _prerelease(b);
  if (preA == null && preB == null) return 0;
  if (preA == null) return 1;
  if (preB == null) return -1;
  return _comparePrerelease(preA, preB);
}

/// Whether [tag] looks like a version tag (`v1.2.3`, `v1.2.3-beta.1`) rather
/// than a moving tag such as `dev-latest`.
bool isVersionTag(String tag) => RegExp(r'^v?\d+\.\d+\.\d+').hasMatch(tag);

List<int> _core(String version) => version
    .split('+')
    .first
    .split('-')
    .first
    .split('.')
    .map((part) => int.tryParse(part.trim()) ?? 0)
    .toList();

List<String>? _prerelease(String version) {
  final withoutBuild = version.split('+').first;
  final dash = withoutBuild.indexOf('-');
  if (dash < 0) return null;
  return withoutBuild.substring(dash + 1).split('.');
}

int _comparePrerelease(List<String> a, List<String> b) {
  final length = a.length > b.length ? a.length : b.length;
  for (var i = 0; i < length; i++) {
    if (i >= a.length) return -1; // fewer fields is older
    if (i >= b.length) return 1;
    final x = int.tryParse(a[i]);
    final y = int.tryParse(b[i]);
    if (x != null && y != null) {
      if (x != y) return x.compareTo(y);
    } else if (x != null) {
      return -1; // numeric identifiers rank below alphanumeric ones
    } else if (y != null) {
      return 1;
    } else {
      final cmp = a[i].compareTo(b[i]);
      if (cmp != 0) return cmp;
    }
  }
  return 0;
}
