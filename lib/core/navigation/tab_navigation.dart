import 'package:flutter/material.dart';

class TabNavigation extends InheritedWidget {
  const TabNavigation({
    super.key,
    required this.selectTab,
    required super.child,
  });

  final void Function(int index) selectTab;

  static TabNavigation? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<TabNavigation>();
  }

  static void go(BuildContext context, int index) {
    maybeOf(context)?.selectTab(index);
  }

  @override
  bool updateShouldNotify(TabNavigation oldWidget) => false;
}
