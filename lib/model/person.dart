class Person {
  final String id;
  final String name;
  final String lastName;
  final String? email;
  final String? phone;
  final String? avatar;

  Person({
    required this.id,
    required this.name,
    required this.lastName,
    this.email,
    this.phone,
    this.avatar,
  });

  String get fullName => '$name $lastName';

  String get initials {
    final firstInitial = name.isNotEmpty ? name[0].toUpperCase() : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'],
      phone: json['phone'],
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'avatar': avatar,
    };
  }

  @override
  String toString() {
    return 'Person(id: $id, name: $fullName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Person && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
