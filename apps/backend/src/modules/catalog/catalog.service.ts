import { Injectable, OnModuleInit } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Product, ProductDocument } from './schemas/product.schema';
import { OrderItemCategory } from '../orders/schemas/order.schema';

@Injectable()
export class CatalogService implements OnModuleInit {
  constructor(
    @InjectModel(Product.name) private productModel: Model<ProductDocument>,
  ) {}

  async onModuleInit() {
    try {
      await this.seedProducts();
    } catch (err: any) {
      console.warn(`[CatalogService] Initial product seeding deferred (database unavailable): ${err?.message || err}`);
    }
  }

  async getActiveProducts(): Promise<Product[]> {
    return this.productModel.find({ isActive: true }).exec();
  }

  async getProductById(itemId: string): Promise<Product | null> {
    return this.productModel.findOne({ itemId, isActive: true }).exec();
  }

  private async seedProducts() {
    const count = await this.productModel.countDocuments();
    if (count > 0) return;

    const initialProducts = [
      {
        itemId: 'prod_hw_adapter_01',
        title: 'RideOS Pro Diagnostics Adapter',
        category: OrderItemCategory.HARDWARE_ADAPTER,
        unitPrice: 129.99,
        isActive: true,
      },
      {
        itemId: 'prod_sub_ai_01',
        title: 'AI Navigation Premium (1 Year)',
        category: OrderItemCategory.CLOUD_SUBSCRIPTION,
        unitPrice: 59.99,
        isActive: true,
      },
      {
        itemId: 'prod_gear_gloves_01',
        title: 'Carbon Fiber Track Gloves',
        category: OrderItemCategory.RIDING_GEAR,
        unitPrice: 189.99,
        isActive: true,
      },
    ];

    await this.productModel.insertMany(initialProducts);
  }
}
