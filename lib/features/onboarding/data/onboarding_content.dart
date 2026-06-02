import '../domain/entities/onboarding_slide.dart';

/// Source de contenu de l'onboarding.
///
/// Couche data : fournit les slides à la présentation. Aujourd'hui statique ;
/// pourra être remplacée par une source distante / remote config sans impacter
/// le reste du code (la présentation ne dépend que de [OnboardingSlide]).
class OnboardingContent {
  const OnboardingContent();

  List<OnboardingSlide> getSlides() => const [
        OnboardingSlide(
          title: 'Bienvenue chez FOT DELSI',
          description:
              "Votre laverie connectée à Dakar. Lavez, séchez et pliez "
              "en toute simplicité, où que vous soyez.",
          illustration: OnboardingIllustration.wash,
        ),
        OnboardingSlide(
          title: 'Scannez, payez, lavez',
          description:
              "Scannez le QR de la machine, payez avec Wave ou Orange Money, "
              "et votre cycle démarre aussitôt.",
          illustration: OnboardingIllustration.pay,
        ),
        OnboardingSlide(
          title: 'Suivez vos cycles en direct',
          description:
              "Visualisez l'état de chaque machine en temps réel et soyez "
              "notifié dès que votre linge est prêt.",
          illustration: OnboardingIllustration.track,
        ),
      ];
}
