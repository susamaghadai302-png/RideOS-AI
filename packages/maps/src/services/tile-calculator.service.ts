import { MapTileCoordinate } from '../models/map-tile.model';

export class TileCalculatorService {
  /**
   * Converts latitude/longitude coordinates to Slippy Map Tile (x, y, z)
   */
  public static latLngToTile(lat: number, lng: number, zoom: number): MapTileCoordinate {
    const latRad = (lat * Math.PI) / 180;
    const n = Math.pow(2, zoom);
    const x = Math.floor(((lng + 180) / 360) * n);
    const y = Math.floor(
      ((1 - Math.log(Math.tan(latRad) + 1 / Math.cos(latRad)) / Math.PI) / 2) * n,
    );
    return { x, y, z: zoom };
  }

  /**
   * Generates standard tile URL template
   */
  public static getTileUrl(
    template: string,
    tile: MapTileCoordinate,
  ): string {
    return template
      .replace('{z}', tile.z.toString())
      .replace('{x}', tile.x.toString())
      .replace('{y}', tile.y.toString());
  }
}
