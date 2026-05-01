/// Represents a single class score from the model.
class ClassScore {
  final String label;
  final String displayName;
  final double confidence;

  const ClassScore({
    required this.label,
    required this.displayName,
    required this.confidence,
  });
}

/// Full result returned by the classifier.
class ClassificationResult {
  final String label;
  final String displayName;
  final double confidence;
  final List<ClassScore> topClasses;
  final int inferenceTimeMs;

  const ClassificationResult({
    required this.label,
    required this.displayName,
    required this.confidence,
    required this.topClasses,
    required this.inferenceTimeMs,
  });

  /// Risk level derived purely from the predicted label.
  ///
  /// | Label      | Risk           | Rationale                              |
  /// |------------|----------------|----------------------------------------|
  /// | melanoma   | HIGH           | Malignant melanoma                     |
  /// | nevus      | NONE           | Benign mole – no clinical concern      |
  /// | other      | LOW → MEDIUM   | Confidence-gated: ≥70 % → medium      |
  RiskLevel get riskLevel {
    switch (label) {
      case 'melanoma':
        return RiskLevel.high;
      case 'nevus':
        return RiskLevel.none;
      case 'other':
        // Escalate to medium when the model is very confident it is an
        // "other" skin condition (e.g. BCC / AK buried in this bucket).
        return confidence >= 0.70 ? RiskLevel.medium : RiskLevel.low;
      default:
        return RiskLevel.low;
    }
  }
}

enum RiskLevel { none, low, medium, high }
