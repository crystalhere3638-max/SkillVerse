enum ReportReason { spam, harassment, fakeContent, violence, other }

extension ReportReasonX on ReportReason {
  String get label {
    switch (this) {
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.harassment:
        return 'Harassment';
      case ReportReason.fakeContent:
        return 'Fake Content';
      case ReportReason.violence:
        return 'Violence';
      case ReportReason.other:
        return 'Other';
    }
  }
}

/// A submitted report. Persisted locally only for now — ready to be
/// forwarded to a moderation backend once one exists.
class Report {
  final String id;
  final String postId;
  final ReportReason reason;
  final DateTime createdAt;

  const Report({
    required this.id,
    required this.postId,
    required this.reason,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'reason': reason.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Report.fromJson(Map<String, dynamic> json) => Report(
        id: json['id'] as String,
        postId: json['postId'] as String,
        reason: ReportReason.values.firstWhere(
          (r) => r.name == json['reason'],
          orElse: () => ReportReason.other,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
