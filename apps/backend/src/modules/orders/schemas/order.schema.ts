import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type OrderDocument = Order & Document;

export enum OrderStatus {
  PENDING_PAYMENT = 'pendingPayment',
  PROCESSING = 'processing',
  SHIPPED = 'shipped',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled',
  REFUNDED = 'refunded',
}

export enum OrderItemCategory {
  HARDWARE_ADAPTER = 'hardwareAdapter',
  REPLACEMENT_PART = 'replacementPart',
  RIDING_GEAR = 'ridingGear',
  WORKSHOP_SERVICE = 'workshopService',
  SOFTWARE_UNLOCK = 'softwareUnlock',
  CLOUD_SUBSCRIPTION = 'cloudSubscription',
}

@Schema()
export class OrderItem {
  @Prop({ required: true })
  itemId: string;

  @Prop({ required: true })
  title: string;

  @Prop({ required: true, enum: OrderItemCategory })
  category: string;

  @Prop({ required: true })
  unitPrice: number;

  @Prop({ required: true })
  quantity: number;
}

const OrderItemSchema = SchemaFactory.createForClass(OrderItem);

@Schema()
export class Address {
  @Prop({ required: true })
  street: string;

  @Prop({ required: true })
  city: string;

  @Prop({ required: true })
  state: string;

  @Prop({ required: true })
  zipCode: string;

  @Prop({ required: true })
  country: string;
}

export const AddressSchema = SchemaFactory.createForClass(Address);

@Schema({ timestamps: true })
export class Order {
  @Prop({ required: true, default: () => new Types.ObjectId().toHexString() })
  orderId: string;

  @Prop({ required: true, index: true })
  customerId: string; // References Rider collection _id / id

  @Prop({ type: [OrderItemSchema], default: [] })
  items: OrderItem[];

  @Prop({ required: true })
  totalAmount: number;

  @Prop({ required: true, default: 'USD' })
  currency: string;

  @Prop({ required: true, enum: OrderStatus, default: OrderStatus.PENDING_PAYMENT })
  status: string;

  @Prop({ type: AddressSchema, required: false })
  deliveryAddress?: Address;
}

export const OrderSchema = SchemaFactory.createForClass(Order);
