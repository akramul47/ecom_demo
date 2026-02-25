import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/api/api_client.dart';
import 'core/theme/app_theme.dart';
import 'providers/product_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/product_listing/product_listing_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Disables the URL strategy on web, which prevents the Flutter web
  // popstate listener assertion error when navigating between routes.
  // Without this, Navigator.pop() on web causes a double-unregister
  // of popstate listeners inside Flutter's url_strategy.dart.
  if (kIsWeb) {
    setUrlStrategy(null);
  }

  final apiClient = ApiClient();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider(api: apiClient)),
        ChangeNotifierProvider(create: (_) => AuthProvider(api: apiClient)),
      ],
      child: const EcomDemoApp(),
    ),
  );
}

class EcomDemoApp extends StatelessWidget {
  const EcomDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ecom Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Custom scroll behavior so that pull-to-refresh works on web
      // (enables mouse drag scrolling + touch drag for all platforms)
      scrollBehavior: const _AppScrollBehavior(),
      home: const ProductListingScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

/// Custom scroll behavior that enables drag scrolling on web.
///
/// By default, Flutter web only allows scroll via mouse wheel/trackpad.
/// This adds mouse drag to the set of drag devices, which is required
/// for RefreshIndicator (pull-to-refresh) to work with mouse input.
class _AppScrollBehavior extends ScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };

  /// Use BouncingScrollPhysics on ALL platforms.
  /// This enables over-scroll which RefreshIndicator needs to trigger.
  /// On web, the default ClampingScrollPhysics blocks over-scroll entirely.
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}
