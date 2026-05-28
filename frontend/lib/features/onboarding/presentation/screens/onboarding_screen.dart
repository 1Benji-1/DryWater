import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/router/route_names.dart';
import '../../../../providers/property_provider.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../properties/presentation/providers/property_feed_controller.dart';
import '../../domain/entities/onboarding_preferences.dart';
import '../providers/onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final TextEditingController _budgetController = TextEditingController();

  String _operationType = 'Alquiler';
  String _preferredZone = 'Equipetrol';
  String? _errorMessage;
  bool _isLoading = false;

  final List<String> _zones = const [
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

  Future<void> _submit() async {
    final budget = double.tryParse(_budgetController.text.trim()) ?? 0.0;

    if (budget <= 0) {
      setState(() {
        _errorMessage = 'Por favor ingresa un presupuesto válido.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final useCase = ref.read(savePreferencesUseCaseProvider);
      final saved = await useCase(
        OnboardingPreferences(
          budget: budget,
          operationType: _operationType,
          preferredZone: _preferredZone,
        ),
      );

      if (!saved) {
        setState(() {
          _errorMessage = 'No se pudo guardar tu perfil inicial.';
        });
        return;
      }

      ref.invalidate(propertyFeedProvider);
      ref.invalidate(propertyFeedProvider);
    ref.invalidate(propertiesProvider);

      if (!mounted) return;
      context.go(RouteNames.home);
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
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
    await ref.read(signOutUseCaseProvider).call();
    ref.invalidate(propertiesProvider);

    if (!mounted) return;
    context.go(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = Supabase.instance.client.auth.currentUser?.email;
    final userLabel = userEmail ?? 'usuario autenticado';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferencias iniciales'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _isLoading ? null : _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: 430,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.home_work, size: 72, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  'Configura tu búsqueda',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sesión: $userLabel',
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
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(
                                () => _operationType = value ?? 'Alquiler',
                              );
                            },
                    ),
                    const Text('Alquiler'),
                    Radio<String>(
                      value: 'Venta',
                      groupValue: _operationType,
                      onChanged: _isLoading
                          ? null
                          : (value) {
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
                  items: _zones.map((zone) {
                    return DropdownMenuItem<String>(
                      value: zone,
                      child: Text(zone),
                    );
                  }).toList(),
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _preferredZone = value);
                          }
                        },
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Ingresar al feed'),
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
