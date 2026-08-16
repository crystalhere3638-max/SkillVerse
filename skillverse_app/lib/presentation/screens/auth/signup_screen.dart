import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _formValid = false;

  void _revalidate() {
    final valid = Validators.isUsernameValid(_usernameCtrl.text) &&
        Validators.isEmailValid(_emailCtrl.text) &&
        Validators.isPasswordStrong(_passCtrl.text) &&
        _confirmCtrl.text == _passCtrl.text &&
        _confirmCtrl.text.isNotEmpty;
    if (valid != _formValid) setState(() => _formValid = valid);
  }

  @override
  void initState() {
    super.initState();
    for (final c in [_usernameCtrl, _emailCtrl, _passCtrl, _confirmCtrl]) {
      c.addListener(_revalidate);
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_formValid) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signUp(
      username: _usernameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    if (!ok) {
      AppSnackbar.error(context, auth.errorMessage ?? 'Sign up failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 26),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Create Account ✨',
                          style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4)),
                      const SizedBox(height: 6),
                      const Text('Start your journey to becoming a skilled creator',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 28),
                      AppTextField(
                        label: 'Username',
                        icon: Icons.person_outline,
                        hint: 'yourname',
                        controller: _usernameCtrl,
                        validator: Validators.username,
                      ),
                      AppTextField(
                        label: 'Email',
                        icon: Icons.mail_outline,
                        hint: 'you@example.com',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                      ),
                      AppTextField(
                        label: 'Password',
                        icon: Icons.lock_outline,
                        hint: '••••••••',
                        controller: _passCtrl,
                        isPassword: true,
                        validator: Validators.password,
                      ),
                      AppTextField(
                        label: 'Confirm Password',
                        icon: Icons.lock_outline,
                        hint: '••••••••',
                        controller: _confirmCtrl,
                        isPassword: true,
                        validator: (v) => Validators.confirmPassword(v, _passCtrl.text),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 18),
                        child: Text(
                          'Use 8+ characters with upper & lower case, a number, and a symbol.',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.5),
                        ),
                      ),
                      AppButton(
                        label: 'Create Account',
                        isLoading: auth.isLoading,
                        onPressed: _formValid ? _submit : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
