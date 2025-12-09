import 'package:flutter/foundation.dart';
import 'productos_service.dart';

/// Modelo para los resultados de búsqueda
class SearchResult {
  final String id;
  final String nombre;
  final double precio;
  final String categoria;
  final int stock;
  final double relevancia; // Score de 0.0 a 1.0
  final String? imagenUrl;

  SearchResult({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.categoria,
    required this.stock,
    required this.relevancia,
    this.imagenUrl,
  });
}

/// Opciones de filtrado
class SearchFilters {
  double minPrice;
  double maxPrice;
  String? category;
  bool inStockOnly;
  SortOption sortBy;

  SearchFilters({
    this.minPrice = 0.0,
    this.maxPrice = double.infinity,
    this.category,
    this.inStockOnly = false,
    this.sortBy = SortOption.relevancia,
  });

  SearchFilters copyWith({
    double? minPrice,
    double? maxPrice,
    String? category,
    bool? inStockOnly,
    SortOption? sortBy,
  }) {
    return SearchFilters(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      category: category ?? this.category,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

enum SortOption {
  relevancia,
  precioAsc,
  precioDesc,
  nuevosPrimero,
  masVendidos,
}

/// Servicio de búsqueda avanzada
class SearchService extends ChangeNotifier {
  final ProductosService _productosService;

  String _searchQuery = '';
  SearchFilters _filters = SearchFilters();
  List<SearchResult> _results = [];
  bool _isSearching = false;

  SearchService(this._productosService);

  String get searchQuery => _searchQuery;
  SearchFilters get filters => _filters;
  List<SearchResult> get results => _results;
  bool get isSearching => _isSearching;

  /// Realizar búsqueda con filtros
  Future<void> search(String query) async {
    _searchQuery = query;
    _isSearching = true;
    notifyListeners();

    try {
      _results = _performSearch(query, _filters);
    } catch (e) {
      print('Error searching: $e');
      _results = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Actualizar filtros
  void updateFilters(SearchFilters newFilters) {
    _filters = newFilters;
    if (_searchQuery.isNotEmpty) {
      _results = _performSearch(_searchQuery, _filters);
    }
    notifyListeners();
  }

  /// Limpiar búsqueda
  void clearSearch() {
    _searchQuery = '';
    _filters = SearchFilters();
    _results = [];
    notifyListeners();
  }

  /// Realizar búsqueda local (sin llamadas a BD)
  List<SearchResult> _performSearch(String query, SearchFilters filters) {
    final productos = _productosService.productos;

    var results = productos.where((producto) {
      // Filtro por texto
      final matchesQuery =
          query.isEmpty ||
          producto.nombre.toLowerCase().contains(query.toLowerCase()) ||
          (producto.descripcion?.toLowerCase() ?? '').contains(
            query.toLowerCase(),
          );

      // Filtro por rango de precio
      final matchesPrice =
          producto.precio >= filters.minPrice &&
          producto.precio <= filters.maxPrice;

      // Filtro por categoría
      final matchesCategory =
          filters.category == null ||
          filters.category!.isEmpty ||
          (producto.categoria?.nombre ?? '').toLowerCase() ==
              (filters.category?.toLowerCase() ?? '');

      // Filtro por stock
      final matchesStock = !filters.inStockOnly || producto.stock > 0;

      return matchesQuery && matchesPrice && matchesCategory && matchesStock;
    }).toList();

    // Calcular relevancia basada en la coincidencia de búsqueda
    final searchResults = results.map((producto) {
      double relevancia = 1.0;

      // Aumentar relevancia si el nombre empieza con la búsqueda
      if (producto.nombre.toLowerCase().startsWith(query.toLowerCase())) {
        relevancia = 1.0;
      }
      // Reducir si solo aparece en la descripción
      else if ((producto.descripcion?.toLowerCase() ?? '').contains(
        query.toLowerCase(),
      )) {
        relevancia = 0.7;
      }
      // Muy baja relevancia para coincidencias parciales
      else {
        relevancia = 0.5;
      }

      return SearchResult(
        id: producto.id,
        nombre: producto.nombre,
        precio: producto.precio,
        categoria: producto.categoria?.nombre ?? 'Sin categoría',
        stock: producto.stock,
        relevancia: relevancia,
        imagenUrl: producto.imagenUrl,
      );
    }).toList();

    // Ordenar resultados
    return _sortResults(searchResults, filters.sortBy);
  }

  /// Ordenar resultados según la opción seleccionada
  List<SearchResult> _sortResults(
    List<SearchResult> results,
    SortOption sortOption,
  ) {
    switch (sortOption) {
      case SortOption.relevancia:
        results.sort((a, b) => b.relevancia.compareTo(a.relevancia));
        break;
      case SortOption.precioAsc:
        results.sort((a, b) => a.precio.compareTo(b.precio));
        break;
      case SortOption.precioDesc:
        results.sort((a, b) => b.precio.compareTo(a.precio));
        break;
      case SortOption.nuevosPrimero:
        // Los nuevos productos estarían al inicio de la lista original
        break;
      case SortOption.masVendidos:
        // Requeriría data de ventas
        break;
    }
    return results;
  }

  /// Obtener sugerencias de búsqueda
  List<String> getSuggestions(String input) {
    if (input.isEmpty) return [];

    final productos = _productosService.productos;
    final suggestions = <String>{};

    for (var producto in productos) {
      if (producto.nombre.toLowerCase().contains(input.toLowerCase())) {
        suggestions.add(producto.nombre);
      }
      if (producto.categoria?.nombre != null) {
        if (producto.categoria!.nombre.toLowerCase().contains(
          input.toLowerCase(),
        )) {
          suggestions.add(producto.categoria!.nombre);
        }
      }
    }

    return suggestions.take(10).toList();
  }

  /// Obtener categorías disponibles
  List<String> getAvailableCategories() {
    final categorias = <String>{};
    for (var p in _productosService.productos) {
      if (p.categoria?.nombre != null && p.categoria!.nombre.isNotEmpty) {
        categorias.add(p.categoria!.nombre);
      }
    }
    return categorias.toList();
  }

  /// Obtener rango de precios
  (double, double) getPriceRange() {
    if (_productosService.productos.isEmpty) {
      return (0.0, 0.0);
    }

    final productos = _productosService.productos;
    double minPrice = productos.first.precio;
    double maxPrice = productos.first.precio;

    for (var producto in productos) {
      if (producto.precio < minPrice) minPrice = producto.precio;
      if (producto.precio > maxPrice) maxPrice = producto.precio;
    }

    return (minPrice, maxPrice);
  }
}
