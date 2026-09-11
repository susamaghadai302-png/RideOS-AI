import 'package:flutter/foundation.dart';

enum OrderStatus {
  pendingPayment,
  processing,
  shipped,
  completed,
  cancelled,
  refunded;
}

enum OrderItemCategory {
  hardwareAdapter,
  replacementPart,
  ridingGear,
  workshopService,
  softwareUnlock,
  cloudSubscription;
}

@immutable
class OrderItemEntity {
  final String itemId;
  final String title;
  final OrderItemCategory category;
  final double unitPrice;
  final int quantity;

  const OrderItemEntity({
    required this.itemId,
    required this.title,
    required this.category,
    required this.unitPrice,
    required this.quantity,
  });
}

@immutable
class OrderAddressEntity {
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  const OrderAddressEntity({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
  });
}

@immutable
class OrderEntity {
  final String orderId;
  final String customerId;
  final List<OrderItemEntity> items;
  final double totalAmount;
  final String currency;
  final OrderStatus status;
  final DateTime createdAt;
  final OrderAddressEntity? deliveryAddress;

  const OrderEntity({
    required this.orderId,
    required this.customerId,
    required this.items,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.deliveryAddress,
  });
}
