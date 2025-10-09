import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_dimensions.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../utils/extensions.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final List<String> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.veryLightBlue,
      appBar: AppBar(
        title: const Text('Búsqueda'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            children: [
              // Campo de búsqueda
              CustomTextField(
                label: 'Buscar',
                controller: _searchController,
                hint: 'Ingrese su búsqueda...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue),
                onChanged: (value) {
                  // Implementar búsqueda en tiempo real
                },
              ),
              const SizedBox(height: AppDimensions.spacingL),
              // Botón de búsqueda
              CustomButton(
                text: 'Buscar',
                onPressed: _handleSearch,
                icon: Icons.search,
              ),
              const SizedBox(height: AppDimensions.spacingL),
              // Resultados
              Expanded(
                child: _searchResults.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay resultados de búsqueda',
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeL,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          return CustomCard(
                            margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
                            child: ListTile(
                              title: Text(_searchResults[index]),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                // Navegar a detalles del resultado
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      context.showErrorSnackBar('Por favor, ingrese un término de búsqueda');
      return;
    }

    // Simular búsqueda
    setState(() {
      _searchResults.clear();
      // Aquí implementarías la lógica real de búsqueda
      _searchResults.addAll([
        'Resultado 1 para "$query"',
        'Resultado 2 para "$query"',
        'Resultado 3 para "$query"',
      ]);
    });

    context.showSuccessSnackBar('Búsqueda completada');
  }
}









