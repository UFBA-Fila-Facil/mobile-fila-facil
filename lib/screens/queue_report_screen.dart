import 'package:flutter/material.dart';

import '../services/queue_service.dart';

class QueueReportScreen extends StatefulWidget {
  final QueueService queueService;
  final String queueId;
  final String establishmentId;

  const QueueReportScreen({
    super.key,
    required this.queueService,
    required this.queueId,
    required this.establishmentId,
  });

  @override
  State<QueueReportScreen> createState() => _QueueReportScreenState();
}

class _QueueReportScreenState extends State<QueueReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _waitTimeController = TextEditingController();
  final _estimatedCountController = TextEditingController();

  String? _selectedSize;
  String? _selectedSpeed;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _waitTimeController.dispose();
    _estimatedCountController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSpeed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a velocidade de atendimento.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final estimatedCount = _selectedSize == 'estimada'
          ? int.tryParse(_estimatedCountController.text.trim())
          : null;

      if (_selectedSize == 'estimada' && (estimatedCount == null || estimatedCount < 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe uma estimativa válida de pessoas na fila.')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      await widget.queueService.submitQueueReport(
        queueId: widget.queueId,
        establishmentId: widget.establishmentId,
        perceivedSize: _selectedSize ?? '',
        estimatedWaitTime: int.parse(_waitTimeController.text.trim()),
        serviceSpeed: _selectedSpeed!,
        estimatedCount: estimatedCount,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Relato enviado com sucesso.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível enviar o relato: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar fila'),
        backgroundColor: const Color(0xFF0CA79B),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contribua com o estado atual da fila',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Seu relato é anônimo e ajuda a manter a fila mais precisa para todos.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  value: _selectedSize,
                  decoration: const InputDecoration(
                    labelText: 'Tamanho percebido da fila',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pequena', child: Text('Pequena')),
                    DropdownMenuItem(value: 'média', child: Text('Média')),
                    DropdownMenuItem(value: 'grande', child: Text('Grande')),
                    DropdownMenuItem(value: 'estimada', child: Text('Estimada')),
                  ],
                  onChanged: (value) => setState(() => _selectedSize = value),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe o tamanho percebido da fila.';
                    }
                    return null;
                  },
                ),
                if (_selectedSize == 'estimada') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _estimatedCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantas pessoas estão na fila?',
                      hintText: 'Ex.: 12',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe uma estimativa válida.';
                      }
                      final parsed = int.tryParse(value.trim());
                      if (parsed == null || parsed < 0) {
                        return 'Use apenas números inteiros positivos.';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _waitTimeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tempo aproximado de espera (minutos)',
                    hintText: 'Ex.: 12',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o tempo aproximado de espera.';
                    }
                    final parsed = int.tryParse(value.trim());
                    if (parsed == null || parsed < 0) {
                      return 'Use apenas números inteiros positivos.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedSpeed,
                  decoration: const InputDecoration(
                    labelText: 'Velocidade de atendimento',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'rápido', child: Text('Rápido')),
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'lento', child: Text('Lento')),
                  ],
                  onChanged: (value) => setState(() => _selectedSpeed = value),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Selecione a velocidade de atendimento.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitReport,
                    icon: const Icon(Icons.send_rounded),
                    label: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Enviar relato anônimo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0CA79B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
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
