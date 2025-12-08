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
    assert(scope != null, 'WalletScope not found in context');
    return scope!.notifier!;
  }

  static WalletProvider? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WalletScope>()?.notifier;
  }

  static WalletProvider read(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<WalletScope>();
    final scope = element?.widget as WalletScope?;
    assert(scope != null, 'WalletScope not found in context');
    return scope!.notifier!;
  }
}
