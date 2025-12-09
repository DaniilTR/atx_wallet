part of '../home_page.dart';

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.controller,
    this.keyboardType,
    this.validator,
    this.textInputAction,
    this.onChanged,
  });

  final String label;
  final String hint;
  final IconData prefixIcon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFFB5BEDF),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          textInputAction: textInputAction,
          onChanged: onChanged,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: const Color(0xFF6A7398)),
            filled: true,
            fillColor: const Color(0xFF1A223E),
            prefixIcon: Icon(prefixIcon, color: const Color(0xFF6FE1F5)),
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
    );
  }
}
