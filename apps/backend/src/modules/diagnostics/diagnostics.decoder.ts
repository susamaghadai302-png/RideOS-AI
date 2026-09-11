import { Injectable, BadRequestException } from '@nestjs/common';
import { DiagnosticFaultDto } from './dto/diagnostic-scan.dto';

@Injectable()
export class DiagnosticsDecoder {
  // Mode 03 response prefix is typically "43"
  // Mode 01 response prefix is typically "41"
  // Mode 04 positive response is typically "44"

  /**
   * Decodes a list of raw hex payloads (e.g., from Mode 03) into a list of normalized DTCs.
   * Format: "43 01 33 00 00" -> P0133
   */
  public decodeDtcs(rawPayloads: string[]): DiagnosticFaultDto[] {
    const faults: DiagnosticFaultDto[] = [];
    const seenCodes = new Set<string>();

    for (const payload of rawPayloads) {
      const cleanPayload = payload.replace(/\s+/g, '').toUpperCase();
      if (!cleanPayload.startsWith('43') || cleanPayload.length < 6) {
        continue; // Not a valid Mode 03 response, skip or throw
      }

      // Each DTC is 2 bytes (4 hex chars). Start reading after "43" (and possibly "43 XX" where XX is the count, but let's assume standard ISO-TP multi-frame is already reassembled and we have "43 XX YY ZZ").
      // Actually standard OBD2 Mode 03 response is: 43 [DTC1_H] [DTC1_L] [DTC2_H] [DTC2_L]...
      let dataOffset = 2;
      
      // Some ELM327 responses might just be "43 01 33 00 00"
      while (dataOffset + 4 <= cleanPayload.length) {
        const dtcHex = cleanPayload.substring(dataOffset, dataOffset + 4);
        dataOffset += 4;

        if (dtcHex === '0000') continue;

        const code = this.parseDtcString(dtcHex);
        if (code && !seenCodes.has(code)) {
          seenCodes.add(code);
          faults.push(this.enrichDtc(code));
        }
      }
    }
    return faults;
  }

  /**
   * Verifies that the clear command was successful (Speed == 0 and valid Mode 04 Ack)
   */
  public verifyClearCommand(speedPayload: string, clearAckPayload: string): boolean {
    const cleanSpeed = speedPayload.replace(/\s+/g, '').toUpperCase();
    const cleanAck = clearAckPayload.replace(/\s+/g, '').toUpperCase();

    // Verify speed
    // Mode 01 PID 0D response: "41 0D XX" where XX is speed in km/h
    if (!cleanSpeed.startsWith('410D') || cleanSpeed.length < 6) {
      throw new BadRequestException('SAFETY INTERLOCK: Invalid speed telemetry payload.');
    }
    
    const speedHex = cleanSpeed.substring(4, 6);
    const speed = parseInt(speedHex, 16);
    if (isNaN(speed) || speed > 0) {
      throw new BadRequestException(`SAFETY INTERLOCK: Cannot clear DTCs while vehicle is in motion (Speed: ${speed} km/h). Park vehicle to 0km/h before resetting fault memory.`);
    }

    // Verify Ack (Mode 04 positive response is "44")
    if (!cleanAck.includes('44')) {
      throw new BadRequestException('CLEAR FAILED: ECU did not positively acknowledge the clear command.');
    }

    return true;
  }

  private parseDtcString(hexString: string): string | null {
    if (hexString.length !== 4) return null;
    
    const firstHex = parseInt(hexString[0], 16);
    if (isNaN(firstHex)) return null;

    // Decoding first character according to SAE J2012
    const prefixMap = ['P0', 'P1', 'P2', 'P3', 'C0', 'C1', 'C2', 'C3', 'B0', 'B1', 'B2', 'B3', 'U0', 'U1', 'U2', 'U3'];
    const prefix = prefixMap[firstHex];
    
    const remainder = hexString.substring(1);
    return `${prefix}${remainder}`;
  }

  private enrichDtc(code: string): DiagnosticFaultDto {
    // A simplified enrichment mapping. In production this would query a real database.
    let severity = 'criticalStopEngine';
    let module = 'engineControlModule_ECM';

    if (code.startsWith('B')) module = 'bodyControlModule_BCM';
    if (code.startsWith('C')) module = 'antiLockBraking_ABS';
    if (code.startsWith('U')) module = 'telematicsBox_TCU';

    if (code === 'P0133') severity = 'confirmedActive';
    if (code === 'P0300') severity = 'criticalStopEngine';
    
    return {
      code,
      module,
      severity,
    };
  }
}
