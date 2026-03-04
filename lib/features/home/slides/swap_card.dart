part of '../home_page.dart';

class _SwapCard extends StatelessWidget {
  const _SwapCard({
    required this.label,
    required this.token,
    required this.amount,
  });

  final String label;
  final String token;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF14191E) : Colors.white;
    final borderColor = isDark
        ? const Color(0x1AFFFFFF)
        : Colors.black.withValues(alpha: 0.08);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedTextColor = isDark
        ? const Color(0xFF8E99C0)
        : const Color(0xFF475569);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: bgColor,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(color: mutedTextColor, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0x332E9AFF),
                ),
                child: Row(
                  children: [
                    Text(
                      token,
                      style: GoogleFonts.inter(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.expand_more, color: primaryTextColor, size: 18),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  amount,
                  style: GoogleFonts.inter(
                    color: primaryTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
