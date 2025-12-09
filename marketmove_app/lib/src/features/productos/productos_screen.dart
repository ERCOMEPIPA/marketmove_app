import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/producto_model.dart';
import '../../shared/services/productos_service.dart';
import '../../shared/services/auth_service.dart';

/// Pantalla de gestión de productos con CRUD completo
class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final _productosService = ProductosService();
  final _authService = AuthService();
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 2);

  List<ProductoModel> _productos = [];
  List<CategoriaModel> _categorias = [];
  bool _isLoading = true;
  String? _error;
  bool _soloActivos = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final productos = await _productosService.getProductos(
        user.id,
        soloActivos: _soloActivos,
      );
      final categorias = await _productosService.getCategorias(user.id);

      setState(() {
        _productos = productos;
        _categorias = categorias;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _buscar(String query) async {
    if (query.isEmpty) {
      _loadData();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser!;
      final productos = await _productosService.buscarProductos(user.id, query);
      setState(() {
        _productos = productos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _eliminarProducto(ProductoModel producto) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar "${producto.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _productosService.eliminarProducto(producto.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Producto eliminado')));
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o código de barras',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadData();
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: _buscar,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_productos.length} productos',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Row(
                      children: [
                        Text(
                          'Solo activos',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Switch(
                          value: _soloActivos,
                          onChanged: (value) {
                            setState(() => _soloActivos = value);
                            _loadData();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de productos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: $_error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : _productos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay productos',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Agrega tu primer producto'),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _productos.length,
                      itemBuilder: (context, index) {
                        final producto = _productos[index];
                        return _buildProductoCard(producto);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioProducto(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Producto'),
      ),
    );
  }

  Widget _buildProductoCard(ProductoModel producto) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: !producto.activo
              ? Colors.grey.shade300
              : producto.stockBajo
              ? Colors.orange.shade100
              : Colors.blue.shade100,
          child: Icon(
            Icons.inventory_2,
            color: !producto.activo
                ? Colors.grey
                : producto.stockBajo
                ? Colors.orange
                : Colors.blue,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(producto.nombre)),
            if (!producto.activo)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Inactivo', style: TextStyle(fontSize: 10)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Precio: ${_currencyFormat.format(producto.precio)}'),
            Text(
              'Stock: ${producto.stock} unid.',
              style: TextStyle(
                color: producto.stockBajo ? Colors.orange.shade700 : null,
                fontWeight: producto.stockBajo ? FontWeight.bold : null,
              ),
            ),
            if (producto.categoria != null)
              Text(
                'Categoría: ${producto.categoria!.nombre}',
                style: const TextStyle(fontSize: 12),
              ),
            if (producto.codigoBarras != null)
              Text(
                'CB: ${producto.codigoBarras}',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (producto.stockBajo && producto.activo)
              const Icon(Icons.warning_amber, color: Colors.orange),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'editar':
                    _mostrarFormularioProducto(producto: producto);
                    break;
                  case 'eliminar':
                    _eliminarProducto(producto);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'editar',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'eliminar',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  void _mostrarFormularioProducto({ProductoModel? producto}) {
    showDialog(
      context: context,
      builder: (context) => _ProductoFormDialog(
        producto: producto,
        categorias: _categorias,
        onSaved: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }
}

/// Diálogo de formulario para crear/editar producto
class _ProductoFormDialog extends StatefulWidget {
  final ProductoModel? producto;
  final List<CategoriaModel> categorias;
  final VoidCallback onSaved;

  const _ProductoFormDialog({
    this.producto,
    required this.categorias,
    required this.onSaved,
  });

  @override
  State<_ProductoFormDialog> createState() => _ProductoFormDialogState();
}

class _ProductoFormDialogState extends State<_ProductoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _productosService = ProductosService();
  final _authService = AuthService();

  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _precioController;
  late TextEditingController _stockController;
  late TextEditingController _stockMinimoController;
  late TextEditingController _codigoBarrasController;

  String? _categoriaId;
  bool _isLoading = false;

  // Variables para imagen
  Uint8List? _imagenBytes;
  String? _imagenNombre;
  String? _imagenUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.producto?.nombre);
    _descripcionController = TextEditingController(
      text: widget.producto?.descripcion,
    );
    _precioController = TextEditingController(
      text: widget.producto?.precio.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: widget.producto?.stock.toString() ?? '0',
    );
    _stockMinimoController = TextEditingController(
      text: widget.producto?.stockMinimo.toString() ?? '10',
    );
    _codigoBarrasController = TextEditingController(
      text: widget.producto?.codigoBarras,
    );
    _categoriaId = widget.producto?.categoriaId;
    _imagenUrl = widget.producto?.imagenUrl;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    _stockMinimoController.dispose();
    _codigoBarrasController.dispose();
    super.dispose();
  }

  /// Selecciona una imagen y la sube a Supabase Storage
  Future<void> _seleccionarImagen() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) return;

      setState(() {
        _imagenBytes = file.bytes;
        _imagenNombre = file.name;
        _isUploadingImage = true;
      });

      // Subir a Supabase Storage
      final userId = _authService.currentUser!.id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.extension ?? 'jpg';
      final fileName = 'productos/${userId}_$timestamp.$extension';

      final supabase = Supabase.instance.client;

      await supabase.storage
          .from('productos')
          .uploadBinary(fileName, file.bytes!);

      // Obtener URL pública
      final publicUrl = supabase.storage
          .from('productos')
          .getPublicUrl(fileName);

      setState(() {
        _imagenUrl = publicUrl;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen subida correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser!;

      if (widget.producto == null) {
        // Crear nuevo
        await _productosService.crearProducto(
          userId: user.id,
          nombre: _nombreController.text.trim(),
          descripcion: _descripcionController.text.trim().isEmpty
              ? null
              : _descripcionController.text.trim(),
          precio: double.parse(_precioController.text),
          stock: int.parse(_stockController.text),
          stockMinimo: int.parse(_stockMinimoController.text),
          categoriaId: _categoriaId,
          codigoBarras: _codigoBarrasController.text.trim().isEmpty
              ? null
              : _codigoBarrasController.text.trim(),
          imagenUrl: _imagenUrl,
        );
      } else {
        // Actualizar existente
        await _productosService.actualizarProducto(
          productoId: widget.producto!.id,
          nombre: _nombreController.text.trim(),
          descripcion: _descripcionController.text.trim().isEmpty
              ? null
              : _descripcionController.text.trim(),
          precio: double.parse(_precioController.text),
          stock: int.parse(_stockController.text),
          stockMinimo: int.parse(_stockMinimoController.text),
          categoriaId: _categoriaId,
          codigoBarras: _codigoBarrasController.text.trim().isEmpty
              ? null
              : _codigoBarrasController.text.trim(),
          imagenUrl: _imagenUrl,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.producto == null
                  ? 'Producto creado'
                  : 'Producto actualizado',
            ),
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.producto == null ? 'Nuevo Producto' : 'Editar Producto',
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _precioController,
                  decoration: const InputDecoration(
                    labelText: 'Precio *',
                    prefixText: '€ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Requerido';
                    if (double.tryParse(value!) == null)
                      return 'Número inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        decoration: const InputDecoration(
                          labelText: 'Stock *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Requerido';
                          if (int.tryParse(value!) == null) return 'Inválido';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stockMinimoController,
                        decoration: const InputDecoration(
                          labelText: 'Stock mínimo *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Requerido';
                          if (int.tryParse(value!) == null) return 'Inválido';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _codigoBarrasController,
                  decoration: const InputDecoration(
                    labelText: 'Código de barras',
                    border: OutlineInputBorder(),
                    helperText: 'Opcional',
                  ),
                ),
                const SizedBox(height: 12),

                // Selector de imagen
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Imagen del producto',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),

                      // Preview de imagen
                      if (_imagenUrl != null && _imagenUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _imagenUrl!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 120,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.broken_image, size: 40),
                              ),
                            ),
                          ),
                        )
                      else if (_imagenBytes != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _imagenBytes!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.add_photo_alternate,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Botón para seleccionar imagen
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isUploadingImage
                              ? null
                              : _seleccionarImagen,
                          icon: _isUploadingImage
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload, size: 18),
                          label: Text(
                            _isUploadingImage
                                ? 'Subiendo...'
                                : (_imagenUrl != null
                                      ? 'Cambiar imagen'
                                      : 'Seleccionar imagen'),
                          ),
                        ),
                      ),

                      if (_imagenNombre != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _imagenNombre!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _categoriaId,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Sin categoría'),
                    ),
                    ...widget.categorias.map(
                      (cat) => DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.nombre),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _categoriaId = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _guardar,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
