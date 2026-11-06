export type VoiceCommandIntent =
  | 'WAKE_UP'
  | 'FIND_FUEL'
  | 'REROUTE_SCENIC'
  | 'CANCEL_NAVIGATION'
  | 'CHECK_TIRES'
  | 'TRIGGER_SOS'
  | 'VEHICLE_HEALTH'
  | 'UNKNOWN';

export class VoiceCommandParserService {
  /**
   * Parses spoken voice transcripts across English, Hindi, Hinglish, and Odia to identify riding intent
   */
  public static parseIntent(transcript: string): VoiceCommandIntent {
    const clean = transcript.toLowerCase().trim();

    // SOS / Emergency across languages:
    // English: sos, emergency, crash, help
    // Hindi/Hinglish: bachao, madad, accident, emergency
    // Odia: sahajya, bipada
    if (
      clean.includes('sos') ||
      clean.includes('emergency') ||
      clean.includes('crash') ||
      clean.includes('accident') ||
      clean.includes('madad') ||
      clean.includes('bachao') ||
      clean.includes('sahajya')
    ) {
      return 'TRIGGER_SOS';
    }

    // Fuel / Gas / Petrol:
    // English: fuel, gas, petrol, pump
    // Hindi/Hinglish: tel, petrol pump, tanki
    // Odia: tel tanki, petrol
    if (
      clean.includes('fuel') ||
      clean.includes('gas') ||
      clean.includes('petrol') ||
      clean.includes('pump') ||
      clean.includes('tel') ||
      clean.includes('tanki')
    ) {
      return 'FIND_FUEL';
    }

    // Scenic / Curvy / Twisties:
    // English: scenic, twisty, curvy, winding
    // Hindi/Hinglish: sundar rasta, pahadi rasta, twisties
    if (
      clean.includes('scenic') ||
      clean.includes('twisty') ||
      clean.includes('curvy') ||
      clean.includes('winding') ||
      clean.includes('ghat') ||
      clean.includes('pahadi')
    ) {
      return 'REROUTE_SCENIC';
    }

    // Tire Pressure / TPMS:
    // English: tire, tyre, psi, pressure
    // Hindi/Hinglish: hawa, pahiya, tyre pressure
    // Odia: chaka hawa
    if (
      clean.includes('tire') ||
      clean.includes('tyre') ||
      clean.includes('psi') ||
      clean.includes('pressure') ||
      clean.includes('hawa') ||
      clean.includes('chaka')
    ) {
      return 'CHECK_TIRES';
    }

    // Vehicle Health / Diagnostics:
    if (
      clean.includes('health') ||
      clean.includes('checkup') ||
      clean.includes('diagnostics') ||
      clean.includes('dtc') ||
      clean.includes('fault') ||
      clean.includes('gadi check') ||
      clean.includes('bike condition')
    ) {
      return 'VEHICLE_HEALTH';
    }

    // Stop / Cancel navigation:
    // English: stop, cancel, end navigation
    // Hindi/Hinglish: roko, band karo, rasta radd karo
    // Odia: bandha kara
    if (
      clean.includes('stop') ||
      clean.includes('cancel') ||
      clean.includes('roko') ||
      clean.includes('band karo') ||
      clean.includes('radd karo')
    ) {
      return 'CANCEL_NAVIGATION';
    }

    // Wakeup:
    if (
      clean.includes('hey rideos') ||
      clean.includes('hello rideos') ||
      clean.includes('ok rideos') ||
      clean.includes('suno rideos')
    ) {
      return 'WAKE_UP';
    }

    return 'UNKNOWN';
  }
}
