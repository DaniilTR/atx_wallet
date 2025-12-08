import '../../dev/dev_wallet_storage.dart';

class HomeRouteArgs {
  const HomeRouteArgs({required this.userId, this.devProfile});

  final String userId;
  final DevWalletProfile? devProfile;
}
