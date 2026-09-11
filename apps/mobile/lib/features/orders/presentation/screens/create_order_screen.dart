import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/order_notifier.dart';
import '../../domain/entities/order_entity.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/catalog_notifier.dart';

class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  ProductEntity? _selectedItem;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(catalogNotifierProvider.notifier).fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderNotifierProvider);
    final catalogState = ref.watch(catalogNotifierProvider);
    final theme = Theme.of(context);
    final rider = ref.watch(authNotifierProvider).rider;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('New Order', style: TextStyle(fontFamily: 'Orbitron')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Product', style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.primaryOrange)),
            const SizedBox(height: 16),
            if (catalogState.isLoading)
              const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange))
            else if (catalogState.error != null)
              Center(child: Text('Failed to load products: ${catalogState.error}', style: const TextStyle(color: Colors.red)))
            else
              ...catalogState.products.map((product) => _buildProductCard(product)),
            const SizedBox(height: 32),
            Text('Delivery Address', style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.primaryOrange)),
            const SizedBox(height: 16),
            _buildAddressSection(rider?.savedAddresses),
            const SizedBox(height: 32),
            // Checkout Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(color: Colors.white, fontSize: 18)),
                  Text(
                    '\$${(_selectedItem?.unitPrice ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(color: AppTheme.primaryOrange, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.isSubmitting ? null : _submitOrder,
                child: state.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Place Order', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductEntity product) {
    final isSelected = _selectedItem?.itemId == product.itemId;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedItem = product;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryOrange.withValues(alpha: 0.1) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primaryOrange : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(Icons.inventory, color: isSelected ? AppTheme.primaryOrange : Colors.white54),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(product.category.name, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            Text('\$${product.unitPrice.toStringAsFixed(2)}', style: TextStyle(color: isSelected ? AppTheme.primaryOrange : Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection(List<OrderAddressEntity>? addresses) {
    if (addresses == null || addresses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: const Center(
          child: Text('No saved addresses. Will use default billing profile.', style: TextStyle(color: Colors.white54)),
        ),
      );
    }
    final address = addresses.first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(address.street, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 4),
          Text('${address.city}, ${address.state} ${address.zipCode}', style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 4),
          Text(address.country, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  void _submitOrder() async {
    if (_selectedItem == null) return;

    final rider = ref.read(authNotifierProvider).rider;
    final address = rider?.savedAddresses.isNotEmpty == true ? rider!.savedAddresses.first : null;

    final orderData = {
      'items': [
        {
          'itemId': _selectedItem!.itemId,
          'quantity': 1,
        }
      ],
      'deliveryAddress': address != null
          ? {
              'street': address.street,
              'city': address.city,
              'state': address.state,
              'zipCode': address.zipCode,
              'country': address.country,
            }
          : null,
    };

    final success = await ref.read(orderNotifierProvider.notifier).createOrder(orderData);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed successfully!')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ref.read(orderNotifierProvider).error ?? 'Failed to place order')));
      }
    }
  }
}
