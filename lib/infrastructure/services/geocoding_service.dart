import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'photo_metadata_database.dart';

/// Service for reverse geocoding (coordinates → place name)
/// Uses OpenStreetMap Nominatim API (free, no API key required)
///
/// Results are cached in the [PhotoMetadataDatabase], keyed by the rounded
/// coordinate. Concurrent requests for the same coordinate share one HTTP call
/// (single-flight), so a frame showing two photos of the same place fires one
/// request instead of two. Without a database the service degrades to the
/// network call only.
class GeocodingService {
  GeocodingService({PhotoMetadataDatabase? database, http.Client? client})
      : _database = database,
        _client = client;

  final PhotoMetadataDatabase? _database;

  /// Optional HTTP client, injected by tests. Production uses the stateless
  /// [http.get] helper, which creates and closes a client per request.
  final http.Client? _client;
  final _log = Logger('GeocodingService');

  /// In-memory single-flight map: coordinate key → in-flight request.
  /// A request is removed once it completed, so the next frame re-checks the
  /// database instead of the network.
  final Map<String, Future<String?>> _inFlight = {};

  /// User-Agent required by Nominatim usage policy
  static const String _userAgent = 'LibrePhotoFrame/1.0';

  /// Rounding of coordinates for the cache key (~100m precision)
  static const int _rounding = 3;

  /// Maximum age of cached entries (3 months)
  static const Duration _maxCacheAge = Duration(days: 90);

  bool _pruned = false;

  /// Reverse geocode coordinates to a place name
  /// Returns format: "City, State, Country" or null if failed
  Future<String?> getLocationName(double latitude, double longitude) async {
    if (!_pruned) {
      _pruned = true;
      _database?.prunePlacesOlderThan(_maxCacheAge);
    }

    final key = _cacheKey(latitude, longitude);
    final inFlight = _inFlight[key];
    if (inFlight != null) return inFlight;

    final future = _resolve(key, latitude, longitude).whenComplete(() {
      _inFlight.remove(key);
    });
    _inFlight[key] = future;
    return future;
  }

  Future<String?> _resolve(
    String key,
    double latitude,
    double longitude,
  ) async {
    final db = _database;

    final cached = db?.place(key);
    if (cached != null) {
      // Cached result, including a cached miss (null name).
      return cached.name;
    }

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$latitude'
        '&lon=$longitude'
        '&format=json'
        '&zoom=10' // City level
        '&addressdetails=1',
      );

      const headers = {
        'User-Agent': _userAgent,
        'Accept-Language': 'de,en', // Prefer German, fallback English
      };
      final response = _client != null
          ? await _client.get(url, headers: headers)
              .timeout(const Duration(seconds: 5))
          : await http.get(url, headers: headers)
              .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        _log.warning('Geocoding failed: HTTP ${response.statusCode}');
        // Don't cache HTTP errors - might be temporary
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final address = json['address'] as Map<String, dynamic>?;

      final result = address == null ? null : _buildName(address);
      db?.savePlace(key, result);

      _log.fine('Geocoded ($latitude, $longitude) → $result');
      return result;
    } catch (e) {
      _log.warning('Geocoding error for ($latitude, $longitude): $e');
      // Don't cache network errors - might be temporary
      return null;
    }
  }

  /// Builds "City, State, Country" from the Nominatim address block, or null
  /// when the place has no readable name.
  static String? _buildName(Map<String, dynamic> address) {
    final parts = <String>[];

    // City (try multiple fields)
    final city = address['city'] ??
        address['town'] ??
        address['village'] ??
        address['municipality'] ??
        address['county'];
    if (city != null) parts.add(city.toString());

    // State/Region
    final state = address['state'];
    if (state != null) parts.add(state.toString());

    // Country
    final country = address['country'];
    if (country != null) parts.add(country.toString());

    return parts.isNotEmpty ? parts.join(', ') : null;
  }

  /// Cache key for a coordinate pair: 3 decimal digits ≈ 100 m.
  static String _cacheKey(double latitude, double longitude) =>
      '${latitude.toStringAsFixed(_rounding)},${longitude.toStringAsFixed(_rounding)}';

  /// Clears the geocoding cache (beyond the age-based pruning that happens
  /// automatically).
  Future<void> clearCache() async {
    _database?.clearPlaces();
  }
}