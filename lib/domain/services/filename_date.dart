/// Capture date recovered from a file name.
///
/// Photos synced from a phone (WhatsApp, Telegram, ...) often carry neither
/// EXIF nor a usable file time: WhatsApp strips the metadata and stamps the
/// file with the moment it received it, and Syncthing keeps that time. The
/// name is then the only capture date left:
///
///   IMG-20261224-WA0001.jpg      WhatsApp
///   IMG_20261224_133700.jpg      Android camera
///   PXL_20261224_133700123.jpg   Pixel
///   Screenshot_20261224-133700   Android screenshot
///   2026-12-24_13-37-00.jpg      generic
///
/// The time part is optional (midnight is used when absent). Anything that is
/// not a valid calendar date is ignored, so unrelated numbers in a name do not
/// turn into dates.
class FilenameDate {
  /// `YYYYMMDD` possibly followed by `HHMM` / `HHMMSS` (extra digits ignored).
  static final RegExp _compact = RegExp(
    r'(?<!\d)(\d{4})(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])'
    r'(?:[ _\-T]?(\d{2})(\d{2})(\d{2})?\d*)?(?!\d)',
  );

  /// `YYYY-MM-DD` (or `/` `_`) possibly followed by `HH:MM[:SS]` / `HH-MM-SS`.
  static final RegExp _separated = RegExp(
    r'(?<!\d)(\d{4})[-_/](\d{1,2})[-_/](\d{1,2})'
    r'(?:[ _\-T]?(\d{1,2})[-:](\d{2})(?:[-:](\d{2}))?)?(?!\d)',
  );

  /// Returns the date encoded in [path] (only the last segment is looked at),
  /// or null when the name carries none.
  static DateTime? parse(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    return _match(_compact, name) ?? _match(_separated, name);
  }

  static DateTime? _match(RegExp pattern, String name) {
    final m = pattern.firstMatch(name);
    if (m == null) return null;
    return _build(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
      m.group(4),
      m.group(5),
      m.group(6),
    );
  }

  static DateTime? _build(
    int year,
    int month,
    int day,
    String? hour,
    String? minute,
    String? second,
  ) {
    if (year < 1900 || year > 2100) return null;
    var h = hour == null ? 0 : int.parse(hour);
    var mi = minute == null ? 0 : int.parse(minute);
    var s = second == null ? 0 : int.parse(second);
    if (h > 23 || mi > 59 || s > 59) {
      h = 0;
      mi = 0;
      s = 0;
    }
    final date = DateTime(year, month, day, h, mi, s);
    // DateTime normalises out-of-range values (Feb 30 -> Mar 02), so check back.
    if (date.year != year || date.month != month || date.day != day) return null;
    return date;
  }
}
