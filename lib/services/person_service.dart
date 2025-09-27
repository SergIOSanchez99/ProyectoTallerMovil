import '../model/person.dart';
import '../model/api_response.dart';

class PersonService {
  // Simulamos una base de datos de personas
  static final List<Person> _persons = [
    Person(
      id: '1',
      name: 'Pedro',
      lastName: 'Lopez',
      email: 'pedro.lopez@email.com',
      phone: '+1234567890',
    ),
    Person(
      id: '2',
      name: 'Pedro',
      lastName: 'Garcia',
      email: 'pedro.garcia@email.com',
      phone: '+1234567891',
    ),
    Person(
      id: '3',
      name: 'Pedro',
      lastName: 'Martinez',
      email: 'pedro.martinez@email.com',
      phone: '+1234567892',
    ),
    Person(
      id: '4',
      name: 'Pedro',
      lastName: 'Perez',
      email: 'pedro.perez@email.com',
      phone: '+1234567893',
    ),
    Person(
      id: '5',
      name: 'Pedro',
      lastName: 'Ortiz',
      email: 'pedro.ortiz@email.com',
      phone: '+1234567894',
    ),
    Person(
      id: '6',
      name: 'Juan',
      lastName: 'Gonzalez',
      email: 'juan.gonzalez@email.com',
      phone: '+1234567895',
    ),
    Person(
      id: '7',
      name: 'María',
      lastName: 'Rodriguez',
      email: 'maria.rodriguez@email.com',
      phone: '+1234567896',
    ),
    Person(
      id: '8',
      name: 'Carlos',
      lastName: 'Hernandez',
      email: 'carlos.hernandez@email.com',
      phone: '+1234567897',
    ),
  ];

  /// Busca personas por nombre
  Future<ApiResponse<List<Person>>> searchPersons(String query) async {
    try {
      // Simulamos un delay de red
      await Future.delayed(const Duration(milliseconds: 800));

      if (query.isEmpty) {
        return ApiResponse.success([]);
      }

      final filteredPersons = _persons.where((person) {
        final fullName = person.fullName.toLowerCase();
        final queryLower = query.toLowerCase();
        return fullName.contains(queryLower);
      }).toList();

      return ApiResponse.success(filteredPersons);
    } catch (e) {
      return ApiResponse.error('Error al buscar personas: $e');
    }
  }

  /// Obtiene todas las personas
  Future<ApiResponse<List<Person>>> getAllPersons() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return ApiResponse.success(_persons);
    } catch (e) {
      return ApiResponse.error('Error al obtener personas: $e');
    }
  }

  /// Obtiene una persona por ID
  Future<ApiResponse<Person>> getPersonById(String id) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final person = _persons.firstWhere(
        (person) => person.id == id,
        orElse: () => throw Exception('Persona no encontrada'),
      );

      return ApiResponse.success(person);
    } catch (e) {
      return ApiResponse.error('Error al obtener persona: $e');
    }
  }

  /// Agrega una nueva persona
  Future<ApiResponse<Person>> addPerson(Person person) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      // Generar nuevo ID
      final newId = (_persons.length + 1).toString();
      final newPerson = Person(
        id: newId,
        name: person.name,
        lastName: person.lastName,
        email: person.email,
        phone: person.phone,
        avatar: person.avatar,
      );

      _persons.add(newPerson);
      return ApiResponse.success(newPerson, message: 'Persona agregada exitosamente');
    } catch (e) {
      return ApiResponse.error('Error al agregar persona: $e');
    }
  }
}
