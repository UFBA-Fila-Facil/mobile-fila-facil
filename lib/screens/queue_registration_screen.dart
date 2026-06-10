import 'package:flutter/material.dart';

import '../models/establishment.dart';
import '../models/queue_model.dart';
import '../services/queue_service.dart';

class QueueRegistrationScreen extends StatefulWidget {
  final Establishment establishment;
  final QueueService queueService;
  final QueueModel? queue;

  QueueRegistrationScreen({
    super.key,
    required this.establishment,
    QueueService? queueService,
    this.queue,
  }) : queueService = queueService ?? QueueService();

  @override
  State<QueueRegistrationScreen> createState() => _QueueRegistrationScreenState();
}

class _QueueRegistrationScreenState extends State<QueueRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _averageTimeController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  bool _isLoading = false;

  bool get _isEditing => widget.queue != null;

  @override
  void initState() {
    super.initState();
    final queue = widget.queue;
    if (queue != null) {
      _quantityController.text = queue.quantityPeople.toString();
      _averageTimeController.text = queue.averageWaitingTime.toString();
      _serviceTypeController.text = queue.serviceType;
    } else {
      _serviceTypeController.text = widget.establishment.serviceType;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _averageTimeController.dispose();
    _serviceTypeController.dispose();
    super.dispose();
  }

  Future<void> _saveQueue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final queue = QueueModel(
        id: widget.queue?.id ?? '',
        establishmentId: widget.establishment.id,
        quantityPeople: int.parse(_quantityController.text.trim()),
        averageWaitingTime: int.parse(_averageTimeController.text.trim()),
        serviceType: _serviceTypeController.text.trim(),
        active: true,
      );

      if (_isEditing) {
        await widget.queueService.updateQueue(queue);
      } else {
        await widget.queueService.addQueue(queue);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao salvar fila: ${error.toString()}')),
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
        title: Text(_isEditing ? 'Editar fila' : 'Registrar fila'),
        backgroundColor: const Color(0xFF0CA79B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.establishment.name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.establishment.address,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: _decoration('Quantidade de pessoas na fila', Icons.people),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a quantidade de pessoas.';
                  }
                  final number = int.tryParse(value.trim());
                  if (number == null || number < 0) {
                    return 'Informe um número válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _averageTimeController,
                keyboardType: TextInputType.number,
                decoration: _decoration('Tempo médio de espera (min)', Icons.access_time),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o tempo médio de espera.';
                  }
                  final number = int.tryParse(value.trim());
                  if (number == null || number < 0) {
                    return 'Informe um número válido.';
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
                onPressed: _isLoading ? null : _saveQueue,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEditing ? 'Salvar alterações' : 'Salvar fila'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
