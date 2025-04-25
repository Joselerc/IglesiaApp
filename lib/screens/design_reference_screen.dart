import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_text_field.dart';
import '../widgets/common/app_section_title.dart';
import '../widgets/common/app_empty_state.dart';

/// Pantalla de referencia para mostrar todos los elementos del sistema de diseño
class DesignReferenceScreen extends StatefulWidget {
  const DesignReferenceScreen({Key? key}) : super(key: key);

  @override
  _DesignReferenceScreenState createState() => _DesignReferenceScreenState();
}

class _DesignReferenceScreenState extends State<DesignReferenceScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _switchValue = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guía de Diseño'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sección de colores
          const AppSectionTitle(
            title: 'Colores',
            padding: EdgeInsets.only(bottom: 16),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildColorBox('Primary', AppColors.primary),
              _buildColorBox('Secondary', AppColors.secondary),
              _buildColorBox('Warm Sand', AppColors.warmSand),
              _buildColorBox('Terracotta', AppColors.terracotta),
              _buildColorBox('Soft Gold', AppColors.softGold),
              _buildColorBox('Background', AppColors.background),
              _buildColorBox('Text Primary', AppColors.textPrimary),
              _buildColorBox('Text Secondary', AppColors.textSecondary),
              _buildColorBox('Muted Gray', AppColors.mutedGray),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Sección de tipografía
          const AppSectionTitle(
            title: 'Tipografía',
            padding: EdgeInsets.only(bottom: 16),
          ),
          Text('Headline 1', style: AppTextStyles.headline1),
          const SizedBox(height: 8),
          Text('Headline 2', style: AppTextStyles.headline2),
          const SizedBox(height: 8),
          Text('Headline 3', style: AppTextStyles.headline3),
          const SizedBox(height: 8),
          Text('Subtitle 1', style: AppTextStyles.subtitle1),
          const SizedBox(height: 8),
          Text('Subtitle 2', style: AppTextStyles.subtitle2),
          const SizedBox(height: 8),
          Text('Body Text 1', style: AppTextStyles.bodyText1),
          const SizedBox(height: 8),
          Text('Body Text 2', style: AppTextStyles.bodyText2),
          const SizedBox(height: 8),
          Text('Caption', style: AppTextStyles.caption),
          
          const SizedBox(height: 32),
          
          // Sección de botones
          const AppSectionTitle(
            title: 'Botones',
            padding: EdgeInsets.only(bottom: 16),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 16,
            children: [
              AppButton(
                text: 'Botón Primario',
                onPressed: () {},
              ),
              AppButton(
                text: 'Botón Secundario',
                onPressed: () {},
                isSecondary: true,
              ),
              AppButton(
                text: 'Botón Outline',
                onPressed: () {},
                isOutlined: true,
              ),
              AppButton(
                text: 'Botón con Icono',
                onPressed: () {},
                icon: Icons.add,
              ),
              AppButton(
                text: 'Botón Pequeño',
                onPressed: () {},
                isSmall: true,
              ),
              AppButton(
                text: 'Botón Deshabilitado',
                onPressed: null,
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Sección de tarjetas
          const AppSectionTitle(
            title: 'Tarjetas',
            padding: EdgeInsets.only(bottom: 16),
          ),
          Row(
            children: [
              Expanded(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tarjeta Estándar', style: AppTextStyles.subtitle1),
                      const SizedBox(height: 8),
                      Text(
                        'Esta es una tarjeta con estilo estándar.',
                        style: AppTextStyles.bodyText2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppCard(
                  useSandBackground: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tarjeta Arena', style: AppTextStyles.subtitle1),
                      const SizedBox(height: 8),
                      Text(
                        'Esta es una tarjeta con fondo arena.',
                        style: AppTextStyles.bodyText2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppCard(
                  useGoldBackground: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tarjeta Dorada', style: AppTextStyles.subtitle1),
                      const SizedBox(height: 8),
                      Text(
                        'Esta es una tarjeta con fondo dorado suave.',
                        style: AppTextStyles.bodyText2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppCard(
                  isHighlighted: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tarjeta Destacada', style: AppTextStyles.subtitle1),
                      const SizedBox(height: 8),
                      Text(
                        'Esta es una tarjeta con estilo destacado.',
                        style: AppTextStyles.bodyText2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Sección de campos de texto
          const AppSectionTitle(
            title: 'Campos de Texto',
            padding: EdgeInsets.only(bottom: 16),
          ),
          AppTextField(
            label: 'Campo de texto',
            hint: 'Escribe algo aquí',
            controller: _textController,
          ),
          const SizedBox(height: 16),
          AppPasswordField(
            label: 'Contraseña',
            hint: 'Escribe tu contraseña',
            controller: _passwordController,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Campo con error',
            hint: 'Campo con mensaje de error',
            errorText: 'Este campo tiene un error',
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Campo de búsqueda',
            hint: 'Buscar...',
            controller: _searchController,
            isSearchField: true,
            prefixIcon: Icons.search,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Campo multilinea',
            hint: 'Escribe un texto largo aquí',
            isMultiline: true,
          ),
          
          const SizedBox(height: 32),
          
          // Sección de elementos de formulario
          const AppSectionTitle(
            title: 'Elementos de Formulario',
            padding: EdgeInsets.only(bottom: 16),
          ),
          Row(
            children: [
              Checkbox(
                value: _switchValue,
                onChanged: (value) {
                  setState(() {
                    _switchValue = value ?? false;
                  });
                },
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text('Checkbox', style: AppTextStyles.bodyText1),
              const Spacer(),
              Switch(
                value: _switchValue,
                onChanged: (value) {
                  setState(() {
                    _switchValue = value;
                  });
                },
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text('Switch', style: AppTextStyles.bodyText1),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: _switchValue,
                onChanged: (value) {
                  setState(() {
                    _switchValue = value ?? false;
                  });
                },
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text('Radio seleccionado', style: AppTextStyles.bodyText1),
              const SizedBox(width: 16),
              Radio<bool>(
                value: false,
                groupValue: _switchValue,
                onChanged: (value) {
                  setState(() {
                    _switchValue = value ?? false;
                  });
                },
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text('Radio no seleccionado', style: AppTextStyles.bodyText1),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Sección de estados vacíos
          const AppSectionTitle(
            title: 'Estados Vacíos',
            padding: EdgeInsets.only(bottom: 16),
          ),
          SizedBox(
            height: 200,
            child: AppEmptyState(
              title: 'Sin elementos',
              message: 'No se encontraron elementos para mostrar.',
              icon: Icons.inbox,
              buttonText: 'Agregar Elemento',
              onButtonPressed: () {},
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: AppEmptyState.error(
              message: 'Ocurrió un error al cargar los datos.',
              buttonText: 'Reintentar',
              onButtonPressed: () {},
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildColorBox(String name, Color color) {
    final bool isDark = ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
    
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          name,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
} 