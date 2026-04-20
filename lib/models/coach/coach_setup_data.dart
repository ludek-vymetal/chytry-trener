class CoachSetupData {
  final String firstName;
  final String securityPin;
  final String exportFolderPath;

  const CoachSetupData({
    required this.firstName,
    required this.securityPin,
    required this.exportFolderPath,
  });

  bool get isComplete =>
      firstName.trim().isNotEmpty &&
      securityPin.trim().length == 4 &&
      exportFolderPath.trim().isNotEmpty;

  CoachSetupData copyWith({
    String? firstName,
    String? securityPin,
    String? exportFolderPath,
  }) {
    return CoachSetupData(
      firstName: firstName ?? this.firstName,
      securityPin: securityPin ?? this.securityPin,
      exportFolderPath: exportFolderPath ?? this.exportFolderPath,
    );
  }
}