import 'package:flutter/material.dart';
import '../../theme/app_colors.dart'; // Asegúrate que la ruta a tus colores es correcta
import '../../theme/app_text_styles.dart'; // Asegúrate que la ruta a tus estilos de texto es correcta
import './family_list_screen.dart'; // <-- AÑADIR IMPORT
import './visitor_list_screen.dart'; // <-- AÑADIR IMPORT

class KidsAdminScreen extends StatefulWidget {
  const KidsAdminScreen({super.key});

  @override
  State<KidsAdminScreen> createState() => _KidsAdminScreenState();
}

class _KidsAdminScreenState extends State<KidsAdminScreen> {
  // TODO: Definir acciones para los botones de acceso rápido
  void _navigateToFamilyManagement() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const FamilyListScreen()));
  }

  void _navigateToVisitorManagement() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const VisitorListScreen()));
  }

  void _navigateToQuickCheckin() {
    print('Navegar para Check-in Rápido');
    // Navigator.push(context, MaterialPageRoute(builder: (context) => QuickCheckinScreen()));
  }

  void _navigateToMoreOptions() {
    print('Navegar para Mais Opções');
    // Navigator.push(context, MaterialPageRoute(builder: (context) => MoreKidsOptionsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administração Kids'),
        centerTitle: true,
        backgroundColor: AppColors.primary, // O el color que uses para admin
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: AppColors.background, // Color de fondo general
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. Fila de accesos rápidos
            _buildQuickAccessRow(),
            const SizedBox(height: 24),

            // 3. Sección "Asistencia" (Placeholder)
            _buildSectionTitle('Asistência', Icons.show_chart, () { print('Recarregar Asistência'); }),
            // TODO: Implementar gráfico de asistencia
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300)
              ),
              alignment: Alignment.center,
              child: Text('Gráfico de Asistência (pendente)', style: AppTextStyles.bodyText2.copyWith(color: Colors.grey)),
            ),
            const SizedBox(height: 24),

            // 4. Sección "Cumpleañeros de la semana" (Placeholder)
            _buildSectionTitle('Cumpleañeros da Semana', Icons.cake_outlined, () { print('Recarregar Cumpleañeros'); }),
            // TODO: Implementar carrusel de cumpleañeros
            Container(
              height: 120,
               decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300)
              ),
              alignment: Alignment.center,
              child: Text('Carrusel de Cumpleañeros (pendente)', style: AppTextStyles.bodyText2.copyWith(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, VoidCallback onRefresh) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textPrimary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary, size: 20),
            onPressed: onRefresh,
            tooltip: 'Recarregar',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildQuickAccessButton(Icons.family_restroom_outlined, 'Família', _navigateToFamilyManagement, Colors.orange.shade700),
        _buildQuickAccessButton(Icons.person_add_alt_1_outlined, 'Visitante', _navigateToVisitorManagement, Colors.blue.shade700),
        _buildQuickAccessButton(Icons.qr_code_scanner_outlined, 'Check-in', _navigateToQuickCheckin, Colors.green.shade700),
        _buildQuickAccessButton(Icons.more_horiz_outlined, 'Ver mais', _navigateToMoreOptions, Colors.purple.shade700),
      ],
    );
  }

  Widget _buildQuickAccessButton(IconData icon, String label, VoidCallback onTap, Color iconColor) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0), // Padding para el InkWell
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: iconColor),
            ),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,)
          ],
        ),
      ),
    );
  }
} 