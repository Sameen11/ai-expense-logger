class OnboardingPageModel {
  final String lottiePath;
  final String? secondLottiePath; // Added this
  final String title;
  final String subtitle;

  OnboardingPageModel({
    required this.lottiePath,
    this.secondLottiePath,
    required this.title,
    required this.subtitle
  });
}