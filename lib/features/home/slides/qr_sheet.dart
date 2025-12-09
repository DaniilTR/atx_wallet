part of '../home_page.dart';

class _QrSheet extends StatefulWidget {
  const _QrSheet({required this.address});

  final String? address;

  @override
  State<_QrSheet> createState() => _QrSheetState();
}

class _QrSheetState extends State<_QrSheet> {
  final MobileScannerController _scannerController = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  bool _scannerMode = false;
  bool _scanError = false;
  bool _processingScan = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _toggleMode(bool scanner) {
    if (_scannerMode == scanner) return;
    setState(() {
      _scannerMode = scanner;
      _scanError = false;
    });
    if (scanner) {
      _scannerController.start();
    } else {
      _scannerController.stop();
    }
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (!_scannerMode || _processingScan) return;
    final raw = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .firstWhere(
          (value) => value != null && value.trim().isNotEmpty,
          orElse: () => null,
        );
    if (raw == null) return;
    final parsed = _sanitizeAddress(raw);
    if (parsed == null) {
      if (!_scanError) {
        setState(() => _scanError = true);
      }
      return;
    }
    setState(() {
      _processingScan = true;
      _scanError = false;
    });
    await _scannerController.stop();
    if (!mounted) return;
    Navigator.of(context).pop(parsed);
  }

  String? _sanitizeAddress(String value) {
    final cleaned = value.replaceAll('\u0000', '').trim();
    final pattern = RegExp(r'^0x[a-fA-F0-9]{40}$');
    return pattern.hasMatch(cleaned) ? cleaned : null;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final fallback = widget.address ?? 'Адрес недоступен';
    final sheetHeight = (media.size.height * 0.82).clamp(420.0, 760.0);

    return _SheetContainer(
      title: 'QR & Сканер',
      subtitle: 'Покажите свой адрес или отсканируйте чужой',
      child: SizedBox(
        height: sheetHeight.toDouble(),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _QrModeButton(
                    icon: Icons.qr_code_rounded,
                    label: 'Мой QR',
                    active: !_scannerMode,
                    onTap: () => _toggleMode(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QrModeButton(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Сканировать',
                    active: _scannerMode,
                    onTap: () => _toggleMode(true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _scannerMode
                    ? _ScannerPane(
                        key: const ValueKey('scanner'),
                        controller: _scannerController,
                        scanError: _scanError,
                        onDetect: _handleDetection,
                      )
                    : _MyQrPane(
                        key: const ValueKey('my_qr'),
                        address: fallback,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 60),
              child: _scannerMode
                  ? Column(
                      children: [
                        Text(
                          'Наведите камеру на QR-код. Работает оффлайн.',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF9AA5CC),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        AnimatedOpacity(
                          opacity: _scanError ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            'Это не правильный QR',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFFF8F8F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Text(
                          'Сканируйте, чтобы поделиться адресом',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF9AA5CC),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          fallback,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrModeButton extends StatelessWidget {
  const _QrModeButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : const Color(0xFF7F8CB7);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1F2642) : const Color(0xFF141A2B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? const Color(0xFF4C63FF) : const Color(0x332F3A5F),
        ),
      ),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color),
        label: Text(
          label,
          style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _MyQrPane extends StatelessWidget {
  const _MyQrPane({required super.key, required this.address});
  // для нее задай отступ снизу 100
  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2645), Color(0xFF12162B)],
        ),
        border: Border.all(color: const Color(0x22FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55121C3C),
            blurRadius: 30,
            offset: Offset(0, 22),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: QrImageView(
          data: address,
          backgroundColor: Colors.transparent,
          size: double.infinity,
          gapless: false,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Color(0xFF80B7FF),
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Color(0xFF80B7FF),
          ),
        ),
      ),
    );
  }
}

class _ScannerPane extends StatelessWidget {
  const _ScannerPane({
    required super.key,
    required this.controller,
    required this.scanError,
    required this.onDetect,
  });

  final MobileScannerController controller;
  final bool scanError;
  final Function(BarcodeCapture) onDetect;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F1323), Color(0xFF131A2F)],
                ),
              ),
              child: MobileScanner(controller: controller, onDetect: onDetect),
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: scanError ? const Color(0xFFFF8F8F) : Colors.white,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
