import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../models/product.dart';

/// Manages product data across all category tabs.
///
/// Each category's products are cached independently so that
/// switching tabs doesn't re-fetch. Call [refresh] to force reload.
class ProductProvider extends ChangeNotifier {
  final ApiClient _api;

  ProductProvider({required ApiClient api}) : _api = api;

  // ── Per-category cache ─────────────────────────────────────────────────
  final Map<String, List<Product>> _productsByCategory = {};
  final Map<String, bool> _loadingByCategory = {};
  final Map<String, String?> _errorByCategory = {};

  List<Product> getProducts(String category) =>
      _productsByCategory[category] ?? [];

  bool isLoading(String category) => _loadingByCategory[category] ?? false;

  String? getError(String category) => _errorByCategory[category];

  // ── Categories ─────────────────────────────────────────────────────────
  List<String> _categories = [];
  bool _categoriesLoading = false;
  String? _categoriesError;

  List<String> get categories => _categories;
  bool get categoriesLoading => _categoriesLoading;
  String? get categoriesError => _categoriesError;

  /// Fetch all category names from the API.
  Future<void> fetchCategories() async {
    _categoriesLoading = true;
    _categoriesError = null;
    notifyListeners();

    try {
      _categories = await _api.getCategories();
    } catch (e) {
      _categoriesError = e.toString();
    } finally {
      _categoriesLoading = false;
      notifyListeners();
    }
  }

  /// Fetch products for a specific category.
  /// Uses 'all' as the key for fetching all products.
  Future<void> fetchProducts(String category) async {
    // Skip if already loaded and not forcing refresh
    if (_productsByCategory.containsKey(category) &&
        !(_loadingByCategory[category] ?? false)) {
      return;
    }

    _loadingByCategory[category] = true;
    _errorByCategory[category] = null;
    notifyListeners();

    try {
      final products = category == 'all'
          ? await _api.getAllProducts()
          : await _api.getProductsByCategory(category);
      _productsByCategory[category] = products;
    } catch (e) {
      _errorByCategory[category] = e.toString();
    } finally {
      _loadingByCategory[category] = false;
      notifyListeners();
    }
  }

  /// Force-refresh products for the given category.
  Future<void> refresh(String category) async {
    _productsByCategory.remove(category);
    await fetchProducts(category);
  }

  /// Refresh all loaded categories.
  Future<void> refreshAll() async {
    final keys = _productsByCategory.keys.toList();
    _productsByCategory.clear();
    await Future.wait(keys.map((cat) => fetchProducts(cat)));
  }
}
