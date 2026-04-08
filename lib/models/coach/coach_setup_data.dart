class CoachSetupData {
  final String firstName;
  final String securityPin;

  const CoachSetupData({
    required this.firstName,
    required this.securityPin,
  });

  bool get isComplete =>
      firstName.trim().isNotEmpty && securityPin.trim().length == 4;

  CoachSetupData copyWith({
    String? firstName,
    String? securityPin,
  }) {
    return CoachSetupData(
      firstName: firstName ?? this.firstName,
      securityPin: securityPin ?? this.securityPin,
    );
  }
}