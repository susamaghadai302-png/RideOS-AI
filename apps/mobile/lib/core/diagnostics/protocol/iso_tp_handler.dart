import 'package:flutter/foundation.dart';

/// ISO 15765-2 ISO-TP Frame Types.
enum IsoTpFrameType {
  singleFrame(0x0),
  firstFrame(0x1),
  consecutiveFrame(0x2),
  flowControl(0x3);

  final int pciNibble;
  const IsoTpFrameType(this.pciNibble);
}

/// Flow Control Status values.
enum IsoTpFlowStatus {
  continueToSend(0x0),
  wait(0x1),
  overflow(0x2);

  final int value;
  const IsoTpFlowStatus(this.value);
}

/// ISO 15765-2 Transport Protocol (ISO-TP) Network Layer Handler.
///
/// Provides fragmentation of application messages into CAN frames (Single Frame
/// or First Frame + Consecutive Frames) and reassembly of segmented CAN frames
/// into full diagnostic payloads.
class IsoTpHandler {
  /// Maximum payload for Single Frame on standard 8-byte CAN.
  static const int maxSingleFramePayload = 7;

  /// Maximum ISO-TP payload length (12-bit length in First Frame).
  static const int maxIsoTpPayload = 4095;

  // Reassembly state
  bool _isReassembling = false;
  int _expectedLength = 0;
  int _nextSequenceNumber = 1;
  final List<int> _reassemblyBuffer = [];

  bool get isReassembling => _isReassembling;
  int get expectedLength => _expectedLength;
  int get currentReceivedLength => _reassemblyBuffer.length;

  /// Resets the reassembly buffer.
  void resetReassembly() {
    _isReassembling = false;
    _expectedLength = 0;
    _nextSequenceNumber = 1;
    _reassemblyBuffer.clear();
  }

  /// Encodes an application payload into one or more 8-byte CAN frames.
  ///
  /// If payload <= 7 bytes: returns a single Single Frame [0x0N, ...payload].
  /// If payload > 7 bytes: returns a First Frame followed by Consecutive Frames.
  List<Uint8List> encodePayload(List<int> payload) {
    if (payload.isEmpty) {
      throw ArgumentError('Payload cannot be empty');
    }
    if (payload.length > maxIsoTpPayload) {
      throw ArgumentError(
        'Payload length ${payload.length} exceeds ISO-TP limit of $maxIsoTpPayload bytes',
      );
    }

    final frames = <Uint8List>[];

    // Single Frame (SF)
    if (payload.length <= maxSingleFramePayload) {
      final frame = Uint8List(8);
      frame[0] = (IsoTpFrameType.singleFrame.pciNibble << 4) | (payload.length & 0x0F);
      for (int i = 0; i < payload.length; i++) {
        frame[1 + i] = payload[i];
      }
      // Zero-pad remaining bytes per CAN 8-byte standard
      for (int i = 1 + payload.length; i < 8; i++) {
        frame[i] = 0xAA; // 0xAA or 0x00 standard padding
      }
      frames.add(frame);
      return frames;
    }

    // First Frame (FF)
    final ff = Uint8List(8);
    final len = payload.length;
    ff[0] = (IsoTpFrameType.firstFrame.pciNibble << 4) | ((len >> 8) & 0x0F);
    ff[1] = len & 0xFF;
    for (int i = 0; i < 6; i++) {
      ff[2 + i] = payload[i];
    }
    frames.add(ff);

    // Consecutive Frames (CF)
    int offset = 6;
    int seq = 1;
    while (offset < payload.length) {
      final cf = Uint8List(8);
      cf[0] = (IsoTpFrameType.consecutiveFrame.pciNibble << 4) | (seq & 0x0F);
      final remaining = payload.length - offset;
      final bytesToCopy = remaining < 7 ? remaining : 7;

      for (int i = 0; i < bytesToCopy; i++) {
        cf[1 + i] = payload[offset + i];
      }
      // Zero-pad trailing bytes
      for (int i = 1 + bytesToCopy; i < 8; i++) {
        cf[i] = 0xAA;
      }
      frames.add(cf);
      offset += bytesToCopy;
      seq = (seq + 1) & 0x0F; // 4-bit sequence counter wrap 0..15
    }

    return frames;
  }

  /// Encodes a Flow Control (FC) frame.
  Uint8List encodeFlowControl({
    IsoTpFlowStatus status = IsoTpFlowStatus.continueToSend,
    int blockSize = 0, // 0 = send all remaining frames without wait
    int separationTimeMs = 0, // STmin in milliseconds
  }) {
    final fc = Uint8List(8);
    fc[0] = (IsoTpFrameType.flowControl.pciNibble << 4) | (status.value & 0x0F);
    fc[1] = blockSize & 0xFF;
    fc[2] = separationTimeMs & 0xFF;
    for (int i = 3; i < 8; i++) {
      fc[i] = 0xAA;
    }
    return fc;
  }

  /// Processes an incoming raw CAN frame (8 bytes).
  ///
  /// Returns a completed `Uint8List` payload if reassembly is complete,
  /// or `null` if more Consecutive Frames are expected.
  Uint8List? processIncomingCanFrame(List<int> frame) {
    if (frame.isEmpty) return null;

    final pciType = (frame[0] >> 4) & 0x0F;

    if (pciType == IsoTpFrameType.singleFrame.pciNibble) {
      // Single Frame
      final length = frame[0] & 0x0F;
      if (length == 0 || length > 7 || length >= frame.length) return null;
      resetReassembly();
      return Uint8List.fromList(frame.sublist(1, 1 + length));
    } else if (pciType == IsoTpFrameType.firstFrame.pciNibble) {
      // First Frame
      if (frame.length < 3) return null;
      _expectedLength = ((frame[0] & 0x0F) << 8) | frame[1];
      _reassemblyBuffer.clear();
      _reassemblyBuffer.addAll(frame.sublist(2, frame.length < 8 ? frame.length : 8));
      _nextSequenceNumber = 1;
      _isReassembling = true;
      return null;
    } else if (pciType == IsoTpFrameType.consecutiveFrame.pciNibble) {
      // Consecutive Frame
      if (!_isReassembling) return null;

      final seq = frame[0] & 0x0F;
      if (seq != _nextSequenceNumber) {
        debugPrint('[ISO-TP] Sequence error: expected $_nextSequenceNumber but received $seq');
        resetReassembly();
        return null;
      }

      _nextSequenceNumber = (_nextSequenceNumber + 1) & 0x0F;
      final remaining = _expectedLength - _reassemblyBuffer.length;
      final availableInFrame = frame.length - 1;
      final bytesToTake = remaining < availableInFrame ? remaining : availableInFrame;

      _reassemblyBuffer.addAll(frame.sublist(1, 1 + bytesToTake));

      if (_reassemblyBuffer.length >= _expectedLength) {
        final completePayload = Uint8List.fromList(_reassemblyBuffer.sublist(0, _expectedLength));
        resetReassembly();
        return completePayload;
      }
      return null;
    }

    return null;
  }
}
