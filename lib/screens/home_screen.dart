import 'package:flutter/material.dart';

import '../models/establishment.dart';
import '../screens/establishment_registration_screen.dart';
import '../services/auth_service.dart';
import '../services/establishment_service.dart';

class HomeScreen extends StatelessWidget {
  final AuthService authService;
  final EstablishmentService establishmentService;

  HomeScreen({
    super.key,
    required this.authService,
    EstablishmentService? establishmentService,
  }) : establishmentService = establishmentService ?? EstablishmentService();

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
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
                        onPressed: () async {
                          await authService.signOut();
                        },
                        tooltip: 'Sair',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Entre na fila sem sair de casa',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, $displayName',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Seu ponto de fila está disponível. Acompanhe o tempo de espera e atualize seu status.',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _StatusBadge(
                              label: 'Fila',
                              value: 'Média',
                              backgroundColor: const Color.fromRGBO(12, 167, 155, 0.12),
                              labelColor: const Color(0xFF0CA79B),
                              valueColor: const Color(0xFF0CA79B),
                            ),
                            const SizedBox(width: 12),
                            _StatusBadge(
                              label: 'Espera',
                              value: '15 min',
                              backgroundColor: const Color.fromRGBO(58, 183, 154, 0.12),
                              labelColor: const Color(0xFF3AB79A),
                              valueColor: const Color(0xFF3AB79A),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Meus estabelecimentos',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0CA79B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Cadastrar'),
                        onPressed: () {
                          if (user != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EstablishmentRegistrationScreen(
                                  adminId: user.uid,
                                  establishmentService: establishmentService,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<List<Establishment>>(
                      stream: establishmentService.watchUserEstablishments(user?.uid ?? ''),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                'Erro ao carregar estabelecimentos: ${snapshot.error}',
                                style: const TextStyle(fontSize: 16, color: Colors.redAccent),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final establishments = snapshot.data ?? [];

                        return ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.zero,
                          children: [
                            if (establishments.isEmpty) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Nenhum estabelecimento cadastrado ainda.',
                                style: TextStyle(fontSize: 16, color: Colors.black54),
                              ),
                              const SizedBox(height: 12),
                            ] else ...establishments.map((est) => _EstablishmentCard(
                                establishment: est,
                                onEdit: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => EstablishmentRegistrationScreen(
                                        adminId: user?.uid ?? '',
                                        establishmentService: establishmentService,
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
                                      content: const Text('Deseja remover este estabelecimento?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(dialogContext).pop(false),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(dialogContext).pop(true),
                                          child: const Text('Remover'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed == true) {
                                    try {
                                      await establishmentService.deleteEstablishment(est.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Estabelecimento removido.')),
                                        );
                                      }
                                    } catch (error) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Erro ao remover: ${error.toString()}')),
                                        );
                                      }
                                    }
                                  }
                                },
                              )),
                            const SizedBox(height: 24),
                            const Text(
                              'Próximo passo',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            _InfoCard(
                              icon: Icons.location_on,
                              title: 'Perto do estabelecimento',
                              description: 'Você está dentro do raio de 50m, pronto para informar a fila.',
                            ),
                            const SizedBox(height: 12),
                            _InfoCard(
                              icon: Icons.update,
                              title: 'Atualize seu status',
                              description: 'Informe o tamanho da fila e tempo de espera para ajudar outros usuários.',
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstablishmentCard extends StatelessWidget {
  final Establishment establishment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EstablishmentCard({
    required this.establishment,
    required this.onEdit,
    required this.onDelete,
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            establishment.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            establishment.address,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _DetailChip(label: 'Capacidade', value: establishment.capacity.toString()),
              const SizedBox(width: 8),
              _DetailChip(label: 'Atendimento', value: establishment.serviceType),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Editar'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0CA79B),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
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
            Text(
              label,
              style: TextStyle(color: labelColor, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(color: valueColor, fontSize: 20, fontWeight: FontWeight.bold),
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
