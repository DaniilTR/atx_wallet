import 'package:flutter/widgets.dart';

import 'wallet_provider.dart';

class WalletScope extends InheritedNotifier<WalletProvider> {
  const WalletScope({
    super.key,
    required WalletProvider controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static WalletProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WalletScope>();
    if (scope == null) {
      throw StateError('WalletScope not found in context. Make sure WalletScope wraps this widget.');
    }
    final notifier = scope.notifier;
    if (notifier == null) {
      throw StateError('WalletScope has no notifier/controller.');
    }
    return notifier;
  }

  static WalletProvider? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WalletScope>()?.notifier;
  }

  static WalletProvider read(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<WalletScope>();
    final scope = element?.widget as WalletScope?;
    if (scope == null) {
      throw StateError('WalletScope not found in context. Make sure WalletScope wraps this widget.');
    }
    final notifier = scope.notifier;
    if (notifier == null) {
      throw StateError('WalletScope has no notifier/controller.');
    }
    return notifier;
  }
}
