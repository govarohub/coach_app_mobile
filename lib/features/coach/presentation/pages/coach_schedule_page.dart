import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reservation/domain/services/reservation_business_rules.dart';
import '../../domain/entities/coach_schedule.dart';
import 'coach_schedule_provider.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo:
/// lib/features/coach/presentation/pages/coach_schedule_page.dart
///
/// CK-015
///
/// SUB-CK:
/// - CK-015.5: Pantalla de disponibilidad.
/// - CK-015.6: Crear horario.
/// - CK-015.7: Editar horario.
/// - CK-015.8: Bloquear / desbloquear.
/// - CK-015.9: Loading / error / vacío.
///
/// IMPORTANTE:
/// - La UI no accede directamente a Firebase.
/// - Se reutiliza CoachScheduleController.
/// - Se reutiliza el repository existente.
/// - Se reutiliza el DataSource existente.
/// - No se crean providers adicionales.
/// ---------------------------------------------------------------------------

class CoachSchedulePage extends ConsumerWidget {
  const CoachSchedulePage({
    super.key,
    required this.coachId,
  });

  /// Identificador del Coach propietario de los horarios.
  final String coachId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// -----------------------------------------------------------------------
    /// Consulta los horarios mediante el provider existente.
    ///
    /// AsyncValue permite manejar de forma independiente:
    /// - loading
    /// - error
    /// - data
    /// -----------------------------------------------------------------------
    final schedulesAsync = ref.watch(
      coachSchedulesProvider(coachId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi disponibilidad'),
      ),

      /// ---------------------------------------------------------------------
      /// CK-015.6
      ///
      /// Permite crear un nuevo horario.
      /// ---------------------------------------------------------------------
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showScheduleForm(
            context,
            schedule: null,
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo horario'),
      ),

      body: schedulesAsync.when(
        /// -------------------------------------------------------------------
        /// CK-015.9
        ///
        /// ESTADO DE CARGA
        /// -------------------------------------------------------------------
        loading: () {
          return const _ScheduleLoadingState();
        },

        /// -------------------------------------------------------------------
        /// CK-015.9
        ///
        /// ESTADO DE ERROR
        /// -------------------------------------------------------------------
        error: (error, stackTrace) {
          return _ScheduleErrorState(
            onRetry: () {
              /// Vuelve a ejecutar únicamente la consulta de horarios.
              ref.invalidate(
                coachSchedulesProvider(coachId),
              );
            },
          );
        },

        /// -------------------------------------------------------------------
        /// ESTADO DE DATOS
        /// -------------------------------------------------------------------
        data: (schedules) {
          final sortedSchedules = [...schedules]
            ..sort((a, b) {
              final dateCompare = a.date.compareTo(b.date);
              if (dateCompare != 0) {
                return dateCompare;
              }

              return _timeToMinutes(a.startTime)
                  .compareTo(_timeToMinutes(b.startTime));
            });

          /// ---------------------------------------------------------------
          /// CK-015.9
          ///
          /// Cuando la consulta es correcta pero no existen horarios,
          /// se presenta el estado vacío.
          /// ---------------------------------------------------------------
          if (sortedSchedules.isEmpty) {
            return const _ScheduleEmptyState();
          }

          /// ---------------------------------------------------------------
          /// Lista con actualización mediante gesto.
          /// ---------------------------------------------------------------
          return RefreshIndicator(
            onRefresh: () async {
              /// Vuelve a ejecutar la consulta existente.
              ref.invalidate(
                coachSchedulesProvider(coachId),
              );

              /// Esperamos a que termine la nueva consulta.
              await ref.read(
                coachSchedulesProvider(coachId).future,
              );
            },
            child: _ScheduleList(
              schedules: sortedSchedules,

              /// CK-015.7
              onEdit: (schedule) {
                _showScheduleForm(
                  context,
                  schedule: schedule,
                );
              },

              /// CK-015.8
              onToggleBlock: (schedule) {
                _confirmToggleBlock(
                  context,
                  ref,
                  schedule,
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// Convierte HH:mm a minutos para ordenar por hora.
  /// -------------------------------------------------------------------------
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts.first) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    return hour * 60 + minute;
  }

  /// -------------------------------------------------------------------------
  /// CK-015.6 / CK-015.7
  ///
  /// Abre el formulario reutilizable para:
  ///
  /// schedule == null
  ///     Crear horario.
  ///
  /// schedule != null
  ///     Editar horario.
  /// -------------------------------------------------------------------------
  Future<void> _showScheduleForm(
      BuildContext context, {
        required CoachSchedule? schedule,
      }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _ScheduleForm(
          coachId: coachId,
          schedule: schedule,
        );
      },
    );
  }

  /// -------------------------------------------------------------------------
  /// CK-015.8
  ///
  /// Confirma y ejecuta el bloqueo o desbloqueo.
  ///
  /// available -> blocked
  /// blocked   -> available
  ///
  /// reserved no se modifica mediante esta operación.
  /// -------------------------------------------------------------------------
  Future<void> _confirmToggleBlock(
      BuildContext context,
      WidgetRef ref,
      CoachSchedule schedule,
      ) async {
    final isBlocked = schedule.status == 'blocked';

    final newStatus = isBlocked
        ? 'available'
        : 'blocked';

    final actionLabel = isBlocked
        ? 'desbloquear'
        : 'bloquear';

    /// -----------------------------------------------------------------------
    /// Confirmación antes de cambiar el estado.
    /// -----------------------------------------------------------------------
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isBlocked
                ? 'Desbloquear horario'
                : 'Bloquear horario',
          ),
          content: Text(
            '¿Deseas $actionLabel este horario?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(
                isBlocked
                    ? 'Desbloquear'
                    : 'Bloquear',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      /// ---------------------------------------------------------------------
      /// Utilizamos el Controller existente.
      /// ---------------------------------------------------------------------
      await ref
          .read(coachScheduleControllerProvider.notifier)
          .updateScheduleStatus(
        coachId: coachId,
        scheduleId: schedule.scheduleId,
        status: newStatus,
      );

      if (!context.mounted) {
        return;
      }

      final controllerState = ref.read(
        coachScheduleControllerProvider,
      );

      if (controllerState.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No fue posible $actionLabel el horario.',
            ),
          ),
        );

        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBlocked
                ? 'Horario desbloqueado correctamente.'
                : 'Horario bloqueado correctamente.',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fue posible $actionLabel el horario.',
          ),
        ),
      );
    }
  }
}

/// ---------------------------------------------------------------------------
/// CK-015.9
///
/// Estado de carga.
///
/// Se utiliza durante la consulta inicial de disponibilidad.
/// ---------------------------------------------------------------------------

class _ScheduleLoadingState extends StatelessWidget {
  const _ScheduleLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Formulario para crear y editar horarios.
/// ---------------------------------------------------------------------------

class _ScheduleForm extends ConsumerStatefulWidget {
  const _ScheduleForm({
    required this.coachId,
    required this.schedule,
  });

  final String coachId;

  /// null = crear.
  /// objeto = editar.
  final CoachSchedule? schedule;

  @override
  ConsumerState<_ScheduleForm> createState() =>
      _ScheduleFormState();
}

class _ScheduleFormState extends ConsumerState<_ScheduleForm> {
  /// Fecha seleccionada.
  late DateTime _selectedDate;

  /// Hora inicial.
  late TimeOfDay _startTime;

  /// Hora final.
  late TimeOfDay _endTime;

  /// Evita múltiples operaciones simultáneas.
  bool _saving = false;

  /// Indica si el formulario corresponde a edición.
  bool get _isEditing => widget.schedule != null;

  @override
  void initState() {
    super.initState();

    final schedule = widget.schedule;

    if (schedule == null) {
      /// ---------------------------------------------------------------
      /// Valores iniciales para creación.
      /// ---------------------------------------------------------------
      _selectedDate = DateTime.now();
      _startTime = TimeOfDay.now();
      _endTime = _addHour(_startTime);

      return;
    }

    /// ---------------------------------------------------------------
    /// Valores existentes para edición.
    /// ---------------------------------------------------------------
    _selectedDate = schedule.date;
    _startTime = _parseTime(schedule.startTime);
    _endTime = _parseTime(schedule.endTime);
  }

  /// -------------------------------------------------------------------------
  /// Seleccionar fecha.
  /// -------------------------------------------------------------------------
  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(
        DateTime.now().year - 1,
      ),
      lastDate: DateTime(
        DateTime.now().year + 5,
      ),
    );

    if (!mounted || selectedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = selectedDate;
    });
  }

  /// -------------------------------------------------------------------------
  /// Seleccionar hora inicial.
  /// -------------------------------------------------------------------------
  Future<void> _selectStartTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (!mounted || selectedTime == null) {
      return;
    }

    setState(() {
      _startTime = selectedTime;
    });
  }

  /// -------------------------------------------------------------------------
  /// Seleccionar hora final.
  /// -------------------------------------------------------------------------
  Future<void> _selectEndTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );

    if (!mounted || selectedTime == null) {
      return;
    }

    setState(() {
      _endTime = selectedTime;
    });
  }

  /// -------------------------------------------------------------------------
  /// CK-015.6 / CK-015.7
  ///
  /// Guarda el horario mediante el Controller existente.
  /// -------------------------------------------------------------------------
  Future<void> _saveSchedule() async {
    final startMinutes =
        _startTime.hour * 60 + _startTime.minute;

    final endMinutes =
        _endTime.hour * 60 + _endTime.minute;

    /// La hora final debe ser posterior a la inicial.
    if (endMinutes <= startMinutes) {
      _showMessage(
        'La hora de finalización debe ser posterior a la hora de inicio.',
      );
      return;
    }

    if (_saving) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final controller = ref.read(
        coachScheduleControllerProvider.notifier,
      );

      if (_isEditing) {
        /// ---------------------------------------------------------------
        /// CK-015.7
        ///
        /// Actualiza fecha y horas.
        /// Conserva el estado actual.
        /// ---------------------------------------------------------------
        final schedule = widget.schedule!;

        await controller.updateSchedule(
          coachId: widget.coachId,
          scheduleId: schedule.scheduleId,
          date: _selectedDate,
          startTime: _formatTime(_startTime),
          endTime: _formatTime(_endTime),
          status: schedule.status,
        );
      } else {
        /// ---------------------------------------------------------------
        /// CK-015.6
        ///
        /// Todo horario nuevo comienza como available.
        /// ---------------------------------------------------------------
        await controller.createSchedule(
          coachId: widget.coachId,
          date: _selectedDate,
          startTime: _formatTime(_startTime),
          endTime: _formatTime(_endTime),
          status: 'available',
        );
      }

      if (!mounted) {
        return;
      }

      final controllerState = ref.read(
        coachScheduleControllerProvider,
      );

      if (controllerState.hasError) {
        _showMessage(
          _isEditing
              ? 'No fue posible actualizar el horario.'
              : 'No fue posible crear el horario.',
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Horario actualizado correctamente.'
                : 'Horario creado correctamente.',
          ),
        ),
      );

      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  /// -------------------------------------------------------------------------
  /// Convierte TimeOfDay al formato 12 horas con AM/PM.
  /// -------------------------------------------------------------------------
  String _formatTime(TimeOfDay time) {
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    final displayHour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');

    return '$displayHour:$minute $suffix';
  }

  /// -------------------------------------------------------------------------
  /// Convierte HH:mm a TimeOfDay.
  /// -------------------------------------------------------------------------
  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');

    if (parts.length != 2) {
      return TimeOfDay.now();
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return TimeOfDay.now();
    }

    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  }

  /// -------------------------------------------------------------------------
  /// Obtiene una hora una hora después.
  /// -------------------------------------------------------------------------
  TimeOfDay _addHour(TimeOfDay time) {
    final totalMinutes =
        time.hour * 60 + time.minute + 60;

    final normalizedMinutes =
        totalMinutes % (24 * 60);

    return TimeOfDay(
      hour: normalizedMinutes ~/ 60,
      minute: normalizedMinutes % 60,
    );
  }

  /// -------------------------------------------------------------------------
  /// Mensaje funcional.
  /// -------------------------------------------------------------------------
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottomInset + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// Título.
            Text(
              _isEditing
                  ? 'Editar horario'
                  : 'Nuevo horario',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 20),

            /// Fecha.
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.calendar_today_outlined,
              ),
              title: const Text('Fecha'),
              subtitle: Text(
                _formatDate(_selectedDate),
              ),
              onTap: _saving ? null : _selectDate,
            ),

            const Divider(),

            /// Hora inicial.
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.schedule_outlined,
              ),
              title: const Text('Hora de inicio'),
              subtitle: Text(
                _formatTime(_startTime),
              ),
              onTap: _saving ? null : _selectStartTime,
            ),

            const Divider(),

            /// Hora final.
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.access_time_outlined,
              ),
              title: const Text('Hora de finalización'),
              subtitle: Text(
                _formatTime(_endTime),
              ),
              onTap: _saving ? null : _selectEndTime,
            ),

            const SizedBox(height: 16),

            /// Estado actual.
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _statusIcon(
                  widget.schedule?.status ?? 'available',
                ),
              ),
              title: const Text('Estado'),
              subtitle: Text(
                _statusLabel(
                  widget.schedule?.status ?? 'available',
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// Guardar.
            FilledButton.icon(
              onPressed: _saving ? null : _saveSchedule,
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
                    : _isEditing
                    ? 'Guardar cambios'
                    : 'Crear horario',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formatea fecha.
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  /// Icono del estado.
  IconData _statusIcon(String status) {
    switch (status) {
      case 'available':
        return Icons.check_circle_outline;

      case 'reserved':
        return Icons.event_available_outlined;

      case 'blocked':
        return Icons.block_outlined;

      default:
        return Icons.help_outline;
    }
  }

  /// Texto del estado.
  String _statusLabel(String status) {
    switch (status) {
      case 'available':
        return 'Disponible';

      case 'reserved':
        return 'Reservado';

      case 'blocked':
        return 'Bloqueado';

      default:
        return 'Estado desconocido';
    }
  }
}

/// ---------------------------------------------------------------------------
/// Lista de horarios.
/// ---------------------------------------------------------------------------

class _ScheduleList extends StatelessWidget {
  const _ScheduleList({
    required this.schedules,
    required this.onEdit,
    required this.onToggleBlock,
  });

  final List<CoachSchedule> schedules;

  /// Acción para editar.
  final ValueChanged<CoachSchedule> onEdit;

  /// Acción para bloquear/desbloquear.
  final ValueChanged<CoachSchedule> onToggleBlock;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      separatorBuilder: (context, index) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (context, index) {
        final schedule = schedules[index];

        return _ScheduleCard(
          schedule: schedule,

          /// CK-015.7
          onEdit: () {
            onEdit(schedule);
          },

          /// CK-015.8
          onToggleBlock: () {
            onToggleBlock(schedule);
          },
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// Tarjeta individual.
/// ---------------------------------------------------------------------------

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.schedule,
    required this.onEdit,
    required this.onToggleBlock,
  });

  final CoachSchedule schedule;

  /// Acción de edición.
  final VoidCallback onEdit;

  /// Acción de bloqueo/desbloqueo.
  final VoidCallback onToggleBlock;

  @override
  Widget build(BuildContext context) {
    final status = _ScheduleStatusPresentation.from(
      schedule.status,
    );

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),

        /// Estado.
        leading: CircleAvatar(
          child: Icon(status.icon),
        ),

        /// Fecha.
        title: Text(
          _formatDate(schedule.date),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),

        /// Horario.
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            ReservationBusinessRules.formatTimeRange(
              schedule.startTime,
              schedule.endTime,
            ),
          ),
        ),

        /// Acciones.
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusLabel(
              label: status.label,
              icon: status.icon,
            ),

            const SizedBox(width: 8),

            /// CK-015.7
            IconButton(
              tooltip: 'Editar horario',
              onPressed: onEdit,
              icon: const Icon(
                Icons.edit_outlined,
              ),
            ),

            /// CK-015.8
            ///
            /// Los horarios reservados no pueden bloquearse
            /// mediante esta acción.
            if (schedule.status != 'reserved')
              IconButton(
                tooltip: schedule.status == 'blocked'
                    ? 'Desbloquear horario'
                    : 'Bloquear horario',
                onPressed: onToggleBlock,
                icon: Icon(
                  schedule.status == 'blocked'
                      ? Icons.lock_open_outlined
                      : Icons.block_outlined,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Formatea fecha.
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}

/// ---------------------------------------------------------------------------
/// Representación visual de los estados oficiales.
/// ---------------------------------------------------------------------------

class _ScheduleStatusPresentation {
  const _ScheduleStatusPresentation({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  factory _ScheduleStatusPresentation.from(String status) {
    switch (status) {
      case 'available':
        return const _ScheduleStatusPresentation(
          label: 'Disponible',
          icon: Icons.check_circle_outline,
        );

      case 'reserved':
        return const _ScheduleStatusPresentation(
          label: 'Reservado',
          icon: Icons.event_available_outlined,
        );

      case 'blocked':
        return const _ScheduleStatusPresentation(
          label: 'Bloqueado',
          icon: Icons.block_outlined,
        );

      default:
        return const _ScheduleStatusPresentation(
          label: 'Estado desconocido',
          icon: Icons.help_outline,
        );
    }
  }
}

/// ---------------------------------------------------------------------------
/// Etiqueta visual del estado.
/// ---------------------------------------------------------------------------

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// CK-015.9
///
/// Estado vacío.
///
/// Se presenta cuando Firestore responde correctamente pero el Coach
/// todavía no tiene horarios registrados.
/// ---------------------------------------------------------------------------

class _ScheduleEmptyState extends StatelessWidget {
  const _ScheduleEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 56,
            ),

            const SizedBox(height: 16),

            Text(
              'No tienes horarios registrados.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 8),

            Text(
              'Aquí aparecerá tu disponibilidad cuando agregues horarios.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 20),

            /// El botón principal de creación ya está disponible
            /// mediante el FloatingActionButton de la pantalla.
            Text(
              'Utiliza "Nuevo horario" para agregar tu disponibilidad.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// CK-015.9
///
/// Estado de error.
///
/// No muestra la excepción técnica al usuario.
/// Permite ejecutar nuevamente la consulta.
/// ---------------------------------------------------------------------------

class _ScheduleErrorState extends StatelessWidget {
  const _ScheduleErrorState({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
            ),

            const SizedBox(height: 16),

            Text(
              'No fue posible cargar la disponibilidad.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 8),

            Text(
              'Verifica tu conexión a Internet e inténtalo nuevamente.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Reintentar',
              ),
            ),
          ],
        ),
      ),
    );
  }
}