import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/property_provider.dart';
import '../services/api_service.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final TextEditingController _budgetController = TextEditingController();

  String _operationType = 'Alquiler';
  String _preferredZone = 'Equipetrol';
  String? mensajeError;
  bool _isLoading = false;

  final List<String> _zonas = const [
    'Equipetrol',
    'Centro',
    'Zona Norte',
    'Urubó',
    'Zona Sur',
  ];

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _procesarOnboarding() async {
    final presupuesto = double.tryParse(_budgetController.text.trim()) ?? 0.0;

    if (presupuesto <= 0) {
      setState(() {
        mensajeError = 'Por favor ingresa un presupuesto válido.';
      });
      return;
    }

    setState(() {
      mensajeError = null;
      _isLoading = true;
    });

    try {
      final api = ApiService();
      final exito = await api.sendOnboarding(
        budget: presupuesto,
        operationType: _operationType,
        preferredZone: _preferredZone,
      );

      if (!exito) {
        setState(() {
          mensajeError = 'No se pudo guardar tu perfil inicial.';
        });
        return;
      }

      ref.invalidate(propertiesProvider);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (error) {
      setState(() {
        mensajeError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();

    ref.invalidate(propertiesProvider);

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userLabel = user?.email ?? 'usuario';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configura tu búsqueda'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(30),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Rent App 🏠',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Hola, $userLabel',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 28),

                const Text(
                  '¿Qué buscas?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Radio<String>(
                      value: 'Alquiler',
                      groupValue: _operationType,
                      onChanged: (value) {
                        setState(() => _operationType = value ?? 'Alquiler');
                      },
                    ),
                    const Text('Alquiler'),
                    Radio<String>(
                      value: 'Venta',
                      groupValue: _operationType,
                      onChanged: (value) {
                        setState(() => _operationType = value ?? 'Venta');
                      },
                    ),
                    const Text('Comprar'),
                  ],
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tu presupuesto máximo (Bs)',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Zona de inicio preferida:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _preferredZone,
                  isExpanded: true,
                  items: _zonas.map((zona) {
                    return DropdownMenuItem<String>(
                      value: zona,
                      child: Text(zona),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _preferredZone = value);
                    }
                  },
                ),

                const SizedBox(height: 24),

                if (mensajeError != null) ...[
                  Text(
                    mensajeError!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],

                ElevatedButton(
                  onPressed: _isLoading ? null : _procesarOnboarding,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Ingresar al Tinder',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
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
