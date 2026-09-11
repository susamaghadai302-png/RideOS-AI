import 'order_entity.dart';

class ProductEntity {
  final String itemId;
  final String title;
  final OrderItemCategory category;
  final double unitPrice;
  final bool isActive;

  const ProductEntity({
    required this.itemId,
    required this.title,
    required this.category,
    required this.unitPrice,
    required this.isActive,
  });
}
