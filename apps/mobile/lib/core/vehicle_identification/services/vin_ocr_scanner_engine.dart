import 'package:flutter/foundation.dart';
import 'vin_identification_engine.dart';
import '../models/vin_decoder_models.dart';

@immutable
class VinOcrCandidateMatch {
  final String rawOcrText;
  final String candidateVin;
  final double ocrConfidence;
  final VinIdentificationResult decodeResult;
  final bool isExactChecksumVerified;

  const VinOcrCandidateMatch({
    required this.rawOcrText,
    required this.candidateVin,
    required this.ocrConfidence,
    required this.decodeResult,
    required this.isExactChecksumVerified,
  });
}

class VinOcrScannerEngine {
  static final VinOcrScannerEngine instance = VinOcrScannerEngine._internal();
  factory VinOcrScannerEngine() => instance;
  VinOcrScannerEngine._internal();

  final VinIdentificationEngine _decoder = VinIdentificationEngine.instance;

  /// Processes raw OCR recognized text blocks from camera frame and extracts valid VIN candidates.
  List<VinOcrCandidateMatch> parseOcrText(String rawOcrText) {
    if (rawOcrText.trim().isEmpty) return [];

    final candidates = <VinOcrCandidateMatch>[];
    final lines = rawOcrText.split(RegExp(r'[\r\n]+'));

    for (final line in lines) {
      final sanitized = line.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

      // Check for exact 17-character sequence
      if (sanitized.length == 17) {
        final match = _evaluateCandidate(line, sanitized);
        if (match != null) candidates.add(match);
      } else if (sanitized.length > 17) {
        // Sliding window of length 17
        for (int i = 0; i <= sanitized.length - 17; i++) {
          final window = sanitized.substring(i, i + 17);
          final match = _evaluateCandidate(line, window);
          if (match != null) candidates.add(match);
        }
      } else if (sanitized.length >= 15) {
        // Heuristic correction for common OCR confusion: 'I' -> '1', 'O'/'Q' -> '0'
        final corrected = sanitized
            .replaceAll('I', '1')
            .replaceAll('O', '0')
            .replaceAll('Q', '0');
        if (corrected.length == 17) {
          final match = _evaluateCandidate(line, corrected);
          if (match != null) candidates.add(match);
        }
      }
    }

    // Sort by confidence: exact checksum verified first, then highest confidence
    candidates.sort((a, b) {
      if (a.isExactChecksumVerified && !b.isExactChecksumVerified) return -1;
      if (!a.isExactChecksumVerified && b.isExactChecksumVerified) return 1;
      return b.ocrConfidence.compareTo(a.ocrConfidence);
    });

    return candidates;
  }

  VinOcrCandidateMatch? _evaluateCandidate(String originalLine, String candidate) {
    if (candidate.contains(RegExp(r'[IOQ]'))) return null;
    final decodeResult = _decoder.decodeVin(candidate);
    final isValidChecksum = decodeResult.isValid && decodeResult.validationStatus == VinValidationStatus.valid;

    double confidence = 0.50;
    if (isValidChecksum) {
      confidence = decodeResult.resolvedVehicleModel != null ? 1.0 : 0.90;
    } else if (decodeResult.validationStatus == VinValidationStatus.unrecognizedWmi) {
      confidence = 0.70;
    }

    return VinOcrCandidateMatch(
      rawOcrText: originalLine,
      candidateVin: candidate,
      ocrConfidence: confidence,
      decodeResult: decodeResult,
      isExactChecksumVerified: isValidChecksum,
    );
  }
}
