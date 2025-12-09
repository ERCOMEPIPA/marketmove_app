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
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Encabezado
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Catálogo',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineLarge
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${productosService.productos.length} productos',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.store,
                                    color: AppColors.success,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Barra de búsqueda
                            TextField(
                              onChanged: (value) {
                                productosService.setSearchQuery(value);
                              },
                              decoration: InputDecoration(
                                hintText: 'Buscar productos...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: productosService.searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          productosService.setSearchQuery('');
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppColors.surface,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Filtros por categoría
                            if (productosService.categorias.isNotEmpty)
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: productosService.categorias
                                      .map((category) {
                                        final isSelected =
                                            productosService.selectedCategory ==
                                                category.nombre;
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: FilterChip(
                                            selected: isSelected,
                                            label: Text(category.nombre),
                                            onSelected: (selected) {
                                              productosService
                                                  .setSelectedCategory(
                                                      category.nombre);
                                            },
                                            backgroundColor: AppColors.surface,
                                            selectedColor:
                                                AppColors.primary.withOpacity(0.2),
                                            side: BorderSide(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.border,
                                            ),
                                          ),
                                        );
                                      })
                                      .toList(),
                                ),
                              ),
                            const SizedBox(height: 24),

                            // Grid de productos o mensaje vacío
                            if (productosService.productos.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 48),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 80,
                                        color: Colors.grey[300],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Sin productos disponibles',
                                        style:
                                            Theme.of(context).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Intenta con otros filtros',
                                        style: TextStyle(color: Colors.grey[600]),
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
                                  childAspectRatio: 0.75,
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
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    dynamic producto,
    CartService cartService,
  ) {
    final hasStock = producto.stock > 0;
    
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: hasStock ? () => _showProductDetail(context, producto, cartService) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagen con badge de stock
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty
                            ? Image.network(
                                producto.imagenUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    color: Colors.grey[100],
                                    child: Icon(
                                      Icons.inventory_2_outlined,
                                      size: 48,
                                      color: Colors.grey[300],
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[100],
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  size: 48,
                                  color: Colors.grey[300],
                                ),
                              ),
                      ),
                      
                      // Badge de stock
                      if (!hasStock)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: const Text(
                            'Sin stock',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Información del producto
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Nombre y categoría
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            producto.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (producto.categoria != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                producto.categoria!.nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Precio y botón
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currencyFormat.format(producto.precio),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (hasStock)
                                Text(
                                  'Stock: ${producto.stock}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                          if (hasStock)
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  cartService.addItem(
                                    CartItem(
                                      id: producto.id,
                                      nombre: producto.nombre,
                                      precio: producto.precio,
                                      cantidad: 1,
                                      imagen: producto.imagenUrl ?? '',
                                    ),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${producto.nombre} añadido al carrito'),
                                      duration: const Duration(milliseconds: 800),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                iconSize: 18,
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
