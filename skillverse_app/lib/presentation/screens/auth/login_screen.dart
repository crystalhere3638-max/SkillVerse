import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signIn(email: _emailCtrl.text.trim(), password: _passCtrl.text);
    if (!mounted) return;
    if (!ok) AppSnackbar.error(context, auth.errorMessage ?? 'Login failed. Please try again.');
  }

  Future<void> _submitGoogle() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (!mounted) return;
    if (!ok) AppSnackbar.error(context, auth.errorMessage ?? 'Google sign-in failed.');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome Back 👋',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4)),
                const SizedBox(height: 6),
                const Text('Login to continue your SkillVerse journey',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 30),
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
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                    ),
                    child: const Text('Forgot Password?',
                        style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 6),
                AppButton(label: 'Login', isLoading: auth.isLoading, onPressed: _submit),
                const SizedBox(height: 24),
                Row(children: const [
                  Expanded(child: Divider(color: AppColors.divider)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('or continue with', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ),
                  Expanded(child: Divider(color: AppColors.divider)),
                ]),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Continue with Google',
                  variant: AppButtonVariant.outlined,
                  isLoading: auth.isLoading,
                  onPressed: _submitGoogle,
                  icon: const Text('G', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 18)),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      const Text("Don't have an account? ", style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SignupScreen()),
                        ),
                        child: const Text('Create Account',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
