import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import 'anuncio_card.dart';

class EventoDetalheSheet extends StatefulWidget {
  final Evento eventoBase;
  final ApiService api;
  final ValueChanged<ContaUsuario?>? onUsuarioChanged;

  const EventoDetalheSheet({
    super.key,
    required this.eventoBase,
    required this.api,
    this.onUsuarioChanged,
  });

  static Future<void> abrir(
    BuildContext context, {
    required Evento evento,
    required ApiService api,
    ValueChanged<ContaUsuario?>? onUsuarioChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventoDetalheSheet(
        eventoBase: evento,
        api: api,
        onUsuarioChanged: onUsuarioChanged,
      ),
    );
  }

  @override
  State<EventoDetalheSheet> createState() => _EventoDetalheSheetState();
}

class _EventoDetalheSheetState extends State<EventoDetalheSheet> {
  late Future<EventoDetalhe> _futuroDetalhe;
  int _fotoIndex = 0;
  int? _curtidasOverride;
  int? _dislikesOverride;
  String? _reacaoSelecionada;
  bool _enviandoReacao = false;
  String? _tipoCarregando;
  String? _mensagemFeedback;
  bool _mensagemFeedbackSucesso = true;

  final TextEditingController _comentarioController = TextEditingController();
  final FocusNode _comentarioFocusNode = FocusNode();
  List<ComentarioEvento>? _comentariosLocais;
  bool _enviandoComentario = false;

  @override
  void initState() {
    super.initState();
    _futuroDetalhe = widget.api.obterEvento(widget.eventoBase.id);
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    _comentarioFocusNode.dispose();
    super.dispose();
  }

  Future<void> _enviarComentario() async {
    final texto = _comentarioController.text.trim();
    if (texto.isEmpty || _enviandoComentario) return;

    if (!widget.api.estaAutenticado) {
      await _solicitarLogin('comentar');
      return;
    }

    setState(() => _enviandoComentario = true);

    try {
      final novoComentario = await widget.api.adicionarComentario(
        eventoId: widget.eventoBase.id,
        texto: texto,
      );
      if (!mounted) return;

      setState(() {
        _comentariosLocais = [novoComentario, ...?_comentariosLocais];
        _comentarioController.clear();
        _mensagemFeedback = 'Comentário publicado! 💬';
        _mensagemFeedbackSucesso = true;
      });
      _comentarioFocusNode.unfocus();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensagemFeedback = e.toString().replaceFirst('Exception: ', '');
        _mensagemFeedbackSucesso = false;
      });
    } finally {
      if (mounted) {
        setState(() => _enviandoComentario = false);
      }
    }
  }

  Future<void> _solicitarLogin(String tipo) async {
    final acao = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    size: 26,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Entre para interagir',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Apoie ou discorde com sua conta de morador',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Para registrar sua opinião em relatos de infraestrutura e serviços públicos em São José, é necessário identificar-se.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.bolt_rounded, size: 20),
              label: const Text(
                'Entrar com 1 toque (Marcelo)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              onPressed: () => Navigator.of(ctx).pop('marcelo'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.person_outline_rounded, size: 19),
              label: const Text(
                'Entrar como Cidadão Demo',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
              onPressed: () => Navigator.of(ctx).pop('cidadao'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Agora não', style: TextStyle(color: Color(0xFF64748B))),
            ),
          ],
        ),
      ),
    );

    if (acao == null || !mounted) return;

    final email = acao == 'marcelo'
        ? 'marceloflorindo@gmail.com'
        : 'usuario0001@saojose.sc.gov.br';

    setState(() {
      _enviandoReacao = true;
      _tipoCarregando = tipo;
    });

    try {
      final usuario = await widget.api.autenticarDemonstracaoRapida(
        email: email,
        senha: '123456',
      );
      if (!mounted) return;
      widget.onUsuarioChanged?.call(usuario);
      setState(() {
        _mensagemFeedback = 'Conectado como ${usuario.nome}!';
        _mensagemFeedbackSucesso = true;
      });
      if (tipo == 'comentar') {
        setState(() {
          _enviandoReacao = false;
          _tipoCarregando = null;
        });
        await _enviarComentario();
      } else {
        await _alternarReacao(tipo);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensagemFeedback = 'Erro ao autenticar: $e';
        _mensagemFeedbackSucesso = false;
        _enviandoReacao = false;
        _tipoCarregando = null;
      });
    }
  }

  Future<void> _alternarReacao(String tipo) async {
    if (_enviandoReacao && _tipoCarregando == tipo) return;

    if (!widget.api.estaAutenticado) {
      await _solicitarLogin(tipo);
      return;
    }

    setState(() {
      _enviandoReacao = true;
      _tipoCarregando = tipo;
    });

    try {
      final resultado = await widget.api.reagirEvento(
        eventoId: widget.eventoBase.id,
        tipo: tipo,
      );
      if (!mounted) return;

      final acao = resultado['acao']?.toString();
      String aviso = 'Reação atualizada.';
      if (acao == 'adicionado') {
        aviso = (tipo == 'apoiar' || tipo == 'like')
            ? 'Você apoiou este relato! 👍'
            : 'Você discordou deste relato. 👎';
      } else if (acao == 'alterado') {
        aviso = (tipo == 'apoiar' || tipo == 'like')
            ? 'Reação alterada para Apoiar! 👍'
            : 'Reação alterada para Discordar. 👎';
      } else if (acao == 'removido') {
        aviso = 'Reação removida.';
      }

      setState(() {
        _curtidasOverride = resultado['curtidas'] as int?;
        _dislikesOverride = resultado['dislikes'] as int?;
        _reacaoSelecionada = resultado['tipo'] as String?;
        _mensagemFeedback = aviso;
        _mensagemFeedbackSucesso = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensagemFeedback = e.toString().replaceFirst('Exception: ', '');
        _mensagemFeedbackSucesso = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _enviandoReacao = false;
          _tipoCarregando = null;
        });
      }
    }
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
                                contador: _curtidasOverride ?? detalhe.curtidas,
                                ativo: _reacaoSelecionada == 'like' ||
                                    _reacaoSelecionada == 'apoiar',
                                corAtiva: const Color(0xFF15803D),
                                carregando: _enviandoReacao &&
                                    _tipoCarregando == 'apoiar',
                                onTap: () => _alternarReacao('apoiar'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _BotaoReacaoDetalhe(
                                emoji: '👎',
                                rotulo: 'Discordar',
                                contador: _dislikesOverride ?? detalhe.dislikes,
                                ativo: _reacaoSelecionada == 'dislike' ||
                                    _reacaoSelecionada == 'discordar',
                                corAtiva: const Color(0xFFB91C1C),
                                carregando: _enviandoReacao &&
                                    _tipoCarregando == 'discordar',
                                onTap: () => _alternarReacao('discordar'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Material(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: () => _comentarioFocusNode.requestFocus(),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    '💬 ${_comentariosLocais?.length ?? (detalhe.listaComentarios.isNotEmpty ? detalhe.listaComentarios.length : detalhe.comentarios)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Banner de feedback visível dentro do Sheet
                        if (_mensagemFeedback != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _mensagemFeedbackSucesso
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _mensagemFeedbackSucesso
                                    ? const Color(0xFF86EFAC)
                                    : const Color(0xFFFCA5A5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _mensagemFeedbackSucesso
                                      ? Icons.check_circle_rounded
                                      : Icons.info_outline_rounded,
                                  size: 16,
                                  color: _mensagemFeedbackSucesso
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFB91C1C),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _mensagemFeedback!,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: _mensagemFeedbackSucesso
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFFB91C1C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Dica contextual caso visitante não autenticado
                        if (!widget.api.estaAutenticado) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _solicitarLogin('apoiar'),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_open_rounded,
                                    size: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Toque para entrar e registrar sua opinião',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2563EB),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

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

                        // Caixa de Envio de Comentário
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    colorScheme.primary.withValues(alpha: 0.12),
                                child: Icon(
                                  Icons.edit_note_rounded,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _comentarioController,
                                  focusNode: _comentarioFocusNode,
                                  minLines: 1,
                                  maxLines: 4,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _enviarComentario(),
                                  decoration: InputDecoration(
                                    hintText: widget.api.estaAutenticado
                                        ? 'Escreva um comentário sobre este relato...'
                                        : 'Identifique-se para comentar...',
                                    hintStyle: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              _enviandoComentario
                                  ? const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    )
                                  : IconButton(
                                      style: IconButton.styleFrom(
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.all(8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: _enviarComentario,
                                      icon: const Icon(Icons.send_rounded,
                                          size: 16),
                                      tooltip: 'Publicar comentário',
                                    ),
                            ],
                          ),
                        ),

                        Builder(
                          builder: (context) {
                            final comentariosAtuais = _comentariosLocais ??
                                detalhe.listaComentarios;

                            if (comentariosAtuais.isEmpty && !carregando) {
                              return Container(
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
                              );
                            }

                            return Column(
                              children: comentariosAtuais
                                  .map(
                                    (c) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 12,
                                                  backgroundColor: colorScheme
                                                      .primary
                                                      .withValues(alpha: 0.14),
                                                  child: Text(
                                                    c.autor.isNotEmpty
                                                        ? c.autor[0]
                                                            .toUpperCase()
                                                        : 'M',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color:
                                                          colorScheme.primary,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    c.autor,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
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
                                  )
                                  .toList(),
                            );
                          },
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
  final bool carregando;
  final VoidCallback onTap;

  const _BotaoReacaoDetalhe({
    required this.emoji,
    required this.rotulo,
    required this.contador,
    required this.ativo,
    required this.corAtiva,
    this.carregando = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ativo ? corAtiva.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: carregando ? null : onTap,
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
              if (carregando)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ativo ? corAtiva : const Color(0xFF64748B),
                    ),
                  ),
                )
              else
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
