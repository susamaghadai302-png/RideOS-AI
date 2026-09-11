import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product_entity.dart';
import '../../data/repositories/catalog_repository_impl.dart';
import '../../data/datasources/catalog_remote_datasource.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

class CatalogState {
  final bool isLoading;
  final List<ProductEntity> products;
  final String? error;

  CatalogState({
    this.isLoading = false,
    this.products = const [],
    this.error,
  });

  CatalogState copyWith({
    bool? isLoading,
    List<ProductEntity>? products,
    String? error,
  }) {
    return CatalogState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      error: error,
    );
  }
}

class CatalogNotifier extends StateNotifier<CatalogState> {
  final CatalogRepositoryImpl repository;

  CatalogNotifier({required this.repository}) : super(CatalogState());

  Future<void> fetchProducts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final products = await repository.getActiveProducts();
      state = state.copyWith(isLoading: false, products: products);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final catalogRepositoryProvider = Provider<CatalogRepositoryImpl>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return CatalogRepositoryImpl(
    remoteDatasource: CatalogRemoteDatasourceImpl(apiClient: ApiClient(tokenStorage: tokenStorage)),
  );
});

final catalogNotifierProvider = StateNotifierProvider<CatalogNotifier, CatalogState>((ref) {
  final repo = ref.watch(catalogRepositoryProvider);
  return CatalogNotifier(repository: repo);
});
