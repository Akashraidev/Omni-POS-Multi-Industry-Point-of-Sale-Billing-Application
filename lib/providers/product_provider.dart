import 'package:flutter/material.dart';
import '../data/models/category.dart';
import '../data/models/product.dart';
import '../data/repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _repository = ProductRepository();

  List<Product> _allProducts = [];
  List<Category> _categories = [];
  bool _isLoading = false;

  // Filter & Search state
  String _selectedCategoryId = 'all';
  String _searchQuery = '';
  String _brandFilter = 'all';
  bool _onlyLowStock = false;
  String _sortBy = 'name_asc';

  List<Product> get allProducts => _allProducts;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  String get brandFilter => _brandFilter;
  bool get onlyLowStock => _onlyLowStock;
  String get sortBy => _sortBy;

  int get lowStockCount => _allProducts.where((p) => p.isLowStock).length;

  Future<void> loadProducts(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _repository.getCategories(businessId);
      _allProducts = await _repository.getProducts(
        businessId: businessId,
        categoryId: _selectedCategoryId,
        query: _searchQuery,
        brand: _brandFilter,
        onlyLowStock: _onlyLowStock,
        sortBy: _sortBy,
      );
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(String businessId, String categoryId) {
    _selectedCategoryId = categoryId;
    loadProducts(businessId);
  }

  void setSearchQuery(String businessId, String query) {
    _searchQuery = query;
    loadProducts(businessId);
  }

  void setSortBy(String businessId, String sort) {
    _sortBy = sort;
    loadProducts(businessId);
  }

  void toggleLowStock(String businessId) {
    _onlyLowStock = !_onlyLowStock;
    loadProducts(businessId);
  }

  void clearFilters(String businessId) {
    _selectedCategoryId = 'all';
    _searchQuery = '';
    _brandFilter = 'all';
    _onlyLowStock = false;
    _sortBy = 'name_asc';
    loadProducts(businessId);
  }

  Future<void> saveProduct(Product product) async {
    final existing = await _repository.getProductById(product.id);
    if (existing == null) {
      await _repository.insertProduct(product);
    } else {
      await _repository.updateProduct(product);
    }
    await loadProducts(product.businessId);
  }

  Future<void> deleteProduct(String businessId, String productId) async {
    await _repository.deleteProduct(productId);
    await loadProducts(businessId);
  }
}
