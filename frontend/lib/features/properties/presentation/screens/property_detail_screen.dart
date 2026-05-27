import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/property.dart';
import '../../../../services/api_service.dart';

class PropertyDetailScreen extends StatefulWidget {
  final String propertyId;

  const PropertyDetailScreen({
    super.key,
    required this.propertyId,
  });

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  late final Future<PropertyDetailData> _futureDetail;

  @override
  void initState() {
    super.initState();
    _futureDetail = ApiService().fetchPropertyDetail(widget.propertyId);
  }

  Future<void> _openWhatsapp(PropertyDetailData detail) async {
    final phone = detail.ownerPhone?.trim();

    if (phone == null || phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este propietario aún no tiene teléfono registrado.'),
        ),
      );
      return;
    }

    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final normalized = cleaned.startsWith('+')
        ? cleaned.substring(1)
        : cleaned.length == 8
            ? '591$cleaned'
            : cleaned;

    final message = Uri.encodeComponent(
      'Hola, vi tu inmueble "${detail.property.title}" en Rent App y me interesa.',
    );

    final uri = Uri.parse('https://wa.me/$normalized?text=$message');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
      );
    }
  }

  Future<void> _openCall(PropertyDetailData detail) async {
    final phone = detail.ownerPhone?.trim();

    if (phone == null || phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este propietario aún no tiene teléfono registrado.'),
        ),
      );
      return;
    }

    final uri = Uri.parse('tel:$phone');

    if (!await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la llamada.')),
      );
    }
  }

  Widget _buildImageGallery(List<String> images) {
    return SizedBox(
      height: 280,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Image.network(
            images[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.home_work, size: 70, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAmenities(Property property) {
    if (property.amenities.isEmpty) {
      return const Text('Sin comodidades registradas.');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: property.amenities.map((amenity) {
        return Chip(
          label: Text(amenity),
          avatar: const Icon(Icons.check_circle_outline, size: 18),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PropertyDetailData>(
      future: _futureDetail,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalle')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final detail = snapshot.data!;
        final property = detail.property;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalle del inmueble'),
          ),
          body: ListView(
            children: [
              _buildImageGallery(detail.images),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${property.price.toStringAsFixed(0)} ${property.currency}',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined),
                        const SizedBox(width: 6),
                        Text(property.zone),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.home_work_outlined),
                        const SizedBox(width: 6),
                        Text(
                            '${property.propertyType} · ${property.operationType}'),
                      ],
                    ),
                    const Divider(height: 32),
                    const Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(property.description),
                    const Divider(height: 32),
                    const Text(
                      'Amenidades',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildAmenities(property),
                    const Divider(height: 32),
                    const Text(
                      'Propietario',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(detail.ownerName ?? 'Propietario'),
                    Text(detail.ownerPhone ?? 'Sin teléfono registrado'),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openWhatsapp(detail),
                            icon: const Icon(Icons.chat, color: Colors.white),
                            label: const Text(
                              'WhatsApp',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.all(14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openCall(detail),
                            icon: const Icon(Icons.phone),
                            label: const Text('Llamar'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
