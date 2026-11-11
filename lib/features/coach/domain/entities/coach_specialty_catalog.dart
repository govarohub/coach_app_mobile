import 'coach_specialty.dart';

/// Catálogo centralizado de especialidades profesionales.
abstract final class CoachSpecialtyCatalog {
  CoachSpecialtyCatalog._();

  /// Lista de especialidades disponibles, ordenadas alfabéticamente.
  static const List<CoachSpecialty> items = <CoachSpecialty>[
    CoachSpecialty(
      id: 'Acondicionamiento físico',
      name: 'Acondicionamiento físico',
    ),
    CoachSpecialty(id: 'Artes marciales', name: 'Artes marciales'),
    CoachSpecialty(id: 'Atletismo y running', name: 'Atletismo y running'),
    CoachSpecialty(id: 'Básquetbol', name: 'Básquetbol'),
    CoachSpecialty(id: 'Béisbol y sóftbol', name: 'Béisbol y sóftbol'),
    CoachSpecialty(id: 'Boxeo', name: 'Boxeo'),
    CoachSpecialty(id: 'Calistenia', name: 'Calistenia'),
    CoachSpecialty(id: 'Ciclismo', name: 'Ciclismo'),
    CoachSpecialty(id: 'CrossFit', name: 'CrossFit'),
    CoachSpecialty(
      id: 'Entrenamiento funcional',
      name: 'Entrenamiento funcional',
    ),
    CoachSpecialty(
      id: 'Entrenamiento infantil y juvenil',
      name: 'Entrenamiento infantil y juvenil',
    ),
    CoachSpecialty(
      id: 'Entrenamiento para adultos mayores',
      name: 'Entrenamiento para adultos mayores',
    ),
    CoachSpecialty(
      id: 'Entrenamiento para mujeres',
      name: 'Entrenamiento para mujeres',
    ),
    CoachSpecialty(id: 'Frontón', name: 'Frontón'),
    CoachSpecialty(id: 'Fútbol americano', name: 'Fútbol americano'),
    CoachSpecialty(id: 'Fútbol soccer', name: 'Fútbol soccer'),
    CoachSpecialty(id: 'Gimnasia artística', name: 'Gimnasia artística'),
    CoachSpecialty(id: 'Gimnasia rítmica', name: 'Gimnasia rítmica'),
    CoachSpecialty(id: 'Gimnasio', name: 'Gimnasio'),
    CoachSpecialty(id: 'Golf', name: 'Golf'),
    CoachSpecialty(id: 'Hockey', name: 'Hockey'),
    CoachSpecialty(id: 'Jiu-jitsu', name: 'Jiu-jitsu'),
    CoachSpecialty(id: 'Karate', name: 'Karate'),
    CoachSpecialty(id: 'Kickboxing', name: 'Kickboxing'),
    CoachSpecialty(id: 'Natación', name: 'Natación'),
    CoachSpecialty(id: 'Pádel', name: 'Pádel'),
    CoachSpecialty(id: 'Patinaje', name: 'Patinaje'),
    CoachSpecialty(id: 'Pilates', name: 'Pilates'),
    CoachSpecialty(
      id: 'Preparación física de alto rendimiento',
      name: 'Preparación física de alto rendimiento',
    ),
    CoachSpecialty(id: 'Spinning', name: 'Spinning'),
    CoachSpecialty(id: 'Squash', name: 'Squash'),
    CoachSpecialty(id: 'Taekwondo', name: 'Taekwondo'),
    CoachSpecialty(id: 'Tenis', name: 'Tenis'),
    CoachSpecialty(id: 'Voleibol', name: 'Voleibol'),
    CoachSpecialty(id: 'Yoga', name: 'Yoga'),
    CoachSpecialty(id: 'Zumba', name: 'Zumba'),
  ];
}
