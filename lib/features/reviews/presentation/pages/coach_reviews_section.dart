import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/review.dart';
import '../review_providers.dart';

class CoachReviewsSection extends ConsumerWidget {
  const CoachReviewsSection({super.key, required this.coachId});

  final String coachId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(coachReviewsProvider(coachId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Reseñas', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        reviewsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stackTrace) => _ReviewsErrorState(
            onRetry: () => ref.invalidate(coachReviewsProvider(coachId)),
          ),
          data: (reviews) {
            if (reviews.isEmpty) {
              return const Text('Aún no hay reseñas.');
            }

            return Column(
              children: reviews
                  .map((review) => _PublicReviewCard(review: review))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _PublicReviewCard extends StatelessWidget {
  const _PublicReviewCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final comment = review.comment?.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, size: 20),
                const SizedBox(width: 6),
                Text('${review.rating}/5'),
                const Spacer(),
                Text(
                  _formatDate(review.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (comment != null && comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(comment),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _ReviewsErrorState extends StatelessWidget {
  const _ReviewsErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Text('No fue posible cargar las reseñas.')),
        IconButton(
          tooltip: 'Reintentar',
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}
