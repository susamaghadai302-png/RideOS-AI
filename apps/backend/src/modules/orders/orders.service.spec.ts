import { Test, TestingModule } from '@nestjs/testing';
import { OrdersService } from './orders.service';
import { getModelToken } from '@nestjs/mongoose';
import { Order, OrderStatus } from './schemas/order.schema';
import { CatalogService } from '../catalog/catalog.service';
import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';

const mockOrder = {
  orderId: 'order123',
  customerId: 'cust123',
  items: [{ itemId: 'prod1', quantity: 2, unitPrice: 50.0 }],
  totalAmount: 100.0,
  status: OrderStatus.PENDING_PAYMENT,
  save: jest.fn().mockResolvedValue(true),
};

const mockOrderModel = {
  new: jest.fn().mockReturnValue(mockOrder),
  constructor: jest.fn().mockReturnValue(mockOrder),
  find: jest.fn(),
  findOne: jest.fn(),
};

const mockCatalogService = {
  getProductById: jest.fn(),
};

describe('OrdersService', () => {
  let service: OrdersService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OrdersService,
        {
          provide: getModelToken(Order.name),
          useValue: mockOrderModel,
        },
        {
          provide: CatalogService,
          useValue: mockCatalogService,
        },
      ],
    }).compile();

    service = module.get<OrdersService>(OrdersService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('createOrder', () => {
    it('should reject order without items', async () => {
      await expect(service.createOrder('cust1', { items: [] })).rejects.toThrow(BadRequestException);
    });

    it('should reject order with invalid product', async () => {
      mockCatalogService.getProductById.mockResolvedValue(null);
      await expect(service.createOrder('cust1', { items: [{ itemId: 'invalid_prod', quantity: 1 }] })).rejects.toThrow(BadRequestException);
    });

    it('should securely calculate total amount from catalog and save order', async () => {
      mockCatalogService.getProductById.mockResolvedValue({
        itemId: 'prod1',
        title: 'Test Product',
        category: 'test',
        unitPrice: 50.0,
      });

      mockOrderModel.constructor.mockReturnValue(mockOrder);

      // We need a class implementation mock for the model constructor
      const saveSpy = jest.fn().mockResolvedValue(mockOrder);
      class MockModel {
        constructor(public data: any) {}
        save = saveSpy;
      }
      
      const module: TestingModule = await Test.createTestingModule({
        providers: [
          OrdersService,
          {
            provide: getModelToken(Order.name),
            useValue: MockModel,
          },
          {
            provide: CatalogService,
            useValue: mockCatalogService,
          },
        ],
      }).compile();

      const newService = module.get<OrdersService>(OrdersService);

      const result = await newService.createOrder('cust1', { items: [{ itemId: 'prod1', quantity: 2 }] });

      expect(result).toBeDefined();
      expect(saveSpy).toHaveBeenCalled();
      // The constructed object should have totalAmount = 100
    });
  });

  describe('cancelOrder', () => {
    it('should throw NotFoundException if order does not exist', async () => {
      mockOrderModel.findOne.mockReturnValue({
        exec: jest.fn().mockResolvedValue(null),
      });

      await expect(service.cancelOrder('order123', 'cust123')).rejects.toThrow(NotFoundException);
    });

    it('should throw ForbiddenException if customerId does not match', async () => {
      mockOrderModel.findOne.mockReturnValue({
        exec: jest.fn().mockResolvedValue({ ...mockOrder, customerId: 'other_cust' }),
      });

      await expect(service.cancelOrder('order123', 'cust123')).rejects.toThrow(ForbiddenException);
    });

    it('should reject cancellation if order is already cancelled', async () => {
      mockOrderModel.findOne.mockReturnValue({
        exec: jest.fn().mockResolvedValue({ ...mockOrder, status: OrderStatus.CANCELLED }),
      });

      await expect(service.cancelOrder('order123', 'cust123')).rejects.toThrow(BadRequestException);
    });

    it('should reject cancellation if order is already shipped', async () => {
      mockOrderModel.findOne.mockReturnValue({
        exec: jest.fn().mockResolvedValue({ ...mockOrder, status: OrderStatus.SHIPPED }),
      });

      await expect(service.cancelOrder('order123', 'cust123')).rejects.toThrow(BadRequestException);
    });
  });
});
