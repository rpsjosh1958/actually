import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingStepProvider = NotifierProvider<OnboardingViewModel, int>(
  OnboardingViewModel.new,
);

class OnboardingViewModel extends Notifier<int> {
  @override
  int build() => 0;

  /// Returns true once past the last step (caller should navigate on).
  bool next() {
    if (state < 2) {
      state += 1;
      return false;
    }
    return true;
  }
}
