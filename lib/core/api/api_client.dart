import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_endpoints.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../models/auth_response.dart';

/// HTTP client wrapping the Fake Store API.
///
/// All GET endpoints are public (no auth required in practice),
/// but we store the JWT token from login to simulate authenticated state.
class ApiClient {
  final http.Client _httpClient;
  String? _token;

  ApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;
  bool get hasToken => _token != null;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── Products ──────────────────────────────────────────────────────────

  /// Fetch all 20 products.
  Future<List<Product>> getAllProducts() async {
    final response = await _httpClient.get(
      Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.products}'),
      headers: _headers,
    );
    _assertOk(response);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Product.fromJson(json)).toList();
  }

  /// Fetch products filtered by category name.
  Future<List<Product>> getProductsByCategory(String category) async {
    final response = await _httpClient.get(
      Uri.parse(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.productsByCategory(category)}',
      ),
      headers: _headers,
    );
    _assertOk(response);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Product.fromJson(json)).toList();
  }

  /// Fetch all category names.
  Future<List<String>> getCategories() async {
    final response = await _httpClient.get(
      Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.categories}'),
      headers: _headers,
    );
    _assertOk(response);
    return List<String>.from(jsonDecode(response.body));
  }

  // ── Auth ───────────────────────────────────────────────────────────────

  /// Login and receive a JWT token.
  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _httpClient.post(
      Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.login}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    _assertOk(response);
    return AuthResponse.fromJson(jsonDecode(response.body));
  }

  // ── Users ──────────────────────────────────────────────────────────────

  /// Fetch a single user by ID.
  Future<User> getUser(int id) async {
    final response = await _httpClient.get(
      Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.userById(id)}'),
      headers: _headers,
    );
    _assertOk(response);
    return User.fromJson(jsonDecode(response.body));
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  void _assertOk(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }
  }
}

/// Custom exception for API errors.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
