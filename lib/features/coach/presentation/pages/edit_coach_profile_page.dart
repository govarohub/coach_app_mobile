import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';

import '../../../authentication/presentation/providers/auth_state_provider.dart';
import '../../domain/entities/coach_profile.dart';
import '../../domain/entities/coach_specialty.dart';
import '../../domain/entities/coach_specialty_catalog.dart';
import 'coach_profile_provider.dart';
import 'coach_search_provider.dart' show getCurrentUserPosition;

/// Página de edición del perfil profesional.
class EditCoachProfilePage extends ConsumerStatefulWidget {
  const EditCoachProfilePage({super.key});

  @override
  ConsumerState<EditCoachProfilePage> createState() =>
      _EditCoachProfilePageState();
}

/// Estado de la página de edición.
class _EditCoachProfilePageState
    extends ConsumerState<EditCoachProfilePage> {
  /// Clave para validar el formulario.
  final _formKey = GlobalKey<FormState>();

  /// Controlador de experiencia.
  late final TextEditingController _experienceController;

  /// Controlador de tarifa.
  late final TextEditingController _hourlyRateController;

  /// Controlador de biografía.
  late final TextEditingController _bioController;

  /// Controlador de dirección.
  late final TextEditingController _addressController;

  /// Controlador de latitud.
  late final TextEditingController _latitudeController;

  /// Controlador de longitud.
  late final TextEditingController _longitudeController;

  /// Especialidades seleccionadas actualmente.
  final List<String> _selectedSpecialties = <String>[];

  /// Indica si los datos iniciales del perfil ya fueron cargados.
  ///
  /// Es independiente de la cantidad de especialidades, porque la lista
  /// puede quedar vacía temporalmente cuando el usuario elimina una.
  bool _initialized = false;

  /// Indica si el perfil está siendo guardado.
  ///
  /// Evita ejecuciones simultáneas y permite mostrar al usuario
  /// que la operación continúa en proceso.
  bool _saving = false;

  /// Indica si se está obteniendo la ubicación actual.
  bool _loadingLocation = false;

  @override
  void initState() {
    super.initState();

    _experienceController = TextEditingController();
    _hourlyRateController = TextEditingController();
    _bioController = TextEditingController();
    _addressController = TextEditingController();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();

    // La carga inicial de los datos se realiza posteriormente desde build().
  }

  @override
  void dispose() {
    // Liberamos los controladores al cerrar la pantalla.
    _experienceController.dispose();
    _hourlyRateController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();

    super.dispose();
  }

  /// Inicializa los campos una sola vez con los datos actuales del perfil.
  void _initializeFields(CoachProfile profile) {
    if (_experienceController.text.isEmpty) {
      _experienceController.text = profile.experienceYears.toString();
    }

    if (_hourlyRateController.text.isEmpty) {
      _hourlyRateController.text = profile.hourlyRate.toString();
    }

    if (_bioController.text.isEmpty) {
      _bioController.text = profile.bio ?? '';
    }

    if (_addressController.text.isEmpty) {
      _addressController.text = profile.address ?? '';
    }

    if (_latitudeController.text.isEmpty && profile.location != null) {
      _latitudeController.text = profile.location!.latitude.toString();
    }

    if (_longitudeController.text.isEmpty && profile.location != null) {
      _longitudeController.text = profile.location!.longitude.toString();
    }

    // Las especialidades se cargan una sola vez.
    //
    // No debemos usar _selectedSpecialties.isEmpty como indicador de
    // inicialización, porque el usuario puede eliminar temporalmente todas
    // las especialidades y el siguiente rebuild las volvería a agregar.
    if (!_initialized) {
      _selectedSpecialties.addAll(profile.specialties);
      _initialized = true;
    }
  }

  /// Actualiza las coordenadas internas usando la ubicación del dispositivo.
  Future<void> _updateLocation() async {
    setState(() {
      _loadingLocation = true;
    });

    try {
      final position = await getCurrentUserPosition();

      if (!mounted) {
        return;
      }

      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
      });

      try {
        final address = await _lookupAddress(
          latitude: position.latitude,
          longitude: position.longitude,
        );

        if (!mounted) {
          return;
        }

        if (address != null) {
          setState(() {
            _addressController.text = address;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              address == null
                  ? 'Coordenadas actualizadas. No se encontró una dirección; '
                      'puedes capturarla manualmente.'
                  : 'Dirección actualizada. Guarda los cambios para aplicarla.',
            ),
          ),
        );
      } catch (_) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Coordenadas actualizadas, pero no se pudo consultar la '
              'dirección. Captúrala manualmente.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = error.toString().replaceFirst('Bad state: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
        });
      }
    }
  }

  Future<String?> _lookupAddress({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'format': 'jsonv2',
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'zoom': '18',
        'addressdetails': '1',
        'accept-language': 'es',
      },
    );

    final response = await http
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw const FormatException('No se pudo consultar la dirección.');
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      return null;
    }

    final address = payload['display_name'];
    return address is String && address.trim().isNotEmpty
        ? address.trim()
        : null;
  }

  /// Abre el selector de especialidades.
  Future<void> _selectSpecialties() async {
    // El catálogo central contiene las nuevas especialidades disponibles.
    final catalog = CoachSpecialtyCatalog.items;

    // Si el catálogo está vacío, conservamos las especialidades que ya tiene
    // este perfil como opciones administrables. Esto permite recuperar una
    // especialidad eliminada temporalmente sin inventar valores del catálogo.
    final existingSpecialties = _selectedSpecialties
        .map(
          (specialtyId) => CoachSpecialty(
        id: specialtyId,
        name: specialtyId,
      ),
    )
        .toList();

    final catalogIds = catalog
        .map((specialty) => specialty.id.trim().toLowerCase())
        .toSet();

    final availableSpecialties = <CoachSpecialty>[
      ...catalog,
      ...existingSpecialties.where(
            (specialty) =>
        !catalogIds.contains(specialty.id.trim().toLowerCase()),
      ),
    ];

    // Si no existen opciones del catálogo ni especialidades actuales,
    // informamos al usuario que todavía no hay opciones disponibles.
    if (availableSpecialties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El catálogo de especialidades todavía no contiene opciones.',
          ),
        ),
      );
      return;
    }

    // Copia temporal para permitir cancelar sin modificar la selección actual.
    final temporarySelection = <String>{
      ..._selectedSpecialties,
    };

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Seleccionar especialidades'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: availableSpecialties.map((specialty) {
                    final selected = temporarySelection.contains(
                      specialty.id,
                    );

                    return CheckboxListTile(
                      value: selected,
                      title: Text(specialty.name),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setDialogState(() {
                          if (value == true) {
                            temporarySelection.add(specialty.id);
                          } else {
                            temporarySelection.remove(specialty.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    context.pop();
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    context.pop(temporarySelection);
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );

    // Si el usuario canceló, conservamos la selección original.
    if (result == null) {
      return;
    }

    setState(() {
      _selectedSpecialties
        ..clear()
        ..addAll(result);
    });
  }

  /// Guarda la información profesional del Coach.
  Future<void> _save() async {
    // Evita iniciar otra operación mientras existe un guardado en curso.
    if (_saving) {
      return;
    }

    // Valida primero los campos del formulario.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Un Coach debe conservar al menos una especialidad para poder guardar.
    // Se permite quitar una especialidad de la selección temporal, pero no
    // completar el guardado cuando la lista queda vacía.
    if (_selectedSpecialties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes seleccionar al menos una especialidad.',
          ),
        ),
      );
      return;
    }

    final user = ref.read(authStateProvider).value;

    // Verifica que exista una sesión válida.
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No existe un usuario autenticado.',
          ),
        ),
      );
      return;
    }

    final experience = int.tryParse(
      _experienceController.text.trim(),
    );

    final hourlyRate = double.tryParse(
      _hourlyRateController.text.trim().replaceAll(',', '.'),
    );

    final latitude = double.tryParse(
      _latitudeController.text.trim().replaceAll(',', '.'),
    );

    final longitude = double.tryParse(
      _longitudeController.text.trim().replaceAll(',', '.'),
    );

    // La experiencia y tarifa son datos obligatorios.
    if (experience == null || experience < 0) {
      return;
    }

    if (hourlyRate == null || hourlyRate <= 0) {
      return;
    }

    // La ubicación es opcional.
    CoachLocation? location;

    if (latitude != null || longitude != null) {
      // Si se captura una coordenada, ambas deben existir.
      if (latitude == null || longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La latitud y longitud deben capturarse juntas.',
            ),
          ),
        );
        return;
      }

      location = CoachLocation(
        latitude: latitude,
        longitude: longitude,
      );
    }

    // Activa el estado de carga antes de comunicarse con Firestore.
    setState(() {
      _saving = true;
    });

    try {
      // Las especialidades seleccionadas continúan pasando
      // por el Controller y Repository existentes.
      await ref
          .read(coachProfileControllerProvider.notifier)
          .updateProfile(
        coachId: user.id,
        specialties: List<String>.from(_selectedSpecialties),
        experienceYears: experience,
        hourlyRate: hourlyRate,
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
        location: location,
        available: true,
      );

      if (!mounted) {
        return;
      }

      // El Controller utiliza AsyncValue.guard(), por lo que
      // cualquier error de Repository/Firestore queda reflejado
      // en su estado.
      final state = ref.read(
        coachProfileControllerProvider,
      );

      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No fue posible actualizar el perfil: ${state.error}',
            ),
          ),
        );
        return;
      }

      // Fuerza la lectura nuevamente para obtener los datos
      // realmente almacenados en Firestore.
      ref.invalidate(
        coachProfileProvider(user.id),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Perfil profesional actualizado correctamente.',
          ),
        ),
      );

      // Regresa al perfil después de guardar correctamente.
      context.pop(true);
    } catch (error) {
      // Error inesperado durante la operación de guardado.
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fue posible actualizar el perfil: $error',
          ),
        ),
      );
    } finally {
      // Libera el estado de carga independientemente del resultado.
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('No hay un usuario autenticado.'),
        ),
      );
    }

    final profileAsync = ref.watch(
      coachProfileProvider(user.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil profesional'),
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text(
            'No fue posible cargar el perfil: $error',
          ),
        ),
        data: (profile) {
          // Inicializamos los controles con los datos actuales.
          _initializeFields(profile);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                /// -------------------------------------------------------------
                /// Especialidades
                /// -------------------------------------------------------------
                const Text(
                  'Especialidades',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                OutlinedButton.icon(
                  // Evita abrir el selector mientras se está guardando.
                  onPressed: _saving ? null : _selectSpecialties,
                  icon: const Icon(Icons.category_outlined),
                  label: Text(
                    _selectedSpecialties.isEmpty
                        ? 'Seleccionar especialidades'
                        : 'Modificar especialidades',
                  ),
                ),

                if (_selectedSpecialties.isNotEmpty) ...[
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedSpecialties.map((specialtyId) {
                      // Busca el nombre visible dentro del catálogo.
                      final catalogSpecialty =
                      CoachSpecialtyCatalog.items.where(
                            (specialty) => specialty.id == specialtyId,
                      );

                      final name = catalogSpecialty.isNotEmpty
                          ? catalogSpecialty.first.name
                          : specialtyId;

                      return Chip(
                        label: Text(name),
                        onDeleted: () {
                          setState(() {
                            _selectedSpecialties.remove(specialtyId);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 24),

                /// -------------------------------------------------------------
                /// Experiencia
                /// -------------------------------------------------------------
                TextFormField(
                  controller: _experienceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Años de experiencia',
                  ),
                  validator: (value) {
                    final experience = int.tryParse(
                      value?.trim() ?? '',
                    );

                    if (experience == null || experience < 0) {
                      return 'Captura un número válido.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                /// -------------------------------------------------------------
                /// Tarifa
                /// -------------------------------------------------------------
                TextFormField(
                  controller: _hourlyRateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Tarifa por hora',
                  ),
                  validator: (value) {
                    final rate = double.tryParse(
                      value?.trim().replaceAll(',', '.') ?? '',
                    );

                    if (rate == null || rate <= 0) {
                      return 'Captura una tarifa válida.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                /// -------------------------------------------------------------
                /// Biografía
                /// -------------------------------------------------------------
                TextFormField(
                  controller: _bioController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Biografía',
                  ),
                ),

                const SizedBox(height: 16),

                /// -------------------------------------------------------------
                /// Ubicación
                /// -------------------------------------------------------------
                TextFormField(
                  controller: _addressController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    hintText: 'Dirección registrada del coach',
                  ),
                ),

                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: _saving || _loadingLocation
                      ? null
                      : _updateLocation,
                  icon: _loadingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    _loadingLocation
                        ? 'Actualizando ubicación...'
                        : 'Actualizar ubicación',
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Geocodificación © OpenStreetMap contributors',
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                const SizedBox(height: 24),

                /// -------------------------------------------------------------
                /// Guardar
                /// -------------------------------------------------------------
                FilledButton(
                  // Mientras se guarda, se bloquea el botón para evitar
                  // solicitudes duplicadas a Firestore.
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Guardar cambios'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}