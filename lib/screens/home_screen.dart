import 'dart:async';

import 'package:flutter/material.dart';

import '../models/establishment.dart';
import '../models/queue_model.dart';
import '../models/user_queue_entry.dart';
import '../screens/establishment_registration_screen.dart';
import '../screens/queue_registration_screen.dart';
import '../services/auth_service.dart';
import '../services/establishment_service.dart';
import '../services/queue_service.dart';

class HomeScreen extends StatefulWidget {
  final AuthService authService;
  final EstablishmentService establishmentService;
  final QueueService queueService;

  HomeScreen({
    super.key,
    required this.authService,
    EstablishmentService? establishmentService,
    QueueService? queueService,
  })  : establishmentService = establishmentService ?? EstablishmentService(),
        queueService = queueService ?? QueueService();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Establishment> _searchResults = [];
  bool _isSearchLoading = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() => _isSearchLoading = true);
    final results = await widget.establishmentService.searchEstablishments(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearchLoading = false;
      });
    }
  }

  Future<void> _joinQueue(BuildContext context, Establishment est, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Entrar na fila'),
        content: Text('Deseja entrar na fila de ${est.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await widget.queueService.joinQueue(userId, est.id);
        _searchController.clear();
        if (mounted) setState(() => _searchResults = []);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao entrar na fila: $e')),
          );
        }
      }
    }
  }

  Future<void> _leaveQueue(BuildContext context, String entryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da fila'),
        content: const Text('Deseja sair da fila?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await widget.queueService.leaveQueue(entryId);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao sair da fila: $e')),
          );
        }
      }
    }
  }

  Future<void> _servedQueue(
      BuildContext context, String entryId, String establishmentName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fui atendido'),
        content: const Text('Confirmar que você foi atendido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Color(0xFF0CA79B)),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await widget.queueService.leaveQueue(entryId);
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
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
                      'Conte com o FilaFácil sempre que precisar!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.5,
                      ),
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
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Fechar',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e')),
          );
        }
      }
    }
  }

  Color _getQueueStatusColor(int quantity) {
    if (quantity < 5) return const Color(0xFF4CAF50);
    if (quantity <= 15) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  String _getQueueStatusLabel(int quantity) {
    if (quantity < 5) return 'Baixa';
    if (quantity <= 15) return 'Média';
    return 'Alta';
  }

  Widget _buildSearchContent(BuildContext context, String displayName, String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Olá, $displayName',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Busque um estabelecimento para entrar na fila.',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar por nome ou endereço...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF0CA79B)),
            filled: true,
            fillColor: const Color.fromRGBO(12, 167, 155, 0.07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          onChanged: _onSearchChanged,
        ),
        if (_isSearchLoading) ...[
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(height: 8),
        ] else if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: SingleChildScrollView(
              child: Column(
                children: _searchResults
                    .take(5)
                    .map((est) => _SearchResultItem(
                          establishment: est,
                          queueService: widget.queueService,
                          onTap: () => _joinQueue(context, est, userId),
                        ))
                    .toList(),
              ),
            ),
          ),
        ] else if (_searchController.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Nenhum estabelecimento encontrado.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActiveQueueContent(BuildContext context, UserQueueEntry entry) {
    return StreamBuilder<Establishment?>(
      stream: widget.establishmentService.watchEstablishment(entry.establishmentId),
      builder: (_, estSnapshot) {
        final establishment = estSnapshot.data;
        return StreamBuilder<QueueModel?>(
          stream: widget.queueService.watchQueueForEstablishment(entry.establishmentId),
          builder: (_, queueSnapshot) {
            final queue = queueSnapshot.data;
            final statusColor = queue != null
                ? _getQueueStatusColor(queue.quantityPeople)
                : Colors.grey;
            final statusLabel =
                queue != null ? _getQueueStatusLabel(queue.quantityPeople) : '--';
            final waitTime = queue?.averageWaitingTime ?? 0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Você está na fila',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (establishment != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    establishment.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0CA79B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    establishment.address,
                    style: const TextStyle(fontSize: 13, color: Colors.black45),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    
                    _StatusBadge(
                      label: 'Posição',
                      value: '${entry.position}º',
                      backgroundColor: const Color.fromRGBO(12, 167, 155, 0.12),
                      labelColor: const Color(0xFF0CA79B),
                      valueColor: const Color(0xFF0CA79B),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _StatusBadge(
                      label: 'Fila',
                      value: statusLabel,
                      backgroundColor: statusColor.withValues(alpha: 0.12),
                      labelColor: statusColor,
                      valueColor: statusColor,
                    ),
                    const SizedBox(width: 12),
                    _StatusBadge(
                      label: 'Espera',
                      value: '$waitTime min',
                      backgroundColor: const Color.fromRGBO(12, 167, 155, 0.12),
                      labelColor: const Color(0xFF0CA79B),
                      valueColor: const Color(0xFF0CA79B),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _servedQueue(context, entry.id, establishment?.name ?? 'este estabelecimento'),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Fui atendido'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0CA79B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _leaveQueue(context, entry.id),
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Sair da fila'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;
    final displayName = user?.displayName ?? user?.email ?? 'Usuário';
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F9),
      body: Stack(
        children: [
          Container(
            height: size.height * 0.32,
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
                // Cabeçalho fixo
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'FilaFácil',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white),
                            onPressed: () async => await widget.authService.signOut(),
                            tooltip: 'Sair',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Entre na fila sem sair de casa',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                // Conteúdo rolável
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                          child: StreamBuilder<UserQueueEntry?>(
                            stream: widget.queueService.watchUserActiveQueue(user?.uid ?? ''),
                            builder: (_, queueSnapshot) {
                              final activeEntry = queueSnapshot.data;
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.08),
                                      blurRadius: 24,
                                      offset: Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: activeEntry != null
                                    ? _buildActiveQueueContent(context, activeEntry)
                                    : _buildSearchContent(
                                        context, displayName, user?.uid ?? ''),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Meus estabelecimentos',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              if (user != null)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0CA79B),
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
                                          establishmentService: widget.establishmentService,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              const SizedBox(height: 16),
                              StreamBuilder<List<Establishment>>(
                                stream: widget.establishmentService
                                    .watchUserEstablishments(user?.uid ?? ''),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Text(
                                        'Erro ao carregar estabelecimentos: ${snapshot.error}',
                                        style: const TextStyle(color: Colors.redAccent),
                                      ),
                                    );
                                  }

                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }

                                  final establishments = snapshot.data ?? [];

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (establishments.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 8),
                                          child: Text(
                                            'Nenhum estabelecimento cadastrado ainda.',
                                            style: TextStyle(fontSize: 16, color: Colors.black54),
                                          ),
                                        )
                                      else
                                        ...establishments.map(
                                          (est) => _EstablishmentCard(
                                            establishment: est,
                                            queueService: widget.queueService,
                                            onServed: () async {
                                              final confirmed = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('+1 cliente atendido'),
                                                  content: const Text(
                                                      'Confirmar que um cliente foi atendido? O próximo da fila será chamado.'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(ctx).pop(false),
                                                      child: const Text('Cancelar'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(ctx).pop(true),
                                                      style: TextButton.styleFrom(
                                                        foregroundColor:
                                                            const Color(0xFF0CA79B),
                                                      ),
                                                      child: const Text('Confirmar'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirmed == true) {
                                                try {
                                                  await widget.queueService
                                                      .serveNextCustomer(est.id);
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(SnackBar(
                                                      content: Text('Erro: $e'),
                                                    ));
                                                  }
                                                }
                                              }
                                            },
                                            onEdit: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      EstablishmentRegistrationScreen(
                                                    adminId: user?.uid ?? '',
                                                    establishmentService:
                                                        widget.establishmentService,
                                                    establishment: est,
                                                  ),
                                                ),
                                              );
                                            },
                                            onQueue: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => QueueRegistrationScreen(
                                                    establishment: est,
                                                  ),
                                                ),
                                              );
                                            },
                                            onDelete: () async {
                                              final confirmed = await showDialog<bool>(
                                                context: context,
                                                builder: (dialogContext) => AlertDialog(
                                                  title: const Text('Remover estabelecimento'),
                                                  content: const Text(
                                                      'Deseja remover este estabelecimento?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.of(
                                                              dialogContext)
                                                          .pop(false),
                                                      child: const Text('Cancelar'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () => Navigator.of(
                                                              dialogContext)
                                                          .pop(true),
                                                      child: const Text('Remover'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirmed == true) {
                                                try {
                                                  await widget.establishmentService
                                                      .deleteEstablishment(est.id);
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                              'Estabelecimento removido.')),
                                                    );
                                                  }
                                                } catch (error) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              'Erro ao remover: ${error.toString()}')),
                                                    );
                                                  }
                                                }
                                              }
                                            },
                                            onCustomerArrived: () async {
                                              final confirmed = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('Chegou +1 cliente'),
                                                  content: const Text(
                                                      'Confirmar a chegada de um novo cliente na fila?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(ctx).pop(false),
                                                      child: const Text('Cancelar'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(ctx).pop(true),
                                                      style: TextButton.styleFrom(
                                                        foregroundColor:
                                                            const Color(0xFF0CA79B),
                                                      ),
                                                      child: const Text('Confirmar'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirmed == true) {
                                                try {
                                                  await widget.queueService
                                                      .addCustomerToQueue(est.id);
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(SnackBar(
                                                      content: Text('Erro: $e'),
                                                    ));
                                                  }
                                                }
                                              }
                                            },
                                          ),
                                        ),
                                      const SizedBox(height: 24),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
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

class _SearchResultItem extends StatelessWidget {
  final Establishment establishment;
  final QueueService queueService;
  final VoidCallback onTap;

  const _SearchResultItem({
    required this.establishment,
    required this.queueService,
    required this.onTap,
  });

  Color _getStatusColor(int qty) {
    if (qty < 5) return const Color(0xFF4CAF50);
    if (qty <= 15) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  String _getStatusLabel(int qty) {
    if (qty < 5) return 'Baixa';
    if (qty <= 15) return 'Média';
    return 'Alta';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QueueModel?>(
      stream: queueService.watchQueueForEstablishment(establishment.id),
      builder: (context, snapshot) {
        final queue = snapshot.data;
        final color = queue != null ? _getStatusColor(queue.quantityPeople) : Colors.grey;
        final label = queue != null ? _getStatusLabel(queue.quantityPeople) : '--';

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(12, 167, 155, 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color.fromRGBO(12, 167, 155, 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        establishment.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        establishment.address,
                        style: const TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EstablishmentCard extends StatelessWidget {
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

  Color _getQueueStatusColor(int quantity) {
    if (quantity < 5) return const Color(0xFF4CAF50);
    if (quantity <= 15) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  String _getQueueStatusLabel(int quantity) {
    if (quantity < 5) return 'Baixa';
    if (quantity <= 15) return 'Média';
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
      child: StreamBuilder(
        stream: queueService.watchQueueForEstablishment(establishment.id),
        builder: (context, snapshot) {
          final queue = snapshot.data;
          final statusColor =
              queue != null ? _getQueueStatusColor(queue.quantityPeople) : Colors.grey;
          final statusLabel =
              queue != null ? _getQueueStatusLabel(queue.quantityPeople) : 'Sem dados';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          establishment.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          establishment.address,
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 6),
                        TextButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Editar'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0CA79B),
                            textStyle: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor.withValues(alpha: 0.2),
                        ),
                        child: Center(
                          child: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DetailChip(
                        label: 'Capacidade',
                        value: establishment.capacity.toString()),
                    const SizedBox(width: 8),
                    _DetailChip(
                        label: 'Atendimento', value: establishment.serviceType),
                  ],
                ),
              ),
              if (queue != null) ...[
                const SizedBox(height: 8),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DetailChip(
                          label: 'Pessoas na fila',
                          value: queue.quantityPeople.toString()),
                      const SizedBox(width: 8),
                      _DetailChip(
                          label: 'Tempo esperado',
                          value: '${queue.averageWaitingTime} min'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (queue != null && queue.quantityPeople > 0)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onServed,
                    icon: const Icon(Icons.how_to_reg, size: 18),
                    label: const Text('+1 cliente atendido'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0CA79B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              if (queue != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onCustomerArrived,
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: const Text('Chegou +1 cliente'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0CA79B),
                      side: const BorderSide(color: Color(0xFF0CA79B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: onQueue,
                    icon: const Icon(Icons.queue, size: 18),
                    label: const Text('Fila'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0CA79B),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Remover'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;

  const _DetailChip({required this.label, required this.value});

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

class _StatusBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color backgroundColor;
  final Color labelColor;
  final Color valueColor;

  const _StatusBadge({
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: labelColor, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(12, 167, 155, 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF0CA79B)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
