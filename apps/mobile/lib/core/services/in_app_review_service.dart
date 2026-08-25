import 'dart:developer' as developer;
import 'package:flutter/material.dart';

class InAppReviewService {
  static int _completedRidesCount = 0;

  static void incrementRideCount() {
    _completedRidesCount++;
    developer.log('Completed rides count: $_completedRidesCount', name: 'RideOS.InAppReviewService');
  }

  static Future<void> triggerInAppReviewIfEligible(BuildContext context) async {
    if (_completedRidesCount >= 3) {
      developer.log('Rider eligible for Play Store / App Store in-app review prompt.', name: 'RideOS.InAppReviewService');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enjoying RideOS AI? Rate us 5 stars on Google Play Store!'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}
