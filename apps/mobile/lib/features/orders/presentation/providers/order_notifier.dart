import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../data/datasources/order_remote_datasource.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

class OrderState {
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final List<OrderEntity> orders;
  final OrderEntity? selectedOrder;

  OrderState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.orders = const [],
    this.selectedOrder,
  });

  OrderState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    List<OrderEntity>? orders,
    OrderEntity? selectedOrder,
  }) {
    return OrderState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      orders: orders ?? this.orders,
      selectedOrder: selectedOrder ?? this.selectedOrder,
    );
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  final OrderRepository repository;

  OrderNotifier({required this.repository}) : super(OrderState());

  Future<void> fetchMyOrders() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final orders = await repository.getMyOrders();
      state = state.copyWith(isLoading: false, orders: orders);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchOrderDetails(String orderId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final order = await repository.getOrderById(orderId);
      state = state.copyWith(isLoading: false, selectedOrder: order);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createOrder(Map<String, dynamic> orderData) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final order = await repository.createOrder(orderData);
      state = state.copyWith(
        isSubmitting: false,
        orders: [order, ...state.orders],
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedOrder = await repository.cancelOrder(orderId);
      final updatedOrders = state.orders.map((o) => o.orderId == orderId ? updatedOrder : o).toList();
      state = state.copyWith(
        isLoading: false,
        orders: updatedOrders,
        selectedOrder: state.selectedOrder?.orderId == orderId ? updatedOrder : state.selectedOrder,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return OrderRepositoryImpl(
    remoteDatasource: OrderRemoteDatasourceImpl(apiClient: ApiClient(tokenStorage: tokenStorage)),
  );
});

final orderNotifierProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return OrderNotifier(repository: repo);
});
