import '../../../../core/network/api_client.dart';
import '../models/order_model.dart';

abstract class OrderRemoteDatasource {
  Future<List<OrderModel>> getMyOrders();
  Future<OrderModel> getOrderById(String orderId);
  Future<OrderModel> createOrder(Map<String, dynamic> orderData);
  Future<OrderModel> cancelOrder(String orderId);
}

class OrderRemoteDatasourceImpl implements OrderRemoteDatasource {
  final ApiClient apiClient;

  OrderRemoteDatasourceImpl({required this.apiClient});

  @override
  Future<List<OrderModel>> getMyOrders() async {
    final response = await apiClient.dio.get('/orders');
    final data = response.data as List;
    return data.map((json) => OrderModel.fromJson(json)).toList();
  }

  @override
  Future<OrderModel> getOrderById(String orderId) async {
    final response = await apiClient.dio.get('/orders/$orderId');
    return OrderModel.fromJson(response.data);
  }

  @override
  Future<OrderModel> createOrder(Map<String, dynamic> orderData) async {
    final response = await apiClient.dio.post('/orders', data: orderData);
    return OrderModel.fromJson(response.data);
  }

  @override
  Future<OrderModel> cancelOrder(String orderId) async {
    final response = await apiClient.dio.patch('/orders/$orderId/cancel');
    return OrderModel.fromJson(response.data);
  }
}
