import 'package:flutter/material.dart';
import 'models/usuario.dart';
import 'screens/explorar_screen.dart';
import 'screens/login_screen.dart';
import 'screens/mapa_radar_screen.dart';
import 'screens/parceiros_screen.dart';
import 'services/api_service.dart';
import 'theme/app_themes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RedeSocialMapaApp());
}

class RedeSocialMapaApp extends StatefulWidget {
  final ApiService? apiService;

  const RedeSocialMapaApp({
    super.key,
    this.apiService,
  });

  @override
  State<RedeSocialMapaApp> createState() => _RedeSocialMapaAppState();
}

class _RedeSocialMapaAppState extends State<RedeSocialMapaApp> {
  AppThemeKey _temaAtual = AppThemeKey.floresta;

  @override
  Widget build(BuildContext context) {
    final opcaoTema = AppThemes.porChave(_temaAtual);

    return MaterialApp(
      title: 'Rede Social Mapa',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.construirTema(opcaoTema),
      home: RedeSocialHomeShell(
        apiService: widget.apiService,
        temaAtual: opcaoTema,
        onTemaChanged: (novoTema) {
          setState(() => _temaAtual = novoTema);
        },
      ),
    );
  }
}

class RedeSocialHomeShell extends StatefulWidget {
  final ApiService? apiService;
  final AppThemeOption temaAtual;
  final ValueChanged<AppThemeKey> onTemaChanged;

  const RedeSocialHomeShell({
    super.key,
    this.apiService,
    required this.temaAtual,
    required this.onTemaChanged,
  });

  @override
  State<RedeSocialHomeShell> createState() => _RedeSocialHomeShellState();
}

class _RedeSocialHomeShellState extends State<RedeSocialHomeShell> {
  late final ApiService _api;
  int _abaSelecionada = 0;
  int _refreshToken = 0;
  ContaUsuario? _usuarioAtual;

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? ApiService();
    _restaurarSessao();
  }

  Future<void> _restaurarSessao() async {
    final token = await _api.carregarTokenSalvo();
    final usuario = await _api.carregarUsuarioSalvo();
    if (token != null && usuario != null && mounted) {
      setState(() {
        _usuarioAtual = usuario;
      });
    }
  }

  void _forcarAtualizacao() {
    setState(() => _refreshToken++);
  }

  Future<void> _confirmarSaida() async {
    final confirmar = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Encerrar Sessão',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Deseja realmente sair da conta de ${_usuarioAtual?.nome ?? "Morador"}?',
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'Sim, sair da conta',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );

    if (confirmar == true && mounted) {
      setState(() {
        _usuarioAtual = null;
        _abaSelecionada = 0;
      });
      _api.limparAutenticacao();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sessão encerrada com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _tratarTrocaDeAba(int idx) {
    if (idx == 3 && _usuarioAtual != null) {
      _confirmarSaida();
      return;
    }
    setState(() => _abaSelecionada = idx);
  }

  @override
  Widget build(BuildContext context) {
    final paginas = <Widget>[
      ExplorarScreen(
        api: _api,
        tema: widget.temaAtual,
        refreshToken: _refreshToken,
        onUsuarioChanged: (novoUsuario) {
          setState(() => _usuarioAtual = novoUsuario);
        },
      ),
      MapaRadarScreen(
        api: _api,
        tema: widget.temaAtual,
        refreshToken: _refreshToken,
        onUsuarioChanged: (novoUsuario) {
          setState(() => _usuarioAtual = novoUsuario);
        },
      ),
      ParceirosScreen(
        api: _api,
        tema: widget.temaAtual,
        refreshToken: _refreshToken,
      ),
      LoginScreen(
        api: _api,
        tema: widget.temaAtual,
        usuarioAtual: _usuarioAtual,
        onUsuarioChanged: (novoUsuario) {
          setState(() => _usuarioAtual = novoUsuario);
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.temaAtual.seedColor,
                    widget.temaAtual.secondaryColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Text('🗺️', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Rede Social Mapa',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Zeladoria · Tema ${widget.temaAtual.nome}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Seletor dos 4 Temas da plataforma no topo do app
          _SeletorTemasTopBar(
            temaAtual: widget.temaAtual,
            onSelected: widget.onTemaChanged,
          ),
          IconButton(
            onPressed: _forcarAtualizacao,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Atualizar dados',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
        ),
      ),
      body: IndexedStack(
        index: _abaSelecionada,
        children: paginas,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _abaSelecionada,
        onDestinationSelected: _tratarTrocaDeAba,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Explorar',
          ),
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Mapa Radar',
          ),
          const NavigationDestination(
            icon: Icon(Icons.workspace_premium_outlined),
            selectedIcon: Icon(Icons.workspace_premium_rounded),
            label: 'Parceiros',
          ),
          NavigationDestination(
            icon: Icon(
              _usuarioAtual != null
                  ? Icons.logout_rounded
                  : Icons.person_outline_rounded,
            ),
            selectedIcon: Icon(
              _usuarioAtual != null
                  ? Icons.logout_rounded
                  : Icons.person_rounded,
            ),
            label: _usuarioAtual != null ? 'Sair' : 'Entrar',
          ),
        ],
      ),
    );
  }
}

class _SeletorTemasTopBar extends StatelessWidget {
  final AppThemeOption temaAtual;
  final ValueChanged<AppThemeKey> onSelected;

  const _SeletorTemasTopBar({
    required this.temaAtual,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final larguraTela = MediaQuery.sizeOf(context).width;
    final exibirTextoNoChip = larguraTela >= 480;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: ShapeDecoration(
        color: const Color(0xFFF1F5F9),
        shape: const StadiumBorder(),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: AppThemes.opcoes.map((opcao) {
          final ativo = opcao.key == temaAtual.key;
          return Tooltip(
            message: 'Tema ${opcao.nome}',
            child: GestureDetector(
              key: ValueKey('tema_${opcao.key.name}'),
              onTap: () => onSelected(opcao.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: EdgeInsets.symmetric(
                  horizontal: (ativo && exibirTextoNoChip) ? 8 : 4,
                  vertical: 4,
                ),
                decoration: ShapeDecoration(
                  color: ativo ? opcao.seedColor : Colors.transparent,
                  shape: const StadiumBorder(),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: ativo && !exibirTextoNoChip ? 14 : 12,
                      height: ativo && !exibirTextoNoChip ? 14 : 12,
                      decoration: BoxDecoration(
                        color: ativo && exibirTextoNoChip
                            ? Colors.white
                            : opcao.seedColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: ativo ? 2.0 : 1.5,
                        ),
                      ),
                      child: (ativo && !exibirTextoNoChip)
                          ? const Icon(
                              Icons.check_rounded,
                              size: 9,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    if (ativo && exibirTextoNoChip) ...[
                      const SizedBox(width: 5),
                      Text(
                        opcao.nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
