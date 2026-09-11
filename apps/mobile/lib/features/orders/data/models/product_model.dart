import '../../domain/entities/order_entity.dart';
import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.itemId,
    required super.title,
    required super.category,
    required super.unitPrice,
    required super.isActive,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      itemId: json['itemId'] as String,
      title: json['title'] as String,
      category: OrderItemCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => OrderItemCategory.hardwareAdapter,
      ),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'title': title,
      'category': category.name,
      'unitPrice': unitPrice,
      'isActive': isActive,
    };
  }
}
