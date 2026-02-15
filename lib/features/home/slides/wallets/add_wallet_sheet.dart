part of '../../home_page.dart';

Future<T?> showAddWalletSheet<T>(BuildContext context) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 16,
          right: 16,
          top: 12,
        ),
        child: const _AddWalletSheet(),
      ),
    ),
  );
}

class _AddWalletSheet extends StatefulWidget {
  const _AddWalletSheet();

  @override
  State<_AddWalletSheet> createState() => _AddWalletSheetState();
}

class _AddWalletSheetState extends State<_AddWalletSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _wordsCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _wordsCtrl.dispose();
    super.dispose();
  }

  String _normalizeWords(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String? _validateWords(String? value) {
    final normalized = _normalizeWords(value ?? '');
    if (normalized.isEmpty) return null; // пусто = создать новый
    final parts = normalized.split(' ').where((w) => w.isNotEmpty).toList();
    if (parts.length != 12) {
      return 'Нужно ровно 12 слов (через пробел)';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final wallet = WalletScope.read(context);
    final auth = AuthScope.of(context);
    final userId = auth.currentUser?.id;
    if (userId == null) return;

    final name = _nameCtrl.text.trim();
    final words = _normalizeWords(_wordsCtrl.text);

    setState(() => _loading = true);
    try {
      if (words.isEmpty) {
        await wallet.createNewWallet(
          userId: userId,
          name: name.isEmpty ? null : name,
        );
      } else {
        await wallet.importWalletFromMnemonic(
          userId: userId,
          mnemonic: words,
          name: name.isEmpty ? null : name,
        );
      }
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString(), style: GoogleFonts.inter())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      title: 'Добавить кошелёк',
      subtitle: 'Импорт по 12 словам или создание нового',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _LabeledField(
              label: 'Название ',
              hint: 'Например: Основной',
              prefixIcon: Icons.edit_rounded,
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '12 секретных слов',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFB5BEDF),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _wordsCtrl,
                  validator: _validateWords,
                  minLines: 3,
                  maxLines: 5,
                  textInputAction: TextInputAction.done,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    hintText:
                        'Введите 12 слов через пробел чтобы импортировать, или оставьте пустым для создания нового кошелька',
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF6A7398),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF14191E),
                    prefixIcon: const Icon(
                      Icons.key_rounded,
                      color: Color(0xFF6FE1F5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0x332E9AFF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0x332E9AFF)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _PrimaryButton(
              label: _loading
                  ? 'Подождите…'
                  : (_wordsCtrl.text.trim().isEmpty
                        ? 'Создать новый'
                        : 'Импортировать'),
              onPressed: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
