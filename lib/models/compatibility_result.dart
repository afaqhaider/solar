/// Equipment compatibility statuses. Deliberately limited — never implies
/// certification, guaranteed safety, or manufacturer sign-off.
enum CompatibilityStatus {
  withinEnteredLimits,
  outsideEnteredLimits,
  insufficientData;

  String get label {
    switch (this) {
      case CompatibilityStatus.withinEnteredLimits:
        return 'Within Entered Limits';
      case CompatibilityStatus.outsideEnteredLimits:
        return 'Outside Entered Limits';
      case CompatibilityStatus.insufficientData:
        return 'Insufficient Data';
    }
  }
}

/// One mathematical compatibility check between two pieces of equipment,
/// based solely on the specifications the user entered.
class CompatibilityCheck {
  final String title;
  final CompatibilityStatus status;
  final String detail;

  const CompatibilityCheck({
    required this.title,
    required this.status,
    required this.detail,
  });
}

const compatibilityDisclaimer =
    'Compatibility checks are based solely on specifications entered '
    'by the user and do not replace manufacturer documentation or professional system design.';
