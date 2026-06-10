import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/establishment.dart';
import '../services/establishment_service.dart';

class EstablishmentRegistrationScreen extends StatefulWidget {
  final String adminId;
  final EstablishmentService establishmentService;
  final Establishment? establishment;

  const EstablishmentRegistrationScreen({
    super.key,
    required this.adminId,
    required this.establishmentService,
    this.establishment,
  });

  @override
  State<EstablishmentRegistrationScreen> createState() => _EstablishmentRegistrationScreenState();
}

class _EstablishmentRegistrationScreenState extends State<EstablishmentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _capacityController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  final _addressFocusNode = FocusNode();
  final List<Map<String, String>> _addressSuggestions = [];

  GeoPoint? _selectedLocation;
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final existing = widget.establishment;
    if (existing != null) {
      _nameController.text = existing.name;
      _addressController.text = existing.address;
      _capacityController.text = existing.capacity.toString();
      _serviceTypeController.text = existing.serviceType;
      _selectedLocation = existing.location;
    }
    _addressFocusNode.addListener(() {
      if (!_addressFocusNode.hasFocus) {
        setState(() => _addressSuggestions.clear());
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _addressFocusNode.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _capacityController.dispose();
    _serviceTypeController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.establishment != null;

  Future<void> _saveEstablishment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final establishment = Establishment(
        id: widget.establishment?.id ?? '',
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        capacity: int.parse(_capacityController.text.trim()),
        serviceType: _serviceTypeController.text.trim(),
        adminId: widget.establishment?.adminId ?? widget.adminId,
        createdAt: widget.establishment?.createdAt ?? DateTime.now(),
        location: _selectedLocation ?? widget.establishment?.location,
      );

      if (_isEditing) {
        await widget.establishmentService.updateEstablishment(establishment);
      } else {
        await widget.establishmentService.addEstablishment(establishment);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao cadastrar estabelecimento: ${error.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onAddressChanged(String value) {
    _selectedLocation = null;
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _addressSuggestions.clear());
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchAddressSuggestions(value.trim());
    });
  }

  Future<void> _searchAddressSuggestions(String input) async {
    if (input.isEmpty) {
      return;
    }

    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q': input,
          'format': 'json',
          'addressdetails': '1',
          'limit': '5',
          'countrycodes': 'br',
        },
      );

      final client = HttpClient();
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'mobile-fila-facil-app/1.0');
      final response = await request.close();
      final payload = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode != 200) {
        return;
      }

      final results = jsonDecode(payload) as List<dynamic>?;
      if (results == null) return;

      setState(() {
        _addressSuggestions
          ..clear()
          ..addAll(results.map((result) {
            final data = result as Map<String, dynamic>;
            return {
              'description': data['display_name'] as String? ?? '',
              'lat': data['lat'] as String? ?? '',
              'lon': data['lon'] as String? ?? '',
            };
          }).where((item) => item['lat']!.isNotEmpty && item['lon']!.isNotEmpty));
      });
    } catch (_) {
      // Ignorar falhas silenciosas e manter a experiência de usuário.
    }
  }

  Future<void> _selectAddressSuggestion(Map<String, String> suggestion) async {
    final description = suggestion['description'];
    final latString = suggestion['lat'];
    final lonString = suggestion['lon'];
    if (description == null || latString == null || lonString == null) return;

    final lat = double.tryParse(latString);
    final lon = double.tryParse(lonString);
    if (lat == null || lon == null) return;

    setState(() {
      _addressController.text = description;
      _selectedLocation = GeoPoint(lat, lon);
      _addressSuggestions.clear();
    });
    FocusScope.of(context).unfocus();
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[700]),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar estabelecimento' : 'Cadastrar estabelecimento'),
        backgroundColor: const Color(0xFF0CA79B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: _decoration('Nome do estabelecimento', Icons.store),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome do estabelecimento.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                focusNode: _addressFocusNode,
                decoration: _decoration('Endereço', Icons.location_on),
                onChanged: _onAddressChanged,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o endereço.';
                  }
                  return null;
                },
              ),
              if (_addressSuggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _addressSuggestions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final suggestion = _addressSuggestions[index];
                      return ListTile(
                        title: Text(suggestion['description'] ?? ''),
                        onTap: () => _selectAddressSuggestion(suggestion),
                      );
                    },
                  ),
                ),
              ],
              if (_selectedLocation != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Latitude: ${_selectedLocation!.latitude.toStringAsFixed(6)}, Longitude: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: _decoration('Capacidade máxima da fila', Icons.people),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a capacidade da fila.';
                  }
                  final number = int.tryParse(value.trim());
                  if (number == null || number <= 0) {
                    return 'Informe um número válido maior que zero.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serviceTypeController,
                decoration: _decoration('Tipo de atendimento', Icons.build),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o tipo de atendimento.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF0CA79B),
                ),
                onPressed: _isLoading ? null : _saveEstablishment,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEditing ? 'Salvar alterações' : 'Salvar estabelecimento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
