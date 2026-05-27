import 'package:flutter/material.dart';

import '../../../../services/api_service.dart';

class MarketResultDialog extends StatelessWidget {
  final double price;
  final String operationType;
  final String propertyType;
  final String zone;

  const MarketResultDialog({
    super.key,
    required this.price,
    required this.operationType,
    required this.propertyType,
    required this.zone,
  });

  @override
  Widget build(BuildContext context) {
    final api = ApiService();

    return AlertDialog(
      title: const Text(
        '📊 Análisis de Mercado',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: FutureBuilder(
        future: api.evaluateMarketPrice(
          price,
          operationType,
          zone: zone,
          propertyType: propertyType,
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
              Text(
                  'Muestra analizada: ${data.statistics.sampleSize} inmuebles'),
              Text('Promedio: ${data.statistics.mean} Bs'),
              Text(
                  'Rango bajo del mercado: ${data.statistics.quartiles.q1} Bs'),
              Text(
                  'Rango alto del mercado: ${data.statistics.quartiles.q3} Bs'),
              const SizedBox(height: 15),
              Text(
                'Este inmueble cuesta: $price Bs',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
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
  }
}
