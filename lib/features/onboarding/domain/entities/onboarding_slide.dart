/// Type d'illustration d'un écran d'onboarding.
///
/// La couche domaine reste indépendante de Flutter : on expose un simple
/// énuméré plutôt qu'un `IconData` ou un chemin d'asset. La couche
/// présentation décide ensuite comment chaque type est rendu visuellement.
enum OnboardingIllustration { wash, pay, track }

/// Entité métier : un écran d'onboarding.
class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.illustration,
  });

  final String title;
  final String description;
  final OnboardingIllustration illustration;
}
