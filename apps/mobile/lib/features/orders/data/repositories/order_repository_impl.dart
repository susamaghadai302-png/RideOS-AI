import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDatasource remoteDatasource;

  OrderRepositoryImpl({required this.remoteDatasource});

  @override
  Future<List<OrderEntity>> getMyOrders() async {
    return await remoteDatasource.getMyOrders();
  }

  @override
  Future<OrderEntity> getOrderById(String orderId) async {
    return await remoteDatasource.getOrderById(orderId);
  }

  @override
  Future<OrderEntity> createOrder(Map<String, dynamic> orderData) async {
    return await remoteDatasource.createOrder(orderData);
  }

  @override
  Future<OrderEntity> cancelOrder(String orderId) async {
    return await remoteDatasource.cancelOrder(orderId);
  }
}
