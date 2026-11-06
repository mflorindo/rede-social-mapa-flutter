import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/evento.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../services/localizacao_service.dart';

class CriarRelatoSheet extends StatefulWidget {
  final ApiService api;
  final LatLng? posicaoSugerida;
  final ValueChanged<ContaUsuario>? onUsuarioChanged;
  final Color corTema;

  const CriarRelatoSheet({
    super.key,
    required this.api,
    this.posicaoSugerida,
    this.onUsuarioChanged,
    required this.corTema,
  });

  static Future<Evento?> abrir(
    BuildContext context, {
    required ApiService api,
    LatLng? posicaoSugerida,
    ValueChanged<ContaUsuario>? onUsuarioChanged,
    required Color corTema,
  }) {
    return showModalBottomSheet<Evento>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: CriarRelatoSheet(
          api: api,
          posicaoSugerida: posicaoSugerida,
          onUsuarioChanged: onUsuarioChanged,
          corTema: corTema,
        ),
      ),
    );
  }

  @override
  State<CriarRelatoSheet> createState() => _CriarRelatoSheetState();
}

class _CriarRelatoSheetState extends State<CriarRelatoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();

  String _categoriaSelecionada = 'buraco';
  LatLng? _posicaoAtual;
  bool _buscandoGps = false;
  String? _erroGps;
  bool _enviando = false;
  String? _erroEnvio;

  final List<Map<String, String>> _categorias = const [
    {'slug': 'buraco', 'nome': 'Buraco', 'icone': '🕳️'},
    {'slug': 'alagamento', 'nome': 'Alagamento', 'icone': '🌊'},
    {'slug': 'iluminacao', 'nome': 'Iluminação', 'icone': '💡'},
    {'slug': 'lixo', 'nome': 'Lixo', 'icone': '🗑️'},
    {'slug': 'outro', 'nome': 'Outro', 'icone': '📍'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.posicaoSugerida != null) {
      _posicaoAtual = widget.posicaoSugerida;
    }
    _obterLocalizacaoGps();
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _obterLocalizacaoGps() async {
    setState(() {
      _buscandoGps = true;
      _erroGps = null;
    });

    try {
      final pos = await LocalizacaoService.obterPosicaoAtual();
      if (!mounted) return;
      setState(() {
        _posicaoAtual = LatLng(pos.latitude, pos.longitude);
        _buscandoGps = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _buscandoGps = false;
        _erroGps = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _autenticarDemonstracao() async {
    setState(() => _enviando = true);
    try {
      final usuario = await widget.api.autenticarDemonstracaoRapida(
        email: 'marceloflorindo@gmail.com',
        senha: '123456',
      );
      if (!mounted) return;
      widget.onUsuarioChanged?.call(usuario);
      setState(() {
        _enviando = false;
        _erroEnvio = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Identificado como Marcelo Florindo.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _erroEnvio = 'Erro ao identificar: $e';
      });
    }
  }

  Future<void> _publicarRelato() async {
    if (!_formKey.currentState!.validate()) return;

    if (_posicaoAtual == null) {
      setState(() {
        _erroEnvio = 'Aguarde ou obtenha a localização para criar o relato.';
      });
      return;
    }

    if (!widget.api.estaAutenticado) {
      await _autenticarDemonstracao();
      if (!widget.api.estaAutenticado) return;
    }

    setState(() {
      _enviando = true;
      _erroEnvio = null;
    });

    try {
      final novoEvento = await widget.api.criarEvento(
        categoria: _categoriaSelecionada,
        descricao: _descricaoController.text.trim(),
        lat: _posicaoAtual!.latitude,
        lng: _posicaoAtual!.longitude,
      );

      if (!mounted) return;
      Navigator.of(context).pop(novoEvento);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _erroEnvio = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra de arraste
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Cabeçalho
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.corTema.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('📢', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Criar Relato com GPS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Marque um problema na sua posição atual',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card da Localização GPS
                    _buildCardLocalizacao(),

                    const SizedBox(height: 18),

                    // Seleção de Categoria
                    const Text(
                      'Qual o tipo de problema?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSeletorCategorias(),

                    const SizedBox(height: 18),

                    // Campo de Descrição
                    const Text(
                      'Descrição do relato',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descricaoController,
                      maxLines: 3,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText:
                            'Ex.: Buraco fundo na pista da direita, risco de acidentes para carros e motos.',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: widget.corTema, width: 2),
                        ),
                      ),
                      validator: (valor) {
                        if (valor == null || valor.trim().length < 5) {
                          return 'Descreva com pelo menos 5 caracteres.';
                        }
                        return null;
                      },
                    ),

                    // Mensagem de Erro geral se houver
                    if (_erroEnvio != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: Color(0xFFDC2626), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _erroEnvio!,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF991B1B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Botão de Publicação
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: widget.corTema,
                          shape: RoundedRectangle6xl(),
                          elevation: 2,
                        ),
                        onPressed: _enviando ? null : _publicarRelato,
                        icon: _enviando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 20),
                        label: Text(
                          _enviando ? 'Publicando relato...' : 'Publicar no Mapa',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardLocalizacao() {
    if (_buscandoGps) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Obtendo sinal GPS de alta precisão...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_posicaoAtual != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.my_location_rounded,
                color: Color(0xFF16A34A), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Posição do celular detectada',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF166534),
                    ),
                  ),
                  Text(
                    '${_posicaoAtual!.latitude.toStringAsFixed(5)}, ${_posicaoAtual!.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Atualizar GPS',
              icon: const Icon(Icons.refresh_rounded,
                  size: 18, color: Color(0xFF166534)),
              onPressed: _obterLocalizacaoGps,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      );
    }

    // Se houve falha no GPS
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_off_rounded,
                  color: Color(0xFFD97706), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _erroGps ?? 'Não foi possível capturar o GPS.',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: const Color(0xFFB45309),
              side: const BorderSide(color: Color(0xFFF59E0B)),
            ),
            onPressed: _obterLocalizacaoGps,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Tentar GPS novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildSeletorCategorias() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categorias.map((cat) {
        final selecionado = _categoriaSelecionada == cat['slug'];
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _categoriaSelecionada = cat['slug']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selecionado
                  ? widget.corTema.withValues(alpha: 0.12)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selecionado
                    ? widget.corTema
                    : const Color(0xFFE2E8F0),
                width: selecionado ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(cat['icone']!, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  cat['nome']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        selecionado ? FontWeight.w800 : FontWeight.w600,
                    color: selecionado
                        ? widget.corTema
                        : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class RoundedRectangle6xl extends RoundedRectangleBorder {
  RoundedRectangle6xl() : super(borderRadius: BorderRadius.circular(16));
}
