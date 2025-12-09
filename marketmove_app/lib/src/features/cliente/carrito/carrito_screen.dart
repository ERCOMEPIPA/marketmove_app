import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/services/cart_service.dart';
import '../../../shared/services/orders_service.dart';
import '../../../shared/services/auth_service.dart';

/// Pantalla de carrito de compras
class CarritoScreen extends StatelessWidget {
  static final _currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 2);

  const CarritoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<CartService>(
        builder: (context, cartService, _) {
          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
            },
            child: SingleChildScrollView(
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
                            'Mi Carrito',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${cartService.itemCount} items',
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
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shopping_cart,
                          color: AppColors.warning,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (cartService.items.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Carrito vacío',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Agrega productos para comenzar',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => context.go('/empleado/catalogo'),
                              icon: const Icon(Icons.shopping_bag),
                              label: const Text('Continuar Comprando'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        // Lista de items
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cartService.items.length,
                          itemBuilder: (context, index) {
                            final item = cartService.items[index];
                            return _buildCartItem(context, cartService, item);
                          },
                        ),
                        const SizedBox(height: 24),

                        // Resumen
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal:'),
                                  Text(_currencyFormat.format(cartService.total)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text('Envío:'),
                                  Text('Gratis'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text('Impuestos:'),
                                  Text('Incluidos'),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _currencyFormat.format(cartService.total),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Botones
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final authService = AuthService();
                              final currentUser = Supabase.instance.client.auth.currentUser;
                              
                              if (currentUser == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Error: Usuario no autenticado'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }

                              // Obtener el perfil del usuario actual para el dueño_id
                              final profiles = await Supabase.instance.client
                                  .from('perfiles')
                                  .select('id')
                                  .eq('email', currentUser.email!)
                                  .single();

                              final userId = currentUser.id;
                              final ownerId = profiles['id'] as String;

                              // Guardar la orden en Supabase
                              final ordersService = context.read<OrdersService>();
                              await ordersService.addOrderFromCart(
                                cartService.items
                                    .map((item) => {
                                          'nombre': item.nombre,
                                          'cantidad': item.cantidad,
                                          'precio': item.precio,
                                          'imagen': item.imagen,
                                        })
                                    .toList(),
                                cartService.total,
                                userId,
                                ownerId,
                              );

                              // Mostrar mensaje y limpiar carrito
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pedido realizado exitosamente'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              cartService.clear();
                              context.go('/empleado/compras');
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al realizar pedido: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Realizar Pedido'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => context.go('/empleado/catalogo'),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Continuar Comprando'),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCartItem(
      BuildContext context, CartService cartService, CartItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Imagen
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  item.imagen,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currencyFormat.format(item.precio),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Cantidad
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (item.cantidad > 1) {
                            cartService.updateQuantity(
                              item.id,
                              item.cantidad - 1,
                            );
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      SizedBox(
                        width: 30,
                        child: Center(
                          child: Text(
                            '${item.cantidad}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          cartService.updateQuantity(
                            item.id,
                            item.cantidad + 1,
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Total y eliminar
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _currencyFormat.format(item.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                IconButton(
                  onPressed: () {
                    cartService.removeItem(item.id);
                  },
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.error,
                  iconSize: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
