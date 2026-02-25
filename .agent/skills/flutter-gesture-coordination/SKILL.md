---
name: Flutter Gesture Coordination
description: How to handle horizontal tab swiping and vertical scrolling without conflicts in a NestedScrollView + TabBarView setup.
---

# Flutter Gesture Coordination

This skill covers the **gesture isolation** requirement: horizontal swiping for tabs must NOT interfere with vertical scrolling.

---

## The Problem

When combining `NestedScrollView` (vertical scroll) with `TabBarView` (horizontal swipe), Flutter's gesture system must decide: **is this drag horizontal or vertical?**

If handled poorly:
- Diagonal swipes cause both systems to fight for the gesture
- Vertical scrolling stutters when the user slightly moves horizontally
- Tab switches happen accidentally during vertical scrolls

---

## How Flutter's Gesture Arena Works

Flutter uses a **GestureArena** to resolve competing gestures:

1. When a pointer goes down, all interested `GestureRecognizer`s enter the arena
2. As the pointer moves, recognizers analyze the drag direction
3. The first recognizer to **claim victory** wins the gesture; others are rejected
4. `TabBarView` uses a `HorizontalDragGestureRecognizer`
5. `NestedScrollView` uses a `VerticalDragGestureRecognizer`

Because they use **different axes**, Flutter naturally disambiguates them. The key is to **not break this natural separation**.

---

## Implementation: Correct Gesture Isolation

### Default Behavior (Usually Sufficient)

`NestedScrollView` + `TabBarView` naturally handles gesture isolation because:
- `TabBarView` only claims **horizontal** drags
- `NestedScrollView` only claims **vertical** drags
- They don't compete for the same gestures

```dart
NestedScrollView(
  headerSliverBuilder: (context, innerBoxIsScrolled) => [...],
  body: TabBarView(
    controller: _tabController,
    children: [
      // Each child is a CustomScrollView with slivers
      _TabContent(category: 'all'),
      _TabContent(category: 'electronics'),
      _TabContent(category: 'clothing'),
    ],
  ),
)
```

> **Key Insight:** Do NOT add custom gesture detectors or listeners on top of this structure unless you have a specific reason. The default behavior is correct.

### When Gesture Conflicts Occur

If you experience gesture conflicts, it's usually because:

1. **A `GestureDetector` wrapping the `TabBarView`** — removes the gesture from the arena before `TabBarView` can claim it
2. **A `NotificationListener<ScrollNotification>` that calls `notification.depth == 0`** — may interfere with nested scroll coordination
3. **Using `physics: NeverScrollableScrollPhysics()` on `TabBarView`** — disables horizontal swiping entirely

### Advanced: Custom Scroll Physics for Diagonal Protection

If diagonal gestures cause issues, you can increase the threshold at which `TabBarView` accepts a horizontal drag:

```dart
class StrictHorizontalScrollPhysics extends ScrollPhysics {
  const StrictHorizontalScrollPhysics({super.parent});

  @override
  StrictHorizontalScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return StrictHorizontalScrollPhysics(parent: buildParent(ancestor));
  }

  // Require a larger horizontal drag threshold before claiming the gesture
  @override
  double get dragStartDistanceMotionThreshold => 18.0;
}

// Usage:
TabBarView(
  physics: const StrictHorizontalScrollPhysics(),
  controller: _tabController,
  children: [...],
)
```

---

## Gesture Ownership Summary

| Gesture | Owner | Why |
|---------|-------|-----|
| Vertical drag | `NestedScrollView` | Owns the outer + inner scroll coordination |
| Horizontal drag | `TabBarView` | Owns tab switching via swipe |
| Tap on tab | `TabBar` | Switches tab without scroll impact |
| Pull-to-refresh (vertical over-scroll) | `RefreshIndicator` wrapping `NestedScrollView` | Works because of `floatHeaderSlivers: true` |

---

## Testing Gesture Isolation

### Manual Tests

1. **Pure vertical scroll** — Scroll up/down rapidly. Tabs should NOT switch.
2. **Pure horizontal swipe** — Swipe left/right. Vertical scroll position should NOT change.
3. **Diagonal drag (45°)** — Should be claimed by either vertical or horizontal, NOT both. No jitter.
4. **Slow diagonal drag** — Flutter should commit to one direction after the drag threshold is exceeded.
5. **Fast flick horizontally** — Tab should switch cleanly.
6. **Fast flick vertically at edge of tab** — Should scroll, not switch tab.

### Automated / Integration Test Approach

```dart
testWidgets('horizontal swipe switches tab without vertical scroll change', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.pumpAndSettle();

  // Record initial scroll position
  final scrollPosition = tester
      .widget<NestedScrollView>(find.byType(NestedScrollView))
      .controller!
      .position
      .pixels;

  // Perform horizontal swipe
  await tester.fling(find.byType(TabBarView), const Offset(-300, 0), 800);
  await tester.pumpAndSettle();

  // Verify scroll position unchanged
  final newScrollPosition = tester
      .widget<NestedScrollView>(find.byType(NestedScrollView))
      .controller!
      .position
      .pixels;

  expect(newScrollPosition, equals(scrollPosition));
});
```

---

## Common Anti-Patterns

### ❌ DON'T: Wrap TabBarView in GestureDetector

```dart
// BAD: GestureDetector steals horizontal gestures from TabBarView
GestureDetector(
  onHorizontalDragEnd: (details) { /* switch tab manually */ },
  child: TabBarView(...),
)
```

### ❌ DON'T: Disable TabBarView swiping and re-implement it

```dart
// BAD: Re-implementing swipe defeats the purpose
TabBarView(
  physics: NeverScrollableScrollPhysics(), // Disables swipe
  children: [...],
)
// Then adding custom PageView or gesture handling
```

### ✅ DO: Trust the default behavior

```dart
// GOOD: NestedScrollView + TabBarView just work together
NestedScrollView(
  body: TabBarView(
    controller: _tabController,
    children: [...],
  ),
)
```

---

## README Documentation Template

When documenting horizontal swipe in the README:

```markdown
## Horizontal Swipe Implementation

Horizontal tab switching is handled by `TabBarView`, which uses Flutter's
built-in `HorizontalDragGestureRecognizer`. This recognizer competes with
`NestedScrollView`'s `VerticalDragGestureRecognizer` in Flutter's
`GestureArena`.

Because these recognizers claim different axes (horizontal vs vertical),
Flutter naturally disambiguates them without any custom logic. The drag
direction is determined by the initial pointer movement vector — once
the movement exceeds the drag threshold in one axis, that axis's recognizer
claims the gesture and the other is rejected.

### Trade-offs
- **Pro:** Zero custom gesture code means fewer bugs and better maintainability
- **Pro:** Flutter's gesture system is battle-tested across millions of apps
- **Con:** Very shallow diagonal drags (~10-15°) may occasionally be claimed
  by the wrong recognizer, but this matches user expectation and is standard
  platform behavior
```
