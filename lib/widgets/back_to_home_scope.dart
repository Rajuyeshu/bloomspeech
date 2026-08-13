import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/routes/app_router.dart';

/// Makes the Android hardware / gesture back button fall back to the home
/// screen on routes that may have no page below them.
///
/// Every screen is registered as a top-level GoRoute, so a route reached
/// through `context.go(...)`, a deep link, or a web reload has an empty
/// navigator stack. Without this, the root navigator has nothing to pop and
/// Android closes the whole app instead of going back.
class BackToHomeScope extends StatelessWidget {
  final Widget child;

  const BackToHomeScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Let a real page below us handle the pop normally; only step in when
      // this route is the only thing on the stack.
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.goNamed(AppRouter.home);
      },
      child: child,
    );
  }
}
