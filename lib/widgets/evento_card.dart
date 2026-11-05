import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../services/api_service.dart';

class EventoCard extends StatelessWidget {
  final Evento evento;
  final VoidCallback onTap;

  const EventoCard({
    super.key,
    required this.evento,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final urlCapa = ApiService.resolverUrlMidia(evento.fotoCapa);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CapaEventoHeader(evento: evento, urlCapa: urlCapa),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${evento.categoriaNome} #${evento.id}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: ShapeDecoration(
                            color: evento.statusCorFundo,
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            '${evento.statusIcone} ${evento.statusNome}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: evento.statusCorTexto,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.place_rounded,
                          size: 15,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            evento.localizacaoFormatada,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (evento.descricao.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        evento.descricao.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor:
                              colorScheme.primary.withValues(alpha: 0.12),
                          child: Text(
                            evento.autor.isNotEmpty
                                ? evento.autor[0].toUpperCase()
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
                            evento.autor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                        _ContadorReacaoPill(
                          emoji: '👍',
                          valor: evento.curtidas,
                          corFundo: const Color(0xFFF0FDF4),
                          corTexto: const Color(0xFF15803D),
                        ),
                        const SizedBox(width: 6),
                        _ContadorReacaoPill(
                          emoji: '👎',
                          valor: evento.dislikes,
                          corFundo: const Color(0xFFFEF2F2),
                          corTexto: const Color(0xFFB91C1C),
                        ),
                        const SizedBox(width: 6),
                        _ContadorReacaoPill(
                          emoji: '💬',
                          valor: evento.comentarios,
                          corFundo: const Color(0xFFF8FAFC),
                          corTexto: const Color(0xFF334155),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CapaEventoHeader extends StatelessWidget {
  final Evento evento;
  final String? urlCapa;

  const _CapaEventoHeader({
    required this.evento,
    required this.urlCapa,
  });

  @override
  Widget build(BuildContext context) {
    final corCat = evento.categoriaCor;

    return SizedBox(
      height: urlCapa != null ? 156 : 84,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (urlCapa != null)
            Image.network(
              urlCapa!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _PlaceholderGradiente(
                evento: evento,
                corCat: corCat,
              ),
            )
          else
            _PlaceholderGradiente(evento: evento, corCat: corCat),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: ShapeDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                shape: const StadiumBorder(),
                shadows: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(evento.icone, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 5),
                  Text(
                    evento.categoriaNome,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (urlCapa != null)
            Positioned(
              bottom: 10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: ShapeDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  shape: const StadiumBorder(),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_camera_outlined,
                      size: 13,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Com foto',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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

class _PlaceholderGradiente extends StatelessWidget {
  final Evento evento;
  final Color corCat;

  const _PlaceholderGradiente({
    required this.evento,
    required this.corCat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            corCat.withValues(alpha: 0.16),
            corCat.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 18),
          child: Text(
            evento.icone,
            style: TextStyle(
              fontSize: 42,
              color: Colors.black.withValues(alpha: 0.18),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContadorReacaoPill extends StatelessWidget {
  final String emoji;
  final int valor;
  final Color corFundo;
  final Color corTexto;

  const _ContadorReacaoPill({
    required this.emoji,
    required this.valor,
    required this.corFundo,
    required this.corTexto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: ShapeDecoration(
        color: corFundo,
        shape: const StadiumBorder(),
      ),
      child: Text(
        '$emoji $valor',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: corTexto,
        ),
      ),
    );
  }
}
