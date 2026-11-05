import 'package:flutter/material.dart';
import '../models/anuncio.dart';
import '../models/evento.dart';
import '../services/api_service.dart';

class AnuncioCard extends StatefulWidget {
  final Anuncio anuncio;
  final VoidCallback? onActionTap;

  const AnuncioCard({
    super.key,
    required this.anuncio,
    this.onActionTap,
  });

  @override
  State<AnuncioCard> createState() => _AnuncioCardState();
}

class _AnuncioCardState extends State<AnuncioCard> {
  int _paginaAtual = 0;

  @override
  Widget build(BuildContext context) {
    final a = widget.anuncio;
    final colorScheme = Theme.of(context).colorScheme;
    final fotosResolvidas = a.fotos
        .map(ApiService.resolverUrlMidia)
        .whereType<String>()
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: a.nivelPlano == 'Ouro'
              ? const Color(0xFFFCD34D)
              : const Color(0xFFE2E8F0),
          width: a.nivelPlano == 'Ouro' ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header estilo Instagram Sponsored Post
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    a.nomeEmpresa.isNotEmpty
                        ? a.nomeEmpresa[0].toUpperCase()
                        : 'P',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.nomeEmpresa,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Patrocinado · ${a.segmento}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: ShapeDecoration(
                    color: a.corFundoPlano,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    '${a.emojiPlano} Plano ${a.nivelPlano}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: a.corTextoPlano,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Carrossel de Fotos estilo Instagram Ads
          SizedBox(
            height: 190,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (fotosResolvidas.isNotEmpty)
                  PageView.builder(
                    itemCount: fotosResolvidas.length,
                    onPageChanged: (idx) => setState(() => _paginaAtual = idx),
                    itemBuilder: (context, index) {
                      return Image.network(
                        fotosResolvidas[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _BannerParceiroFallback(anuncio: a),
                      );
                    },
                  )
                else
                  _BannerParceiroFallback(anuncio: a),
                if (fotosResolvidas.length > 1)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: ShapeDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        '${_paginaAtual + 1}/${fotosResolvidas.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (fotosResolvidas.length > 1)
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        fotosResolvidas.length,
                        (idx) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _paginaAtual == idx ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _paginaAtual == idx
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Conteúdo, Endereço, Horário e CTA
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (a.descricao.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    a.descricao.trim(),
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (a.endereco.trim().isNotEmpty || a.bairro.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            [
                              if (a.endereco.trim().isNotEmpty)
                                a.endereco.trim(),
                              if (a.bairro.trim().isNotEmpty) a.bairro.trim(),
                              if (a.cidade != null && a.cidade!.isNotEmpty)
                                a.cidade!,
                            ].join(' · '),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (a.horarioFuncionamento.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            a.horarioFuncionamento.trim(),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: widget.onActionTap,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text(
                      a.textoBotao.isNotEmpty
                          ? a.textoBotao
                          : 'Conhecer Parceiro',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
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

class _BannerParceiroFallback extends StatelessWidget {
  final Anuncio anuncio;

  const _BannerParceiroFallback({required this.anuncio});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.18),
            colorScheme.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storefront_rounded,
            size: 44,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            anuncio.nomeEmpresa,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            anuncio.segmento,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class AnuncioResumoCard extends StatefulWidget {
  final AnuncioResumo anuncio;
  final VoidCallback? onTap;

  const AnuncioResumoCard({
    super.key,
    required this.anuncio,
    this.onTap,
  });

  @override
  State<AnuncioResumoCard> createState() => _AnuncioResumoCardState();
}

class _AnuncioResumoCardState extends State<AnuncioResumoCard> {
  int _pagina = 0;

  @override
  Widget build(BuildContext context) {
    final a = widget.anuncio;
    final colorScheme = Theme.of(context).colorScheme;
    final fotos = a.fotos
        .map(ApiService.resolverUrlMidia)
        .whereType<String>()
        .toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFFBEB),
            colorScheme.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.nomeEmpresa,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Apoia melhorias neste bairro · ${a.segmento}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: const ShapeDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: StadiumBorder(),
                  ),
                  child: const Text(
                    'Parceiro',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (fotos.isNotEmpty)
            SizedBox(
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: fotos.length,
                    onPageChanged: (idx) => setState(() => _pagina = idx),
                    itemBuilder: (_, idx) => Image.network(
                      fotos[idx],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFFEF3C7),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.storefront_rounded,
                          size: 36,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ),
                  if (fotos.length > 1)
                    Positioned(
                      bottom: 8,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: ShapeDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          '${_pagina + 1}/${fotos.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (a.descricao.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    a.descricao.trim(),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.onTap,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.touch_app_rounded, size: 16),
                    label: Text(
                      a.textoBotao.isNotEmpty ? a.textoBotao : 'Saiba mais',
                      style: const TextStyle(fontWeight: FontWeight.w800),
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
