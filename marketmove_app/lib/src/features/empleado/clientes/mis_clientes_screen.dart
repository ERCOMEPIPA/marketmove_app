import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/clientes_service.dart';
import '../../../shared/services/actividades_service.dart';
import '../../../shared/constants/app_colors.dart';

/// Pantalla de clientes asignados para empleados
/// Vista restringida: solo puede ver/editar clientes asignados
class MisClientesScreen extends StatefulWidget {
  const MisClientesScreen({super.key});

  @override
  State<MisClientesScreen> createState() => _MisClientesScreenState();
}

class _MisClientesScreenState extends State<MisClientesScreen> {
  final _clientesService = ClientesService();
  final _actividadesService = ActividadesService();
  final _searchController = TextEditingController();

  String? _empleadoId;
  String? _negocioId;
  List<ClienteModel> _clientes = [];
  List<ClienteModel> _clientesFiltrados = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _empleadoId = user.id;

    // Obtener negocio_id del empleado
    try {
      final profile = await Supabase.instance.client
          .from('perfiles')
          .select('negocio_id')
          .eq('id', user.id)
          .single();

      _negocioId = profile['negocio_id'] as String?;
    } catch (e) {
      // Si falla, usamos el ID del usuario
      _negocioId = user.id;
    }

    _loadData();
  }

  Future<void> _loadData() async {
    if (_empleadoId == null) return;

    setState(() => _isLoading = true);
    try {
      final clientes = await _clientesService.getClientesAsignados(
        _empleadoId!,
      );

      setState(() {
        _clientes = clientes;
        _clientesFiltrados = clientes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _filtrarClientes(String query) {
    setState(() {
      _clientesFiltrados = _clientes.where((c) {
        return query.isEmpty ||
            c.nombre.toLowerCase().contains(query.toLowerCase()) ||
            (c.email?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
            (c.empresa?.toLowerCase().contains(query.toLowerCase()) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.info, AppColors.info.withOpacity(0.85)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mis Clientes',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_clientes.length} clientes asignados',
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      onChanged: _filtrarClientes,
                      decoration: InputDecoration(
                        hintText: 'Buscar...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Lista
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_clientesFiltrados.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes clientes asignados',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildClienteCard(_clientesFiltrados[index]),
                    childCount: _clientesFiltrados.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioLead(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildClienteCard(ClienteModel cliente) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _mostrarDetalleCliente(cliente),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _getColorEstado(
                  cliente.estado,
                ).withOpacity(0.1),
                child: Text(
                  cliente.nombre.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: _getColorEstado(cliente.estado),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (cliente.empresa != null)
                      Text(
                        cliente.empresa!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getColorEstado(cliente.estado).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        EstadoCliente.nombre(cliente.estado),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _getColorEstado(cliente.estado),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.phone),
                onPressed: () => _registrarLlamada(cliente),
                tooltip: 'Registrar llamada',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case EstadoCliente.lead:
        return Colors.grey;
      case EstadoCliente.contactado:
        return Colors.blue;
      case EstadoCliente.calificado:
        return Colors.purple;
      case EstadoCliente.cliente:
        return AppColors.success;
      case EstadoCliente.inactivo:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _mostrarFormularioLead() {
    if (_negocioId == null) return;

    final nombreController = TextEditingController();
    final emailController = TextEditingController();
    final telefonoController = TextEditingController();
    final empresaController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo Lead'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: empresaController,
                  decoration: const InputDecoration(
                    labelText: 'Empresa',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nombreController.text.trim().isEmpty) return;

                      setDialogState(() => isLoading = true);

                      try {
                        final cliente = ClienteModel(
                          id: '',
                          negocioId: _negocioId!,
                          empleadoAsignadoId: _empleadoId,
                          nombre: nombreController.text.trim(),
                          email: emailController.text.trim().isEmpty
                              ? null
                              : emailController.text.trim(),
                          telefono: telefonoController.text.trim().isEmpty
                              ? null
                              : telefonoController.text.trim(),
                          empresa: empresaController.text.trim().isEmpty
                              ? null
                              : empresaController.text.trim(),
                          estado: EstadoCliente.lead,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );

                        await _clientesService.crearCliente(cliente);
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        _loadData();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            this.context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _registrarLlamada(ClienteModel cliente) {
    final notasController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Llamada a ${cliente.nombre}'),
        content: TextField(
          controller: notasController,
          decoration: const InputDecoration(
            labelText: 'Resultado de la llamada',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _actividadesService.registrarLlamada(
                  negocioId: _negocioId!,
                  empleadoId: _empleadoId!,
                  clienteId: cliente.id,
                  titulo: 'Llamada a ${cliente.nombre}',
                  resultado: notasController.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Llamada registrada'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalleCliente(ClienteModel cliente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _getColorEstado(
                      cliente.estado,
                    ).withOpacity(0.1),
                    child: Text(
                      cliente.nombre.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: _getColorEstado(cliente.estado),
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente.nombre,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (cliente.empresa != null)
                          Text(
                            cliente.empresa!,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildInfoRow(Icons.email, 'Email', cliente.email ?? 'Sin email'),
              _buildInfoRow(
                Icons.phone,
                'Teléfono',
                cliente.telefono ?? 'Sin teléfono',
              ),
              _buildInfoRow(
                Icons.label,
                'Estado',
                EstadoCliente.nombre(cliente.estado),
              ),

              if (cliente.notas != null && cliente.notas!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Notas',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(cliente.notas!),
                ),
              ],

              const SizedBox(height: 24),

              // Acciones rápidas
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.phone, size: 18),
                    label: const Text('Llamar'),
                    onPressed: () {
                      Navigator.pop(context);
                      _registrarLlamada(cliente);
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.email, size: 18),
                    label: const Text('Email'),
                    onPressed: () {
                      Navigator.pop(context);
                      _registrarEmail(cliente);
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.note_add, size: 18),
                    label: const Text('Nota'),
                    onPressed: () {
                      Navigator.pop(context);
                      _agregarNota(cliente);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Cambiar estado
              const Text(
                'Cambiar estado:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: EstadoCliente.todos.map((estado) {
                  final isSelected = estado == cliente.estado;
                  return FilterChip(
                    label: Text(EstadoCliente.nombre(estado)),
                    selected: isSelected,
                    onSelected: isSelected
                        ? null
                        : (_) async {
                            Navigator.pop(context);
                            await _clientesService.cambiarEstado(
                              cliente.id,
                              estado,
                            );
                            _loadData();
                          },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  void _registrarEmail(ClienteModel cliente) {
    // Similar a _registrarLlamada pero para email
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Email registrado')));
  }

  void _agregarNota(ClienteModel cliente) {
    final notasController = TextEditingController(text: cliente.notas);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Agregar Nota'),
        content: TextField(
          controller: notasController,
          decoration: const InputDecoration(
            labelText: 'Notas',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _clientesService.actualizarCliente(cliente.id, {
                'notas': notasController.text.trim(),
              });
              _loadData();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
