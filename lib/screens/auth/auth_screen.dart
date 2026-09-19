import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _registering = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final auth = Supabase.instance.client.auth;
      if (_registering) {
        final response = await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'full_name': _name.text.trim()},
        );
        if (mounted && response.session == null) {
          _message('Check your email to verify your new account.');
        }
      } else {
        await auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on AuthException catch (error) {
      if (mounted) _message(error.message);
    } catch (_) {
      if (mounted) _message('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      _message('Enter your email address first.');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) _message('Password reset instructions sent to your email.');
    } on AuthException catch (error) {
      if (mounted) _message(error.message);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 760;
                  final form = _AuthForm(
                    formKey: _formKey,
                    registering: _registering,
                    busy: _busy,
                    obscure: _obscure,
                    name: _name,
                    email: _email,
                    password: _password,
                    confirm: _confirm,
                    onSubmit: _submit,
                    onReset: _resetPassword,
                    onToggleObscure: () =>
                        setState(() => _obscure = !_obscure),
                    onToggleMode: () =>
                        setState(() => _registering = !_registering),
                  );
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 5, child: _BrandPanel(wide: wide)),
                        const SizedBox(width: 56),
                        Expanded(flex: 4, child: form),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _BrandPanel(wide: wide),
                      const SizedBox(height: 28),
                      form,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.navy,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LOST & FOUND',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.2,
            ),
          ),
          const SizedBox(height: 34),
          Text(
            'Helping the university community reconnect with what matters.',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.08,
                ),
          ),
          const SizedBox(height: 18),
          const Text(
            'A trusted space to report, search, and recover belongings across campus.',
            style: TextStyle(
              color: Color(0xFFB9C8D8),
              height: 1.5,
              fontSize: 16,
            ),
          ),
          if (wide) ...[
            const SizedBox(height: 50),
            const Row(
              children: [
                _TrustPoint(icon: Icons.verified_user_outlined, text: 'Verified community'),
                SizedBox(width: 22),
                _TrustPoint(icon: Icons.shield_outlined, text: 'Privacy first'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TrustPoint extends StatelessWidget {
  const _TrustPoint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFB9C8D8), size: 18),
        const SizedBox(width: 7),
        Text(text, style: const TextStyle(color: Color(0xFFB9C8D8))),
      ],
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.formKey,
    required this.registering,
    required this.busy,
    required this.obscure,
    required this.name,
    required this.email,
    required this.password,
    required this.confirm,
    required this.onSubmit,
    required this.onReset,
    required this.onToggleObscure,
    required this.onToggleMode,
  });

  final GlobalKey<FormState> formKey;
  final bool registering;
  final bool busy;
  final bool obscure;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController confirm;
  final VoidCallback onSubmit;
  final VoidCallback onReset;
  final VoidCallback onToggleObscure;
  final VoidCallback onToggleMode;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                registering ? 'Create your account' : 'Welcome back',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                registering
                    ? 'Join your campus community.'
                    : 'Sign in to manage your reports.',
                style: const TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 26),
              if (registering) ...[
                TextFormField(
                  controller: name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (value) =>
                      value == null || value.trim().length < 2
                          ? 'Enter your full name'
                          : null,
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Email address'),
                validator: (value) =>
                    value == null || !value.contains('@')
                        ? 'Enter a valid email'
                        : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: password,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    onPressed: onToggleObscure,
                    icon: Icon(
                      obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) => value == null || value.length < 8
                    ? 'Use at least 8 characters'
                    : null,
              ),
              if (registering) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: confirm,
                  obscureText: obscure,
                  decoration: const InputDecoration(labelText: 'Confirm password'),
                  validator: (value) =>
                      value != password.text ? 'Passwords do not match' : null,
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: busy ? null : onSubmit,
                  child: busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(registering ? 'Create account' : 'Sign in'),
                ),
              ),
              if (!registering)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: busy ? null : onReset,
                    child: const Text('Forgot password?'),
                  ),
                ),
              const Divider(height: 32),
              Center(
                child: TextButton(
                  onPressed: busy ? null : onToggleMode,
                  child: Text(
                    registering
                        ? 'Already have an account? Sign in'
                        : 'New to Lost & Found? Create an account',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
