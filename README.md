# Ecom Demo — Daraz-Style Product Listing

A Flutter application that implements a **single-scrollable product listing** screen inspired by Daraz, featuring a collapsible header, sticky tab bar, horizontal swipe navigation, and data from the [Fake Store API](https://fakestoreapi.com/).

## Getting Started

```bash
flutter pub get
flutter run
```

**Test Login Credentials:**
| Username | Password |
|----------|----------|
| `mor_2314` | `83r5^_` |

---

## Architecture: Scroll & Gesture Ownership

### Who Owns the Vertical Scroll?

**`NestedScrollView`** owns all vertical scrolling.

```
NestedScrollView (VERTICAL SCROLL OWNER)
├── Outer Scrollable
│   ├── SliverAppBar        → collapses on scroll
│   └── SliverPersistentHeader → pins when header collapses
└── Inner Scrollable (per tab)
    ├── SliverOverlapInjector → offsets below pinned header
    └── SliverGrid           → product cards
```

**Why NestedScrollView?**
- It coordinates outer (header collapse) and inner (tab content) scrolling into a **single scrollable feel** — satisfying the "exactly ONE vertical scrollable" constraint.
- It provides built-in per-tab scroll position persistence via `PageStorageKey`.
- It supports `SliverOverlapAbsorber` / `SliverOverlapInjector` to prevent content from rendering behind the pinned tab bar.

### How Horizontal Swipe Works

**`TabBarView`** handles horizontal tab switching using Flutter's built-in `HorizontalDragGestureRecognizer`.

**Gesture Isolation** — no custom gesture code is needed:
1. When a pointer goes down, both `VerticalDragGestureRecognizer` (from `NestedScrollView`) and `HorizontalDragGestureRecognizer` (from `TabBarView`) enter Flutter's `GestureArena`.
2. As the pointer moves, the recognizer whose axis matches the primary drag direction **claims the gesture**.
3. The losing recognizer is **rejected** — they never fight over the same gesture.

This is why horizontal swiping does NOT trigger vertical scrolling and vice versa.

### Trade-offs and Limitations

| Aspect | Trade-off |
|--------|-----------|
| **Diagonal drags (~10-15°)** | May be claimed by either axis recognizer. This is standard platform behavior and matches user expectation. |
| **NestedScrollView API** | Slightly opinionated — requires `SliverOverlapAbsorber`/`Injector` pair. But this eliminates manual scroll coordination bugs. |
| **Pull-to-refresh** | Requires `floatHeaderSlivers: true` on `NestedScrollView` so the `RefreshIndicator` can detect over-scroll. This also makes the header "snap" back on slight scroll-up, which we use intentionally. |
| **Tab count** | Currently 5 tabs (All, Electronics, Jewelery, Men's, Women's) mapped to API categories. Adding/removing tabs only requires editing the `_tabs` list. |
| **Auth flow** | The Fake Store API login doesn't return a user ID, so we search users 1-10 by username to find the matching profile. This is O(10) API calls worst-case but only happens once at login. |

---

## Project Structure

```
lib/
├── main.dart                           # Entry point, MultiProvider setup
├── core/
│   ├── api/
│   │   ├── api_client.dart             # HTTP client (Fake Store API)
│   │   └── api_endpoints.dart          # Endpoint constants
│   └── theme/
│       └── app_theme.dart              # Daraz-inspired orange theme
├── models/
│   ├── product.dart                    # Product + Rating
│   ├── user.dart                       # User + Name + Address
│   └── auth_response.dart              # JWT + LoginRequest
├── providers/
│   ├── product_provider.dart           # Per-category product state
│   └── auth_provider.dart              # Login, token, user profile
└── screens/
    ├── product_listing/
    │   ├── product_listing_screen.dart  # ⭐ Core: NestedScrollView
    │   ├── sticky_tab_bar_delegate.dart # SliverPersistentHeader
    │   └── widgets/
    │       ├── product_card.dart        # Product display card
    │       └── product_grid_shimmer.dart # Loading skeleton
    ├── auth/
    │   └── login_screen.dart            # Login form
    └── profile/
        └── profile_screen.dart          # User profile display
```

## Key Implementation Details

- **Single Scrollable** — `NestedScrollView` is the only vertical scroll controller. No `ListView` or `SingleChildScrollView` nested inside.
- **Scroll Persistence** — `PageStorageKey` per tab + `AutomaticKeepAliveClientMixin` preserves scroll position and widget state across tab switches.
- **Sticky Tab Bar** — `SliverPersistentHeader(pinned: true)` with a custom `StickyTabBarDelegate`.
- **State Management** — Provider pattern with `ProductProvider` (per-category caching) and `AuthProvider` (JWT + user profile).
