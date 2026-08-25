import { TileCalculatorService, MapTileCoordinate } from '@rideos/maps';
import { OfflineRegion } from '../models/offline-region.model';

export class TileDownloaderService {
  /**
   * Generates total list of tile coordinates required to cover an offline region
   */
  public static calculateRequiredTiles(region: OfflineRegion): MapTileCoordinate[] {
    const tiles: MapTileCoordinate[] = [];
    const { minLat, maxLat, minLng, maxLng } = region.boundingBox;

    for (let z = region.minZoom; z <= region.maxZoom; z++) {
      const minTile = TileCalculatorService.latLngToTile(maxLat, minLng, z);
      const maxTile = TileCalculatorService.latLngToTile(minLat, maxLng, z);

      for (let x = minTile.x; x <= maxTile.x; x++) {
        for (let y = minTile.y; y <= maxTile.y; y++) {
          tiles.push({ x, y, z });
        }
      }
    }

    return tiles;
  }
}
