# Ecom Demo — Flutter Hiring Task 2026

## Project Overview

Build a **single Flutter screen** that mimics a **Daraz-style product listing** page. This is a **scroll-architecture and gesture-coordination problem**, NOT a UI task.

> [!CAUTION]
> **Submission Deadline:** 28/02/2026 at 11:59 PM  
> **Submission Link:** https://forms.gle/QhVyeevyLxrZkMFq6

---

## Core Requirements

### 1. Layout
- **Collapsible Header** — A header with a banner or search bar that collapses as the user scrolls down.
- **Sticky Tab Bar** — A tab bar that becomes **pinned/sticky** once the header fully collapses.
- **2–3 Tabs** — Each tab displays a list of products fetched from the Fake Store API.

### 2. Scrolling (MOST CRITICAL)
- There must be **exactly ONE vertical scrollable** element in the entire screen.
- **Pull-to-refresh** must function correctly from **any** tab.
- **Scroll persistence** — Switching tabs must **NOT** reset or cause jumps in the vertical scroll position.
- **No scroll jitter**, conflicts, or duplicate scrolling issues.
- The **tab bar must remain visible** once it reaches the pinned position.

### 3. Horizontal Navigation
- Tabs must be switchable by **tapping** and **horizontal swiping**.
- Horizontal swipe must **NOT** introduce or control vertical scrolling.
- Gesture handling must be **intentional and predictable**.

### 4. Architecture
- **Sliver-based layout** is **required** for the core layout.
- **Clear separation of concerns**: UI, Scroll/Gesture ownership, and State.
- **Avoid fragile solutions** — no magic numbers, no global hacks.

### 5. Data & API
- Use the **Fake Store API**: https://fakestoreapi.com/
- Implement **login** functionality.
- Display the **user's profile** after authentication.

### 6. Mandatory Documentation (README)
The README must explain:
1. How **horizontal swipe** was implemented
2. Who **owns the vertical scroll** and why
3. **Trade-offs or limitations** of the chosen approach

---

## API Reference (Fake Store API)

| Resource     | Endpoint                                    | Description                        |
|-------------|---------------------------------------------|------------------------------------|
| All Products | `GET /products`                             | 20 products with title, price, etc.|
| Single Product | `GET /products/{id}`                      | Product by ID                       |
| Categories   | `GET /products/categories`                  | List of all categories              |
| By Category  | `GET /products/category/{name}`             | Products filtered by category       |
| Login        | `POST /auth/login`                          | Returns JWT token                   |
| All Users    | `GET /users`                                | 10 user profiles                    |
| Single User  | `GET /users/{id}`                           | User by ID (name, email, address)   |

### Login Request Body
```json
{
  "username": "mor_2314",
  "password": "83r5^_"
}
```

### Product Schema
```json
{
  "id": 1,
  "title": "...",
  "price": 109.95,
  "description": "...",
  "category": "men's clothing",
  "image": "https://...",
  "rating": { "rate": 3.9, "count": 120 }
}
```

---

## Evaluation Focus

The evaluators will check:
1. **Correct single-scroll architecture** — exactly ONE `CustomScrollView` owning the vertical scroll
2. **Absence of scroll/gesture conflicts** — no jitter, no duplicate scrolling
3. **Clean, understandable structure** — good separation of concerns
4. **Ability to reason and explain decisions** — the README matters

---

## Project Structure (Recommended)

```
lib/
├── main.dart                     # App entry point
├── app.dart                      # MaterialApp configuration
├── core/
│   ├── api/
│   │   ├── api_client.dart       # HTTP client wrapper (Dio/http)
│   │   └── api_endpoints.dart    # Endpoint constants
│   ├── constants/
│   │   └── app_constants.dart    # App-wide constants
│   └── theme/
│       └── app_theme.dart        # Theme data
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_repository.dart
│   │   │   └── auth_service.dart
│   │   ├── presentation/
│   │   │   ├── login_screen.dart
│   │   │   └── widgets/
│   │   └── state/
│   │       └── auth_provider.dart
│   ├── product_listing/
│   │   ├── data/
│   │   │   ├── product_repository.dart
│   │   │   └── product_service.dart
│   │   ├── presentation/
│   │   │   ├── product_listing_screen.dart   # THE main screen
│   │   │   ├── slivers/
│   │   │   │   ├── collapsible_header.dart   # SliverAppBar
│   │   │   │   └── pinned_tab_bar.dart       # SliverPersistentHeader
│   │   │   └── widgets/
│   │   │       ├── product_card.dart
│   │   │       └── product_grid.dart
│   │   └── state/
│   │       └── product_provider.dart
│   └── profile/
│       ├── data/
│       │   └── user_repository.dart
│       ├── presentation/
│       │   └── profile_screen.dart
│       └── state/
│           └── profile_provider.dart
└── shared/
    └── widgets/
        └── ...
```

---

## Key Technical Decisions to Document

### Scroll Architecture
- Use `NestedScrollView` OR a single `CustomScrollView` with `SliverOverlapAbsorber` / `SliverOverlapInjector`.
- The **outer scroll controller (NestedScrollView's)** owns the vertical scroll.
- Each tab's content is a `SliverList` / `SliverGrid` inside the body, participating in the same scroll physics.

### Horizontal Swipe
- Use `TabBarView` for horizontal swiping with `NeverScrollableScrollPhysics` on the vertical axis inside tabs.
- Gesture disambiguation is handled by Flutter's `GestureArena` — the `TabBarView` claims horizontal drags, the `NestedScrollView` claims vertical drags.

### Why NestedScrollView
- It provides **built-in coordination** between an outer scrollable (header + tab bar) and inner scrollables (tab content).
- It handles **scroll persistence** per tab using `ScrollController` per inner scrollable.
- It supports `SliverOverlapAbsorber` / `SliverOverlapInjector` to prevent content from appearing behind the pinned tab bar.

---

## Rules for This Project

1. **Never nest scrollable widgets** — no `ListView` inside `SingleChildScrollView`.
2. **Always use slivers** for the main layout — `SliverAppBar`, `SliverPersistentHeader`, `SliverList`, `SliverGrid`.
3. **State management** — use Provider or Riverpod (keep it simple, no over-engineering).
4. **Error handling** — show user-friendly error states, not raw exceptions.
5. **Loading states** — show shimmer or skeleton loaders, not just spinners.
6. **Responsive** — the product grid should adapt to screen width (2 columns on phones, 3+ on tablets).
7. **Code comments** — explain WHY, not WHAT, especially around scroll/gesture logic.
