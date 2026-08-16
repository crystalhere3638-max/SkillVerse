import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final AutovalidateMode autovalidateMode;
  final void Function(String)? onChanged;

  const AppTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.onChanged,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.controller,
            obscureText: widget.isPassword && _obscure,
            keyboardType: widget.keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            validator: widget.validator,
            autovalidateMode: widget.autovalidateMode,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: Icon(widget.icon, size: 18, color: AppColors.textMuted),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
