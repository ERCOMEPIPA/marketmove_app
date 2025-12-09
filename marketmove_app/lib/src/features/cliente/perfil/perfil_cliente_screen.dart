import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/services/auth_service.dart';

/// Pantalla de perfil del empleado
/// Permite ver información personal y gestionar cuenta
class PerfilClienteScreen extends StatefulWidget {
  const PerfilClienteScreen({super.key});

  @override
  State<PerfilClienteScreen> createState() => _PerfilClienteScreenState();
}

class _PerfilClienteScreenState extends State<PerfilClienteScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final userEmail = _authService.currentUser?.email ?? 'usuario@ejemplo.com';

    return Scaffold(
      body: RefreshIndicator(
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
                        'Mi Perfil',
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gestiona tu información',
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
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.secondary,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tarjeta de perfil
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 56,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nombre/Email
                    Text(
                      userEmail,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Empleado',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Información de cuenta
              Text(
                'Información de Cuenta',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                icon: Icons.email,
                label: 'Email',
                value: userEmail,
              ),
              _buildInfoItem(
                icon: Icons.calendar_today,
                label: 'Miembro desde',
                value: 'Diciembre 2025',
              ),
              const SizedBox(height: 24),

              // Acciones
              Text(
                'Configuración',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                icon: Icons.lock,
                label: 'Cambiar Contraseña',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cambio de contraseña en desarrollo'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                icon: Icons.notifications,
                label: 'Notificaciones',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Preferencias de notificaciones'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                icon: Icons.help,
                label: 'Ayuda y Soporte',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Centro de ayuda'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Botón de cerrar sesión
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar Sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);

    try {
      await _authService.signOut();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
