import 'package:flutter/material.dart';
import '../models/anuncio.dart';
import '../services/api_service.dart';
import '../theme/app_themes.dart';
import '../widgets/anuncio_card.dart';

class ParceirosScreen extends StatefulWidget {
  final ApiService api;
  final AppThemeOption tema;
  final int refreshToken;

  const ParceirosScreen({
    super.key,
    required this.api,
    required this.tema,
    this.refreshToken = 0,
  });

  @override
  State<ParceirosScreen> createState() => _ParceirosScreenState();
}

class _ParceirosScreenState extends State<ParceirosScreen> {
  String _planoFiltro = '';
  late Future<List<Anuncio>> _futuroAnuncios;

  @override
  void initState() {
    super.initState();
    _carregarParceiros();
  }

  @override
  void didUpdateWidget(covariant ParceirosScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      setState(_carregarParceiros);
    }
  }

  void _carregarParceiros() {
    _futuroAnuncios = widget.api.listarAnuncios();
  }

  Future<void> _acionarParceiro(Anuncio anuncio) async {
    try {
      await widget.api.registrarCliqueAnuncio(anuncio.id);
    } catch (_) {
      // Mesmo offline, exibe feedback visual ao morador
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Redirecionando para ${anuncio.nomeEmpresa} (${anuncio.dominio.isNotEmpty ? anuncio.dominio : anuncio.urlClique})...',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Anuncio>>(
      future: _futuroAnuncios,
      builder: (context, snapshot) {
        final todos = snapshot.data ?? const [];
        final filtrados = _planoFiltro.isEmpty
            ? todos
            : todos.where((a) => a.nivelPlano == _planoFiltro).toList();

        return RefreshIndicator(
          onRefresh: () async {
            setState(_carregarParceiros);
            await _futuroAnuncios;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Banner de Parceiros da Cidade
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
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: ShapeDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text(
                            '🤝 Comércio Hiperlocal & Patrocinadores',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Parceiros da Cidade',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Empresas locais que apoiam a manutenção urbana e oferecem vantagens para moradores da região.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Chips de Filtro por Plano (Ouro / Prata / Bronze)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    children: [
                      _ChipPlano(
                        rotulo: '✨ Todos (${todos.length})',
                        selecionado: _planoFiltro.isEmpty,
                        onTap: () => setState(() => _planoFiltro = ''),
                      ),
                      const SizedBox(width: 8),
                      _ChipPlano(
                        rotulo: '🥇 Ouro',
                        selecionado: _planoFiltro == 'Ouro',
                        onTap: () => setState(() => _planoFiltro = 'Ouro'),
                      ),
                      const SizedBox(width: 8),
                      _ChipPlano(
                        rotulo: '🥈 Prata',
                        selecionado: _planoFiltro == 'Prata',
                        onTap: () => setState(() => _planoFiltro = 'Prata'),
                      ),
                      const SizedBox(width: 8),
                      _ChipPlano(
                        rotulo: '🥉 Bronze',
                        selecionado: _planoFiltro == 'Bronze',
                        onTap: () => setState(() => _planoFiltro = 'Bronze'),
                      ),
                    ],
                  ),
                ),
              ),

              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
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
                            Icons.store_mall_directory_outlined,
                            size: 48,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Não foi possível carregar os parceiros:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => setState(_carregarParceiros),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (filtrados.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Nenhum parceiro patrocinado encontrado neste filtro.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  sliver: SliverList.separated(
                    itemCount: filtrados.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final anuncio = filtrados[index];
                      return AnuncioCard(
                        anuncio: anuncio,
                        onActionTap: () => _acionarParceiro(anuncio),
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

class _ChipPlano extends StatelessWidget {
  final String rotulo;
  final bool selecionado;
  final VoidCallback onTap;

  const _ChipPlano({
    required this.rotulo,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ChoiceChip(
      selected: selecionado,
      showCheckmark: false,
      label: Text(rotulo),
      labelStyle: TextStyle(
        fontWeight: selecionado ? FontWeight.w800 : FontWeight.w600,
        color: selecionado ? primary : const Color(0xFF334155),
      ),
      onSelected: (_) => onTap(),
    );
  }
}
