import { IsString, IsNotEmpty, IsOptional, IsEnum } from 'class-validator';

export enum DeviceProtocolType {
  BLE_GENERIC = 'BLE_GENERIC',
  OBD2_CAN = 'OBD2_CAN',
  YAMAHA_CCU = 'YAMAHA_CCU',
  ROYAL_ENFIELD_TRIPPER = 'ROYAL_ENFIELD_TRIPPER',
  TVS_SMARTXONNECT = 'TVS_SMARTXONNECT',
  SIMULATOR = 'SIMULATOR',
}

export class ConnectDeviceDto {
  @IsString()
  @IsNotEmpty()
  deviceId: string;

  @IsString()
  @IsNotEmpty()
  deviceName: string;

  @IsEnum(DeviceProtocolType)
  @IsOptional()
  protocolType?: DeviceProtocolType = DeviceProtocolType.BLE_GENERIC;

  @IsString()
  @IsOptional()
  macAddress?: string;
}
