import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/accent_button.dart';
import '../view_model/auth_view_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isSignUp = false;
  bool _obscure = true;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final vm = ref.read(authViewModelProvider.notifier);
    final emailOrUsername = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (_isSignUp) {
      vm.signUpWithEmail(emailOrUsername, password, _nameCtrl.text.trim());
    } else {
      vm.signInWithEmailOrUsername(emailOrUsername, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).appTextTheme;
    final auth = ref.watch(authViewModelProvider);

    ref.listen(authViewModelProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.error!,
              style: textTheme.body.copyWith(color: Colors.white),
            ),
            backgroundColor: colors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(authViewModelProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: colors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              // Bounded min-height so Center actually centers the form
              // instead of just sizing to it.
              constraints: BoxConstraints(minHeight: viewport.maxHeight),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: textTheme.headline.copyWith(
                          fontSize: 24,
                          color: colors.paperText,
                        ),
                        children: [
                          const TextSpan(text: 'ACTUALLY'),
                          TextSpan(
                            text: '...',
                            style: TextStyle(color: colors.accent),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _isSignUp ? 'JOIN THE CLUB' : 'BACK FOR MORE?',
                      style: textTheme.wordmark.copyWith(
                        fontSize: 42,
                        color: colors.paperText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isSignUp
                          ? 'make an account. start busting myths.'
                          : 'sign in. your streak missed you.',
                      style: textTheme.bodyRegular.copyWith(
                        color: colors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SortaHint(colors: colors, textTheme: textTheme),
                    const SizedBox(height: 22),
                    if (_isSignUp) ...[
                      _PillField(
                        controller: _nameCtrl,
                        hint: 'username',
                        colors: colors,
                        textTheme: textTheme,
                      ),
                      const SizedBox(height: 14),
                    ],
                    _PillField(
                      controller: _emailCtrl,
                      hint: _isSignUp ? 'email' : 'email or username',
                      colors: colors,
                      textTheme: textTheme,
                      keyboardType: _isSignUp
                          ? TextInputType.emailAddress
                          : TextInputType.text,
                    ),
                    const SizedBox(height: 14),
                    _PillField(
                      controller: _passwordCtrl,
                      hint: 'password',
                      colors: colors,
                      textTheme: textTheme,
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: colors.faintText,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    const SizedBox(height: 26),
                    AccentButton(
                      label: _isSignUp ? 'SIGN UP' : 'SIGN IN',
                      variant: AccentButtonVariant.ink,
                      onTap: auth.isLoading ? null : _submit,
                      isLoading: auth.isLoading,
                    ),
                    const SizedBox(height: 22),
                    Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _isSignUp = !_isSignUp);
                          ref.read(authViewModelProvider.notifier).clearError();
                        },
                        child: RichText(
                          text: TextSpan(
                            style: textTheme.bodyRegular.copyWith(
                              color: colors.mutedText,
                            ),
                            children: [
                              TextSpan(
                                text: _isSignUp
                                    ? 'already in the club?  '
                                    : 'new here?  ',
                              ),
                              TextSpan(
                                text: _isSignUp ? 'sign in' : 'sign up',
                                style: TextStyle(
                                  color: colors.paperText,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

class _SortaHint extends StatelessWidget {
  final AppColorsExtension colors;
  final AppTextThemeExtension textTheme;

  const _SortaHint({required this.colors, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.paperBg,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: colors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              'got a SORTA account? same login works here.',
              style: textTheme.bodyRegular.copyWith(
                fontSize: 12.5,
                color: colors.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final AppColorsExtension colors;
  final AppTextThemeExtension textTheme;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _PillField({
    required this.controller,
    required this.hint,
    required this.colors,
    required this.textTheme,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.paperBg,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: textTheme.body.copyWith(color: colors.paperText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: textTheme.bodyRegular.copyWith(color: colors.faintText),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 20,
          ),
        ),
      ),
    );
  }
}
