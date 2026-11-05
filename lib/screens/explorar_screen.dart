import 'package:flutter/material.dart';
import '../models/anuncio.dart';
import '../models/evento.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../theme/app_themes.dart';
import '../widgets/evento_card.dart';
import '../widgets/evento_detalhe_sheet.dart';

class ExplorarScreen extends StatefulWidget {
  final ApiService api;
  final AppThemeOption tema;
  final int refreshToken;
  final ValueChanged<ContaUsuario?>? onUsuarioChanged;

  const ExplorarScreen({
    super.key,
    required this.api,
    required this.tema,
    this.refreshToken = 0,
    this.onUsuarioChanged,
  });

  @override
  State<ExplorarScreen> createState() => _ExplorarScreenState();
}

class _ExplorarScreenState extends State<ExplorarScreen> {
  String _categoriaSelecionada = '';
  String? _ufSelecionada;
  bool _incluirResolvidos = false;
  late Future<List<Evento>> _futuroEventos;
  List<Estado> _estados = const [];

  @override
  void initState() {
    super.initState();
    _carregarEventos();
    _carregarEstados();
  }

  @override
  void didUpdateWidget(covariant ExplorarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      setState(_carregarEventos);
    }
  }

  void _carregarEventos() {
    _futuroEventos = widget.api.listarEventos(
      categoria: _categoriaSelecionada.isEmpty ? null : _categoriaSelecionada,
      estado: _ufSelecionada,
      incluirResolvidos: _incluirResolvidos,
    );
  }

  Future<void> _carregarEstados() async {
    try {
      final lista = await widget.api.listarEstados();
      if (mounted) {
        setState(() => _estados = lista);
      }
    } catch (_) {
      // Silencioso caso a API de estados esteja indisponível no momento
    }
  }

  void _selecionarCategoria(String slug) {
    setState(() {
      _categoriaSelecionada = slug;
      _carregarEventos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Evento>>(
      future: _futuroEventos,
      builder: (context, snapshot) {
        final eventos = snapshot.data ?? const [];
        final totalRelatos = eventos.length;
        final totalApoios =
            eventos.fold<int>(0, (acc, item) => acc + item.curtidas);
        final totalAcao = eventos
            .where((e) => e.status != 'novo')
            .length;

        return RefreshIndicator(
          onRefresh: () async {
            setState(_carregarEventos);
            await _futuroEventos;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header em degradê com estatísticas rápidas
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.tema.seedColor,
                          widget.tema.secondaryColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: widget.tema.seedColor.withValues(alpha: 0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: ShapeDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: const StadiumBorder(),
                                ),
                                child: const Text(
                                  '🏙️ Termômetro Urbano',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_estados.isNotEmpty)
                              _SeletorUfChip(
                                estados: _estados,
                                ufAtual: _ufSelecionada,
                                onChanged: (uf) {
                                  setState(() {
                                    _ufSelecionada = uf;
                                    _carregarEventos();
                                  });
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'O que está acontecendo na sua cidade agora',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.5,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricaBannerItem(
                                rotulo: 'Relatos',
                                valor: '$totalRelatos',
                                icone: '📍',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MetricaBannerItem(
                                rotulo: 'Em Ação',
                                valor: '$totalAcao',
                                icone: '🚓',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MetricaBannerItem(
                                rotulo: 'Apoios',
                                valor: '$totalApoios',
                                icone: '👍',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Barra de Filtro de Categoria (Combo/Select) + Toggle de Resolvidos
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Row(
                    children: [
                      // Seletor Dropdown/Combo de Categorias
                      Expanded(
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _categoriaSelecionada,
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(16),
                              dropdownColor: Colors.white,
                              icon: Icon(
                                Icons.unfold_more_rounded,
                                size: 20,
                                color: widget.tema.seedColor,
                              ),
                              selectedItemBuilder: (context) {
                                return CategoriaFiltro.todas.map((cat) {
                                  final label = cat.slug.isEmpty
                                      ? 'Todas as Categorias'
                                      : cat.nome;
                                  return Row(
                                    children: [
                                      Text(cat.icone, style: const TextStyle(fontSize: 15)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Categoria: $label',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: cat.slug.isEmpty
                                                ? const Color(0xFF334155)
                                                : widget.tema.seedColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList();
                              },
                              items: CategoriaFiltro.todas.map((cat) {
                                final sel = _categoriaSelecionada == cat.slug;
                                final label = cat.slug.isEmpty
                                    ? 'Todas as Categorias'
                                    : cat.nome;
                                return DropdownMenuItem<String>(
                                  value: cat.slug,
                                  child: Row(
                                    children: [
                                      Text(cat.icone, style: const TextStyle(fontSize: 16)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                                            color: sel ? widget.tema.seedColor : const Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                      if (sel)
                                        Icon(
                                          Icons.check_rounded,
                                          size: 17,
                                          color: widget.tema.seedColor,
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (novoSlug) {
                                if (novoSlug == null) return;
                                _selecionarCategoria(novoSlug);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Botão Alternador de 'Resolvidos'
                      InkWell(
                        onTap: () {
                          setState(() {
                            _incluirResolvidos = !_incluirResolvidos;
                            _carregarEventos();
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: _incluirResolvidos
                                ? const Color(0xFFDCFCE7)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _incluirResolvidos
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFE2E8F0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _incluirResolvidos
                                    ? Icons.check_circle_rounded
                                    : Icons.check_circle_outline_rounded,
                                size: 16,
                                color: _incluirResolvidos
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Resolvidos',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _incluirResolvidos
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: _incluirResolvidos
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Conteúdo: Loading, Erro, Vazio ou Lista de Cards
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (snapshot.hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            size: 52,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Não foi possível conectar à API:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => setState(_carregarEventos),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (eventos.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🎉', style: TextStyle(fontSize: 42)),
                          SizedBox(height: 10),
                          Text(
                            'Nenhum evento ativo para este filtro.',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Experimente selecionar outra categoria acima.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  sliver: SliverList.separated(
                    itemCount: eventos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final evento = eventos[index];
                      return EventoCard(
                        evento: evento,
                        onTap: () => EventoDetalheSheet.abrir(
                          context,
                          evento: evento,
                          api: widget.api,
                          onUsuarioChanged: widget.onUsuarioChanged,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricaBannerItem extends StatelessWidget {
  final String rotulo;
  final String valor;
  final String icone;

  const _MetricaBannerItem({
    required this.rotulo,
    required this.valor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(icone, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 5),
                Text(
                  valor,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            rotulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeletorUfChip extends StatelessWidget {
  final List<Estado> estados;
  final String? ufAtual;
  final ValueChanged<String?> onChanged;

  const _SeletorUfChip({
    required this.estados,
    required this.ufAtual,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      tooltip: 'Filtrar por Estado (UF)',
      onSelected: onChanged,
      itemBuilder: (context) => [
        const PopupMenuItem<String?>(
          value: null,
          child: Text('🇧🇷 Todos os estados'),
        ),
        ...estados.map(
          (e) => PopupMenuItem<String?>(
            value: e.sigla,
            child: Text('${e.sigla} · ${e.nome}'),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: ShapeDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ufAtual ?? 'Brasil',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
