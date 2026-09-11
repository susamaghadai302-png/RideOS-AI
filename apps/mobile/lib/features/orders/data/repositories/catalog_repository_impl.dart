import '../../domain/entities/product_entity.dart';
import '../datasources/catalog_remote_datasource.dart';

abstract class CatalogRepository {
  Future<List<ProductEntity>> getActiveProducts();
}

class CatalogRepositoryImpl implements CatalogRepository {
  final CatalogRemoteDatasource remoteDatasource;

  CatalogRepositoryImpl({required this.remoteDatasource});

  @override
  Future<List<ProductEntity>> getActiveProducts() async {
    return await remoteDatasource.getActiveProducts();
  }
}
