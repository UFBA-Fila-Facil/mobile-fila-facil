import 'package:flutter/material.dart';

import '../services/queue_service.dart';

class QueueReportScreen extends StatefulWidget {
  final String establishmentId;
  final String? queueId;
  final QueueService queueService;

  const QueueReportScreen({
    super.key,
    required this.establishmentId,
    this.queueId,
    required this.queueService,
  });

  @override
  State<QueueReportScreen> createState() => _QueueReportScreenState();
}

class _QueueReportScreenState extends State<QueueReportScreen> {
  String _perceived = 'Pequeno';
  final TextEditingController _estimatedController = TextEditingController();
  final TextEditingController _waitController = TextEditingController();
  String _serviceSpeed = 'Normal';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _estimatedController.dispose();
    _waitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final perceivedKey = _perceived.toLowerCase();
    int? estimated;
    if (_perceived == 'Estimado') {
      final text = _estimatedController.text.trim();
      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe um número estimado.')),
        );
        setState(() => _isSubmitting = false);
        return;
      }
      estimated = int.tryParse(text);
      if (estimated == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Número estimado inválido.')),
        );
        setState(() => _isSubmitting = false);
        return;
      }
    }

  final waitText = _waitController.text.trim();
  final waitMinutes = int.tryParse(waitText.isEmpty ? '0' : waitText) ?? 0;

    try {
      await widget.queueService.reportQueue(
        establishmentId: widget.establishmentId,
        queueId: widget.queueId,
        perceivedSize: perceivedKey,
        estimatedNumber: estimated,
        waitMinutes: waitMinutes,
        serviceSpeed: _serviceSpeed.toLowerCase(),
      );

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Obrigado!'),
          content: const Text('Seu informe foi registrado anonimamente.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildPerceivedChips() {
    final items = ['Pequeno', 'Médio', 'Grande', 'Estimado'];
    return Wrap(
      spacing: 8,
      children: items.map((label) {
        final selected = _perceived == label;
        return ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) {
            setState(() {
              _perceived = label;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildServiceSpeedChips() {
    final items = ['Rápido', 'Normal', 'Lento'];
    return Wrap(
      spacing: 8,
      children: items.map((label) {
        final selected = _serviceSpeed == label;
        return ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) {
            setState(() => _serviceSpeed = label);
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar fila'),
        backgroundColor: const Color(0xFF0CA79B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tamanho percebido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildPerceivedChips(),
            if (_perceived == 'Estimado') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _estimatedController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número estimado de pessoas',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text('Tempo aproximado de espera (minutos)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _waitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Ex: 15',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Velocidade de atendimento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildServiceSpeedChips(),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0CA79B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Enviar informe'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
