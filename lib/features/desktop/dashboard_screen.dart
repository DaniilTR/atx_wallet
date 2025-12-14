import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../providers/wallet_scope.dart';
import '../../providers/wallet_provider.dart';

class DesktopDashboardScreen extends StatelessWidget {
  const DesktopDashboardScreen({super.key});

  Widget _sideNav(BuildContext context) {
    return Container(
      width: 125,
      color: const Color(0x1A3A3F4A),
      child: Stack(
        children: [
          Positioned(
            top: 24,
            left: 12,
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
              tooltip: 'Wallet',
            ),
          ),
          Positioned(
            top: 120,
            left: 12,
            child: IconButton(
              onPressed: () => Navigator.pushNamed(context, '/market'),
              icon: const Icon(Icons.pie_chart, color: Colors.white54),
              tooltip: 'Market',
            ),
          ),
          Positioned(
            top: 200,
            left: 12,
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.swap_horiz, color: Colors.white54),
              tooltip: 'Transactions',
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceCard(BuildContext context) {
    final wallet = WalletScope.maybeOf(context);
    final balances = wallet?.balances ?? WalletBalances.initial(kTrackedTokens);
    final address = wallet?.activeProfile?.addressHex;
    final displayAddress = address == null
        ? null
        : (address.length > 12 ? '${address.substring(0, 6)}...${address.substring(address.length - 4)}' : address);
    final totalUsd = balances.totalUsd;
    final totalTbnb = balances.totalTbnb;

    return Container(
      width: 920,
      height: 340,
      decoration: BoxDecoration(
        color: const Color(0xFF162C5E).withOpacity(0.5),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Total balance', style: TextStyle(color: Color(0xFFA6A6A6), fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              totalUsd != null ? '\$${totalUsd.toStringAsFixed(2)}' : '${totalTbnb.toStringAsFixed(4)} TBNB',
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            // months row placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(12, (i) => Text(['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][i], style: const TextStyle(color: Color(0xFF24E0F9), fontSize: 12))),
            ),
            const SizedBox(height: 12),
            // address row
            if (displayAddress != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFF2A3145), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.account_balance_wallet, size: 18, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(displayAddress, style: const TextStyle(color: Colors.white70)),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _recentActions(BuildContext context) {
    final wallet = WalletScope.maybeOf(context);
    final history = wallet?.history ?? const [];
    return Container(
      width: 365,
      height: 208,
      decoration: BoxDecoration(color: const Color(0xFF162C5E).withOpacity(0.5), borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Последние действия:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (history.isEmpty) const Text('-', style: TextStyle(color: Colors.white70))
          else
            for (var i = 0; i < (history.length < 4 ? history.length : 4); i++)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  history[i].note ?? '${history[i].incoming ? 'Вход' : 'Исход'} ${history[i].amount} ${history[i].tokenSymbol}',
                  style: const TextStyle(color: Colors.white),
                ),
              )
        ]),
      ),
    );
  }

  Widget _actionsRow() {
    final labels = ['SEND', 'Receive', 'Loan', 'Topup'];
    return Row(
      children: labels
          .map((l) => Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF162C5E)),
                  onPressed: () {},
                  child: Text(l),
                ),
              ))
          .toList(),
    );
  }

  Widget _transactionsList(BuildContext context) {
    final wallet = WalletScope.maybeOf(context);
    final balances = wallet?.balances ?? WalletBalances.initial(kTrackedTokens);
    return Column(
      children: balances.assets
          .map(
            (asset) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF211E41), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: Colors.white24, child: Text(asset.token.symbol[0])),
                  const SizedBox(width: 12),
                  Expanded(child: Text(asset.token.name, style: const TextStyle(color: Colors.white, fontSize: 20))),
                  Text(asset.token.symbol, style: const TextStyle(color: Color(0xFFA6A6A6), fontSize: 18)),
                  const SizedBox(width: 24),
                  Text(_formatAmount(asset.amount), style: const TextStyle(color: Color(0xFFA6A6A6), fontSize: 18)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // small helper: format amounts with up to 6 decimals but trim trailing zeros
  String _formatAmount(double v) {
    if (v == v.floorToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(v < 1 ? 6 : 4).replaceFirst(RegExp(r"(?:\.0+|([0-9]*\.[0-9]*?)0+)"), r"\1");
  }

  // (no state required)

  @override
  Widget build(BuildContext context) {
    final wallet = WalletScope.maybeOf(context);
    final address = wallet?.activeProfile?.addressHex;
    final displayAddress = address == null
        ? null
        : (address.length > 12 ? '${address.substring(0, 6)}...${address.substring(address.length - 4)}' : address);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ATX Wallet — Desktop'),
        actions: [
          if (displayAddress != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Text(displayAddress, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Copy address',
                    onPressed: () async {
                      final addr = address!;
                      try {
                        await Clipboard.setData(ClipboardData(text: addr));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address copied')));
                      } catch (_) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to copy')));
                      }
                    },
                    icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => _showProfileDialog(context),
                icon: const Icon(Icons.person_outline, size: 18, color: Colors.white),
                label: const Text('Load profile', style: TextStyle(color: Colors.white)),
              ),
            ),
          TextButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/desktop/pair'),
            icon: const Icon(Icons.logout, size: 18, color: Colors.white),
            label: const Text('Отключить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sideNav(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // top area
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // left column
                          Column(
                            children: [
                              _recentActions(context),
                              const SizedBox(height: 16),
                              _actionsRow(),
                            ],
                          ),
                          const SizedBox(width: 24),
                          // center balance card
                          _balanceCard(context),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // transaction list
                      _transactionsList(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showProfileDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Dev profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Введите userId профиля (dev) или создайте новый:'),
              const SizedBox(height: 8),
              TextField(controller: controller, decoration: const InputDecoration(hintText: 'user@example.com')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                final id = controller.text.trim();
                if (id.isEmpty) return;
                Navigator.of(ctx).pop();
                final wallet = WalletScope.of(context);
                try {
                  // Try to load existing profile first
                  final profile = await wallet.loadDevProfile(id);
                  if (profile == null) {
                    // generate new if none
                    await wallet.generateAndPersistForUser(id);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile loaded')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Load / Create'),
            ),
          ],
        );
      },
    );
  }
}
