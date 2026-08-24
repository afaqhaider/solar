/// A workflow state, not a certification. The app never claims to certify,
/// approve, or verify the safety of a plan — "Reviewed" only means the user
/// chose to mark it that way.
enum ProjectStatus {
  draft,
  readyForReview,
  reviewed;

  String get label {
    switch (this) {
      case ProjectStatus.draft:
        return 'Draft';
      case ProjectStatus.readyForReview:
        return 'Ready for Review';
      case ProjectStatus.reviewed:
        return 'Reviewed';
    }
  }

  static ProjectStatus fromName(String? name) {
    return ProjectStatus.values.firstWhere(
      (s) => s.name == name,
      orElse: () => ProjectStatus.draft,
    );
  }
}
