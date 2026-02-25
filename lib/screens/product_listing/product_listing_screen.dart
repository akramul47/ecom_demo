import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import 'sticky_tab_bar_delegate.dart';
import 'widgets/product_card.dart';
import 'widgets/product_grid_shimmer.dart';

/// The CORE deliverable of the hiring task.
///
/// Architecture:
/// ┌─────────────────────────────────────────────┐
/// │              NestedScrollView               │
/// │         (OWNS the vertical scroll)          │
/// │                                             │
/// │  ┌─────────────────────────────────────┐    │
/// │  │   Outer Scrollable (header area)    │    │
/// │  │   ├── SliverAppBar (collapsible)    │    │
/// │  │   └── SliverPersistentHeader (pin)  │    │
/// │  └─────────────────────────────────────┘    │
/// │                                             │
/// │  ┌─────────────────────────────────────┐    │
/// │  │   Inner Scrollable (per tab)        │    │
/// │  │   └── SliverGrid (product cards)    │    │
/// │  └─────────────────────────────────────┘    │
/// │                                             │
/// └─────────────────────────────────────────────┘
///
/// Key decisions:
/// 1. NestedScrollView owns ALL vertical scrolling.
/// 2. TabBarView owns horizontal swipe (Flutter's GestureArena separates axes).
/// 3. Each tab uses PageStorageKey for scroll persistence.
/// 4. SliverOverlapAbsorber/Injector prevents content behind pinned tab bar.
/// 5. RefreshIndicator wraps NestedScrollView for pull-to-refresh from any tab.
class ProductListingScreen extends StatefulWidget {
  const ProductListingScreen({super.key});

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab definitions — maps display name → API category key
  static const List<_TabDef> _tabs = [
    _TabDef(label: 'All', category: 'all'),
    _TabDef(label: 'Electronics', category: 'electronics'),
    _TabDef(label: 'Jewelery', category: 'jewelery'),
    _TabDef(label: "Men's", category: "men's clothing"),
    _TabDef(label: "Women's", category: "women's clothing"),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    // Fetch initial data after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCurrentTab();
    });

    // Fetch data when tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _fetchCurrentTab();
      }
    });
  }

  void _fetchCurrentTab() {
    final category = _tabs[_tabController.index].category;
    context.read<ProductProvider>().fetchProducts(category);
  }

  Future<void> _refreshCurrentTab() async {
    final category = _tabs[_tabController.index].category;
    await context.read<ProductProvider>().refresh(category);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // RefreshIndicator wraps the entire NestedScrollView so that
      // pull-to-refresh works from ANY tab, as required.
      body: RefreshIndicator(
        onRefresh: _refreshCurrentTab,
        color: const Color(0xFFF85606),
        child: NestedScrollView(
          // floatHeaderSlivers: true allows the header to re-appear
          // on a slight scroll-up AND enables RefreshIndicator to work.
          floatHeaderSlivers: true,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // ── 1. Collapsible Header (banner + search bar) ────────
              SliverAppBar(
                expandedHeight: 180.0,
                floating: true,
                pinned: false, // Collapses fully — only tab bar pins
                snap: true,
                backgroundColor: const Color(0xFFF85606),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildBanner(context),
                ),
                // Search bar in the app bar
                title: _buildSearchBar(),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.person_outline),
                    onPressed: () => _navigateToProfile(context),
                  ),
                ],
              ),

              // ── 2. Pinned Tab Bar ──────────────────────────────────
              // SliverOverlapAbsorber tells NestedScrollView how much
              // of the header overlaps the body, so that the
              // SliverOverlapInjector in each tab can offset correctly.
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
                sliver: SliverPersistentHeader(
                  pinned: true, // STAYS VISIBLE once header collapses
                  delegate: StickyTabBarDelegate(
                    tabBar: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
                    ),
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
              ),
            ];
          },

          // ── 3. Tab Content (horizontal swipe via TabBarView) ────────
          //
          // GESTURE ISOLATION:
          // TabBarView uses HorizontalDragGestureRecognizer.
          // NestedScrollView uses VerticalDragGestureRecognizer.
          // Flutter's GestureArena naturally separates them by axis.
          // No custom gesture code needed.
          body: TabBarView(
            controller: _tabController,
            children: _tabs
                .map((t) => _TabContent(category: t.category))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF85606), Color(0xFFFF8C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Discover Products',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Find the best deals across all categories',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          SizedBox(width: 12),
          Icon(Icons.search, size: 18, color: Colors.white70),
          SizedBox(width: 8),
          Text(
            'Search products...',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      Navigator.pushNamed(context, '/profile');
    } else {
      Navigator.pushNamed(context, '/login');
    }
  }
}

// ── Tab Content ────────────────────────────────────────────────────────────
/// Each tab's content as a CustomScrollView with SliverOverlapInjector.
///
/// KEY: The PageStorageKey ensures scroll position is PRESERVED when
/// switching between tabs — this is a critical requirement.
class _TabContent extends StatefulWidget {
  final String category;
  const _TabContent({required this.category});

  @override
  State<_TabContent> createState() => _TabContentState();
}

class _TabContentState extends State<_TabContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Preserve state across tab switches

  @override
  void initState() {
    super.initState();
    // Fetch products for this tab if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts(widget.category);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        final isLoading = provider.isLoading(widget.category);
        final error = provider.getError(widget.category);
        final products = provider.getProducts(widget.category);

        return Builder(
          builder: (context) {
            // ScrollConfiguration removes the default Scrollbar that
            // conflicts with NestedScrollView's multiple ScrollPositions.
            return ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: CustomScrollView(
                // PageStorageKey preserves scroll position per tab
                key: PageStorageKey<String>(widget.category),
                slivers: [
                  // CRITICAL: SliverOverlapInjector prevents content from
                  // rendering behind the pinned tab bar.
                  SliverOverlapInjector(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                      context,
                    ),
                  ),

                  // ── Loading State ────────────────────────────────────
                  if (isLoading && products.isEmpty)
                    const ProductGridShimmer(itemCount: 6),

                  // ── Error State ──────────────────────────────────────
                  if (error != null && products.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _ErrorView(
                        error: error,
                        onRetry: () => provider.refresh(widget.category),
                      ),
                    ),

                  // ── Product Grid ─────────────────────────────────────
                  if (products.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.all(8),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.65,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              ProductCard(product: products[index]),
                          childCount: products.length,
                        ),
                      ),
                    ),

                  // ── Empty State ──────────────────────────────────────
                  if (!isLoading && error == null && products.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('No products found')),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Error View Widget ──────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Failed to load products',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab Definition ─────────────────────────────────────────────────────────
class _TabDef {
  final String label;
  final String category;
  const _TabDef({required this.label, required this.category});
}
