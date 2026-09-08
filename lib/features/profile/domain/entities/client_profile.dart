class ClientProfile {
  const ClientProfile({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    this.photoUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// UID proveniente de Firebase Authentication.
  final String uid;

  /// Correo electrónico asociado a la cuenta.
  final String email;

  /// Nombre completo del cliente.
  final String name;

  /// Teléfono del cliente.
  ///
  /// Es opcional porque el usuario puede no haberlo registrado.
  final String? phone;

  /// Rol del usuario dentro de la aplicación.
  final String role;

  /// URL de la fotografía de perfil.
  ///
  /// Es opcional porque el cliente puede no tener fotografía.
  final String? photoUrl;

  /// Estado actual de la cuenta.
  final String status;

  /// Fecha de creación del perfil.
  final DateTime createdAt;

  /// Fecha de última actualización del perfil.
  final DateTime updatedAt;

  /// Crea una copia del perfil conservando los valores
  /// que no sean modificados.
  ClientProfile copyWith({
    String? name,
    String? phone,
    String? photoUrl,
    String? status,
    DateTime? updatedAt,
  }) {
    return ClientProfile(
      uid: uid,
      email: email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}