import 'dart:async';
import 'dart:developer' as developer;

class BetaTesterProfile {
  final String testerId;
  final String email;
  final String invitationCode;
  final String betaTrackGroup;
  final bool isAccessApproved;

  const BetaTesterProfile({
    required this.testerId,
    required this.email,
    required this.invitationCode,
    required this.betaTrackGroup,
    required this.isAccessApproved,
  });
}

class BetaFeedbackReport {
  final String reportId;
  final String category;
  final String userFeedbackText;
  final int ratingStars;
  final String timestampIso;

  const BetaFeedbackReport({
    required this.reportId,
    required this.category,
    required this.userFeedbackText,
    required this.ratingStars,
    required this.timestampIso,
  });
}

class ProductionClosedBetaLaunchEngine {
  static final ProductionClosedBetaLaunchEngine instance = ProductionClosedBetaLaunchEngine._internal();
  ProductionClosedBetaLaunchEngine._internal();

  final _feedbackStreamController = StreamController<BetaFeedbackReport>.broadcast();

  Stream<BetaFeedbackReport> get feedbackStream => _feedbackStreamController.stream;

  BetaTesterProfile validateBetaInvitationCode({required String invitationCode}) {
    developer.log('Validating Closed Beta Invitation Code [$invitationCode]...', name: 'RideOS.ClosedBeta');
    throw Exception('CONFIGURATION REQUIRED: Backend invitation validation required.');
  }

  BetaFeedbackReport submitBetaFeedback({
    required String category,
    required String feedbackText,
    required int ratingStars,
  }) {
    developer.log('Submitting Closed Beta Feedback [$category - $ratingStars Stars]: "$feedbackText"', name: 'RideOS.BetaFeedback');
    final report = BetaFeedbackReport(
      reportId: 'fb_report_7741',
      category: category,
      userFeedbackText: feedbackText,
      ratingStars: ratingStars,
      timestampIso: DateTime.now().toIso8601String(),
    );
    _feedbackStreamController.add(report);
    return report;
  }

  void captureCrashTelemetry({required String errorDetails, required String stackTrace}) {
    developer.log('CRASH TELEMETRY CAPTURED: [$errorDetails]', name: 'RideOS.CrashReporting');
  }

  void dispose() {
    _feedbackStreamController.close();
  }
}
