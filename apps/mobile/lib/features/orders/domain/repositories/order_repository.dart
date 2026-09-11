import '../entities/order_entity.dart';

abstract class OrderRepository {
  Future<List<OrderEntity>> getMyOrders();
  Future<OrderEntity> getOrderById(String orderId);
  Future<OrderEntity> createOrder(Map<String, dynamic> orderData);
  Future<OrderEntity> cancelOrder(String orderId);
}
