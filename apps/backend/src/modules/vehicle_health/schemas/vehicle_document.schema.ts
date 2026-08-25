import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type VehicleDocumentDocument = VehicleDocument & Document;

@Schema({ timestamps: true })
export class VehicleDocument {
  @Prop({ required: true, index: true })
  vehicleId: string;

  @Prop({ required: true, index: true })
  riderId: string;

  @Prop({ required: true, default: 'CUSTOM' })
  docType: string; // 'MANUAL' | 'INSURANCE' | 'REGISTRATION' | 'SERVICE_INVOICE' | 'WARRANTY' | 'CUSTOM'

  @Prop({ required: true })
  title: string;

  @Prop({ required: true })
  fileUrl: string;

  @Prop({ default: '' })
  fileName: string;

  @Prop({ default: 'application/pdf' })
  mimeType: string;

  @Prop()
  expiryDate?: Date;

  @Prop({ default: '' })
  notes: string;
}

export const VehicleDocumentSchema = SchemaFactory.createForClass(VehicleDocument);
VehicleDocumentSchema.index({ vehicleId: 1, docType: 1 });
VehicleDocumentSchema.index({ riderId: 1, createdAt: -1 });
