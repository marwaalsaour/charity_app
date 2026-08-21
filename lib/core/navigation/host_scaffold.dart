import 'package:flutter/material.dart';

/// Opens the nearest ancestor [Scaffold] that actually has an end drawer.
///
/// Home tabs sit inside [MainNavigationScreen]'s scaffold, so [Scaffold.of]
/// would otherwise hit the inner scaffold (no drawer) and do nothing.
///
/// The menu button sits at the trailing edge of the home header, so the
/// drawer must open from that same side in both LTR and RTL.
void openHostDrawer(BuildContext context) {
  ScaffoldState? match;
  context.visitAncestorElements((element) {
    if (element is StatefulElement && element.state is ScaffoldState) {
      final state = element.state as ScaffoldState;
      if (state.hasEndDrawer) {
        match = state;
        return false;
      }
    }
    return true;
  });
  match?.openEndDrawer();
}
