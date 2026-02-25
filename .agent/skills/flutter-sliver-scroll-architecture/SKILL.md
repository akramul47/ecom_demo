---
name: Flutter Sliver Scroll Architecture
description: How to build a single-scrollable Daraz-style product listing using NestedScrollView, SliverAppBar, and SliverPersistentHeader with proper scroll coordination and tab persistence.
---

# Flutter Sliver Scroll Architecture

This skill covers the **most critical** requirement of the hiring task: building a screen with **exactly one vertical scrollable**, a collapsible header, a sticky tab bar, and per-tab content — all without scroll conflicts.

---

## Core Pattern: NestedScrollView + SliverAppBar + TabBarView

The recommended architecture uses `NestedScrollView` which coordinates an **outer** scrollable (header area) with **inner** scrollables (tab content).

### Why NestedScrollView (Not CustomScrollView)

| Approach | Pros | Cons |
|----------|------|------|
| `NestedScrollView` | Built-in inner/outer scroll coordination, per-tab scroll persistence, handles `SliverOverlapAbsorber` | Slightly opinionated API |
| `CustomScrollView` | Full control | Must manually coordinate scroll positions, no built-in tab persistence |

**Decision:** Use `NestedScrollView` because it solves the two hardest requirements automatically:
1. Single scrollable feel with coordinated inner/outer scrolling
2. Per-tab scroll position persistence

---

## Implementation Blueprint

### Step 1: Scaffold with NestedScrollView

```dart
class ProductListingScreen extends StatefulWidget {
  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        // floatHeaderSlivers: true enables pull-to-refresh to work
        // by letting the header float back into view
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // 1. Collapsible header (banner/search bar)
            SliverAppBar(
              expandedHeight: 200.0,
              floating: true,
              pinned: false, // Header COLLAPSES away
              snap: true,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildBanner(),
              ),
            ),
            // 2. Pinned tab bar — uses SliverOverlapAbsorber
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Electronics'),
                      Tab(text: 'Clothing'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        // 3. Tab content as the body
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTabContent('all'),
            _buildTabContent('electronics'),
            _buildTabContent("men's clothing"),
          ],
        ),
      ),
    );
  }
}
```

### Step 2: Sticky Tab Bar Delegate

```dart
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
```

### Step 3: Tab Content with SliverOverlapInjector

Each tab MUST use `SliverOverlapInjector` to avoid content rendering behind the pinned tab bar.

```dart
Widget _buildTabContent(String category) {
  return Builder(
    builder: (context) {
      return CustomScrollView(
        // KEY: Each tab gets its own scroll controller via NestedScrollView
        // This is what enables scroll persistence across tab switches!
        key: PageStorageKey<String>(category),
        slivers: [
          // CRITICAL: Inject the overlap from the pinned header
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          // Actual product grid
          SliverPadding(
            padding: const EdgeInsets.all(8.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => ProductCard(product: products[index]),
                childCount: products.length,
              ),
            ),
          ),
        ],
      );
    },
  );
}
```

### Step 4: Pull-to-Refresh

Wrap the entire `NestedScrollView` in a `RefreshIndicator` for pull-to-refresh support from any tab:

```dart
RefreshIndicator(
  onRefresh: () async {
    // Refresh data for the current tab
    await _refreshCurrentTab();
  },
  child: NestedScrollView(
    // ... same as above
  ),
)
```

> **Note:** `RefreshIndicator` works with `NestedScrollView` because `floatHeaderSlivers: true` allows the scroll to over-scroll at the top, triggering the refresh indicator.

---

## Scroll Ownership Diagram

```
┌─────────────────────────────────────────────┐
│              NestedScrollView               │
│         (OWNS the vertical scroll)          │
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │   Outer Scrollable                  │    │
│  │   ├── SliverAppBar (collapsible)    │    │
│  │   └── SliverPersistentHeader (pin)  │    │
│  └─────────────────────────────────────┘    │
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │   Inner Scrollable (per tab)        │    │
│  │   ├── SliverOverlapInjector         │    │
│  │   └── SliverGrid (product cards)    │    │
│  └─────────────────────────────────────┘    │
│                                             │
└─────────────────────────────────────────────┘
```

The `NestedScrollView` coordinates these two scrollables so they feel like **one** continuous scroll.

---

## Common Pitfalls to Avoid

1. **❌ Putting a `ListView` inside a tab** — This creates a second scrollable. Use `SliverList` / `SliverGrid` inside a `CustomScrollView` instead.
2. **❌ Forgetting `SliverOverlapInjector`** — Content will render behind the pinned tab bar.
3. **❌ Forgetting `PageStorageKey`** — Scroll position won't persist when switching tabs.
4. **❌ Using `NeverScrollableScrollPhysics` on the inner scrollable** — This breaks the inner scroll coordination with `NestedScrollView`.
5. **❌ Using magic numbers for header heights** — Use `SliverAppBar.expandedHeight` and let `SliverPersistentHeaderDelegate` compute the tab bar height dynamically.

---

## Testing Checklist

- [ ] Scroll down — header collapses, tab bar pins
- [ ] Continue scrolling — product list scrolls smoothly
- [ ] Switch tabs via tap — scroll position does NOT jump
- [ ] Switch tabs via swipe — horizontal only, no vertical movement
- [ ] Pull down from top — refresh indicator appears
- [ ] Pull down from any tab — refresh works consistently
- [ ] Scroll down in Tab 1, switch to Tab 2, switch back — Tab 1 scroll position is preserved
- [ ] No jitter or flicker at any point during scroll or tab switch
