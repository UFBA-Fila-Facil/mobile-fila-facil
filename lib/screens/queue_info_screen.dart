import 'package:flutter/material.dart';

import '../models/establishment.dart';
import '../services/queue_service.dart';

class QueueInfoScreen extends StatefulWidget {
  final Establishment establishment;
  final QueueService queueService;

  QueueInfoScreen({
    super.key,
    required this.establishment,
    QueueService? queueService,
  }) : queueService = queueService ?? QueueService();

  @override
  State<QueueInfoScreen> createState() => _QueueInfoScreenState();
}

class _QueueInfoScreenState extends State<QueueInfoScreen> {
  String _perceivedSize = 'Médio'; // Pequeno, Médio, Grande, Estimado
  int? _estimatedSize; 
  int? _waitMinutes;
  String _serviceSpeed = 'Normal'; // Rápido, Normal, Lento
  bool _loading = false;

  Future<void> _submit() async {
    setState(() { _loading = true; });
    try {
      final int? queueSizeToSend = _perceivedSize == 'Estimado' ? _estimatedSize : null;
      final perceivedLabel = _perceivedSize;

      await widget.queueService.reportQueue(
        establishmentId: widget.establishment.id,
        queueSize: queueSizeToSend,
        waitMinutes: _waitMinutes,
        serviceSpeed: _serviceSpeed,
        perceivedSize: perceivedLabel,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Relatório enviado. Obrigado pela contribuição.')));
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Informar fila - ${widget.establishment.name}'),
        backgroundColor: const Color(0xFF0CA79B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Como você percebe a fila?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Pequeno'),
                    selected: _perceivedSize == 'Pequeno',
                    onSelected: (_) => setState(() { _perceivedSize = 'Pequeno'; _estimatedSize = null; }),
                  ),
                  ChoiceChip(
                    label: const Text('Médio'),
                    selected: _perceivedSize == 'Médio',
                    onSelected: (_) => setState(() { _perceivedSize = 'Médio'; _estimatedSize = null; }),
                  ),
                  ChoiceChip(
                    label: const Text('Grande'),
                    selected: _perceivedSize == 'Grande',
                    onSelected: (_) => setState(() { _perceivedSize = 'Grande'; _estimatedSize = null; }),
                  ),
                  ChoiceChip(
                    label: const Text('Estimado'),
                    selected: _perceivedSize == 'Estimado',
                    onSelected: (_) => setState(() { _perceivedSize = 'Estimado'; }),
                  ),
                ],
              ),
              if (_perceivedSize == 'Estimado') ...[
                const SizedBox(height: 12),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Estimativa de pessoas', border: OutlineInputBorder()),
                  onChanged: (v) => _estimatedSize = int.tryParse(v),
                ),
              ],
              const SizedBox(height: 16),
              const Text('Tempo aproximado de espera (minutos)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Ex: 15', border: OutlineInputBorder()),
                onChanged: (v) => _waitMinutes = int.tryParse(v),
              ),
              const SizedBox(height: 16),
              const Text('Velocidade de atendimento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Rápido'),
                    selected: _serviceSpeed == 'Rápido',
                    onSelected: (_) => setState(() { _serviceSpeed = 'Rápido'; }),
                  ),
                  ChoiceChip(
                    label: const Text('Normal'),
                    selected: _serviceSpeed == 'Normal',
                    onSelected: (_) => setState(() { _serviceSpeed = 'Normal'; }),
                  ),
                  ChoiceChip(
                    label: const Text('Lento'),
                    selected: _serviceSpeed == 'Lento',
                    onSelected: (_) => setState(() { _serviceSpeed = 'Lento'; }),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0CA79B)),
                  onPressed: _loading ? null : _submit,
                  child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Enviar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
