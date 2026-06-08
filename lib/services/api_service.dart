import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ApiService {
  static const String baseUrl = "https://archiquant.in";

  // ═══════════════════════════════════════════════════════
  // TOKEN HELPERS
  // ══════════════════════════════════════════════════
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<Map<String, String>> get _headers async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ═══════════════════════════════════════════════════════
  // AUTH
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> register(
    String companyName,
    String slug,
    String email,
    String password, {
    String plan  = 'starter',
    String phone = '',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'company_name': companyName,
        'company_slug': slug,
        'email':        email,
        'password':     password,
        'plan':         plan,
        'phone':        phone,
      }),
    );
    final data = jsonDecode(res.body);
    if (data['token'] != null) await saveToken(data['token']);
    return data;
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
    String companySlug,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email':        email,
        'password':     password,
        'company_slug': companySlug,
      }),
    );
    final data = jsonDecode(res.body);
    if (data['token'] != null) await saveToken(data['token']);
    return data;
  }

  static Future<void> logout() async => clearToken();

  // ═══════════════════════════════════════════════════════
  // USER PROFILE
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: await _headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/profile'),
      headers: await _headers,
      body: jsonEncode({
        'full_name': fullName,
        'phone':     phone,
      }),
    );
    return jsonDecode(res.body);
  }

  // ═══════════════════════════════════════════════════════
  // PROJECTS
  // ═══════════════════════════════════════════════════════

  static Future<List<dynamic>> getProjects() async {
    final res = await http.get(
      Uri.parse('$baseUrl/projects'),
      headers: await _headers,
    );
    return jsonDecode(res.body);
  }

  // Latest saved plan for a project (OCR + user edits) — lets Plan Result show
  // a selected project without re-uploading.
  static Future<Map<String, dynamic>?> getProjectPlan(String projectId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/projects/$projectId/plan'),
        headers: await _headers,
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>> createProject(
    String name,
    String description,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/projects'),
      headers: await _headers,
      body: jsonEncode({'name': name, 'description': description}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getProject(String id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/projects/$id'),
      headers: await _headers,
    );
    return jsonDecode(res.body);
  }

  // ═══════════════════════════════════════════════════════
  // FLOOR PLANS / OCR UPLOAD
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> uploadBlueprint(
    String projectId,
    List<int> bytes,
    String fileName,
  ) async {
    final token = await getToken();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/projects/$projectId/floor-plans'),
    );
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );
    final response = await request.send();
    final body     = await response.stream.bytesToString();
    return jsonDecode(body);
  }

  // ═══════════════════════════════════════════════════════
  // SAVE ROOM COMPONENTS (edited results page)
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> saveRoomComponents(
    String projectId,
    Map<String, dynamic> components,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl/projects/$projectId/components'),
      headers: await _headers,
      body: jsonEncode({'components': components}),
    );
    return jsonDecode(res.body);
  }

  // ═══════════════════════════════════════════════════════
  // BRICK CALCULATION
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> calculateBricksWithTypes(
    String projectId, {
    Map<String, String> brickTypeMap = const {
      "9": "red_brick",
      "6": "white_cement",
      "4": "white_cement",
    },
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/projects/$projectId/calculate'),
      headers: await _headers,
      body: jsonEncode({'brick_type_map': brickTypeMap}),
    );
    return jsonDecode(res.body);
  }

  // ═══════════════════════════════════════════════════════
  // ESTIMATIONS
  // ═══════════════════════════════════════════════════════

  static Future<List<dynamic>> getEstimations(String projectId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/projects/$projectId/estimations'),
      headers: await _headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> createEstimation(
    String projectId,
    Map<String, dynamic> payload,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/projects/$projectId/estimations'),
      headers: await _headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(res.body);
  }

  // ═══════════════════════════════════════════════════════
  // MATERIAL CONFIGS
  // ═══════════════════════════════════════════════════════

  static Future<List<dynamic>> getMaterialConfigs() async {
    final res = await http.get(
      Uri.parse('$baseUrl/material-configs'),
      headers: await _headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> createMaterialConfig(
    Map<String, dynamic> payload,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/material-configs'),
      headers: await _headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(res.body);
  }

  // ═══════════════════════════════════════════════════════
  // FORMULAS
  // ═══════════════════════════════════════════════════════

  static Future<List<dynamic>> getFormulas() async {
    final res = await http.get(
      Uri.parse('$baseUrl/formulas'),
      headers: await _headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateFormula(
    String id,
    String expression,
    String description,
  ) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/formulas/$id'),
      headers: await _headers,
      body: jsonEncode({
        'expression':  expression,
        'description': description,
      }),
    );
    return jsonDecode(res.body);
  }

  // ═══════════════════════════════════════════════════════
  // COMPANY SETTINGS
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getSettings() async {
    final res = await http.get(
      Uri.parse('$baseUrl/settings'),
      headers: await _headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateSettings(
    Map<String, dynamic> payload,
  ) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/settings'),
      headers: await _headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(res.body);
  }

  // ═══════════════════════════════════════════════════════
  // MASTER RATES
  // ═══════════════════════════════════════════════════════

  static Future<List<dynamic>> getMasterRates() async {
    final res = await http.get(
      Uri.parse('$baseUrl/master-rates'),
      headers: await _headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateMasterRate(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/master-rates/$id'),
      headers: await _headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> addMasterRate(
    Map<String, dynamic> payload,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/master-rates'),
      headers: await _headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> deleteMasterRate(String id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/master-rates/$id'),
      headers: await _headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> seedMasterRates() async {
    final res = await http.post(
      Uri.parse('$baseUrl/master-rates/seed'),
      headers: await _headers,
    );
    return jsonDecode(res.body);
  }

  // ═══════════════════════════════════════════════════════
  // REVIEW & BUDGET
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getReviewBudget(
      String projectId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/projects/$projectId/review'),
      headers: await _headers,
    );
    return jsonDecode(res.body);
  }

  // ═══════════════════════════════════════════════════════
  // TAKEOFF (QTO)
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getTakeoff(
      String projectId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/projects/$projectId/takeoff'),
      headers: await _headers,
    );
    return jsonDecode(res.body);
  }

  // ═══════════════════════════════════════════════════════
  // TEAM MANAGEMENT
  // ═══════════════════════════════════════════════════════

  static Future<List<dynamic>> getTeam() async {
    final res = await http.get(
      Uri.parse('$baseUrl/team'),
      headers: await _headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> inviteUser(
    String email,
    String password,
    String role,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/team/invite'),
      headers: await _headers,
      body: jsonEncode({
        'email':    email,
        'password': password,
        'role':     role,
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> toggleUser(String userId) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/team/$userId/toggle'),
      headers: await _headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> deleteUser(String userId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/team/$userId'),
      headers: await _headers,
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    // Return error details for debugging
    return {
      'success': false,
      'error': 'Status ${res.statusCode}: ${res.body}',
    };
  }

  // ═══════════════════════════════════════════════════════
  // EXPORT — PDF + EXCEL (token passed as query param)
  // ═══════════════════════════════════════════════════════

  static Future<void> exportPDF(String projectId) async {
    final token = await getToken();
    if (token == null) return;
    final url = Uri.parse(
      '$baseUrl/projects/$projectId/export/pdf?token=$token',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> exportExcel(String projectId) async {
    final token = await getToken();
    if (token == null) return;
    final url = Uri.parse(
      '$baseUrl/projects/$projectId/export/excel?token=$token',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}