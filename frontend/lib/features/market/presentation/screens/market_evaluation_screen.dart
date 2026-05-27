import 'package:flutter/material.dart';

class MarketEvaluationScreen extends StatelessWidget {
  const MarketEvaluationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Análisis de mercado')),
      body: const Center(
        child: Text('Pantalla base para análisis de mercado.'),
      ),
    );
  }
}
