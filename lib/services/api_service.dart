import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:shared_preferences/shared_preferences.dart';
import 'downloader.dart';
import 'project_store.dart';

/// Thrown for any non-success API response. Carries the HTTP status and a
/// user-safe message (the server's `error` field when present).
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});
  bool get isUnauthorized => statusCode == 401;
  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = "https://archiquant.in";
  static const Duration _timeout = Duration(seconds: 30);

  // ═══════════════════════════════════════════════════════
  // TOKEN HELPERS
  // ═══════════════════════════════════════════════════════
  // In-memory copy of the access token so the route guard can answer
  // "is the user logged in?" synchronously.
  static String? _cachedToken;

  static bool get isLoggedIn => (_cachedToken ?? '').isNotEmpty;

  /// Load the persisted access token into the cache. Call once at startup.
  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('token');
  }

  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('token');
    return _cachedToken;
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> _saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('refresh_token', token);
  }

  static Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refresh_token');
  }

  // ═══════════════════════════════════════════════════════
  // CORE REQUEST PLUMBING
  // Every authenticated call funnels through _send → _request, which:
  //  • attaches the bearer token + a timeout,
  //  • on 401, transparently refreshes the access token once and retries,
  //  • if refresh fails, signals global session-expiry (router → /login),
  //  • decodes JSON with status-code checks (no raw FormatException leaks).
  // ═══════════════════════════════════════════════════════

  static Future<http.Response> _send(
    String method,
    String path, {
    Object? body,
    bool auth = true,
    bool retried = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final t = await getToken();
      if (t != null) headers['Authorization'] = 'Bearer $t';
    }
    final encoded = body != null ? jsonEncode(body) : null;

    http.Response res;
    switch (method) {
      case 'GET':
        res = await http.get(uri, headers: headers).timeout(_timeout);
        break;
      case 'POST':
        res = await http.post(uri, headers: headers, body: encoded).timeout(_timeout);
        break;
      case 'PUT':
        res = await http.put(uri, headers: headers, body: encoded).timeout(_timeout);
        break;
      case 'PATCH':
        res = await http.patch(uri, headers: headers, body: encoded).timeout(_timeout);
        break;
      case 'DELETE':
        res = await http.delete(uri, headers: headers).timeout(_timeout);
        break;
      default:
        throw ArgumentError('Unsupported method $method');
    }

    if (auth && res.statusCode == 401 && !retried) {
      if (await _refreshAccessToken()) {
        return _send(method, path, body: body, auth: auth, retried: true);
      }
      await _onSessionExpired();
    }
    return res;
  }

  static Future<dynamic> _request(String method, String path, {Object? body, bool auth = true}) async {
    final res = await _send(method, path, body: body, auth: auth);
    return _decode(res);
  }

  static dynamic _decode(http.Response res) {
    if (res.statusCode == 401) {
      throw const ApiException('Your session has expired. Please sign in again.', statusCode: 401);
    }
    dynamic parsed;
    if (res.body.isNotEmpty) {
      try {
        parsed = jsonDecode(res.body);
      } catch (_) {
        if (res.statusCode >= 200 && res.statusCode < 300) return null;
        throw ApiException('Unexpected server response (${res.statusCode}).', statusCode: res.statusCode);
      }
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return parsed;
    final msg = (parsed is Map && parsed['error'] is String)
        ? parsed['error'] as String
        : 'Request failed (${res.statusCode}).';
    throw ApiException(msg, statusCode: res.statusCode);
  }

  static Future<Map<String, dynamic>> _requestMap(String method, String path, {Object? body, bool auth = true}) async {
    final data = await _request(method, path, body: body, auth: auth);
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  static Future<List<dynamic>> _requestList(String method, String path, {Object? body, bool auth = true}) async {
    final data = await _request(method, path, body: body, auth: auth);
    return data is List ? data : <dynamic>[];
  }

  static Future<bool> _refreshAccessToken() async {
    final rt = await getRefreshToken();
    if (rt == null || rt.isEmpty) return false;
    try {
      final res = await http
          .post(Uri.parse('$baseUrl/auth/refresh'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'refresh_token': rt}))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['token'] != null) {
          await saveToken(data['token']);
          return true;
        }
      }
    } catch (_) {/* fall through to false */}
    return false;
  }

  // Called when the session can't be recovered. Clears tokens and pings the
  // router (via gSessionExpired) to redirect to /login.
  static Future<void> _onSessionExpired() async {
    await clearToken();
    gSessionExpired.value = !gSessionExpired.value;
  }

  // ═══════════════════════════════════════════════════════
  // AUTH
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> register(
    String companyName,
    String slug,
    String email,
    String password, {
    String plan = 'starter',
    String phone = '',
  }) async {
    // Like login(): return the server's body so the form can show a real error
    // (e.g. "company ID already taken") instead of a generic thrown exception.
    final res = await _send('POST', '/auth/register', auth: false, body: {
      'company_name': companyName,
      'company_slug': slug,
      'email': email,
      'password': password,
      'plan': plan,
      'phone': phone,
    });
    Map<String, dynamic> data;
    try {
      data = (jsonDecode(res.body) as Map).cast<String, dynamic>();
    } catch (_) {
      throw const ApiException('Could not reach the server. Please try again.');
    }
    await _persistSession(data);
    return data;
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
    String companySlug,
  ) async {
    // Login is special: we want the server's error body (wrong password etc.)
    // surfaced to the form rather than thrown, so decode without _request.
    final res = await _send('POST', '/auth/login', auth: false, body: {
      'email': email,
      'password': password,
      'company_slug': companySlug,
    });
    Map<String, dynamic> data;
    try {
      data = (jsonDecode(res.body) as Map).cast<String, dynamic>();
    } catch (_) {
      throw const ApiException('Could not reach the server. Please try again.');
    }
    await _persistSession(data);
    return data;
  }

  static Future<void> _persistSession(Map<String, dynamic> data) async {
    if (data['token'] != null) {
      await saveToken(data['token']);
      if (data['refresh_token'] != null) await _saveRefreshToken(data['refresh_token']);
      gSessionExpired.value = false;
    }
  }

  static Future<void> logout() async => clearToken();

  // ═══════════════════════════════════════════════════════
  // USER PROFILE
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getProfile() => _requestMap('GET', '/profile');

  static Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String phone,
  }) =>
      _requestMap('PATCH', '/profile', body: {'full_name': fullName, 'phone': phone});

  // ═══════════════════════════════════════════════════════
  // PROJECTS
  // ═══════════════════════════════════════════════════════

  static Future<List<dynamic>> getProjects() => _requestList('GET', '/projects');

  // Latest saved plan for a project. Returns null on any failure (callers treat
  // null as "no plan yet").
  static Future<Map<String, dynamic>?> getProjectPlan(String projectId) async {
    try {
      final res = await _send('GET', '/projects/$projectId/plan');
      if (res.statusCode == 200) return (jsonDecode(res.body) as Map).cast<String, dynamic>();
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>> createProject(String name, String description) =>
      _requestMap('POST', '/projects', body: {'name': name, 'description': description});

  static Future<Map<String, dynamic>> getProject(String id) => _requestMap('GET', '/projects/$id');

  // ═══════════════════════════════════════════════════════
  // FLOOR PLANS / OCR UPLOAD
  // ═══════════════════════════════════════════════════════

  // Map a filename to its MIME type so the multipart part isn't sent as
  // application/octet-stream (which the server's file-type filter rejects).
  static MediaType _contentTypeFor(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.pdf')) return MediaType('application', 'pdf');
    if (n.endsWith('.png')) return MediaType('image', 'png');
    if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return MediaType('image', 'jpeg');
    return MediaType('application', 'octet-stream');
  }

  static Future<Map<String, dynamic>> uploadBlueprint(
    String projectId,
    List<int> bytes,
    String fileName,
  ) async {
    Future<http.StreamedResponse> doSend() async {
      final token = await getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/projects/$projectId/floor-plans'),
      );
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes(
        'file', bytes,
        filename: fileName,
        contentType: _contentTypeFor(fileName),
      ));
      return request.send().timeout(const Duration(seconds: 180));
    }

    var resp = await doSend();
    if (resp.statusCode == 401) {
      if (await _refreshAccessToken()) {
        resp = await doSend();
      } else {
        await _onSessionExpired();
      }
    }
    final bodyStr = await resp.stream.bytesToString();
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      String msg = 'Upload failed (${resp.statusCode}).';
      try {
        final m = jsonDecode(bodyStr);
        if (m is Map && m['error'] is String) msg = m['error'];
      } catch (_) {}
      throw ApiException(msg, statusCode: resp.statusCode);
    }
    return (jsonDecode(bodyStr) as Map).cast<String, dynamic>();
  }

  // ═══════════════════════════════════════════════════════
  // SAVE ROOM COMPONENTS / CALCULATION
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> saveRoomComponents(
    String projectId,
    Map<String, dynamic> components,
  ) =>
      _requestMap('PUT', '/projects/$projectId/components', body: {'components': components});

  static Future<Map<String, dynamic>> calculateBricksWithTypes(
    String projectId, {
    Map<String, String> brickTypeMap = const {
      "9": "red_brick",
      "6": "white_cement",
      "4": "white_cement",
    },
  }) =>
      _requestMap('POST', '/projects/$projectId/calculate', body: {'brick_type_map': brickTypeMap});

  // ═══════════════════════════════════════════════════════
  // ESTIMATIONS
  // ═══════════════════════════════════════════════════════

  static Future<List<dynamic>> getEstimations(String projectId) =>
      _requestList('GET', '/projects/$projectId/estimations');

  static Future<Map<String, dynamic>> createEstimation(String projectId, Map<String, dynamic> payload) =>
      _requestMap('POST', '/projects/$projectId/estimations', body: payload);

  // ═══════════════════════════════════════════════════════
  // MATERIAL CONFIGS
  // ═══════════════════════════════════════════════════════

  static Future<List<dynamic>> getMaterialConfigs() => _requestList('GET', '/material-configs');

  static Future<Map<String, dynamic>> createMaterialConfig(Map<String, dynamic> payload) =>
      _requestMap('POST', '/material-configs', body: payload);

  // ═══════════════════════════════════════════════════════
  // FORMULAS
  // ═══════════════════════════════════════════════════════

  static Future<List<dynamic>> getFormulas() => _requestList('GET', '/formulas');

  static Future<Map<String, dynamic>> updateFormula(String id, String expression, String description) =>
      _requestMap('PATCH', '/formulas/$id', body: {'expression': expression, 'description': description});

  // ═══════════════════════════════════════════════════════
  // COMPANY SETTINGS
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getSettings() => _requestMap('GET', '/settings');

  static Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> payload) =>
      _requestMap('PATCH', '/settings', body: payload);

  // ═══════════════════════════════════════════════════════
  // MASTER RATES
  // ═══════════════════════════════════════════════════════

  static Future<List<dynamic>> getMasterRates() => _requestList('GET', '/master-rates');

  static Future<Map<String, dynamic>> updateMasterRate(String id, Map<String, dynamic> payload) =>
      _requestMap('PATCH', '/master-rates/$id', body: payload);

  static Future<Map<String, dynamic>> addMasterRate(Map<String, dynamic> payload) =>
      _requestMap('POST', '/master-rates', body: payload);

  static Future<Map<String, dynamic>> deleteMasterRate(String id) =>
      _requestMap('DELETE', '/master-rates/$id');

  static Future<Map<String, dynamic>> seedMasterRates() => _requestMap('POST', '/master-rates/seed');

  // ═══════════════════════════════════════════════════════
  // REVIEW & BUDGET / TAKEOFF
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getReviewBudget(String projectId) =>
      _requestMap('GET', '/projects/$projectId/review');

  static Future<Map<String, dynamic>> getTakeoff(String projectId) =>
      _requestMap('GET', '/projects/$projectId/takeoff');

  // ═══════════════════════════════════════════════════════
  // TEAM MANAGEMENT
  // ═══════════════════════════════════════════════════════

  static Future<List<dynamic>> getTeam() => _requestList('GET', '/team');

  static Future<Map<String, dynamic>> inviteUser(String email, String password, String role) =>
      _requestMap('POST', '/team/invite', body: {'email': email, 'password': password, 'role': role});

  static Future<Map<String, dynamic>> toggleUser(String userId) =>
      _requestMap('PATCH', '/team/$userId/toggle');

  static Future<Map<String, dynamic>> deleteUser(String userId) async {
    final res = await _send('DELETE', '/team/$userId');
    if (res.statusCode == 200) return (jsonDecode(res.body) as Map).cast<String, dynamic>();
    return {'success': false, 'error': 'Status ${res.statusCode}: ${res.body}'};
  }

  // ═══════════════════════════════════════════════════════
  // EXPORT — PDF + EXCEL (token in header, downloaded as a blob)
  // ═══════════════════════════════════════════════════════

  static Future<bool> exportPDF(String projectId) async {
    final res = await _send('GET', '/projects/$projectId/export/pdf');
    if (res.statusCode != 200) return false;
    downloadBytes('estimate_$projectId.pdf', res.bodyBytes, 'application/pdf');
    return true;
  }

  static Future<bool> exportExcel(String projectId) async {
    final res = await _send('GET', '/projects/$projectId/export/excel');
    if (res.statusCode != 200) return false;
    downloadBytes(
      'estimate_$projectId.xlsx',
      res.bodyBytes,
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    return true;
  }
}
