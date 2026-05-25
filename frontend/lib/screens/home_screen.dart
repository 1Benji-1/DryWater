import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/owner_dashboard/presentation/dashboard_screen.dart';
import '../models/property.dart';
import '../providers/property_provider.dart';
import '../services/api_service.dart';
import 'onboarding_screen.dart';
import 'property_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await Supabase.instance.client.auth.signOut();

    ref.invalidate(propertiesProvider);
    ref.invalidate(userIdProvider);

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      (route) => false,
    );
  }

  void _openDashboard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
  }

  void _openDetail(BuildContext context, Property property) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PropertyDetailScreen(propertyId: property.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          'Rent App',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard, color: Colors.green),
            tooltip: 'Panel / Matches / Propietario',
            onPressed: () => _openDashboard(context),
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.blue),
            tooltip: 'Cambiar filtros',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const OnboardingScreen()),
              );
            },
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
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No quedan más propiedades con esos filtros.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const OnboardingScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.restart_alt, color: Colors.white),
                      label: const Text(
                        'Cambiar filtros',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
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
                  if (activity is Swipe) {
                    final propertyId = properties[previousIndex].id;
                    final api = ApiService();

                    if (activity.direction == AxisDirection.right) {
                      api.sendSwipeAction(propertyId, 'like').catchError((error) {
                        debugPrint('Error enviando like: $error');
                      });
                    } else if (activity.direction == AxisDirection.left) {
                      api.sendSwipeAction(propertyId, 'nope').catchError((error) {
                        debugPrint('Error enviando nope: $error');
                      });
                    }
                  }
                },
                cardBuilder: (BuildContext context, int index) {
                  final property = properties[index];

                  return GestureDetector(
                    onTap: () => _openDetail(context, property),
                    child: PropertyCard(property: property),
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

class PropertyCard extends StatelessWidget {
  final Property property;

  const PropertyCard({
    super.key,
    required this.property,
  });

  void _mostrarAnalisisMercado(BuildContext context) {
    final api = ApiService();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            '📊 Análisis de Mercado',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: FutureBuilder(
            future: api.evaluateMarketPrice(
              property.price,
              property.operationType,
              zone: property.zone,
              propertyType: property.propertyType,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Text('Error al calcular estadísticas: ${snapshot.error}');
              }

              final data = snapshot.data;

              if (data == null) {
                return const Text('Error al calcular las estadísticas.');
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.priceVerdict.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 30),
                  const Text(
                    'Valores comparables:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text('Muestra analizada: ${data.statistics.sampleSize} inmuebles'),
                  Text('Promedio: ${data.statistics.mean} Bs'),
                  Text('Más baratos (Q1): ${data.statistics.quartiles.q1} Bs'),
                  Text('Más caros (Q3): ${data.statistics.quartiles.q3} Bs'),
                  const SizedBox(height: 15),
                  Text(
                    'Este inmueble cuesta: ${property.price} Bs',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.network(
                property.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.home_work, size: 60, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Toca para ver detalle',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.analytics,
                          color: Colors.blueAccent,
                          size: 30,
                        ),
                        tooltip: 'Analizar precio',
                        onPressed: () => _mostrarAnalisisMercado(context),
                      ),
                    ],
                  ),
                  Text(
                    '${property.price.toStringAsFixed(0)} ${property.currency}',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${property.propertyType} · ${property.zone}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    property.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
