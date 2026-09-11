import '../../domain/entities/order_entity.dart';

class OrderItemModel extends OrderItemEntity {
  const OrderItemModel({
    required super.itemId,
    required super.title,
    required super.category,
    required super.unitPrice,
    required super.quantity,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      itemId: json['itemId'] ?? '',
      title: json['title'] ?? '',
      category: OrderItemCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => OrderItemCategory.hardwareAdapter,
      ),
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'title': title,
      'category': category.name,
      'unitPrice': unitPrice,
      'quantity': quantity,
    };
  }
}

class OrderAddressModel extends OrderAddressEntity {
  const OrderAddressModel({
    required super.street,
    required super.city,
    required super.state,
    required super.zipCode,
    required super.country,
  });

  factory OrderAddressModel.fromJson(Map<String, dynamic> json) {
    return OrderAddressModel(
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
      country: json['country'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
    };
  }
}

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.orderId,
    required super.customerId,
    required super.items,
    required super.totalAmount,
    required super.currency,
    required super.status,
    required super.createdAt,
    super.deliveryAddress,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['orderId'] ?? json['_id'] ?? '',
      customerId: json['customerId'] ?? '',
      items: (json['items'] as List?)?.map((i) => OrderItemModel.fromJson(i)).toList() ?? [],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pendingPayment,
      ),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      deliveryAddress: json['deliveryAddress'] != null ? OrderAddressModel.fromJson(json['deliveryAddress']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'items': items.map((i) => (i as OrderItemModel).toJson()).toList(),
      'totalAmount': totalAmount,
      'currency': currency,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'deliveryAddress': deliveryAddress != null ? (deliveryAddress as OrderAddressModel).toJson() : null,
    };
  }
}
