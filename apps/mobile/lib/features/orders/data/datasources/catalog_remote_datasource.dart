import '../../../../core/network/api_client.dart';
import '../models/product_model.dart';

abstract class CatalogRemoteDatasource {
  Future<List<ProductModel>> getActiveProducts();
}

class CatalogRemoteDatasourceImpl implements CatalogRemoteDatasource {
  final ApiClient apiClient;

  CatalogRemoteDatasourceImpl({required this.apiClient});

  @override
  Future<List<ProductModel>> getActiveProducts() async {
    final response = await apiClient.dio.get('/catalog');
    final data = response.data as List;
    return data.map((json) => ProductModel.fromJson(json)).toList();
  }
}
