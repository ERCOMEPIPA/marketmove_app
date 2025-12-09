import 'package:flutter/material.dart';
import 'package:marketmove_app/src/shared/constants/app_colors.dart';
import 'package:marketmove_app/src/shared/models/producto_model.dart';
import 'package:intl/intl.dart';

/// Card para mostrar un producto en grid o lista
class ProductoCard extends StatelessWidget {
  final ProductoModel producto;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductoCard({
    super.key,
    required this.producto,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isStockBajo = producto.stock <= producto.stockMinimo;
    final currencyFormat = NumberFormat.currency(symbol: '€');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isStockBajo ? AppColors.warning : AppColors.border,
          width: isStockBajo ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Stack(
                  children: [
                    // Imagen o ícono placeholder
                    Center(
                      child: producto.imagenUrl != null &&
                              producto.imagenUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Image.network(
                                producto.imagenUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildPlaceholderIcon();
                                },
                              ),
                            )
                          : _buildPlaceholderIcon(),
                    ),
                    // Badge de estado activo/inactivo
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: producto.activo
                              ? AppColors.success
                              : AppColors.textDisabled,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          producto.activo ? 'Activo' : 'Inactivo',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Badge de stock bajo
                    if (isStockBajo)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.warning_amber,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    // Menú de acciones
                    if (onEdit != null || onDelete != null)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: PopupMenuButton<String>(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.more_vert,
                              size: 20,
                            ),
                          ),
                          onSelected: (value) {
                            if (value == 'edit' && onEdit != null) {
                              onEdit!();
                            } else if (value == 'delete' && onDelete != null) {
                              onDelete!();
                            }
                          },
                          itemBuilder: (context) => [
                            if (onEdit != null)
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                            if (onDelete != null)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20),
                                    SizedBox(width: 8),
                                    Text('Eliminar'),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Información del producto
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  Text(
                    producto.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Precio
                  Text(
                    currencyFormat.format(producto.precio),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Stock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2,
                            size: 14,
                            color: isStockBajo
                                ? AppColors.warning
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Stock: ${producto.stock}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isStockBajo
                                  ? AppColors.warning
                                  : AppColors.textSecondary,
                              fontWeight:
                                  isStockBajo ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      if (isStockBajo)
                        Text(
                          'Mín: ${producto.stockMinimo}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textDisabled,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Icon(
      Icons.inventory_2_outlined,
      size: 48,
      color: AppColors.textDisabled,
    );
  }
}
