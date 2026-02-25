/// All Fake Store API endpoint constants.
///
/// Base URL: https://fakestoreapi.com
/// Docs: https://fakestoreapi.com/docs
class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://fakestoreapi.com';

  // Products
  static const String products = '/products';
  static String productById(int id) => '/products/$id';
  static const String categories = '/products/categories';
  static String productsByCategory(String category) =>
      '/products/category/$category';

  // Auth
  static const String login = '/auth/login';

  // Users
  static const String users = '/users';
  static String userById(int id) => '/users/$id';
}
