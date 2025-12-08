import 'package:flutter/material.dart';
import '../dev/dev_wallet_storage.dart';
import '../features/home/home_route_args.dart';
import '../providers/wallet_provider.dart';

class RegisterScreen extends StatelessWidget {
  final bool devEnabled;

  const RegisterScreen({super.key, this.devEnabled = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // 1) Создаём юзера на сервере (MongoDB) -> получаем userId.
            final userId = await registerOnServer(); // реализуйте сами

            // 2) Только в DEV: генерим и сохраняем профиль сразу при регистрации.
            final walletProvider = WalletProvider(devEnabled: devEnabled);
            final DevWalletProfile? profile = await walletProvider
                .generateAndPersistForUser(userId);

            // 3) Переходим на главный экран.
            if (context.mounted) {
              Navigator.pushReplacementNamed(
                context,
                '/home',
                arguments: HomeRouteArgs(userId: userId, devProfile: profile),
              );
            }
          },
          child: const Text('Зарегистрироваться'),
        ),
      ),
    );
  }

  Future<String> registerOnServer() async {
    // TODO: ваш вызов API, возвращает userId
    return 'user-123'; // временно
  }
}
