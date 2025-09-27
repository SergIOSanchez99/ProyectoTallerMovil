import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/search_viewmodel.dart';
import '../model/person.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchViewModel(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F8FF), // Fondo azul muy claro
        appBar: AppBar(
          title: const Text(
            'Buscar Personas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Barra de búsqueda
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    onChanged: (value) {
                      final viewModel = Provider.of<SearchViewModel>(context, listen: false);
                      if (value.isEmpty) {
                        viewModel.clearSearch();
                      } else {
                        viewModel.searchPersons(value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Lista de resultados
                Expanded(
                  child: Consumer<SearchViewModel>(
                    builder: (context, viewModel, child) {
                      if (viewModel.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0066CC),
                          ),
                        );
                      }

                      if (viewModel.errorMessage != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                viewModel.errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      if (!viewModel.hasResults) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.search,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                viewModel.searchQuery.isEmpty
                                    ? 'Ingrese un nombre para buscar'
                                    : 'No se encontraron resultados',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: viewModel.searchResults.length,
                        itemBuilder: (context, index) {
                          final person = viewModel.searchResults[index];
                          return _buildPersonCard(person);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonCard(Person person) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF0066CC),
          child: Text(
            person.initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(
          person.fullName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        subtitle: person.email != null
            ? Text(
                person.email!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              )
            : null,
        onTap: () => _showPersonDetails(person),
      ),
    );
  }

  void _showPersonDetails(Person person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(person.fullName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (person.email != null) ...[
              const Text('Email:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(person.email!),
              const SizedBox(height: 8),
            ],
            if (person.phone != null) ...[
              const Text('Teléfono:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(person.phone!),
              const SizedBox(height: 8),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
