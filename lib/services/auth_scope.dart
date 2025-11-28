import 'package:flutter/widgets.dart';
import 'auth_controller.dart';

class AuthScope extends InheritedWidget {
  AuthScope({super.key, required super.child});
  static final AuthController _instance = AuthController();

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found in context');
    return _instance;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}
