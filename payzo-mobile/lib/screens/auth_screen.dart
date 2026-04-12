import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../animations/animations.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final bool startWithLogin;
  const AuthScreen({super.key, this.startWithLogin = true});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late bool _isLogin;
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl            = TextEditingController();
  final _emailCtrl           = TextEditingController();
  final _passwordCtrl        = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  late final AnimationController _switchCtrl;
  late final Animation<double> _switchAnim;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.startWithLogin;
    _switchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 1.0,
    );
    _switchAnim = CurvedAnimation(parent: _switchCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _switchCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleMode() async {
    ref.read(authProvider.notifier).clearError();
    await _switchCtrl.reverse();
    setState(() => _isLogin = !_isLogin);
    _switchCtrl.forward();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = ref.read(authProvider.notifier);
    bool success;
    if (_isLogin) {
      success = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    } else {
      success = await auth.register(
        name:     _nameCtrl.text.trim(),
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        passwordConfirmation: _confirmPasswordCtrl.text,
      );
    }
    if (success && mounted) {
      final user = ref.read(authProvider).user;
      final destination = (user != null && !user.hasTransactionPin)
          ? AppRoutes.pinSetup
          : AppRoutes.shell;
      Navigator.pushReplacementNamed(context, destination);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              // Logo
              FadeSlideIn(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.cardGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'payzo',
                      style: tt.titleLarge?.copyWith(fontSize: 26, letterSpacing: -1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Heading
              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: FadeTransition(
                  opacity: _switchAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin ? 'Welcome back 👋' : 'Create account',
                        style: tt.displayMedium?.copyWith(fontSize: 30, letterSpacing: -0.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin
                            ? 'Sign in to continue to Payzo'
                            : 'Join thousands moving money smarter',
                        style: tt.bodyLarge?.copyWith(fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 56),
              // Form
              FadeSlideIn(
                delay: const Duration(milliseconds: 180),
                child: FadeTransition(
                  opacity: _switchAnim,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (!_isLogin) ...[
                          AppTextField(
                            label: 'Full Name',
                            hint: 'John Doe',
                            controller: _nameCtrl,
                            prefixIcon: Icons.person_outline_rounded,
                            textInputAction: TextInputAction.next,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                          ),
                          const SizedBox(height: 16),
                        ],
                        AppTextField(
                          label: 'Email',
                          hint: 'you@example.com',
                          controller: _emailCtrl,
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) =>
                              (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Password',
                          hint: '••••••••',
                          controller: _passwordCtrl,
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: true,
                          textInputAction: _isLogin
                              ? TextInputAction.done
                              : TextInputAction.next,
                          onSubmitted: _isLogin ? (_) => _submit() : null,
                          validator: (v) =>
                              (v == null || v.length < 8) ? 'Min 8 characters' : null,
                        ),
                        if (!_isLogin) ...[
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Confirm Password',
                            hint: '••••••••',
                            controller: _confirmPasswordCtrl,
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Please confirm password';
                              if (v != _passwordCtrl.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Error
              if (state.error != null)
                FadeSlideIn(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: cs.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: cs.error, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            state.error!,
                            style: TextStyle(color: cs.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              FadeSlideIn(
                delay: const Duration(milliseconds: 260),
                child: PrimaryButton(
                  label: _isLogin ? 'Sign In' : 'Create Account',
                  onTap: _submit,
                  isLoading: state.isLoading,
                ),
              ),
              const SizedBox(height: 24),
              // Toggle
              FadeSlideIn(
                delay: const Duration(milliseconds: 320),
                child: Center(
                  child: GestureDetector(
                    onTap: _toggleMode,
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 14, color: cs.onSurface),
                        children: [
                          TextSpan(
                            text: _isLogin
                                ? "Don't have an account? "
                                : 'Already have an account? ',
                            style: tt.bodyMedium,
                          ),
                          TextSpan(
                            text: _isLogin ? 'Sign Up' : 'Sign In',
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Divider
              FadeSlideIn(
                delay: const Duration(milliseconds: 360),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: cs.outlineVariant, thickness: 0.5)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                    Expanded(child: Divider(color: cs.outlineVariant, thickness: 0.5)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Guest button
              FadeSlideIn(
                delay: const Duration(milliseconds: 400),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.shell,
                        ),
                        icon: Icon(
                          Icons.visibility_outlined,
                          size: 18,
                          color: cs.onSurfaceVariant,
                        ),
                        label: Text(
                          'Continue as Guest',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: cs.outlineVariant,
                            width: 0.8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explore the app without signing in',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
