import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_scope.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = AuthScope.of(context);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          children: const [
            _NeonAvatar(),
            SizedBox(width: 12),
            Text('Wallet 1'),
            SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Выйти',
            onPressed: () async {
              await auth.logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF151A29), Color(0xFF141826)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              _BalanceCard(
                onCopy: () async {
                  await Clipboard.setData(const ClipboardData(text: '0xF09...67c445fg84'));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address copied')));
                  }
                },
              ),
              const SizedBox(height: 16),
              _ActionsRow(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Trends', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  TextButton(onPressed: () {}, child: const Text('view all')),
                ],
              ),
              const SizedBox(height: 8),
              const _TrendTile(name: 'Litecoin', ticker: 'LTE', color: Color(0xFF4D7CFE), price: '3457.00'),
              const SizedBox(height: 12),
              const _TrendTile(name: 'Dogecoin', ticker: 'DOGE', color: Color(0xFF00D1B2), price: '4457.00'),
              const SizedBox(height: 12),
              const _TrendTile(name: 'Levcoin', ticker: 'LEV', color: Color(0xFFFFE600), price: '512.00'),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x80131A2B), blurRadius: 18, spreadRadius: 2)],
        ),
        child: FloatingActionButton(
          onPressed: () {},
          shape: const CircleBorder(),
          backgroundColor: cs.primary,
          child: const Icon(Icons.qr_code_scanner_rounded, size: 28),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.onCopy});
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2F46), Color(0xFF1A2032)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total balance', style: Theme.of(context).textTheme.bodyMedium),
              const _GrowthPill(value: '+15%'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '\$13450.00',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF212845),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your address', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                      const SizedBox(height: 6),
                      Text('0xF09...67c445fg84', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                InkWell(
                  onTap: onCopy,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A3154),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.copy_rounded, size: 18),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget action(IconData icon, String label) => Column(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF222943),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon),
            ),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        action(Icons.north_east_rounded, 'Sent'),
        action(Icons.south_rounded, 'Receive'),
        action(Icons.attach_money_rounded, 'Loan'),
        action(Icons.upload_rounded, 'Topup'),
      ],
    );
  }
}

class _TrendTile extends StatelessWidget {
  const _TrendTile({required this.name, required this.ticker, required this.color, required this.price});
  final String name;
  final String ticker;
  final Color color;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(.10), const Color(0xFF1A2030)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(.2),
            child: Icon(Icons.currency_bitcoin_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(ticker, style: const TextStyle(color: Colors.white60)),
              ],
            ),
          ),
          // Placeholder mini chart
          Container(
            height: 24,
            width: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(.2), color.withOpacity(.05)]),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Text(price, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _NeonAvatar extends StatelessWidget {
  const _NeonAvatar();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFB084FF), Color(0xFF6A63FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const CircleAvatar(
        backgroundColor: Color(0xFF1B2032),
        child: Icon(Icons.person, size: 18),
      ),
    );
  }
}

class _GrowthPill extends StatelessWidget {
  const _GrowthPill({required this.value});
  final String value;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(.18),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up, size: 16, color: cs.primary),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: const Color(0xFF141826),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => onChanged(0),
              icon: Icon(Icons.home_rounded, color: index == 0 ? Theme.of(context).colorScheme.primary : Colors.white70),
            ),
            IconButton(
              onPressed: () => onChanged(1),
              icon: Icon(Icons.account_balance_wallet_rounded, color: index == 1 ? Theme.of(context).colorScheme.primary : Colors.white70),
            ),
            const SizedBox(width: 48), // space for FAB
            IconButton(
              onPressed: () => onChanged(2),
              icon: Icon(Icons.settings_rounded, color: index == 2 ? Theme.of(context).colorScheme.primary : Colors.white70),
            ),
            IconButton(
              onPressed: () => onChanged(3),
              icon: Icon(Icons.list_alt_rounded, color: index == 3 ? Theme.of(context).colorScheme.primary : Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
