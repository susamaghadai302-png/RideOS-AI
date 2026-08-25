import { MapBoundingBox } from '@rideos/maps';

export interface OfflineRegion {
  id: string;
  name: string;
  boundingBox: MapBoundingBox;
  minZoom: number;
  maxZoom: number;
  totalSizeMb: number;
  downloadedSizeBytes: number;
  isDownloaded: boolean;
}
