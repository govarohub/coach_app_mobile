class CoachPublicIdentity {
  const CoachPublicIdentity({
    required this.name,
    this.photoUrl,
  });

  /// Nombre público del Coach.
  final String name;

  /// URL pública de la fotografía del Coach.
  ///
  /// Es opcional porque el Coach puede no tener fotografía configurada.
  final String? photoUrl;
}