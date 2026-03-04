import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../utils/validators.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'counter@motibakery.com');
  final _passwordController = TextEditingController(text: '1234');
  bool _obscurePassword = true;

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

    await ref.read(authControllerProvider).login(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider).state;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: 24),
                    const Icon(Icons.cake_rounded, size: 80, color: AppColors.primary)
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.25, end: 0, duration: 300.ms),
                    const SizedBox(height: 12),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.displayMedium,
                        children: const [
                          TextSpan(
                            text: 'moti ',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: 'BAKERY',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 50.ms),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to your account',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      autofocus: true,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: Validators.email,
                    ).animate().fadeIn(delay: 150.ms, duration: 250.ms),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      validator: (value) => Validators.requiredField(
                        value,
                        label: 'Password',
                      ),
                    ).animate().fadeIn(delay: 250.ms, duration: 250.ms),
                    if (authState.error != null) ...<Widget>[
                      const SizedBox(height: 10),
                      Text(
                        authState.error!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: authState.isLoading ? null : _submit,
                      child: authState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign In'),
                    ).animate().fadeIn(delay: 350.ms, duration: 250.ms),
                    const SizedBox(height: 12),
                    Text(
                      'Accounts managed by Admin only',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
