import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/matches_controller.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: matchesAsync.when(
        data: (matches) {
          if (matches.isEmpty) {
            return const Center(child: Text('Aún no tienes matches.'));
          }

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final property = matches[index];

              return ListTile(
                title: Text(property.title),
                subtitle: Text('${property.price} ${property.currency}'),
              );
            },
          );
        },
        error: (error, stack) => Center(child: Text('Error: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
