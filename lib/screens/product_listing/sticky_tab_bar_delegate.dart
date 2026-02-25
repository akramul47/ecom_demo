import 'package:flutter/material.dart';

/// SliverPersistentHeaderDelegate that keeps the [TabBar] pinned
/// at the top of the screen once the collapsible header scrolls away.
///
/// This is the "sticky tab bar" required by the hiring task.
/// The delegate simply wraps a TabBar with a solid background so
/// content doesn't bleed through behind it.
class StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color? backgroundColor;

  const StickyTabBarDelegate({required this.tabBar, this.backgroundColor});

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
      color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
