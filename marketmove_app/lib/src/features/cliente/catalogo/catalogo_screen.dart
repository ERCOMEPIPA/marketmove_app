import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/cart_service.dart';
import '../../../shared/services/productos_service.dart';

/// Pantalla de catálogo de productos para empleados
/// Carga productos de Supabase según el dueño del negocio
class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  final _authService = AuthService();
  final _currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 2);
  String? _ownerUserId;

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  Future<void> _loadProductos() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      // Obtener el owner_id del empleado
      final profile = await Supabase.instance.client
          .from('perfiles')
          .select('owner_id')
          .eq('id', currentUser.id)
          .single();

      _ownerUserId = profile['owner_id'] as String?;

      if (_ownerUserId != null && mounted) {
        final productosService = context.read<ProductosService>();
        await productosService.loadProductosForEmployee(_ownerUserId!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductosService>(
      builder: (context, productosService, _) {
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: _loadProductos,
            child: productosService.isLoading
                ? const Center(child: CircularProgressIndicator())
                : productosService.error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            productosService.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      )
                    : ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withOpacity(0.8),
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Catálogo',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${productosService.productos.length} productos disponibles',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Contenido
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Búsqueda
                                TextField(
                                  onChanged: (value) =>
                                      productosService.setSearchQuery(value),
                                  decoration: InputDecoration(
                                    hintText: 'Buscar productos...',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon:
                                        productosService.searchQuery.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear),
                                                onPressed: () =>
                                                    productosService.setSearchQuery(''),
                                              )
                                            : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Categorías
                                if (productosService.categorias.isNotEmpty)
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: productosService.categorias
                                          .map((cat) {
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: _buildCategoryChip(
                                            cat.nombre,
                                            (productosService.selectedCategory ==
                                                    cat.nombre ||
                                                (cat.nombre == 'Todos' &&
                                                    productosService
                                                        .selectedCategory ==
                                                        'Todos')),
                                            () => productosService
                                                .setSelectedCategory(cat.nombre),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                const SizedBox(height: 20),

                                // Grid de productos
                                if (productosService.productos.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 60),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.shopping_bag_outlined,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Sin productos disponibles',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                          childAspectRatio: 0.72,
                                        ),
                                    itemCount: productosService.productos.length,
                                    itemBuilder: (context, index) {
                                      final producto =
                                          productosService.productos[index];
                                      return _buildProductCard(
                                        context,
                                        producto,
                                        context.read<CartService>(),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    dynamic producto,
    CartService cartService,
  ) {
    final hasStock = producto.stock > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagen
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagen o placeholder
                  producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty
                      ? Image.network(
                          producto.imagenUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image_outlined,
                              color: Colors.grey[400],
                              size: 40,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image_outlined,
                            color: Colors.grey[400],
                            size: 40,
                          ),
                        ),

                  // Overlay agotado
                  if (!hasStock)
                    Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'AGOTADO',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Badge stock
                  if (hasStock)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${producto.stock}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Info del producto
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nombre
                Text(
                  producto.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),

                // Categoría
                if (producto.categoria != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      producto.categoria!.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Precio y botón
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _currencyFormat.format(producto.precio),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (hasStock)
                      GestureDetector(
                        onTap: () =>
                            _showProductDetail(context, producto, cartService),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDetail(
    BuildContext context,
    dynamic producto,
    CartService cartService,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        int cantidad = 1;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Imagen grande
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 250,
                        color: AppColors.surface,
                        child: producto.imagenUrl != null &&
                                producto.imagenUrl!.isNotEmpty
                            ? Image.network(
                                producto.imagenUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Center(
                                    child: Icon(
                                      Icons.inventory_2_outlined,
                                      size: 80,
                                      color: Colors.grey[300],
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  size: 80,
                                  color: Colors.grey[300],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nombre y categoría
                    Text(
                      producto.nombre,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (producto.categoria != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        width: double.infinity,
                        child: Text(
                          producto.categoria!.nombre,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Descripción
                    if (producto.descripcion != null &&
                        producto.descripcion!.isNotEmpty)
                      Text(
                        producto.descripcion!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Info row: Precio y Stock
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Precio',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currencyFormat.format(producto.precio),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Stock disponible',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: producto.stock > 0
                                    ? AppColors.success.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${producto.stock} un.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: producto.stock > 0
                                      ? AppColors.success
                                      : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Selector de cantidad
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: cantidad > 1
                                ? () => setModalState(() => cantidad--)
                                : null,
                            color: cantidad > 1
                                ? AppColors.primary
                                : Colors.grey[400],
                          ),
                          Text(
                            cantidad.toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: cantidad < producto.stock
                                ? () => setModalState(() => cantidad++)
                                : null,
                            color: cantidad < producto.stock
                                ? AppColors.primary
                                : Colors.grey[400],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botón agregar al carrito
                    ElevatedButton.icon(
                      onPressed: () {
                        cartService.addItem(
                          CartItem(
                            id: producto.id,
                            nombre: producto.nombre,
                            precio: producto.precio,
                            cantidad: cantidad,
                            imagen: producto.imagenUrl ?? '',
                          ),
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '$cantidad x ${producto.nombre} añadido al carrito',
                            ),
                            duration: const Duration(seconds: 1),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart),
                      label: Text(
                        'Agregar al carrito - ${_currencyFormat.format(producto.precio * cantidad)}',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
