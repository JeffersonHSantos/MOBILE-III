import 'package:flutter/material.dart';
import '../../../database/db_helper.dart';
import '../../../services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../backup/screens/backup_screen.dart';
import '../../clients/screens/clients_screen.dart';
import '../../damages/screens/damages_screen.dart';
import '../../filaments/screens/filaments_screen.dart';
import '../../finance/screens/finance_screen.dart';
import '../../pricing/screens/pricing_calculator_screen.dart';
import '../../printers/screens/printers_screen.dart';
import '../../production/screens/production_queue_screen.dart';
import '../../products/screens/products_screen.dart';
import '../../quotes/screens/quotes_screen.dart';
import '../../settings/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _DashboardView(
        user: widget.user,
        onNavigateTab: (idx) => setState(() => _selectedIndex = idx),
      ),
      const PricingCalculatorScreen(),
      const QuotesScreen(),
      const ProductionQueueScreen(),
      const PrintersScreen(),
      const FilamentsScreen(),
      const ClientsScreen(),
      const ProductsScreen(),
      const FinanceScreen(),
      const DamagesScreen(),
      const SettingsScreen(),
      const BackupScreen(),
    ];
  }

  void _fazerLogout() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
                        labelType: NavigationRailLabelType.all,
                        leading: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.view_in_ar_rounded, color: Colors.white),
                          ),
                        ),
                        trailing: Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 12),
                          child: IconButton(
                            tooltip: 'Sair da conta',
                            icon: const Icon(Icons.logout_rounded, color: Colors.red),
                            onPressed: _fazerLogout,
                          ),
                        ),
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.dashboard_outlined),
                            selectedIcon: Icon(Icons.dashboard_rounded),
                            label: Text('Início'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.calculate_outlined),
                            selectedIcon: Icon(Icons.calculate_rounded),
                            label: Text('Precificação'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.request_quote_outlined),
                            selectedIcon: Icon(Icons.request_quote_rounded),
                            label: Text('Orçamentos'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.precision_manufacturing_outlined),
                            selectedIcon: Icon(Icons.precision_manufacturing_rounded),
                            label: Text('Produção'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.print_outlined),
                            selectedIcon: Icon(Icons.print_rounded),
                            label: Text('Impressoras'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.inventory_2_outlined),
                            selectedIcon: Icon(Icons.inventory_2_rounded),
                            label: Text('Estoque'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.people_outline_rounded),
                            selectedIcon: Icon(Icons.people_rounded),
                            label: Text('Clientes'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.view_in_ar_outlined),
                            selectedIcon: Icon(Icons.view_in_ar_rounded),
                            label: Text('Produtos'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.attach_money_rounded),
                            selectedIcon: Icon(Icons.attach_money_rounded),
                            label: Text('Financeiro'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.warning_amber_rounded),
                            selectedIcon: Icon(Icons.warning_rounded),
                            label: Text('Avarias'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.settings_outlined),
                            selectedIcon: Icon(Icons.settings_rounded),
                            label: Text('Config.'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.cloud_sync_outlined),
                            selectedIcon: Icon(Icons.cloud_sync_rounded),
                            label: Text('Backup'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: _pages[_selectedIndex]),
          ],
        ),
      );
    }

    // Layout Mobile com NavigationBar (5 destinos principais + acesso completo pelo Dashboard)
    final mobileIndex = _selectedIndex <= 4 ? _selectedIndex : 0;
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: mobileIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.calculate_outlined), selectedIcon: Icon(Icons.calculate_rounded), label: 'Preço'),
          NavigationDestination(icon: Icon(Icons.request_quote_outlined), selectedIcon: Icon(Icons.request_quote_rounded), label: 'Orçamentos'),
          NavigationDestination(icon: Icon(Icons.precision_manufacturing_outlined), selectedIcon: Icon(Icons.precision_manufacturing_rounded), label: 'Produção'),
          NavigationDestination(icon: Icon(Icons.print_outlined), selectedIcon: Icon(Icons.print_rounded), label: 'Impressoras'),
        ],
      ),
    );
  }
}

class _DashboardView extends StatefulWidget {
  final Map<String, dynamic> user;
  final void Function(int tabIndex) onNavigateTab;

  const _DashboardView({required this.user, required this.onNavigateTab});

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  int _orcamentosPendentes = 0;
  int _filaProducao = 0;
  int _impressorasCount = 0;
  int _clientesCount = 0;

  @override
  void initState() {
    super.initState();
    _carregarContadores();
  }

  Future<void> _carregarContadores() async {
    final vendas = await DbHelper.getAll('vendas');
    final prod = await DbHelper.getAll('historico_producao');
    final imps = await DbHelper.getAll('impressoras');
    final clis = await DbHelper.getAll('clientes');

    if (mounted) {
      setState(() {
        _orcamentosPendentes = vendas.where((v) => v['statusOrcamento'] == 'PENDENTE').length;
        _filaProducao = prod.where((p) => p['status'] == 'AGUARDANDO_IMPRESSAO' || p['status'] == 'IMPRIMINDO').length;
        _impressorasCount = imps.length;
        _clientesCount = clis.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user['nome'] ?? 'Usuário';
    final email = widget.user['email'] ?? 'usuario@exemplo.com';
    final provider = widget.user['provider'] ?? 'local';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Atualizar resumo',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _carregarContadores,
          ),
          IconButton(
            tooltip: 'Sair da conta',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await AuthService.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, $name',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sessão Ativa & Persistência Local',
                            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Conectado via ${provider.toString().toUpperCase()}',
                            style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.of(context).size.width >= 600 ? 4 : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _MetricCard(
                    title: 'Orçamentos Pendentes',
                    value: '$_orcamentosPendentes',
                    badge: 'Aguardando',
                    icon: Icons.request_quote_rounded,
                    color: const Color(0xFFD97706),
                  ),
                  _MetricCard(
                    title: 'Em Produção',
                    value: '$_filaProducao',
                    badge: 'Fila',
                    icon: Icons.precision_manufacturing_rounded,
                    color: const Color(0xFF2563EB),
                  ),
                  _MetricCard(
                    title: 'Impressoras 3D',
                    value: '$_impressorasCount',
                    badge: 'Máquinas',
                    icon: Icons.print_rounded,
                    color: const Color(0xFF059669),
                  ),
                  _MetricCard(
                    title: 'Clientes',
                    value: '$_clientesCount',
                    badge: 'Cadastro',
                    icon: Icons.people_rounded,
                    color: const Color(0xFF7C3AED),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text('Módulos do ERP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _QuickActionTile(
                icon: Icons.calculate_rounded,
                iconBg: const Color(0xFFEEF2FF),
                iconColor: const Color(0xFF4F46E5),
                title: 'Calculadora de Precificação & AMS Multicor',
                subtitle: 'Múltiplos filamentos, insumos, trocas AMS, purga e importação .3MF',
                onTap: () => widget.onNavigateTab(1),
              ),
              _QuickActionTile(
                icon: Icons.print_rounded,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
                title: 'Impressoras 3D & Máquinas',
                subtitle: 'Cadastro de potência (W), preço, vida útil e manutenção/hora',
                onTap: () => widget.onNavigateTab(4),
              ),
              _QuickActionTile(
                icon: Icons.inventory_2_rounded,
                iconBg: const Color(0xFFECFDF5),
                iconColor: const Color(0xFF059669),
                title: 'Estoque de Filamentos & Insumos',
                subtitle: 'Carretéis, insumos, alertas de mínimo e leitor de código de barras',
                onTap: () => widget.onNavigateTab(5),
              ),
              _QuickActionTile(
                icon: Icons.people_rounded,
                iconBg: const Color(0xFFF5F3FF),
                iconColor: const Color(0xFF7C3AED),
                title: 'Cadastro de Clientes',
                subtitle: 'Gerencie clientes, WhatsApp e endereços para orçamentos',
                onTap: () => widget.onNavigateTab(6),
              ),
              _QuickActionTile(
                icon: Icons.view_in_ar_rounded,
                iconBg: const Color(0xFFFFFBEB),
                iconColor: const Color(0xFFD97706),
                title: 'Catálogo de Produtos & Etiquetas',
                subtitle: 'Produtos salvos, prateleira pronta e código de barras Code128',
                onTap: () => widget.onNavigateTab(7),
              ),
              _QuickActionTile(
                icon: Icons.attach_money_rounded,
                iconBg: const Color(0xFFF0FDF4),
                iconColor: const Color(0xFF16A34A),
                title: 'Financeiro, Caixa & ROI',
                subtitle: 'Entradas, saídas, lucro líquido e retorno sobre máquinas',
                onTap: () => widget.onNavigateTab(8),
              ),
              _QuickActionTile(
                icon: Icons.warning_rounded,
                iconBg: const Color(0xFFFEF2F2),
                iconColor: const Color(0xFFDC2626),
                title: 'Gestão de Avarias & Perdas',
                subtitle: 'Baixa avulsa de filamentos (g), insumos ou peças avariadas',
                onTap: () => widget.onNavigateTab(9),
              ),
              _QuickActionTile(
                icon: Icons.settings_rounded,
                iconBg: const Color(0xFFF3F4F6),
                iconColor: const Color(0xFF374151),
                title: 'Configurações Gerais & Taxas',
                subtitle: 'Valor kWh, mão de obra/h, margens, canais e pagamentos',
                onTap: () => widget.onNavigateTab(10),
              ),
              _QuickActionTile(
                icon: Icons.cloud_sync_rounded,
                iconBg: const Color(0xFFEEF2FF),
                iconColor: const Color(0xFF4F46E5),
                title: 'Exportação & Backup JSON',
                subtitle: 'Exporte e compartilhe seu estoque ou restaure backups',
                onTap: () => widget.onNavigateTab(11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        leading: CircleAvatar(backgroundColor: iconBg, child: Icon(icon, color: iconColor)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String badge;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.badge,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 4),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    badge,
                    style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          ),
          Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
