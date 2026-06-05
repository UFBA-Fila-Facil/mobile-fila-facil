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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.establishment;
    if (existing != null) {
      _nameController.text = existing.name;
      _addressController.text = existing.address;
      _capacityController.text = existing.capacity.toString();
      _serviceTypeController.text = existing.serviceType;
    }
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
                decoration: _decoration('Endereço', Icons.location_on),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o endereço.';
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
