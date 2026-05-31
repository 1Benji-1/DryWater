import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/router/route_names.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _preferredZone = 'Santa Cruz';
  bool _isLoading = false;

  final List<String> _zones = const [
    'Santa Cruz',
    'La Paz',
    'Cochabamba',
    'Tarija',
    'Pando',
  ];

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
    });

    // Simulando el guardado de la preferencia de zona en MVP
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    context.go(RouteNames.dashboard);
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    context.go(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = Supabase.instance.client.auth.currentUser?.email;
    final userLabel = userEmail ?? 'usuario';

    return Scaffold(
      backgroundColor: const Color(0xFFC3E7C9),
      appBar: AppBar(
        title: const Text('Configuración Inicial'),
        backgroundColor: const Color(0xFF10471D),
        foregroundColor: Colors.white,
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
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 20,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.cloud_queue, size: 72, color: Color(0xFF246D34)),
                const SizedBox(height: 16),
                const Text(
                  'Bienvenido a DryWater',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF10471D)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sesión: $userLabel',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 32),
                const Text(
                  '¿Qué zona deseas monitorear?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF10471D)),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFD2ECD9)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _preferredZone,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF246D34)),
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
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10471D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Ir al DryWater',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
