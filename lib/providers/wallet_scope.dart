import 'package:flutter/widgets.dart';

import 'wallet_provider.dart';

class WalletScope extends InheritedNotifier<WalletProvider> {
  const WalletScope({
    required WalletProvider controller,
    required Widget child,
    super.key,
  }) : super(notifier: controller, child: child);

  static WalletProvider? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WalletScope>();
    return scope?.notifier;
  }

  static WalletProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WalletScope>();
    assert(scope != null, 'WalletScope not found in context');
    return scope!.notifier!;
  }

  static WalletProvider read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<WalletScope>();
    assert(scope != null, 'WalletScope not found in context');
    return scope!.notifier!;
  }
}
