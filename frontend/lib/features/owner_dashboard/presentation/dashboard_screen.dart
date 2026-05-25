import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../properties/domain/entities/property.dart';
import '../../../providers/property_provider.dart';
import '../../../screens/property_detail_screen.dart';
import '../../../services/api_service.dart';
import 'owner_property_form_screen.dart';

final profileProvider = FutureProvider<UserProfile>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchProfile();
});

final matchesProvider = FutureProvider<List<Property>>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId.isEmpty) return [];

  final api = ref.watch(apiServiceProvider);
  return api.fetchMatches();
});

final ownerPropertiesProvider = FutureProvider<List<Property>>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (!profile.isOwnerOrAdmin) return [];

  final api = ref.watch(apiServiceProvider);
  return api.fetchOwnerProperties();
});

final ownerMatchesProvider = FutureProvider<List<OwnerMatchItem>>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (!profile.isOwnerOrAdmin) return [];

  final api = ref.watch(apiServiceProvider);
  return api.fetchOwnerMatches();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _activateOwner(BuildContext context, WidgetRef ref) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.becomeOwner();

      ref.invalidate(profileProvider);
      ref.invalidate(ownerPropertiesProvider);
      ref.invalidate(ownerMatchesProvider);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rol propietario activado.')),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Future<void> _openCreateProperty(BuildContext context, WidgetRef ref) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const OwnerPropertyFormScreen(),
      ),
    );

    if (created == true) {
      ref.invalidate(ownerPropertiesProvider);
      ref.invalidate(propertiesProvider);
    }
  }

  Future<void> _changePropertyStatus(
    BuildContext context,
    WidgetRef ref,
    Property property,
    String status,
  ) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.updateOwnerPropertyStatus(property.id, status);

      ref.invalidate(ownerPropertiesProvider);
      ref.invalidate(propertiesProvider);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estado actualizado.')),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Future<void> _deleteProperty(
    BuildContext context,
    WidgetRef ref,
    Property property,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ocultar propiedad'),
          content: Text(
            '¿Seguro que quieres ocultar "${property.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ocultar'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final api = ref.read(apiServiceProvider);
      await api.deleteOwnerProperty(property.id);

      ref.invalidate(ownerPropertiesProvider);
      ref.invalidate(propertiesProvider);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propiedad ocultada.')),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Future<void> _changeMatchStatus(
    BuildContext context,
    WidgetRef ref,
    OwnerMatchItem item,
    String status,
  ) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.updateMatchStatus(item.matchId, status);

      ref.invalidate(ownerMatchesProvider);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match actualizado.')),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Widget _buildBuyerMatches(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesProvider);

    return matchesAsync.when(
      data: (matches) {
        if (matches.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Aún no tienes matches.\n¡Desliza a la derecha para guardar propiedades!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final property = matches[index];

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: _PropertyThumbnail(url: property.imageUrl),
                title: Text(
                  property.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${property.zone}\n${property.price.toStringAsFixed(0)} Bs',
                  style: const TextStyle(color: Colors.green),
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PropertyDetailScreen(
                        propertyId: property.id,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildOwnerProperties(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      data: (profile) {
        if (!profile.isOwnerOrAdmin) {
          return _ActivateOwnerView(
            onActivate: () => _activateOwner(context, ref),
          );
        }

        final ownerPropertiesAsync = ref.watch(ownerPropertiesProvider);

        return ownerPropertiesAsync.when(
          data: (properties) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openCreateProperty(context, ref),
                      icon: const Icon(Icons.add_home, color: Colors.white),
                      label: const Text(
                        'Publicar nuevo inmueble',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: properties.isEmpty
                      ? const Center(
                          child: Text(
                            'Aún no publicaste inmuebles.',
                            style: TextStyle(fontSize: 17),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: properties.length,
                          itemBuilder: (context, index) {
                            final property = properties[index];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 14),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  children: [
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: _PropertyThumbnail(
                                        url: property.imageUrl,
                                      ),
                                      title: Text(
                                        property.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${property.zone}\n${property.price.toStringAsFixed(0)} Bs',
                                      ),
                                      isThreeLine: true,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PropertyDetailScreen(
                                              propertyId: property.id,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        OutlinedButton(
                                          onPressed: () =>
                                              _changePropertyStatus(
                                            context,
                                            ref,
                                            property,
                                            'available',
                                          ),
                                          child: const Text('Disponible'),
                                        ),
                                        OutlinedButton(
                                          onPressed: () =>
                                              _changePropertyStatus(
                                            context,
                                            ref,
                                            property,
                                            'reserved',
                                          ),
                                          child: const Text('Reservado'),
                                        ),
                                        OutlinedButton(
                                          onPressed: () =>
                                              _changePropertyStatus(
                                            context,
                                            ref,
                                            property,
                                            'sold',
                                          ),
                                          child:
                                              const Text('Vendido/Alquilado'),
                                        ),
                                        TextButton.icon(
                                          onPressed: () => _deleteProperty(
                                            context,
                                            ref,
                                            property,
                                          ),
                                          icon: const Icon(
                                            Icons.visibility_off,
                                            color: Colors.red,
                                          ),
                                          label: const Text(
                                            'Ocultar',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildOwnerMatches(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      data: (profile) {
        if (!profile.isOwnerOrAdmin) {
          return _ActivateOwnerView(
            onActivate: () => _activateOwner(context, ref),
          );
        }

        final ownerMatchesAsync = ref.watch(ownerMatchesProvider);

        return ownerMatchesAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: Text(
                  'Todavía nadie hizo match con tus propiedades.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: _PropertyThumbnail(
                            url: item.property.imageUrl,
                          ),
                          title: Text(
                            item.property.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Interesado: ${item.buyerName ?? item.buyerId}\nEstado: ${item.status}',
                          ),
                          isThreeLine: true,
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _changeMatchStatus(
                                context,
                                ref,
                                item,
                                'contacted',
                              ),
                              icon: const Icon(Icons.chat),
                              label: const Text('Contactado'),
                            ),
                            TextButton.icon(
                              onPressed: () => _changeMatchStatus(
                                context,
                                ref,
                                item,
                                'archived',
                              ),
                              icon: const Icon(Icons.archive),
                              label: const Text('Archivar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text(
            'Panel Rent App',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          centerTitle: true,
          elevation: 1,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.favorite), text: 'Matches'),
              Tab(icon: Icon(Icons.home_work), text: 'Mis inmuebles'),
              Tab(icon: Icon(Icons.people), text: 'Interesados'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBuyerMatches(context, ref),
            _buildOwnerProperties(context, ref),
            _buildOwnerMatches(context, ref),
          ],
        ),
      ),
    );
  }
}

class _PropertyThumbnail extends StatelessWidget {
  final String url;

  const _PropertyThumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 70,
            height: 70,
            color: Colors.grey[300],
            child: const Icon(Icons.home_work, color: Colors.grey),
          );
        },
      ),
    );
  }
}

class _ActivateOwnerView extends StatelessWidget {
  final VoidCallback onActivate;

  const _ActivateOwnerView({required this.onActivate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.real_estate_agent,
                    size: 70, color: Colors.green),
                const SizedBox(height: 16),
                const Text(
                  'Activa el modo propietario',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Podrás publicar inmuebles, subir imágenes y ver interesados.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: onActivate,
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text(
                    'Activar propietario',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
