import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/order_notifier.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderNotifierProvider.notifier).fetchMyOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Order History', style: TextStyle(fontFamily: 'Orbitron')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: state.isLoading && state.orders.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange))
          : state.error != null && state.orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.primaryOrange, size: 48),
                      const SizedBox(height: 16),
                      Text('Failed to load orders', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => ref.read(orderNotifierProvider.notifier).fetchMyOrders(),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryOrange),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : state.orders.isEmpty
                  ? Center(
                      child: Text(
                        'No orders found.',
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.white54),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppTheme.primaryOrange,
                      onRefresh: () => ref.read(orderNotifierProvider.notifier).fetchMyOrders(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.orders.length,
                        itemBuilder: (context, index) {
                          final order = state.orders[index];
                          return Card(
                            color: const Color(0xFF1A1A1A),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.white10),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Text(
                                'Order #${order.orderId.substring(order.orderId.length - 6).toUpperCase()}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '${order.items.length} item(s) • \$${order.totalAmount.toStringAsFixed(2)}\nStatus: ${order.status.name.toUpperCase()}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderDetailScreen(orderId: order.orderId),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
