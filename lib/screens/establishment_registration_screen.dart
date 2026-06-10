import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/establishment.dart';
import '../screens/queue_registration_screen.dart';
import '../services/establishment_service.dart';
import '../services/queue_service.dart';

class EstablishmentRegistrationScreen extends StatefulWidget {
  final String adminId;
  final EstablishmentService establishmentService;
  final QueueService? queueService;
  final Establishment? establishment;

  const EstablishmentRegistrationScreen({
    super.key,
    required this.adminId,
    required this.establishmentService,
    this.queueService,
    this.establishment,
  });

  @override
  State<EstablishmentRegistrationScreen> createState() => _EstablishmentRegistrationScreenState();
}

class _EstablishmentRegistrationScreenState extends State<EstablishmentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cepController = TextEditingController();
  final _selectedAddressController = TextEditingController();
  final _addressDetailsController = TextEditingController();
  final _capacityController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  final _cepFocusNode = FocusNode();
  final List<Map<String, String>> _cepSuggestions = [];

  String _selectedAddress = '';
  GeoPoint? _selectedLocation;
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final existing = widget.establishment;
    if (existing != null) {
      _nameController.text = existing.name;
      _cepController.text = existing.cep;
      // Dividir endereço em endereço selecionado e detalhes do usuário
      final parts = existing.address.split(' - ');
      if (parts.length >= 2) {
        _selectedAddress = parts[0];
        _addressDetailsController.text = parts.sublist(1).join(' - ');
      } else {
        _selectedAddress = existing.address;
      }
      _selectedAddressController.text = _selectedAddress;
      _capacityController.text = existing.capacity.toString();
      _serviceTypeController.text = existing.serviceType;
      _selectedLocation = existing.location;
    }
    _cepFocusNode.addListener(() {
      if (!_cepFocusNode.hasFocus) {
        setState(() => _cepSuggestions.clear());
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cepFocusNode.dispose();
    _nameController.dispose();
    _cepController.dispose();
    _selectedAddressController.dispose();
    _addressDetailsController.dispose();
    _capacityController.dispose();
    _serviceTypeController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.establishment != null;

  Future<void> _saveEstablishment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAddressController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione o endereço encontrado pelo CEP antes de salvar.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Combinar endereço resultante da busca por CEP com o complemento digitado pelo usuário
      final fullAddress = '${_selectedAddressController.text.trim()} - ${_addressDetailsController.text.trim()}';
      
      final establishment = Establishment(
        id: widget.establishment?.id ?? '',
        name: _nameController.text.trim(),
        cep: _cepController.text.trim(),
        address: fullAddress,
        capacity: int.parse(_capacityController.text.trim()),
        serviceType: _serviceTypeController.text.trim(),
        adminId: widget.establishment?.adminId ?? widget.adminId,
        createdAt: widget.establishment?.createdAt ?? DateTime.now(),
        location: _selectedLocation ?? widget.establishment?.location,
      );

      if (_isEditing) {
        await widget.establishmentService.updateEstablishment(establishment);
        if (mounted) Navigator.of(context).pop();
      } else {
        final createdId = await widget.establishmentService.addEstablishment(establishment);
        final savedEstablishment = establishment.copyWith(id: createdId);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => QueueRegistrationScreen(
                establishment: savedEstablishment,
                queueService: widget.queueService,
              ),
            ),
          );
        }
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

  void _onCepChanged(String value) {
    _selectedLocation = null;
    _debounce?.cancel();
    // Remover formatação anterior se houver
    final cleanCep = value.replaceAll(RegExp(r'\D'), '');
    if (cleanCep.length < 8) {
      setState(() => _cepSuggestions.clear());
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchCepSuggestions(cleanCep);
    });
  }

  Future<void> _searchCepSuggestions(String cep) async {
    if (cep.isEmpty || cep.length != 8) {
      return;
    }

    try {
      final uri = Uri.https(
        'brasilapi.com.br',
        '/api/cep/v2/$cep',
      );

      final client = http.Client();
      http.Response response = http.Response('', 500);
      String payload = '';

      try {
        response = await client.get(
          uri,
          headers: {
            'User-Agent': 'mobile-fila-facil-app/1.0',
          },
        );
        payload = response.body;
      } catch (e) {
        print('Erro na requisição BrasilAPI: $e');
      } finally {
        client.close();
      }

      if (response.statusCode != 200) {
        return;
      }

      final data = jsonDecode(payload) as Map<String, dynamic>?;
      if (data == null) return;

      final street = data['street'] as String? ?? '';
      final neighborhood = data['neighborhood'] as String? ?? '';
      final city = data['city'] as String? ?? '';
      final state = data['state'] as String? ?? '';
      final formattedAddress = [street, neighborhood, city, state]
          .where((part) => part.isNotEmpty)
          .join(', ');

      if (formattedAddress.isEmpty) {
        return;
      }

      setState(() {
        _cepSuggestions
          ..clear()
          ..add({
            'description': formattedAddress,
          });
        _selectedAddress = '';
        _selectedLocation = null;
        _selectCepSuggestion(_cepSuggestions.first);
      });
    } catch (_) {
      // Ignorar falhas silenciosas
    }
  }

  Future<void> _selectCepSuggestion(Map<String, String> suggestion) async {
    final description = suggestion['description'];
    if (description == null || description.isEmpty) return;
    // DEBUG: log selection
    // ignore: avoid_print
    print('CEP suggestion tapped: $description');

    final location = await _geocodeAddress(description);
    if (location == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível localizar o endereço.')),        
        );
      }
      return;
    }

    setState(() {
      _selectedAddress = description;
      _selectedAddressController.text = description;
      _selectedLocation = location;
      _cepSuggestions.clear();
    });
    FocusScope.of(context).unfocus();
  }

  Future<GeoPoint?> _geocodeAddress(String address) async {
    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q': address,
          'format': 'json',
          'limit': '1',
          'addressdetails': '1',
          'countrycodes': 'br',
        },
      );

      final client = http.Client();
      final response = await client.get(
        uri,
        headers: {
          'User-Agent': 'mobile-fila-facil-app/1.0',
        },
      );
      client.close();

      if (response.statusCode != 200) {
        return null;
      }

      final results = jsonDecode(response.body) as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final data = results.first as Map<String, dynamic>;
      final lat = double.tryParse(data['lat']?.toString() ?? '');
      final lon = double.tryParse(data['lon']?.toString() ?? '');
      if (lat == null || lon == null) return null;

      return GeoPoint(lat, lon);
    } catch (e) {
      print('Erro no geocoding: $e');
      return null;
    }
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
                controller: _cepController,
                focusNode: _cepFocusNode,
                decoration: _decoration('CEP', Icons.mail),
                keyboardType: TextInputType.number,
                onChanged: _onCepChanged,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o CEP.';
                  }
                  final cleanCep = value.replaceAll(RegExp(r'\D'), '');
                  if (cleanCep.length != 8) {
                    return 'CEP deve ter 8 dígitos.';
                  }
                  return null;
                },
              ),
              if (_cepSuggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < _cepSuggestions.length; i++) ...[
                          InkWell(
                            onTap: () => _selectCepSuggestion(_cepSuggestions[i]),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              child: Text(
                                _cepSuggestions[i]['description'] ?? '',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          if (i < _cepSuggestions.length - 1) const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _selectedAddressController,
                decoration: _decoration('Endereço', Icons.location_on),
                enabled: false,
              ),
              if (_selectedLocation != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Latitude: ${_selectedLocation!.latitude.toStringAsFixed(6)}, Longitude: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressDetailsController,
                decoration: _decoration('Número e Complemento', Icons.home),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o número e/ou complemento.';
                  }
                  return null;
                },
              ),
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
