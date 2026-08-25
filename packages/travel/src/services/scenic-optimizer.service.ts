import { TripPlan } from '../models/trip-itinerary.model';

export class ScenicOptimizerService {
  /**
   * Exports a TripPlan to standard GPX XML string format
   */
  public static exportToGpx(plan: TripPlan): string {
    let gpx = `<?xml version="1.0" encoding="UTF-8"?>\n<gpx version="1.1" creator="RideOS AI">\n`;
    gpx += `  <metadata><name>${plan.title}</name></metadata>\n`;

    for (const day of plan.days) {
      gpx += `  <rte><name>Day ${day.dayNumber}</name>\n`;
      for (const stop of day.stops) {
        gpx += `    <rtept lat="${stop.lat}" lon="${stop.lng}"><name>${stop.title}</name></rtept>\n`;
      }
      gpx += `  </rte>\n`;
    }

    gpx += `</gpx>`;
    return gpx;
  }
}
