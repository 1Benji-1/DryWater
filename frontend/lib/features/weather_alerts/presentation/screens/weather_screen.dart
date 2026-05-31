import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../services/api_service.dart';
import '../../../../services/local_notification_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Future<Map<String, dynamic>>? _weatherFuture;
  
  double? _currentLat;
  double? _currentLon;
  String _errorMessage = '';
  String? _currentSimulation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _fetchWeather({String? simulation}) {
    setState(() {
      _currentSimulation = simulation;
      _weatherFuture = ApiService().fetchWeatherForecast(
        'Tu Ubicación Actual', 
        lat: _currentLat, 
        lon: _currentLon,
        simulate: simulation,
      );
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _weatherFuture = Future.value({'loading': true});
      _errorMessage = '';
    });

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _errorMessage = 'El GPS está desactivado. Por favor actívalo para continuar.';
        _weatherFuture = null;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage = 'Los permisos de ubicación fueron denegados. La app necesita tu ubicación obligatoriamente para las alertas.';
          _weatherFuture = null;
        });
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _errorMessage = 'Los permisos de ubicación están denegados permanentemente. Ve a la configuración de tu teléfono para activarlos.';
        _weatherFuture = null;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      
      _currentLat = position.latitude;
      _currentLon = position.longitude;
      
      _fetchWeather(simulation: _currentSimulation);
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocurrió un error al intentar obtener la ubicación.';
        _weatherFuture = null;
      });
    }
  }

  void _showSimulatorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.auto_fix_high, color: Colors.purple),
              SizedBox(width: 10),
              Text('Modo Simulador'),
            ],
          ),
          content: const Text('Elige un desastre para simular. La alerta llegará en 10 segundos.'),
          actions: [
            _buildSimButton('Inundación', 'flood', Colors.blue),
            _buildSimButton('Sequía', 'drought', Colors.orange),
            _buildSimButton('Helada', 'frost', Colors.cyan),
            _buildSimButton('Ola de Calor', 'heatwave', Colors.red),
            _buildSimButton('Normalidad', null, Colors.green),
          ],
        );
      }
    );
  }

  Widget _buildSimButton(String label, String? simType, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
        onPressed: () {
          Navigator.pop(context);
          if (simType == null) {
             _fetchWeather(simulation: null);
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Clima real restaurado.')),
             );
             return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Simulación de $label programada en 10 segundos. Puedes minimizar la app.'),
              duration: const Duration(seconds: 4),
            ),
          );

          // Delay de 10 segundos
          Future.delayed(const Duration(seconds: 10), () async {
            // 1. Intentar disparar Notificación Local Nativa (puede no verse en Chrome Web)
            try {
              await LocalNotificationService.showSimulatedNotification(
                title: '¡ALERTA EXTREMA: $label!',
                body: 'Toca aquí para ver protocolos de supervivencia inmediatamente.',
                payload: 'Alerta simulada de $label detectada en tu zona.',
              );
            } catch (e) {
              debugPrint('Local notifications not supported on this platform: $e');
            }

            // 2. Mostrar la ventana global in-app obligatoriamente (Funciona 100% en Web y Móvil)
            LocalNotificationService.showGlobalAlertModal(
              AppRouter.navigatorKey, 
              'Alerta simulada de $label detectada en tu zona. Ve a la pestaña de prevención para seguir el protocolo de supervivencia.'
            );

            // 3. Actualizar la UI del Clima
            if (mounted) {
              _fetchWeather(simulation: simType);
            }
          });
        },
        child: Text(label),
      ),
    );
  }

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'flood': return Icons.water_damage;
      case 'heatwave': return Icons.local_fire_department;
      case 'frost': return Icons.ac_unit;
      case 'drought': return Icons.wb_sunny;
      default: return Icons.cloud_done;
    }
  }

  Color _getAlertColor(String type) {
    switch (type) {
      case 'flood': return Colors.blue;
      case 'heatwave': return Colors.red;
      case 'frost': return Colors.cyan;
      case 'drought': return Colors.orange;
      default: return Colors.green;
    }
  }

  IconData _getConditionIcon(String condition) {
    if (condition == "Lluvioso") return Icons.water_drop;
    if (condition == "Nublado") return Icons.cloud;
    if (condition == "Muy Caluroso") return Icons.wb_sunny;
    if (condition == "Frío") return Icons.ac_unit;
    return Icons.wb_sunny_outlined;
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, d MMM', 'es').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 80, color: Colors.redAccent),
            const SizedBox(height: 20),
            const Text(
              'Ubicación Necesaria',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10471D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clima Local', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF10471D),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high, color: Colors.amber),
            onPressed: _showSimulatorDialog,
            tooltip: 'Simular Desastre',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'Actualizar mi ubicación',
          )
        ],
      ),
      body: _weatherFuture == null
          ? _buildErrorScreen()
          : FutureBuilder<Map<String, dynamic>>(
              future: _weatherFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting || 
                   (snapshot.hasData && snapshot.data!.containsKey('loading'))) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF10471D)),
                        SizedBox(height: 16),
                        Text('Buscando tu ubicación exacta...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error al cargar datos: ${snapshot.error}', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _getCurrentLocation,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No hay datos disponibles.'));
                }

                final data = snapshot.data!;
                final status = data['status'] as String;
                final message = data['message'] as String;
                final type = data['type'] as String;
                final forecast = data['forecast'] as List<dynamic>;

                final isAlert = type != 'normal';
                final alertColor = _getAlertColor(type);

                return RefreshIndicator(
                  onRefresh: _getCurrentLocation,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Alert Banner
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isAlert ? alertColor.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isAlert ? alertColor : Colors.green, width: 2),
                        ),
                        child: Column(
                          children: [
                            Icon(_getAlertIcon(type), size: 80, color: isAlert ? alertColor : Colors.green),
                            const SizedBox(height: 16),
                            Text(
                              status,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isAlert ? alertColor : Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: isAlert ? alertColor.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.gps_fixed, size: 14, color: isAlert ? alertColor : Colors.green),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Ubicación exacta conectada',
                                    style: TextStyle(
                                      fontSize: 12, 
                                      color: isAlert ? alertColor : Colors.green, 
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Pronóstico a 5 días',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF10471D)),
                      ),
                      const SizedBox(height: 16),
                      // Days List
                      ...forecast.map((day) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: Colors.grey[100],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: Icon(_getConditionIcon(day['condition']), color: const Color(0xFF246D34), size: 40),
                            title: Text(
                              _formatDate(day['date']),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('${day['condition']} • Lluvia: ${day['precipitation']}mm'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${day['temp_max']}°C', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                                Text('${day['temp_min']}°C', style: const TextStyle(fontSize: 14, color: Colors.blue)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
