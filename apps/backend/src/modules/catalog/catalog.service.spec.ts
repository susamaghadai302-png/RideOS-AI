import { Test, TestingModule } from '@nestjs/testing';
import { CatalogService } from './catalog.service';
import { getModelToken } from '@nestjs/mongoose';
import { Product } from './schemas/product.schema';

const mockProduct = {
  itemId: 'prod_hw_adapter_01',
  title: 'RideOS Pro Diagnostics Adapter',
  category: 'hardwareAdapter',
  unitPrice: 129.99,
  isActive: true,
};

const mockProductModel = {
  find: jest.fn().mockReturnValue({
    exec: jest.fn().mockResolvedValue([mockProduct]),
  }),
  findOne: jest.fn().mockReturnValue({
    exec: jest.fn().mockResolvedValue(mockProduct),
  }),
  countDocuments: jest.fn().mockResolvedValue(0),
  insertMany: jest.fn().mockResolvedValue(true),
};

describe('CatalogService', () => {
  let service: CatalogService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CatalogService,
        {
          provide: getModelToken(Product.name),
          useValue: mockProductModel,
        },
      ],
    }).compile();

    service = module.get<CatalogService>(CatalogService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should seed products on init if count is 0', async () => {
    await service.onModuleInit();
    expect(mockProductModel.countDocuments).toHaveBeenCalled();
    expect(mockProductModel.insertMany).toHaveBeenCalled();
  });

  it('should fetch active products', async () => {
    const products = await service.getActiveProducts();
    expect(products).toHaveLength(1);
    expect(products[0].itemId).toBe('prod_hw_adapter_01');
    expect(mockProductModel.find).toHaveBeenCalledWith({ isActive: true });
  });

  it('should fetch product by id', async () => {
    const product = await service.getProductById('prod_hw_adapter_01');
    expect(product).toBeDefined();
    expect(product?.itemId).toBe('prod_hw_adapter_01');
    expect(mockProductModel.findOne).toHaveBeenCalledWith({ itemId: 'prod_hw_adapter_01', isActive: true });
  });
});
