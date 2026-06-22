import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/establishment.dart';
import '../utils/share_image_helper.dart';
import '../models/queue_model.dart';
import '../screens/establishment_registration_screen.dart';
import '../screens/queue_registration_screen.dart';
import '../services/auth_service.dart';
import '../services/establishment_service.dart';
import '../services/queue_service.dart';

class MyEstablishmentsScreen extends StatelessWidget {
  final AuthService authService;
  final EstablishmentService establishmentService;
  final QueueService queueService;

  const MyEstablishmentsScreen({
    super.key,
    required this.authService,
    required this.establishmentService,
    required this.queueService,
  });

  Future<void> _confirmAndRun(
    BuildContext context, {
    required String title,
    required String content,
    required Future<void> Function() onConfirm,
    String? successMessage,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF0CA79B)),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await onConfirm();
        if (successMessage != null && context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(successMessage)));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Erro: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F9),
      body: Stack(
        children: [
          Container(
            height: size.height * 0.22,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0CA79B), Color(0xFF0A887E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: const Text(
                    'Meus estabelecimentos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user != null)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0CA79B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Cadastrar'),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => EstablishmentRegistrationScreen(
                                    adminId: user.uid,
                                    establishmentService: establishmentService,
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 16),
                        StreamBuilder<List<Establishment>>(
                          stream: establishmentService
                              .watchUserEstablishments(user?.uid ?? ''),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Erro ao carregar: ${snapshot.error}',
                                  style: const TextStyle(color: Colors.redAccent),
                                ),
                              );
                            }
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final all = snapshot.data ?? [];

                            if (all.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Nenhum estabelecimento cadastrado ainda.',
                                  style: TextStyle(fontSize: 16, color: Colors.black54),
                                ),
                              );
                            }

                            return Column(
                              children: all
                                  .map((est) => _EstablishmentCard(
                                        establishment: est,
                                        queueService: queueService,
                                        onServed: () => _confirmAndRun(
                                          context,
                                          title: '+1 cliente atendido',
                                          content:
                                              'Confirmar que um cliente foi atendido? O próximo da fila será chamado.',
                                          onConfirm: () =>
                                              queueService.serveNextCustomer(est.id),
                                        ),
                                        onEdit: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                EstablishmentRegistrationScreen(
                                              adminId: user?.uid ?? '',
                                              establishmentService: establishmentService,
                                              establishment: est,
                                            ),
                                          ),
                                        ),
                                        onQueue: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => QueueRegistrationScreen(
                                                establishment: est),
                                          ),
                                        ),
                                        onDelete: () => _confirmAndRun(
                                          context,
                                          title: 'Remover estabelecimento',
                                          content:
                                              'Deseja remover este estabelecimento?',
                                          onConfirm: () => establishmentService
                                              .deleteEstablishment(est.id),
                                          successMessage: 'Estabelecimento removido.',
                                        ),
                                        onCustomerArrived: () => _confirmAndRun(
                                          context,
                                          title: 'Chegou +1 cliente',
                                          content:
                                              'Confirmar a chegada de um novo cliente na fila?',
                                          onConfirm: () =>
                                              queueService.addCustomerToQueue(est.id),
                                        ),
                                      ))
                                  .toList(),
                            );
                          },
                        ),
                      ],
                    ),
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

class _EstablishmentCard extends StatefulWidget {
  final Establishment establishment;
  final QueueService queueService;
  final VoidCallback onEdit;
  final VoidCallback onQueue;
  final VoidCallback onDelete;
  final VoidCallback onServed;
  final VoidCallback onCustomerArrived;

  const _EstablishmentCard({
    required this.establishment,
    required this.queueService,
    required this.onEdit,
    required this.onQueue,
    required this.onDelete,
    required this.onServed,
    required this.onCustomerArrived,
  });

  @override
  State<_EstablishmentCard> createState() => _EstablishmentCardState();
}

class _EstablishmentCardState extends State<_EstablishmentCard> {
  bool _expanded = false;

  Color _statusColor(int qty) {
    if (qty < 5) return const Color(0xFF4CAF50);
    if (qty <= 15) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  String _statusLabel(int qty) {
    if (qty < 5) return 'Baixa';
    if (qty <= 15) return 'Média';
    return 'Alta';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: StreamBuilder<QueueModel?>(
        stream: widget.queueService
            .watchQueueForEstablishment(widget.establishment.id),
        builder: (context, snapshot) {
          final queue = snapshot.data;
          final color =
              queue != null ? _statusColor(queue.quantityPeople) : Colors.grey;
          final label =
              queue != null ? _statusLabel(queue.quantityPeople) : 'Sem dados';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho do card (sempre visível)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.establishment.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.establishment.address,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _expanded = !_expanded),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Veja o detalhe',
                                style: TextStyle(
                                  color: Color(0xFF0CA79B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              AnimatedRotation(
                                turns: _expanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFF0CA79B),
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.share_outlined,
                                color: Colors.black45),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (_) => _QrShareDialog(
                                establishmentId: widget.establishment.id,
                                establishmentName: widget.establishment.name,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                color: Colors.black45),
                            padding: EdgeInsets.zero,
                            onSelected: (value) {
                              if (value == 'fila') {
                                widget.onQueue();
                              } else if (value == 'editar') {
                                widget.onEdit();
                              } else if (value == 'remover') {
                                widget.onDelete();
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'fila',
                                child: Text('Alterar Fila'),
                              ),
                              PopupMenuItem(
                                value: 'editar',
                                child: Text('Editar Estabelecimento'),
                              ),
                              PopupMenuItem(
                                value: 'remover',
                                child: Text('Remover'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.2),
                        ),
                        child: Center(
                          child: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Seção colapsável (editar + chips)
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: _expanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _Chip(
                                    label: 'Capacidade',
                                    value: widget.establishment.capacity
                                        .toString()),
                                const SizedBox(width: 8),
                                _Chip(
                                    label: 'Atendimento',
                                    value: widget.establishment.serviceType),
                              ],
                            ),
                          ),
                          if (queue != null) ...[
                            const SizedBox(height: 8),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _Chip(
                                      label: 'Pessoas na fila',
                                      value:
                                          queue.quantityPeople.toString()),
                                  const SizedBox(width: 8),
                                  _Chip(
                                      label: 'Tempo esperado',
                                      value:
                                          '${queue.averageWaitingTime} min'),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              // Botões de ação (sempre visíveis)
              const SizedBox(height: 4),
              if (queue != null && queue.quantityPeople > 0)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onServed,
                    icon: const Icon(Icons.how_to_reg, size: 18),
                    label: const Text('+1 cliente atendido'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0CA79B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              if (queue != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.onCustomerArrived,
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: const Text('Chegou +1 cliente'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0CA79B),
                      side: const BorderSide(color: Color(0xFF0CA79B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;

  const _Chip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(12, 167, 155, 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          '$label: $value',
          style: const TextStyle(fontSize: 13, color: Color(0xFF0A887E)),
        ),
      ),
    );
  }
}

class _QrShareDialog extends StatefulWidget {
  final String establishmentId;
  final String establishmentName;

  const _QrShareDialog({
    required this.establishmentId,
    required this.establishmentName,
  });

  @override
  State<_QrShareDialog> createState() => _QrShareDialogState();
}

class _QrShareDialogState extends State<_QrShareDialog> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _sharing = false;

  String get _deepLink =>
      'filafacil:/join-queue?establishmentId=${widget.establishmentId}';

  Future<void> _shareQr() async {
    setState(() => _sharing = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      await shareImageBytes(
        Uint8List.view(byteData.buffer),
        'qrcode_${widget.establishmentId}.png',
        'Entre na fila de ${widget.establishmentName}',
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _repaintKey,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.08),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0CA79B), Color(0xFF0A887E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.establishmentName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Escaneie para entrar na fila',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: QrImageView(
                        data: _deepLink,
                        version: QrVersions.auto,
                        size: 200,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Fila Fácil',
                        style: TextStyle(
                          color: Color(0xFF0CA79B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sharing ? null : _shareQr,
                icon: _sharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.share_rounded),
                label: Text(_sharing ? 'Preparando...' : 'Compartilhar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0CA79B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle:
                      const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
