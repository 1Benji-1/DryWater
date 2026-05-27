import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/owner_property_controller.dart';

class OwnerPropertyListScreen extends ConsumerWidget {
  const OwnerPropertyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(ownerPropertiesControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis inmuebles')),
      body: propertiesAsync.when(
        data: (properties) {
          if (properties.isEmpty) {
            return const Center(child: Text('Aún no publicaste inmuebles.'));
          }

          return ListView.builder(
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final property = properties[index];

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
