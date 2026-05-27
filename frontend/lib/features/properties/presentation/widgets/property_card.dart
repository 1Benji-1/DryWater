import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../features/market/presentation/widgets/market_result_dialog.dart';
import '../../domain/entities/property.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;

  const PropertyCard({
    super.key,
    required this.property,
    this.onTap,
  });

  void _showMarketAnalysis(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return MarketResultDialog(
          price: property.price,
          operationType: property.operationType,
          propertyType: property.propertyType,
          zone: property.zone,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = property.imageUrl.trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
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
                child: imageUrl.isEmpty
                    ? _ImageFallback()
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorWidget: (context, url, error) {
                          return _ImageFallback();
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
                          onPressed: () => _showMarketAnalysis(context),
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
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.home_work, size: 60, color: Colors.grey),
      ),
    );
  }
}
