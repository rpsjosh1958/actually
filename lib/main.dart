import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_shell.dart';
import 'core/data/onboarding_prefs.dart';
import 'core/providers/actually_profile_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/bouncing_dots.dart';
import 'features/auth/view/login_screen.dart';
import 'features/onboarding/view/onboarding_screen.dart';
import 'features/splash/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: ActuallyApp()));
}

class ActuallyApp extends ConsumerWidget {
  const ActuallyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Actually',
      debugShowCheckedModeBanner: false,
      theme: AppThemeNotifier.light,
      home: const _SplashGate(),
    );
  }
}

class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return SplashScreen(onComplete: () => setState(() => _splashDone = true));
    }
    return const _AuthGate();
  }
}

/// Order is onboarding → login → menu: a signed-out visitor sees the
/// tutorial carousel first, then signs in/up, then lands on the menu. A
/// returning session (already authenticated) skips straight to the menu —
/// onboarding is a first-look pitch, not a gate for every launch.
class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate();

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  // null while the persisted flag is still loading, so a signed-out visitor
  // never flashes onboarding for a frame before we know they've seen it.
  bool? _onboardingSeen;

  @override
  void initState() {
    super.initState();
    OnboardingPrefs.isSeen().then((seen) {
      if (mounted) setState(() => _onboardingSeen = seen);
    });
  }

  void _completeOnboarding() {
    setState(() => _onboardingSeen = true);
    OnboardingPrefs.markSeen();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final colors = Theme.of(context).appColors;

    return authState.when(
      data: (user) {
        if (user != null) {
          // Covers a returning session (user already signed in on app
          // launch) — the sign-in/up flows themselves also bootstrap.
          ref.read(actuallyProfileActionsProvider).bootstrapIfNeeded();
          return const AppShell();
        }
        if (_onboardingSeen == null) {
          return Scaffold(
            backgroundColor: colors.background,
            body: Center(child: BouncingDots(color: colors.accent)),
          );
        }
        if (!_onboardingSeen!) {
          return OnboardingScreen(onComplete: _completeOnboarding);
        }
        return const LoginScreen();
      },
      loading: () => Scaffold(
        backgroundColor: colors.background,
        body: Center(child: BouncingDots(color: colors.accent)),
      ),
      error: (error, stack) => const LoginScreen(),
    );
  }
}
