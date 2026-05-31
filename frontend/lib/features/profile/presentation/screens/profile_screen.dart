import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isPremium = false;
  String _fullName = 'Usuario';
  String _email = '';

  final List<String> _randomStatuses = [
    'Amante de la lluvia 🌧️',
    'Esperando el verano ☀️',
    'Sobreviviente de la ola de calor 🥵',
    'Buscando sombra 🌳',
    'Preparado para todo 🛡️'
  ];
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = _randomStatuses[DateTime.now().millisecond % _randomStatuses.length];
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _email = user.email ?? '';
        
        // Cargar datos de la tabla profiles
        final data = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();
            
        setState(() {
          _fullName = data['full_name'] ?? 'Usuario';
          _isPremium = data['is_premium'] ?? false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar tu perfil. Revisa tu conexión.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _editName() async {
    final TextEditingController nameController = TextEditingController(text: _fullName);
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Nombre'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Tu nombre completo'),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, nameController.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10471D), foregroundColor: Colors.white),
              child: const Text('Guardar'),
            ),
          ],
        );
      }
    );

    if (newName != null && newName.isNotEmpty && newName != _fullName) {
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          await Supabase.instance.client
              .from('profiles')
              .update({'full_name': newName})
              .eq('id', userId);
              
          setState(() {
            _fullName = newName;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nombre actualizado exitosamente.'), backgroundColor: Colors.green),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al actualizar el nombre.'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _togglePremium(bool value) async {
    // Guardar el estado previo por si falla
    final previousState = _isPremium;
    setState(() {
      _isPremium = value;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('No hay usuario autenticado');

      await Supabase.instance.client
          .from('profiles')
          .update({'is_premium': value})
          .eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? '¡Suscripción activada exitosamente!' : 'Suscripción cancelada.'),
            backgroundColor: value ? Colors.green : Colors.grey,
          ),
        );
      }
    } catch (e) {
      // Revertir si hay error
      if (mounted) {
        setState(() {
          _isPremium = previousState;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hubo un error al actualizar tu suscripción. Intenta de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF10471D),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Cerrar Sesión',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10471D)))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFFC3E7C9),
                  child: Icon(Icons.person, size: 50, color: Color(0xFF10471D)),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _fullName,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                        onPressed: _editName,
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Text(
                    _email,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _currentStatus,
                      style: const TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Notificaciones Premium', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Recibe alertas meteorológicas con 5 días de anticipación.'),
                  value: _isPremium,
                  activeThumbColor: const Color(0xFF246D34),
                  activeTrackColor: const Color(0xFFC3E7C9),
                  onChanged: _togglePremium,
                ),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 30),
                if (_isPremium)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 30),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            '¡Gracias por ser Premium! Estás protegido contra eventos climáticos extremos.',
                            style: TextStyle(color: Colors.brown, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
