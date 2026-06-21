import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_actions_handler.dart';

class DeepLinkHandler {
  final GlobalKey<NavigatorState> navigatorKey;
  final AppActionsHandler _actions;

  DeepLinkHandler({
    required this.navigatorKey,
    AppActionsHandler? actionsHandler,
  }) : _actions = actionsHandler ?? AppActionsHandler();

  // ── ponto de entrada ────────────────────────────────────────────────────

  Future<void> handleUri(Uri uri) async {
    final context = navigatorKey.currentState?.context;
    if (context == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await _showStyledDialog(
        context,
        icon: Icons.lock_outline_rounded,
        iconColor: Colors.blueGrey,
        title: 'Login necessário',
        message: 'Faça login no Fila Fácil para usar os atalhos de fila.',
      );
      return;
    }

    String path = uri.path;
    print('Deep link recebido: $path');
    
    switch (uri.path) {
      case '/serve-customer':
        await _handleServeCustomer(context, uri, user.uid);
      case '/customer-arrived':
        await _handleCustomerArrived(context, uri, user.uid);
      case '/leave-queue':
        await _handleUserQueueAction(context, user.uid, served: false);
      case '/served':
        await _handleUserQueueAction(context, user.uid, served: true);
      default:
        await _handleLegacyUpdateQueue(context, uri, user);
    }
  }

  // ── handlers de ação ────────────────────────────────────────────────────

  Future<void> _handleServeCustomer(
      BuildContext context, Uri uri, String userId) async {
    final params = uri.queryParameters;
    final estId = _notEmpty(params['establishmentId']);
    final estName = _notEmpty(params['establishmentName'] ?? params['name']);

    if (estId == null && estName == null) {
      await _showStyledDialog(
        context,
        icon: Icons.error_outline_rounded,
        iconColor: Colors.orange,
        title: 'Link incompleto',
        message: 'O link não informou qual estabelecimento deve atender o cliente. '
            'Verifique o link e tente novamente.',
      );
      return;
    }

    final establishment = await _actions.findUserEstablishment(
      userId: userId,
      establishmentId: estId,
      establishmentName: estName,
    );
    if (!context.mounted) return;

    if (establishment == null) {
      await _showEstablishmentNotFoundDialog(context, estName ?? estId ?? '');
      return;
    }

    final confirmed = await _showConfirmDialog(
      context,
      title: '+1 cliente atendido',
      message: 'Confirmar que um cliente foi atendido em ${establishment.name}? '
          'O próximo da fila será chamado.',
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await _actions.serveNextCustomer(establishment.id);
      if (context.mounted) {
        await _showStyledDialog(
          context,
          icon: Icons.how_to_reg_rounded,
          iconColor: const Color(0xFF0CA79B),
          title: 'Cliente atendido!',
          message: 'O próximo da fila de ${establishment.name} foi chamado.',
        );
      }
    } catch (e) {
      if (context.mounted) await _showErrorDialog(context);
    }
  }

  Future<void> _handleCustomerArrived(
      BuildContext context, Uri uri, String userId) async {
    final params = uri.queryParameters;
    final estId = _notEmpty(params['establishmentId']);
    final estName = _notEmpty(params['establishmentName'] ?? params['name']);

    if (estId == null && estName == null) {
      await _showStyledDialog(
        context,
        icon: Icons.error_outline_rounded,
        iconColor: Colors.orange,
        title: 'Link incompleto',
        message: 'O link não informou qual estabelecimento recebeu o cliente. '
            'Verifique o link e tente novamente.',
      );
      return;
    }

    final establishment = await _actions.findUserEstablishment(
      userId: userId,
      establishmentId: estId,
      establishmentName: estName,
    );
    if (!context.mounted) return;

    if (establishment == null) {
      await _showEstablishmentNotFoundDialog(context, estName ?? estId ?? '');
      return;
    }

    final confirmed = await _showConfirmDialog(
      context,
      title: 'Chegou +1 cliente',
      message: 'Confirmar a chegada de um novo cliente em ${establishment.name}?',
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await _actions.addCustomerToQueue(establishment.id);
      if (context.mounted) {
        await _showStyledDialog(
          context,
          icon: Icons.person_add_rounded,
          iconColor: const Color(0xFF0CA79B),
          title: 'Cliente registrado!',
          message: 'Um novo cliente foi adicionado à fila de ${establishment.name}.',
        );
      }
    } catch (e) {
      if (context.mounted) await _showErrorDialog(context);
    }
  }

  Future<void> _handleUserQueueAction(
    BuildContext context,
    String userId, {
    required bool served,
  }) async {
    final entry = await _actions.getUserActiveEntry(userId);
    if (!context.mounted) return;

    if (entry == null) {
      await _showStyledDialog(
        context,
        icon: Icons.info_outline_rounded,
        iconColor: Colors.blueGrey,
        title: 'Você não está em nenhuma fila',
        message: 'Para usar este recurso, entre em uma fila pelo aplicativo Fila Fácil.',
      );
      return;
    }

    final establishment = await _actions.getEstablishmentById(entry.establishmentId);
    if (!context.mounted) return;
    final estName = establishment?.name ?? 'este estabelecimento';

    final confirmed = await _showConfirmDialog(
      context,
      title: served ? 'Fui atendido' : 'Sair da fila',
      message: served
          ? 'Confirmar que você foi atendido em $estName?'
          : 'Confirmar que você deseja sair da fila de $estName?',
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await _actions.leaveQueue(entry.id);
      if (context.mounted) {
        if (served) {
          await _showThankYouDialog(context, estName);
        } else {
          await _showStyledDialog(
            context,
            icon: Icons.exit_to_app_rounded,
            iconColor: Colors.blueGrey,
            title: 'Você saiu da fila',
            message: 'Sua posição em $estName foi liberada. Até a próxima!',
          );
        }
      }
    } catch (e) {
      if (context.mounted) await _showErrorDialog(context);
    }
  }

  Future<void> _handleLegacyUpdateQueue(
      BuildContext context, Uri uri, User user) async {
    final params = uri.queryParameters;
    final establishmentName = params['establishmentName'] ?? params['name'];
    final quantity = _parseInt(params['quantity'] ?? params['quantityPeople']);
    final wait = _parseInt(params['wait'] ?? params['averageWaitTime']);

    if ((quantity == null && wait == null) ||
        establishmentName == null ||
        establishmentName.isEmpty) {
      await _showStyledDialog(
        context,
        icon: Icons.error_outline_rounded,
        iconColor: Colors.orange,
        title: 'Parâmetros inválidos',
        message: 'O link deve informar o nome do estabelecimento e pelo menos '
            'a quantidade de pessoas ou o tempo médio de espera.',
      );
      return;
    }

    final establishment = await _actions.findUserEstablishment(
      userId: user.uid,
      establishmentName: establishmentName,
    );
    if (!context.mounted) return;

    if (establishment == null) {
      await _showEstablishmentNotFoundDialog(context, establishmentName);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar alteração de fila'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estabelecimento: ${establishment.name}'),
            if (quantity != null) Text('Quantidade de pessoas: $quantity'),
            if (wait != null) Text('Tempo médio de espera: $wait minutos'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final result = await _actions.updateQueue(
        establishmentId: establishment.id,
        quantityPeople: quantity,
        averageWaitTime: wait,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
      }
    } catch (e) {
      if (context.mounted) await _showErrorDialog(context);
    }
  }

  // ── diálogos ────────────────────────────────────────────────────────────

  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
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
  }

  Future<void> _showEstablishmentNotFoundDialog(
      BuildContext context, String searched) {
    return _showStyledDialog(
      context,
      icon: Icons.search_off_rounded,
      iconColor: Colors.orange,
      title: 'Estabelecimento não encontrado',
      message: 'Não encontramos "$searched" entre os seus estabelecimentos. '
          'Verifique o link e tente novamente.',
    );
  }

  Future<void> _showErrorDialog(BuildContext context) {
    return _showStyledDialog(
      context,
      icon: Icons.error_outline_rounded,
      iconColor: Colors.redAccent,
      title: 'Erro ao executar ação',
      message: 'Algo deu errado. Tente novamente ou abra o aplicativo.',
    );
  }

  Future<void> _showStyledDialog(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.12),
                ),
                child: Icon(icon, color: iconColor, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0CA79B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Fechar',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showThankYouDialog(BuildContext context, String establishmentName) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.fromRGBO(12, 167, 155, 0.12),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF0CA79B),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Obrigado pela visita!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0CA79B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ficamos felizes em ter facilitado sua visita a $establishmentName. '
                'Conte com o Fila Fácil sempre que precisar!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0CA79B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Fechar',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── utilitários ─────────────────────────────────────────────────────────

  String? _notEmpty(String? value) =>
      (value == null || value.isEmpty) ? null : value;

  int? _parseInt(String? value) {
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }
}
