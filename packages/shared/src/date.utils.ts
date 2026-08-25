export class DateUtils {
  public static toIsoUtcString(date: Date = new Date()): string {
    return date.toISOString();
  }

  public static formatDurationSeconds(seconds: number): string {
    const hrs = Math.floor(seconds / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);

    if (hrs > 0) {
      return `${hrs}h ${mins}m`;
    }
    return `${mins}m ${secs}s`;
  }
}
