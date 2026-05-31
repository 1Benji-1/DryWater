import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _supabase = Supabase.instance.client;

  Future<void> _showAddReportDialog() async {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    bool isDanger = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nuevo Reporte'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: '¿Qué sucedió?',
                        hintText: 'Ej. Árbol caído',
                      ),
                      maxLength: 100,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Ubicación',
                        hintText: 'Ej. Av. Principal Sur',
                      ),
                      maxLength: 50,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: const Text('¿Es peligroso?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      value: isDanger,
                      activeThumbColor: Colors.red,
                      activeTrackColor: Colors.red[100],
                      onChanged: (val) {
                        setDialogState(() {
                          isDanger = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10471D), foregroundColor: Colors.white),
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty || locationController.text.trim().isEmpty) {
                      return;
                    }
                    
                    try {
                      await _supabase.from('community_reports').insert({
                        'title': titleController.text.trim(),
                        'location': locationController.text.trim(),
                        'is_danger': isDanger,
                      });
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        setState(() {}); // Recargar la lista
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reporte enviado con éxito.'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: const Text('Enviar Reporte'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prevención y Protocolos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF10471D),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReportDialog,
        backgroundColor: const Color(0xFF10471D),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alert),
        label: const Text('Reportar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Sección: Protocolos de Emergencia
          const Row(
            children: [
              Icon(Icons.shield, color: Color(0xFF246D34)),
              SizedBox(width: 10),
              Text(
                'Guía de Supervivencia',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF10471D)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Conoce qué hacer antes, durante y después de un evento climático extremo.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _buildProtocolCard(
            title: 'Inundaciones',
            icon: Icons.water_damage,
            color: Colors.blue,
            content: '• Evacúa inmediatamente hacia zonas altas.\n• Desconecta la electricidad y cierra el gas.\n• No cruces ríos ni calles inundadas caminando o en auto.\n• Ten a mano una mochila de emergencia con agua potable.',
          ),
          _buildProtocolCard(
            title: 'Sequía Extrema',
            icon: Icons.wb_sunny,
            color: Colors.orange,
            content: '• Raciona el agua para consumo humano estricto.\n• Evita encender fogatas o tirar colillas, riesgo alto de incendios.\n• Si tienes cultivos, instala sistemas de riego por goteo o mallas sombra.',
          ),
          _buildProtocolCard(
            title: 'Heladas',
            icon: Icons.ac_unit,
            color: Colors.cyan,
            content: '• Resguarda a tus animales en lugares techados.\n• Cubre plantas sensibles con plástico o mallas térmicas.\n• Mantén la calefacción encendida pero con ventilación para evitar monóxido de carbono.\n• Abrígate con varias capas de ropa.',
          ),
          _buildProtocolCard(
            title: 'Ola de Calor',
            icon: Icons.local_fire_department,
            color: Colors.red,
            content: '• Mantente hidratado, bebe agua aunque no tengas sed.\n• No te expongas al sol entre las 11:00 y las 16:00.\n• Usa ropa ligera, holgada y de colores claros.\n• Presta atención a personas mayores y mascotas.',
          ),

          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 20),

          // Sección: Reportes Comunitarios
          const Row(
            children: [
              Icon(Icons.campaign, color: Colors.deepOrange),
              SizedBox(width: 10),
              Text(
                'Reportes Comunitarios',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Últimos incidentes reportados por usuarios. (Máx. 10)',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),

          FutureBuilder<List<Map<String, dynamic>>>(
            future: _supabase
                .from('community_reports')
                .select()
                .order('created_at', ascending: false)
                .limit(10),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
              }
              
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Aún no se ha creado la tabla community_reports en Supabase.', style: TextStyle(color: Colors.red)),
                );
              }
              
              final reports = snapshot.data ?? [];
              
              if (reports.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('No hay incidentes reportados recientes. Todo tranquilo.', style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              return Column(
                children: reports.map((r) {
                  return _buildReportCard(
                    title: r['title'],
                    time: _formatRelativeTime(r['created_at']),
                    location: r['location'],
                    isDanger: r['is_danger'],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) {
        return 'Hace ${diff.inMinutes} minutos';
      } else if (diff.inHours < 24) {
        return 'Hace ${diff.inHours} horas';
      } else {
        return DateFormat('d MMM', 'es').format(date);
      }
    } catch (e) {
      return 'Reciente';
    }
  }

  Widget _buildProtocolCard({
    required String title,
    required IconData icon,
    required Color color,
    required String content,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: color.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        iconColor: color,
        collapsedIconColor: color,
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              content,
              style: TextStyle(height: 1.5, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String time,
    required String location,
    required bool isDanger,
  }) {
    final iconColor = isDanger ? Colors.red : Colors.orange;
    final iconData = isDanger ? Icons.warning : Icons.info_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
