import 'package:flutter/material.dart';
import '../../services/config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller.text = ApiConfig.base;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ApiConfig.setBase(_controller.text.trim());
    setState(() => _saving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('API Base URL (for dev/testing)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(hintText: 'http://192.168.1.100:3000'),
            ),
            const SizedBox(height: 12),
            Row(children: [
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  _controller.text = kApiBaseUrl;
                },
                child: const Text('Reset to default'),
              ),
            ])
          ],
        ),
      ),
    );
  }
}
