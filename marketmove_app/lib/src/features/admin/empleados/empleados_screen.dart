import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/limites_service.dart';
import '../../../shared/widgets/plan_usage_widget.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/models/user_profile_model.dart';

/// Pantalla de gestión de empleados para el dueño del negocio
/// Incluye validación de límites del plan y barra de uso
class EmpleadosScreen extends StatefulWidget {
  const EmpleadosScreen({super.key});

  @override
  State<EmpleadosScreen> createState() => _EmpleadosScreenState();
}

class _EmpleadosScreenState extends State<EmpleadosScreen> {
  final _supabase = Supabase.instance.client;
  final _limitesService = LimitesService();

  String? _duenoId;
  List<UserProfileModel> _empleados = [];
  PlanLimites? _limites;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _duenoId = _supabase.auth.currentUser?.id;
    _loadData();
  }

  Future<void> _loadData() async {
    if (_duenoId == null) return;

    setState(() => _isLoading = true);
    try {
      // Cargar empleados del negocio
      final empleadosData = await _supabase
          .from('perfiles')
          .select()
          .eq('negocio_id', _duenoId!)
          .eq('rol', 'empleado')
          .order('created_at', ascending: false);

      final empleados = (empleadosData as List)
          .map((e) => UserProfileModel.fromJson(e))
          .toList();

      // Cargar límites del plan
      final limites = await _limitesService.getLimitesDueno(_duenoId!);

      setState(() {
        _empleados = empleados;
        _limites = limites;
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

  Future<void> _crearEmpleado() async {
    if (_duenoId == null) return;

    // Validar límites antes de crear
    final validacion = await _limitesService.puedeAgregarEmpleado(_duenoId!);
    if (!validacion.permitido) {
      if (mounted) {
        _mostrarDialogoLimite(validacion.mensaje);
      }
      return;
    }

    // Mostrar formulario de creación
    _mostrarFormularioEmpleado();
  }

  void _mostrarDialogoLimite(String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber,
          color: AppColors.warning,
          size: 48,
        ),
        title: const Text('Límite Alcanzado'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navegar a pantalla de planes
            },
            child: const Text('Ver Planes'),
          ),
        ],
      ),
    );
  }

  void _mostrarFormularioEmpleado([UserProfileModel? empleado]) {
    final emailController = TextEditingController(text: empleado?.email);
    final nombreController = TextEditingController(
      text: empleado?.nombreNegocio,
    );
    final telefonoController = TextEditingController(text: empleado?.telefono);
    final passwordController = TextEditingController();
    bool isLoading = false;
    final isEditing = empleado != null;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Editar Empleado' : 'Nuevo Empleado'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  enabled: !isEditing, // No se puede cambiar el email
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                if (!isEditing) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                ],
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
                      if (emailController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('El email es requerido'),
                          ),
                        );
                        return;
                      }

                      if (!isEditing && passwordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'La contraseña debe tener al menos 6 caracteres',
                            ),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        if (isEditing) {
                          // Actualizar empleado existente
                          await _supabase
                              .from('perfiles')
                              .update({
                                'nombre_negocio':
                                    nombreController.text.trim().isEmpty
                                    ? null
                                    : nombreController.text.trim(),
                                'telefono':
                                    telefonoController.text.trim().isEmpty
                                    ? null
                                    : telefonoController.text.trim(),
                              })
                              .eq('id', empleado.id);
                        } else {
                          // Guardar la sesión actual del dueño
                          final duenoSession = _supabase.auth.currentSession;
                          final duenoRefreshToken = duenoSession?.refreshToken;

                          try {
                            // Crear nuevo usuario empleado
                            // NOTA: Si Supabase tiene "Confirm email" habilitado,
                            // el empleado recibirá un email de confirmación
                            final response = await _supabase.auth.signUp(
                              email: emailController.text.trim(),
                              password: passwordController.text,
                              data: {
                                'rol': 'empleado',
                                'negocio_id': _duenoId,
                                'nombre': nombreController.text.trim(),
                              },
                            );

                            // Verificar si el usuario fue creado
                            if (response.user != null) {
                              final empleadoId = response.user!.id;

                              // La sesión puede haber cambiado, restaurar la del dueño primero
                              if (duenoRefreshToken != null) {
                                try {
                                  await _supabase.auth.setSession(
                                    duenoRefreshToken,
                                  );
                                } catch (_) {
                                  // Si falla, intentar refrescar
                                  await _supabase.auth.refreshSession();
                                }
                              }

                              // Ahora crear/actualizar el perfil del empleado
                              // Esto debe hacerse con la sesión del dueño activa
                              await _supabase.from('perfiles').upsert({
                                'id': empleadoId,
                                'email': emailController.text.trim(),
                                'rol': 'empleado',
                                'negocio_id': _duenoId,
                                'nombre_negocio':
                                    nombreController.text.trim().isEmpty
                                    ? null
                                    : nombreController.text.trim(),
                                'telefono':
                                    telefonoController.text.trim().isEmpty
                                    ? null
                                    : telefonoController.text.trim(),
                                'activo': true,
                              });
                            } else if (response.session == null) {
                              // Usuario creado pero necesita confirmación de email
                              // Restaurar sesión del dueño
                              if (duenoRefreshToken != null) {
                                await _supabase.auth.setSession(
                                  duenoRefreshToken,
                                );
                              }

                              // Mostrar mensaje informativo
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Empleado invitado. Debe confirmar su email para activarse.',
                                    ),
                                    backgroundColor: AppColors.info,
                                    duration: Duration(seconds: 4),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            // Asegurar que restauramos la sesión del dueño
                            if (duenoRefreshToken != null) {
                              try {
                                await _supabase.auth.setSession(
                                  duenoRefreshToken,
                                );
                              } catch (_) {}
                            }
                            rethrow;
                          }
                        }

                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        _loadData();

                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEditing
                                    ? 'Empleado actualizado'
                                    : 'Empleado creado exitosamente',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Guardar' : 'Crear'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminarEmpleado(UserProfileModel empleado) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.delete_forever,
          color: AppColors.error,
          size: 48,
        ),
        title: const Text('¿Eliminar Empleado?'),
        content: Text(
          'Esta acción desactivará al empleado ${empleado.email}. '
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        // Desactivar el empleado (no borramos realmente)
        await _supabase
            .from('perfiles')
            .update({
              'activo': false,
              'negocio_id': null, // Desvinculamos del negocio
            })
            .eq('id', empleado.id);

        _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Empleado eliminado'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // Header con barra de uso
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.85),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mis Empleados',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_empleados.length} empleados registrados',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Widget de uso del plan
                  if (_limites != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: PlanUsageWidget(
                          limites: _limites!,
                          onUpgrade: () {
                            // TODO: Navegar a pantalla de planes
                          },
                        ),
                      ),
                    ),

                  // Lista de empleados
                  if (_empleados.isEmpty)
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
                              'No tienes empleados',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Toca el botón + para agregar uno',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildEmpleadoCard(_empleados[index]),
                          childCount: _empleados.length,
                        ),
                      ),
                    ),

                  // Espacio al final
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearEmpleado,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Empleado'),
      ),
    );
  }

  Widget _buildEmpleadoCard(UserProfileModel empleado) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            empleado.email.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          empleado.nombreNegocio ?? empleado.email,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(empleado.email),
            if (empleado.telefono != null)
              Text(
                empleado.telefono!,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'editar':
                _mostrarFormularioEmpleado(empleado);
                break;
              case 'eliminar':
                _eliminarEmpleado(empleado);
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
                  Icon(Icons.delete, size: 20, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
