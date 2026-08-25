export type VoiceCommandIntent =
  | 'WAKE_UP'
  | 'FIND_FUEL'
  | 'REROUTE_SCENIC'
  | 'CANCEL_NAVIGATION'
  | 'CHECK_TIRES'
  | 'TRIGGER_SOS'
  | 'UNKNOWN';

export class VoiceCommandParserService {
  /**
   * Parses spoken voice transcripts to identify riding intent
   */
  public static parseIntent(transcript: string): VoiceCommandIntent {
    const clean = transcript.toLowerCase().trim();

    if (clean.includes('sos') || clean.includes('emergency') || clean.includes('crash')) {
      return 'TRIGGER_SOS';
    }
    if (clean.includes('fuel') || clean.includes('gas') || clean.includes('petrol')) {
      return 'FIND_FUEL';
    }
    if (clean.includes('scenic') || clean.includes('twisty') || clean.includes('curvy')) {
      return 'REROUTE_SCENIC';
    }
    if (clean.includes('tire') || clean.includes('psi') || clean.includes('pressure')) {
      return 'CHECK_TIRES';
    }
    if (clean.includes('stop') || clean.includes('cancel')) {
      return 'CANCEL_NAVIGATION';
    }

    return 'UNKNOWN';
  }
}
