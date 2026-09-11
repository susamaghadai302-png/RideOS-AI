import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Order, OrderDocument, OrderStatus } from './schemas/order.schema';
import { CatalogService } from '../catalog/catalog.service';

@Injectable()
export class OrdersService {
  constructor(
    @InjectModel(Order.name) private orderModel: Model<OrderDocument>,
    private catalogService: CatalogService,
  ) {}

  async createOrder(customerId: string, createOrderDto: any): Promise<Order> {
    if (!createOrderDto.items || createOrderDto.items.length === 0) {
      throw new BadRequestException('Order must contain at least one item');
    }

    let totalAmount = 0;
    const validatedItems: any[] = [];

    for (const item of createOrderDto.items) {
      const product = await this.catalogService.getProductById(item.itemId);
      if (!product) {
        throw new BadRequestException(`Product with ID ${item.itemId} is invalid or inactive`);
      }
      
      const quantity = item.quantity || 1;
      totalAmount += product.unitPrice * quantity;
      
      validatedItems.push({
        itemId: product.itemId,
        title: product.title,
        category: product.category,
        unitPrice: product.unitPrice,
        quantity: quantity,
      });
    }

    const newOrder = new this.orderModel({
      customerId,
      items: validatedItems,
      totalAmount,
      currency: 'USD',
      status: OrderStatus.PENDING_PAYMENT,
      deliveryAddress: createOrderDto.deliveryAddress,
    });
    
    return newOrder.save();
  }

  async getOrdersForCustomer(customerId: string): Promise<Order[]> {
    return this.orderModel.find({ customerId }).sort({ createdAt: -1 }).exec();
  }

  async getOrderById(orderId: string, customerId: string): Promise<OrderDocument> {
    const order = await this.orderModel.findOne({ orderId }).exec();
    if (!order) {
      throw new NotFoundException(`Order with ID ${orderId} not found`);
    }
    if (order.customerId !== customerId) {
      throw new ForbiddenException(`You are not authorized to access this order`);
    }
    return order;
  }

  async cancelOrder(orderId: string, customerId: string): Promise<Order> {
    const order = await this.getOrderById(orderId, customerId);

    // Enforce business rules
    if (order.status === OrderStatus.CANCELLED) {
      throw new BadRequestException('Order is already cancelled');
    }
    if (order.status === OrderStatus.SHIPPED || order.status === OrderStatus.COMPLETED) {
      throw new BadRequestException('Cannot cancel an order that is already shipped or completed');
    }

    order.status = OrderStatus.CANCELLED;
    return order.save();
  }
}
