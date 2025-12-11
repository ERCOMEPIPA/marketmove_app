import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/services/theme_service.dart';
import '../../shared/constants/app_colors.dart';

/// Pantalla de configuración de la aplicación
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sección de Apariencia
          _buildSectionHeader(context, 'Apariencia'),
          const SizedBox(height: 12),
          _buildThemeSelector(context, isDark),

          const SizedBox(height: 24),

          // Sección de Aplicación
          _buildSectionHeader(context, 'Aplicación'),
          const SizedBox(height: 12),
          _buildInfoTile(
            context,
            icon: Icons.info_outline,
            title: 'Versión',
            subtitle: '1.0.0',
          ),
          _buildInfoTile(
            context,
            icon: Icons.business,
            title: 'MarketMove CRM',
            subtitle: 'Gestión de clientes y ventas',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, bool isDark) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(themeService.themeModeIcon, color: AppColors.primary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Tema',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      themeService.themeModeName,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildThemeOption(
                      context,
                      themeService,
                      ThemeMode.system,
                      Icons.brightness_auto,
                      'Sistema',
                    ),
                    const SizedBox(width: 12),
                    _buildThemeOption(
                      context,
                      themeService,
                      ThemeMode.light,
                      Icons.light_mode,
                      'Claro',
                    ),
                    const SizedBox(width: 12),
                    _buildThemeOption(
                      context,
                      themeService,
                      ThemeMode.dark,
                      Icons.dark_mode,
                      'Oscuro',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeService themeService,
    ThemeMode mode,
    IconData icon,
    String label,
  ) {
    final isSelected = themeService.themeMode == mode;

    return Expanded(
      child: InkWell(
        onTap: () => themeService.setThemeMode(mode),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primary : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[600]),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
