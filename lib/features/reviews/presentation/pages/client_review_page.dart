import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/review_service.dart';
import '../review_providers.dart';

class ClientReviewPage extends ConsumerWidget {
  const ClientReviewPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eligibilityAsync = ref.watch(
      reviewEligibilityProvider(reservationId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Calificar sesión')),
      body: eligibilityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ReviewLoadError(
          onRetry: () =>
              ref.invalidate(reviewEligibilityProvider(reservationId)),
        ),
        data: (eligibility) =>
            _ReviewForm(reservationId: reservationId, eligibility: eligibility),
      ),
    );
  }
}

class _ReviewForm extends ConsumerStatefulWidget {
  const _ReviewForm({required this.reservationId, required this.eligibility});

  final String reservationId;
  final ReviewEligibility eligibility;

  @override
  ConsumerState<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends ConsumerState<_ReviewForm> {
  late final TextEditingController _commentController;
  late int _rating;

  @override
  void initState() {
    super.initState();
    final existingReview = widget.eligibility.existingReview;
    _rating = existingReview?.rating ?? 0;
    _commentController = TextEditingController(
      text: existingReview?.comment ?? '',
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(reviewControllerProvider);
    final isSaving = controllerState.isLoading;
    final isEditing = widget.eligibility.existingReview != null;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          isEditing ? 'Actualiza tu calificación' : '¿Cómo fue tu sesión?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Tu opinión ayuda a otros clientes a conocer al coach.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 28),
        Semantics(
          label: 'Calificación: $_rating de 5 estrellas',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final value = index + 1;
              return IconButton(
                tooltip: '$value ${value == 1 ? 'estrella' : 'estrellas'}',
                onPressed: isSaving
                    ? null
                    : () => setState(() => _rating = value),
                icon: Icon(
                  value <= _rating ? Icons.star : Icons.star_border,
                  size: 38,
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _commentController,
          enabled: !isSaving,
          minLines: 3,
          maxLines: 6,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Comentario (opcional)',
            hintText: 'Comparte tu experiencia',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        if (controllerState.hasError) ...[
          Text(
            'No fue posible guardar la reseña. Verifica tu conexión e inténtalo de nuevo.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          onPressed: isSaving ? null : _save,
          icon: isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(isEditing ? 'Guardar cambios' : 'Enviar reseña'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una calificación de 1 a 5.')),
      );
      return;
    }

    try {
      await ref
          .read(reviewControllerProvider.notifier)
          .submitReview(
            reservationId: widget.reservationId,
            rating: _rating,
            comment: _commentController.text,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu reseña se guardó correctamente.')),
      );
      Navigator.of(context).pop();
    } catch (_) {
      // El estado de error se muestra en el formulario.
    }
  }
}

class _ReviewLoadError extends StatelessWidget {
  const _ReviewLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No fue posible validar esta sesión para reseñarla.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
