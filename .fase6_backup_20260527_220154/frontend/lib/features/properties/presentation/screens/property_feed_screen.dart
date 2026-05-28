import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../providers/property_provider.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../swipes/presentation/providers/swipe_controller.dart';
import '../widgets/property_card.dart';

class PropertyFeedScreen extends ConsumerWidget {
  const PropertyFeedScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(signOutUseCaseProvider).call();

    ref.invalidate(propertiesProvider);

    if (!context.mounted) return;
    context.go(RouteNames.login);
  }

  Future<void> _sendSwipe(
    WidgetRef ref, {
    required String propertyId,
    required String action,
  }) async {
    final useCase = ref.read(sendSwipeUseCaseProvider);

    try {
      await useCase(propertyId: propertyId, action: action);
    } catch (error) {
      debugPrint('Error enviando swipe: $error');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rent App',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard, color: Colors.green),
            tooltip: 'Panel / Matches / Propietario',
            onPressed: () => context.push(RouteNames.ownerDashboard),
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.blue),
            tooltip: 'Cambiar filtros',
            onPressed: () => context.go(RouteNames.onboarding),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            tooltip: 'Cerrar sesión',
            onPressed: () => _signOut(context, ref),
          ),
        ],
      ),
      body: propertiesAsync.when(
        data: (properties) {
          if (properties.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '¡Viste todas las opciones!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No quedan más propiedades con esos filtros.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () => context.go(RouteNames.onboarding),
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Cambiar filtros'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: AppinioSwiper(
                cardCount: properties.length,
                onSwipeEnd: (
                  int previousIndex,
                  int targetIndex,
                  SwiperActivity activity,
                ) {
                  if (activity is! Swipe) return;
                  if (previousIndex < 0 || previousIndex >= properties.length) {
                    return;
                  }

                  final propertyId = properties[previousIndex].id;

                  if (activity.direction == AxisDirection.right) {
                    _sendSwipe(
                      ref,
                      propertyId: propertyId,
                      action: 'like',
                    );
                  } else if (activity.direction == AxisDirection.left) {
                    _sendSwipe(
                      ref,
                      propertyId: propertyId,
                      action: 'nope',
                    );
                  }
                },
                cardBuilder: (BuildContext context, int index) {
                  final property = properties[index];

                  return PropertyCard(
                    property: property,
                    onTap: () {
                      context.pushNamed(
                        RouteNames.propertyDetailName,
                        pathParameters: {'id': property.id},
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
        error: (err, stack) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error: $err',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
