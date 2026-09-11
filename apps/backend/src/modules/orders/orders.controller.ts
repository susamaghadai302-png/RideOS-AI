import { Controller, Get, Post, Body, Param, Patch, UseGuards, Request } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post()
  async createOrder(@Request() req, @Body() createOrderDto: any) {
    const customerId = req.user.userId || req.user.sub || req.user.id;
    return this.ordersService.createOrder(customerId, createOrderDto);
  }

  @Get()
  async getMyOrders(@Request() req) {
    const customerId = req.user.userId || req.user.sub || req.user.id;
    return this.ordersService.getOrdersForCustomer(customerId);
  }

  @Get(':id')
  async getOrderById(@Request() req, @Param('id') id: string) {
    const customerId = req.user.userId || req.user.sub || req.user.id;
    return this.ordersService.getOrderById(id, customerId);
  }

  @Patch(':id/cancel')
  async cancelOrder(@Request() req, @Param('id') id: string) {
    const customerId = req.user.userId || req.user.sub || req.user.id;
    return this.ordersService.cancelOrder(id, customerId);
  }
}
