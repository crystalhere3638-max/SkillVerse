import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendPasswordResetEmail(_emailCtrl.text.trim());
    if (!mounted) return;
    if (ok) {
      setState(() => _sent = true);
      AppSnackbar.success(context, 'Reset link sent — check your inbox.');
    } else {
      AppSnackbar.error(context, auth.errorMessage ?? 'Could not send reset email.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(leading: const BackButton(color: Colors.white)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 26),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reset Password',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
                const SizedBox(height: 8),
                const Text(
                  "Enter the email linked to your account and we'll send a link to reset your password.",
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
                ),
                const SizedBox(height: 28),
                AppTextField(
                  label: 'Email',
                  icon: Icons.mail_outline,
                  hint: 'you@example.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 6),
                AppButton(
                  label: _sent ? 'Resend Link' : 'Send Reset Link',
                  isLoading: auth.isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
