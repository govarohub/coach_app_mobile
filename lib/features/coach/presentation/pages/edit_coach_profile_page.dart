import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../authentication/presentation/providers/auth_state_provider.dart';
import '../../domain/entities/coach_profile.dart';
import 'coach_profile_provider.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo: edit_coach_profile_page.dart
///
/// CK-010.11
///
/// Formulario para editar la información profesional del Coach.
/// ---------------------------------------------------------------------------

class EditCoachProfilePage extends ConsumerStatefulWidget {
  const EditCoachProfilePage({
    super.key,
  });

  @override
  ConsumerState<EditCoachProfilePage> createState() =>
      _EditCoachProfilePageState();
}

class _EditCoachProfilePageState
    extends ConsumerState<EditCoachProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de los campos del formulario.
  final _specialtiesController = TextEditingController();
  final _experienceController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _bioController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  bool _available = false;
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _specialtiesController.dispose();
    _experienceController.dispose();
    _hourlyRateController.dispose();
    _bioController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();

    super.dispose();
  }

  /// Inicializa el formulario con la información actual del Coach.
  void _initializeForm(CoachProfile profile) {
    if (_initialized) {
      return;
    }

    _specialtiesController.text = profile.specialties.join(', ');

    _experienceController.text =
        profile.experienceYears.toString();

    _hourlyRateController.text =
        profile.hourlyRate.toStringAsFixed(2);

    _bioController.text = profile.bio ?? '';

    _available = profile.available;

    if (profile.location != null) {
      _latitudeController.text =
          profile.location!.latitude.toString();

      _longitudeController.text =
          profile.location!.longitude.toString();
    }

    _initialized = true;
  }

  /// Guarda la información profesional del Coach.
  Future<void> _save(String coachId) async {
    // Valida primero todos los campos del formulario.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Convierte el texto de especialidades en una lista.
    final specialties = _specialtiesController.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    // Convierte los años de experiencia a entero.
    final experienceYears = int.tryParse(
      _experienceController.text.trim(),
    );

    // Convierte la tarifa por hora a decimal.
    final hourlyRate = double.tryParse(
      _hourlyRateController.text
          .trim()
          .replaceAll(',', '.'),
    );

    // Obtiene los valores de ubicación.
    final latitudeText = _latitudeController.text.trim();
    final longitudeText = _longitudeController.text.trim();

    final latitude = latitudeText.isEmpty
        ? null
        : double.tryParse(
      latitudeText.replaceAll(',', '.'),
    );

    final longitude = longitudeText.isEmpty
        ? null
        : double.tryParse(
      longitudeText.replaceAll(',', '.'),
    );

    // Estas validaciones adicionales protegen el proceso de guardado.
    if (experienceYears == null || hourlyRate == null) {
      return;
    }

    if ((latitudeText.isNotEmpty && latitude == null) ||
        (longitudeText.isNotEmpty && longitude == null)) {
      _showMessage(
        'La latitud y longitud deben ser números válidos.',
      );
      return;
    }

    // La ubicación debe enviarse completa o permanecer vacía.
    if ((latitude == null) != (longitude == null)) {
      _showMessage(
        'Ingresa latitud y longitud juntas o deja ambas vacías.',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      // Obtiene el controller del Provider.
      //
      // El controller NO es un Family, por eso se utiliza
      // coachProfileControllerProvider.notifier.
      await ref
          .read(coachProfileControllerProvider.notifier)
          .updateProfile(
        coachId: coachId,
        specialties: specialties,
        experienceYears: experienceYears,
        hourlyRate: hourlyRate,
        bio: _bioController.text,
        location: latitude != null && longitude != null
            ? CoachLocation(
          latitude: latitude,
          longitude: longitude,
        )
            : null,
        available: _available,
      );

      // Recarga el perfil para mostrar inmediatamente
      // la información actualizada.
      ref.invalidate(
        coachProfileProvider(coachId),
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Perfil profesional actualizado correctamente.',
      );

      // Regresa a la pantalla anterior mediante GoRouter.
      context.pop(true);
    } catch (error) {
      // Maneja cualquier error producido durante la actualización.
      if (!mounted) {
        return;
      }

      _showMessage(
        'No fue posible actualizar el perfil: $error',
      );
    } finally {
      // Finaliza el estado de guardado independientemente
      // de si la operación terminó correctamente o con error.
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  /// Muestra un mensaje mediante SnackBar.
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(
      authStateProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar perfil profesional',
        ),
      ),
      body: authState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No fue posible validar la sesión: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text(
                'No existe un usuario autenticado.',
              ),
            );
          }

          final coachAsync = ref.watch(
            coachProfileProvider(user.id),
          );

          return coachAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No fue posible cargar el perfil profesional: $error',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (profile) {
              _initializeForm(profile);

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    TextFormField(
                      controller: _specialtiesController,
                      enabled: !_saving,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Especialidades',
                        hintText:
                        'Ej. Coaching, Liderazgo, Desarrollo personal',
                        helperText:
                        'Separa las especialidades con comas.',
                      ),
                      validator: (value) {
                        final specialties = value
                            ?.split(',')
                            .map((item) => item.trim())
                            .where(
                              (item) => item.isNotEmpty,
                        )
                            .toList() ??
                            [];

                        if (specialties.isEmpty) {
                          return 'Ingresa al menos una especialidad.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _experienceController,
                      enabled: !_saving,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Años de experiencia',
                      ),
                      validator: (value) {
                        final years = int.tryParse(
                          value?.trim() ?? '',
                        );

                        if (years == null || years < 0) {
                          return 'Ingresa un número de años válido.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _hourlyRateController,
                      enabled: !_saving,
                      keyboardType:
                      const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Tarifa por hora',
                        prefixText: '\$ ',
                      ),
                      validator: (value) {
                        final rate = double.tryParse(
                          (value ?? '')
                              .trim()
                              .replaceAll(',', '.'),
                        );

                        if (rate == null || rate < 0) {
                          return 'Ingresa una tarifa válida.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _bioController,
                      enabled: !_saving,
                      minLines: 4,
                      maxLines: 7,
                      decoration: const InputDecoration(
                        labelText: 'Biografía profesional',
                        alignLabelWithHint: true,
                      ),
                    ),

                    const SizedBox(height: 16),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _available,
                      onChanged: _saving
                          ? null
                          : (value) {
                        setState(() {
                          _available = value;
                        });
                      },
                      title: const Text(
                        'Disponible para sesiones',
                      ),
                      subtitle: Text(
                        _available
                            ? 'Actualmente disponible'
                            : 'No disponible',
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _latitudeController,
                      enabled: !_saving,
                      keyboardType:
                      const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Latitud',
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return null;
                        }

                        final latitude = double.tryParse(
                          value.trim().replaceAll(',', '.'),
                        );

                        if (latitude == null ||
                            latitude < -90 ||
                            latitude > 90) {
                          return 'Latitud fuera de rango.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _longitudeController,
                      enabled: !_saving,
                      keyboardType:
                      const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Longitud',
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return null;
                        }

                        final longitude = double.tryParse(
                          value.trim().replaceAll(',', '.'),
                        );

                        if (longitude == null ||
                            longitude < -180 ||
                            longitude > 180) {
                          return 'Longitud fuera de rango.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    FilledButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _save(user.id),
                      icon: _saving
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(
                        Icons.save_outlined,
                      ),
                      label: Text(
                        _saving
                            ? 'Guardando...'
                            : 'Guardar cambios',
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}