// EDIT_TARGET: lib/screens/auth_screen.dart
// EDIT_PURPOSE: Provides the Firebase email/password sign-in screen
// EDIT_REASON: User accounts are provisioned manually and registration is disabled

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    final signedIn = await widget.authService.signIn(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);
    if (!signedIn) {
      showAppToast(
        context,
        widget.authService.lastError ?? 'Email or password is incorrect.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AppCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Sign In', style: AppTextStyles.pageTitle),
                      const SizedBox(height: 8),
                      Text(
                        'Smart Building App',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _EmailInput(controller: _emailController),
                      const SizedBox(height: 14),
                      _PasswordInput(controller: _passwordController),
                      const SizedBox(height: 22),
                      AppButton(
                        label: 'Sign In',
                        onPressed: _isSubmitting ? null : _submit,
                        isExpanded: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailInput extends StatelessWidget {
  const _EmailInput({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppTextInput(
      label: 'Email',
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) {
          return 'Email is required.';
        }
        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
          return 'Enter a valid email.';
        }
        return null;
      },
    );
  }
}

class _PasswordInput extends StatefulWidget {
  const _PasswordInput({required this.controller});

  final TextEditingController controller;

  @override
  State<_PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<_PasswordInput> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AppTextInput(
      label: 'Password',
      controller: widget.controller,
      obscureText: _obscure,
      suffixIcon: IconButton(
        tooltip: _obscure ? 'Show password' : 'Hide password',
        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
      validator: (value) {
        if ((value ?? '').isEmpty) {
          return 'Password is required.';
        }
        return null;
      },
    );
  }
}
