part of '../home_page.dart';

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF14191E),
        border: Border.all(color: const Color(0x113D7CFF)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(color: const Color(0xFF8FA1D9)),
      ),
    );
  }
}
