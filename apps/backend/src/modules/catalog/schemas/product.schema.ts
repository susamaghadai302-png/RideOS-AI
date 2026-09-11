import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { OrderItemCategory } from '../../orders/schemas/order.schema';

export type ProductDocument = Product & Document;

@Schema({ timestamps: true })
export class Product {
  @Prop({ required: true, default: () => new Types.ObjectId().toHexString() })
  itemId: string;

  @Prop({ required: true })
  title: string;

  @Prop({ required: true, enum: OrderItemCategory })
  category: string;

  @Prop({ required: true })
  unitPrice: number;

  @Prop({ required: true, default: true })
  isActive: boolean;
}

export const ProductSchema = SchemaFactory.createForClass(Product);
