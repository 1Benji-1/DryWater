import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/api_service.dart';

class OwnerPropertyFormScreen extends StatefulWidget {
  const OwnerPropertyFormScreen({super.key});

  @override
  State<OwnerPropertyFormScreen> createState() =>
      _OwnerPropertyFormScreenState();
}

class _OwnerPropertyFormScreenState extends State<OwnerPropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();

  String _operationType = 'Alquiler';
  String _propertyType = 'Departamento';
  String _zone = 'Equipetrol';

  bool _isSaving = false;
  String? _errorMessage;

  final List<String> _selectedAmenities = [];
  final List<PlatformFile> _selectedFiles = [];

  final List<String> _zones = const [
    'Equipetrol',
    'Centro',
    'Zona Norte',
    'Urubó',
    'Zona Sur',
  ];

  final List<String> _propertyTypes = const [
    'Departamento',
    'Casa',
    'Terreno',
    'Oficina',
    'Local Comercial',
  ];

  final List<String> _amenities = const [
    'Piscina',
    'Gimnasio',
    'Amoblado',
    'Balcón',
    'Mascotas',
    'Churrasquera',
    'Jardín',
    'Garaje',
    'Seguridad Privada',
    'Club House',
    'Parqueo',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfilePhone();
  }

  Future<void> _loadProfilePhone() async {
    try {
      final profile = await ApiService().fetchProfile();
      if (!mounted) return;
      _phoneController.text = profile.phone ?? '';
    } catch (_) {
      // No bloquea el formulario.
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true,
    );

    if (result == null) return;

    setState(() {
      _selectedFiles
        ..clear()
        ..addAll(result.files.where((file) => file.bytes != null));
    });
  }

  String _contentTypeFromName(String fileName) {
    final lower = fileName.toLowerCase();

    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';

    return 'image/jpeg';
  }

  Future<List<OwnerPropertyImageInput>> _uploadImages() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      throw const ApiException(message: 'Sesión expirada.');
    }

    final storage = Supabase.instance.client.storage.from('property-images');
    final uploaded = <OwnerPropertyImageInput>[];

    for (final file in _selectedFiles) {
      final bytes = file.bytes;
      if (bytes == null) continue;

      final safeName = file.name
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
          .replaceAll('__', '_');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '${user.id}/$timestamp-$safeName';

      await storage.uploadBinary(
        storagePath,
        Uint8List.fromList(bytes),
        fileOptions: FileOptions(
          contentType: _contentTypeFromName(file.name),
          upsert: true,
        ),
      );

      final publicUrl = storage.getPublicUrl(storagePath);

      uploaded.add(
        OwnerPropertyImageInput(
          imageUrl: publicUrl,
          storagePath: storagePath,
        ),
      );
    }

    return uploaded;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceController.text.trim()) ?? 0;

    if (price <= 0) {
      setState(() {
        _errorMessage = 'Ingresa un precio válido.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService();

      final phone = _phoneController.text.trim();
      if (phone.isNotEmpty) {
        await api.updateProfile(phone: phone);
      }

      final images = await _uploadImages();

      await api.createOwnerProperty(
        OwnerPropertyCreateInput(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          operationType: _operationType,
          propertyType: _propertyType,
          zone: _zone,
          amenities: _selectedAmenities,
          images: images,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propiedad publicada correctamente.')),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildAmenitySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _amenities.map((amenity) {
        final isSelected = _selectedAmenities.contains(amenity);

        return FilterChip(
          selected: isSelected,
          label: Text(amenity),
          onSelected: (value) {
            setState(() {
              if (value) {
                _selectedAmenities.add(amenity);
              } else {
                _selectedAmenities.remove(amenity);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSelectedImages() {
    if (_selectedFiles.isEmpty) {
      return const Text('Aún no seleccionaste imágenes.');
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _selectedFiles.map((file) {
        return Chip(
          avatar: const Icon(Icons.image),
          label: Text(
            file.name,
            overflow: TextOverflow.ellipsis,
          ),
          onDeleted: () {
            setState(() {
              _selectedFiles.remove(file);
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar inmueble'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Datos del inmueble',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'El título debe tener al menos 3 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Precio en Bs',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final price = double.tryParse(value?.trim() ?? '') ?? 0;
                    if (price <= 0) return 'Ingresa un precio válido.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _operationType,
                  decoration: const InputDecoration(
                    labelText: 'Operación',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'Alquiler', child: Text('Alquiler')),
                    DropdownMenuItem(value: 'Venta', child: Text('Venta')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _operationType = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _propertyType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de inmueble',
                    border: OutlineInputBorder(),
                  ),
                  items: _propertyTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _propertyType = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _zone,
                  decoration: const InputDecoration(
                    labelText: 'Zona',
                    border: OutlineInputBorder(),
                  ),
                  items: _zones.map((zone) {
                    return DropdownMenuItem(value: zone, child: Text(zone));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _zone = value);
                    }
                  },
                ),
                const SizedBox(height: 22),
                const Text(
                  'Amenidades',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildAmenitySelector(),
                const SizedBox(height: 22),
                const Text(
                  'Contacto del propietario',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono / WhatsApp',
                    hintText: 'Ejemplo: 60864068',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Imágenes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _pickImages,
                  icon: const Icon(Icons.image_search),
                  label: const Text('Seleccionar imágenes'),
                ),
                const SizedBox(height: 10),
                _buildSelectedImages(),
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
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.publish, color: Colors.white),
                  label: Text(
                    _isSaving ? 'Publicando...' : 'Publicar inmueble',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.all(16),
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
