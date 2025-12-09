import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/search_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _searchController;
  late SearchService _searchService;
  late SearchFilters _currentFilters;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchService = context.read<SearchService>();
    _currentFilters = SearchFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchService.search(value);
  }

  void _showFiltersDialog() {
    final (minPrice, maxPrice) = _searchService.getPriceRange();
    final categories = _searchService.getAvailableCategories();

    double selectedMinPrice = _currentFilters.minPrice;
    double selectedMaxPrice = _currentFilters.maxPrice;
    String? selectedCategory = _currentFilters.category;
    bool inStockOnly = _currentFilters.inStockOnly;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filtros de búsqueda'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rango de precio
                const Text(
                  'Rango de Precio',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          label: Text('Mín'),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(
                          text: selectedMinPrice.toString(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            selectedMinPrice = double.tryParse(value) ?? 0.0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          label: Text('Máx'),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(
                          text: selectedMaxPrice.toString(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            selectedMaxPrice =
                                double.tryParse(value) ?? double.infinity;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Categoría
                const Text(
                  'Categoría',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedCategory,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todas las categorías'),
                    ),
                    ...categories.map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Stock
                CheckboxListTile(
                  title: const Text('Solo productos en stock'),
                  value: inStockOnly,
                  onChanged: (value) {
                    setState(() {
                      inStockOnly = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _currentFilters = SearchFilters();
                _searchService.updateFilters(_currentFilters);
                Navigator.pop(context);
              },
              child: const Text('Limpiar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                _currentFilters = SearchFilters(
                  minPrice: selectedMinPrice,
                  maxPrice: selectedMaxPrice,
                  category: selectedCategory,
                  inStockOnly: inStockOnly,
                  sortBy: _currentFilters.sortBy,
                );
                _searchService.updateFilters(_currentFilters);
                Navigator.pop(context);
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ordenar por'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<SortOption>(
              title: const Text('Relevancia'),
              value: SortOption.relevancia,
              groupValue: _currentFilters.sortBy,
              onChanged: (value) {
                if (value != null) {
                  _currentFilters = _currentFilters.copyWith(sortBy: value);
                  _searchService.updateFilters(_currentFilters);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<SortOption>(
              title: const Text('Precio (menor a mayor)'),
              value: SortOption.precioAsc,
              groupValue: _currentFilters.sortBy,
              onChanged: (value) {
                if (value != null) {
                  _currentFilters = _currentFilters.copyWith(sortBy: value);
                  _searchService.updateFilters(_currentFilters);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<SortOption>(
              title: const Text('Precio (mayor a menor)'),
              value: SortOption.precioDesc,
              groupValue: _currentFilters.sortBy,
              onChanged: (value) {
                if (value != null) {
                  _currentFilters = _currentFilters.copyWith(sortBy: value);
                  _searchService.updateFilters(_currentFilters);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<SortOption>(
              title: const Text('Más nuevos'),
              value: SortOption.nuevosPrimero,
              groupValue: _currentFilters.sortBy,
              onChanged: (value) {
                if (value != null) {
                  _currentFilters = _currentFilters.copyWith(sortBy: value);
                  _searchService.updateFilters(_currentFilters);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar productos'), elevation: 0),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar productos...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _searchService.clearSearch();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
              ],
            ),
          ),

          // Botones de filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _showFiltersDialog,
                  icon: const Icon(Icons.tune),
                  label: const Text('Filtros'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showSortDialog,
                  icon: const Icon(Icons.sort),
                  label: const Text('Ordenar'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Resultados de búsqueda
          Expanded(
            child: Consumer<SearchService>(
              builder: (context, searchService, _) {
                if (searchService.isSearching) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (searchService.results.isEmpty &&
                    _searchController.text.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron productos',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (searchService.results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Escribe para buscar productos',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: searchService.results.length,
                  itemBuilder: (context, index) {
                    final result = searchService.results[index];
                    return SearchResultCard(
                      result: result,
                      onTap: () {
                        // Navegar a detalles del producto
                        Navigator.pop(context, result.id);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar un resultado de búsqueda
class SearchResultCard extends StatelessWidget {
  final SearchResult result;
  final VoidCallback? onTap;

  const SearchResultCard({super.key, required this.result, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 56,
          height: 56,
          color: Colors.grey[100],
          child: result.imagenUrl != null && result.imagenUrl!.isNotEmpty
              ? Image.network(
                  result.imagenUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.inventory_2, color: Colors.grey[400]),
                )
              : Icon(Icons.inventory_2, color: Colors.grey[400]),
        ),
      ),
      title: Text(result.nombre),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            result.categoria,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${result.precio.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                'Stock: ${result.stock}',
                style: TextStyle(
                  fontSize: 12,
                  color: result.stock > 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }
}
