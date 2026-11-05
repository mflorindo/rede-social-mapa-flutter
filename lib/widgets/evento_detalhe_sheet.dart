import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../services/api_service.dart';
import 'anuncio_card.dart';

class EventoDetalheSheet extends StatefulWidget {
  final Evento eventoBase;
  final ApiService api;

  const EventoDetalheSheet({
    super.key,
    required this.eventoBase,
    required this.api,
  });

  static Future<void> abrir(
    BuildContext context, {
    required Evento evento,
    required ApiService api,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventoDetalheSheet(
        eventoBase: evento,
        api: api,
      ),
    );
  }

  @override
  State<EventoDetalheSheet> createState() => _EventoDetalheSheetState();
}

class _EventoDetalheSheetState extends State<EventoDetalheSheet> {
  late Future<EventoDetalhe> _futuroDetalhe;
  int _fotoIndex = 0;
  int _offsetCurtidas = 0;
  int _offsetDislikes = 0;
  String? _reacaoSelecionada;

  @override
  void initState() {
    super.initState();
    _futuroDetalhe = widget.api.obterEvento(widget.eventoBase.id);
  }

  void _alternarReacao(String tipo) {
    setState(() {
      if (_reacaoSelecionada == tipo) {
        _reacaoSelecionada = null;
        if (tipo == 'like') {
          _offsetCurtidas = 0;
        } else {
          _offsetDislikes = 0;
        }
      } else {
        _reacaoSelecionada = tipo;
        if (tipo == 'like') {
          _offsetCurtidas = 1;
          _offsetDislikes = 0;
        } else {
          _offsetDislikes = 1;
          _offsetCurtidas = 0;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          clipBehavior: Clip.antiAlias,
          child: FutureBuilder<EventoDetalhe>(
            future: _futuroDetalhe,
            builder: (context, snapshot) {
              final detalhe = snapshot.data ??
                  EventoDetalhe.fromEvento(widget.eventoBase);
              final carregando =
                  snapshot.connectionState == ConnectionState.waiting;
              final fotosUrls = detalhe.fotos
                  .map((f) => ApiService.resolverUrlMidia(f.url))
                  .whereType<String>()
                  .toList();
              if (fotosUrls.isEmpty && detalhe.fotoCapa != null) {
                final capa = ApiService.resolverUrlMidia(detalhe.fotoCapa);
                if (capa != null) fotosUrls.add(capa);
              }

              return ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  // Handle superior
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Cabeçalho de título e botão fechar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: detalhe.categoriaCor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            detalhe.icone,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${detalhe.categoriaNome} #${detalhe.id}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '📍 ${detalhe.localizacaoFormatada}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Fechar',
                        ),
                      ],
                    ),
                  ),

                  // Galeria de Fotos
                  if (fotosUrls.isNotEmpty)
                    SizedBox(
                      height: 220,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          PageView.builder(
                            itemCount: fotosUrls.length,
                            onPageChanged: (i) =>
                                setState(() => _fotoIndex = i),
                            itemBuilder: (_, idx) => Image.network(
                              fotosUrls[idx],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _GaleriaFallback(detalhe: detalhe),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: ShapeDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                shape: const StadiumBorder(),
                              ),
                              child: Text(
                                '📷 ${_fotoIndex + 1}/${fotosUrls.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _GaleriaFallback(detalhe: detalhe),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Linha de Status + Autor + Coordenadas
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: ShapeDecoration(
                                color: detalhe.statusCorFundo,
                                shape: const StadiumBorder(),
                              ),
                              child: Text(
                                '${detalhe.statusIcone} ${detalhe.statusNome}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: detalhe.statusCorTexto,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: const ShapeDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: StadiumBorder(),
                              ),
                              child: Text(
                                '👤 Relatado por ${detalhe.autor}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Descrição Completa
                        const Text(
                          'Descrição do Relato',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          detalhe.descricao.trim().isNotEmpty
                              ? detalhe.descricao.trim()
                              : 'Relato registrado no mapa colaborativo da cidade.',
                          style: const TextStyle(
                            fontSize: 14.5,
                            height: 1.5,
                            color: Color(0xFF334155),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Barra de Reações (👍 / 👎 / 💬)
                        Row(
                          children: [
                            Expanded(
                              child: _BotaoReacaoDetalhe(
                                emoji: '👍',
                                rotulo: 'Apoiar',
                                contador: detalhe.curtidas + _offsetCurtidas,
                                ativo: _reacaoSelecionada == 'like',
                                corAtiva: const Color(0xFF15803D),
                                onTap: () => _alternarReacao('like'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _BotaoReacaoDetalhe(
                                emoji: '👎',
                                rotulo: 'Discordo',
                                contador: detalhe.dislikes + _offsetDislikes,
                                ativo: _reacaoSelecionada == 'dislike',
                                corAtiva: const Color(0xFFB91C1C),
                                onTap: () => _alternarReacao('dislike'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                '💬 ${detalhe.listaComentarios.isNotEmpty ? detalhe.listaComentarios.length : detalhe.comentarios}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Card contextual do Parceiro Patrocinado
                        if (detalhe.anuncio != null) ...[
                          const SizedBox(height: 22),
                          AnuncioResumoCard(
                            anuncio: detalhe.anuncio!,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Abrindo oferta de ${detalhe.anuncio!.nomeEmpresa}...',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],

                        const SizedBox(height: 24),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 18),

                        // Lista de Comentários da Comunidade
                        Row(
                          children: [
                            Icon(
                              Icons.forum_outlined,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Comentários da Comunidade',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            if (carregando)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (detalhe.listaComentarios.isEmpty && !carregando)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: const Text(
                              'Nenhum comentário ainda. Seja o primeiro morador a comentar sobre este ponto!',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          )
                        else
                          ...detalhe.listaComentarios.map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: colorScheme.primary
                                              .withValues(alpha: 0.14),
                                          child: Text(
                                            c.autor.isNotEmpty
                                                ? c.autor[0].toUpperCase()
                                                : 'M',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            c.autor,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      c.texto,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        height: 1.4,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _GaleriaFallback extends StatelessWidget {
  final EventoDetalhe detalhe;

  const _GaleriaFallback({required this.detalhe});

  @override
  Widget build(BuildContext context) {
    final cor = detalhe.categoriaCor;
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cor.withValues(alpha: 0.18),
            cor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(detalhe.icone, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 4),
            Text(
              'Coordenadas ${detalhe.lat.toStringAsFixed(4)}, ${detalhe.lng.toStringAsFixed(4)}',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotaoReacaoDetalhe extends StatelessWidget {
  final String emoji;
  final String rotulo;
  final int contador;
  final bool ativo;
  final Color corAtiva;
  final VoidCallback onTap;

  const _BotaoReacaoDetalhe({
    required this.emoji,
    required this.rotulo,
    required this.contador,
    required this.ativo,
    required this.corAtiva,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ativo ? corAtiva.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ativo ? corAtiva : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '$rotulo ($contador)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: ativo ? corAtiva : const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
