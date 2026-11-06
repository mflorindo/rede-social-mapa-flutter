import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/anuncio.dart';
import '../models/evento.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../services/localizacao_service.dart';
import '../theme/app_themes.dart';
import '../widgets/criar_relato_sheet.dart';
import '../widgets/evento_detalhe_sheet.dart';

class MapaRadarScreen extends StatefulWidget {
  final ApiService api;
  final AppThemeOption tema;
  final int refreshToken;
  final ValueChanged<ContaUsuario?>? onUsuarioChanged;

  const MapaRadarScreen({
    super.key,
    required this.api,
    required this.tema,
    this.refreshToken = 0,
    this.onUsuarioChanged,
  });

  @override
  State<MapaRadarScreen> createState() => _MapaRadarScreenState();
}

class _MapaRadarScreenState extends State<MapaRadarScreen> {
  static const LatLng _centroInicial = LatLng(-27.5935, -48.6138);
  static const double _zoomInicial = 15.0;
  static const String _tokenMapboxPadrao = '';

  final MapController _mapController = MapController();
  Timer? _debounceArraste;

  String _categoriaFiltro = '';
  bool _exibirPinosPatrocinados = true;
  bool _carregandoArea = true;
  bool _mapaPronto = false;
  String? _erroCarregamento;
  String _mapboxToken = _tokenMapboxPadrao;
  String _estiloMapbox = 'streets-v12';

  static const Map<String, String> _estilosMapboxDisponiveis = {
    'streets-v12': '🗺️ Mapa Ruas (Padrão)',
    'satellite-streets-v12': '🛰️ Mapa Satélite + Ruas',
    'light-v11': '☀️ Mapa Claro',
    'dark-v11': '🌙 Mapa Noturno',
  };

  double _zoomAtual = _zoomInicial;
  LatLngBounds? _limitesVisiveis;

  List<Evento> _eventos = const [];
  List<Anuncio> _anuncios = const [];

  Evento? _eventoSelecionado;
  List<Evento> _clusterSelecionado = const [];
  int _indiceNoCluster = 0;
  Anuncio? _anuncioSelecionado;

  @override
  void initState() {
    super.initState();
    // Busca inicial na vizinhança de Kobrasol / Campinas (São José)
    _limitesVisiveis = LatLngBounds(
      const LatLng(-27.606, -48.628),
      const LatLng(-27.581, -48.599),
    );
    _carregarConfigMapbox();
    _buscarEventosDaArea();
  }

  Future<void> _carregarConfigMapbox() async {
    final token = await widget.api.obterMapboxToken();
    if (mounted && token.isNotEmpty) {
      setState(() => _mapboxToken = token);
    }
  }

  @override
  void dispose() {
    _debounceArraste?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MapaRadarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _buscarEventosDaArea();
    }
  }

  void _aoMoverOuDarZoom(MapCamera camera, bool hasGesture) {
    final novoZoom = camera.zoom;
    final novosLimites = camera.visibleBounds;

    final mudouZoom = (novoZoom - _zoomAtual).abs() >= 0.15;
    if (mudouZoom) {
      setState(() => _zoomAtual = novoZoom);
    } else {
      _zoomAtual = novoZoom;
    }

    _limitesVisiveis = novosLimites;

    if (hasGesture) {
      if (!_carregandoArea) {
        setState(() => _carregandoArea = true);
      }
      _debounceArraste?.cancel();
      _debounceArraste = Timer(
        const Duration(milliseconds: 350),
        _buscarEventosDaArea,
      );
    }
  }

  Future<void> _buscarEventosDaArea() async {
    if (!mounted) return;
    setState(() {
      _carregandoArea = true;
      _erroCarregamento = null;
    });

    final bounds = _limitesVisiveis;
    try {
      final eventos = await widget.api.listarEventos(
        categoria: _categoriaFiltro.isEmpty ? null : _categoriaFiltro,
        minLat: bounds?.south,
        maxLat: bounds?.north,
        minLng: bounds?.west,
        maxLng: bounds?.east,
        limite: 250,
      );

      List<Anuncio> anuncios = const [];
      try {
        anuncios = await widget.api.listarAnuncios(
          apenasMapa: true,
          minLat: bounds?.south,
          maxLat: bounds?.north,
          minLng: bounds?.west,
          maxLng: bounds?.east,
        );
      } catch (_) {
        anuncios = const [];
      }

      if (!mounted) return;
      setState(() {
        _eventos = eventos;
        _anuncios = anuncios;
        _carregandoArea = false;

        if (_eventoSelecionado != null) {
          final aindaVisivel =
              eventos.any((e) => e.id == _eventoSelecionado!.id);
          if (!aindaVisivel) {
            _eventoSelecionado = null;
            _clusterSelecionado = const [];
            _indiceNoCluster = 0;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregandoArea = false;
        _erroCarregamento = e.toString();
      });
    }
  }

  void _alterarZoomBotao(double delta) {
    if (!_mapaPronto) return;
    final camera = _mapController.camera;
    final destino = (camera.zoom + delta).clamp(4.0, 18.5);
    _mapController.move(camera.center, destino);
    setState(() {
      _zoomAtual = destino;
      _limitesVisiveis = _mapController.camera.visibleBounds;
    });
    _debounceArraste?.cancel();
    _debounceArraste = Timer(
      const Duration(milliseconds: 250),
      _buscarEventosDaArea,
    );
  }

  void _voltarParaCentroUrbano() {
    if (!_mapaPronto) return;
    _mapController.move(_centroInicial, _zoomInicial);
    setState(() {
      _zoomAtual = _zoomInicial;
      _limitesVisiveis = _mapController.camera.visibleBounds;
    });
    _buscarEventosDaArea();
  }

  Future<void> _irParaMinhaLocalizacaoGps() async {
    if (!_mapaPronto) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Buscando sinal GPS do celular...'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final pos = await LocalizacaoService.obterPosicaoAtual();
      if (!mounted) return;
      final ponto = LatLng(pos.latitude, pos.longitude);
      _mapController.move(ponto, 16.5);
      setState(() {
        _zoomAtual = 16.5;
        _limitesVisiveis = _mapController.camera.visibleBounds;
      });
      _buscarEventosDaArea();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _abrirCriacaoRelato() async {
    final pontoSugerido = _mapaPronto ? _mapController.camera.center : _centroInicial;
    final novoEvento = await CriarRelatoSheet.abrir(
      context,
      api: widget.api,
      posicaoSugerida: pontoSugerido,
      onUsuarioChanged: widget.onUsuarioChanged,
      corTema: widget.tema.seedColor,
    );

    if (novoEvento != null && mounted) {
      final pontoEvento = LatLng(novoEvento.lat, novoEvento.lng);
      _mapController.move(pontoEvento, 16.5);
      setState(() {
        _eventos = [
          novoEvento,
          ..._eventos.where((e) => e.id != novoEvento.id),
        ];
        _eventoSelecionado = novoEvento;
        _clusterSelecionado = [novoEvento];
        _indiceNoCluster = 0;
        _zoomAtual = 16.5;
        _limitesVisiveis = _mapController.camera.visibleBounds;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Relato "${novoEvento.categoriaNome}" publicado com sucesso!',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  List<_ClusterGeografico> _agruparEventosPorZoom(List<Evento> eventos) {
    if (eventos.isEmpty) return const [];

    // No nível de rua aproximado (zoom >= 16.2), mostra cada pino individualmente
    if (_zoomAtual >= 16.2) {
      return eventos
          .map(
            (e) => _ClusterGeografico(
              centro: LatLng(e.lat, e.lng),
              eventos: [e],
            ),
          )
          .toList();
    }

    // Raio amplo (88px equivalentes) para manter o mapa limpo e legível
    final raioGraus = 88.0 * (360.0 / (256.0 * math.pow(2.0, _zoomAtual)));
    final clusters = <_ClusterGeografico>[];

    for (final ev in eventos) {
      final pos = LatLng(ev.lat, ev.lng);
      _ClusterGeografico? maisProximo;
      var menorDist = double.infinity;

      for (final c in clusters) {
        final dLat = c.centro.latitude - pos.latitude;
        final dLng = c.centro.longitude - pos.longitude;
        final dist = math.sqrt(dLat * dLat + dLng * dLng);
        if (dist < raioGraus && dist < menorDist) {
          menorDist = dist;
          maisProximo = c;
        }
      }

      if (maisProximo != null) {
        maisProximo.adicionar(ev);
      } else {
        clusters.add(_ClusterGeografico(centro: pos, eventos: [ev]));
      }
    }

    return clusters;
  }

  @override
  Widget build(BuildContext context) {
    final clusters = _agruparEventosPorZoom(_eventos);
    final tokenMapboxAtivo =
        _mapboxToken.isNotEmpty ? _mapboxToken : _tokenMapboxPadrao;

    return Stack(
      children: [
        // Mapa Real Interativo Mapbox (arraste para todos os lados e dê zoom)
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centroInicial,
              initialZoom: _zoomInicial,
              minZoom: 4.0,
              maxZoom: 18.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onMapReady: () {
                _mapaPronto = true;
                _limitesVisiveis = _mapController.camera.visibleBounds;
              },
              onPositionChanged: _aoMoverOuDarZoom,
            ),
            children: [
              if (tokenMapboxAtivo.isNotEmpty)
                TileLayer(
                  key: ValueKey('mapbox_${_estiloMapbox}_$tokenMapboxAtivo'),
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/mapbox/$_estiloMapbox/tiles/512/{z}/{x}/{y}@2x?access_token=$tokenMapboxAtivo',
                  tileDimension: 512,
                  zoomOffset: -1,
                  maxNativeZoom: 20,
                  userAgentPackageName: 'br.com.redesocialmapa.mobile',
                  tileProvider: NetworkTileProvider(silenceExceptions: true),
                )
              else
                TileLayer(
                  key: const ValueKey('osm_fallback'),
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  tileDimension: 256,
                  maxNativeZoom: 19,
                  userAgentPackageName: 'br.com.redesocialmapa.mobile',
                  tileProvider: NetworkTileProvider(silenceExceptions: true),
                ),

              // Camada de Pinos Patrocinados (Parceiros da Cidade)
              if (_exibirPinosPatrocinados)
                MarkerLayer(
                  markers: _anuncios
                      .where((a) => a.lat != null && a.lng != null)
                      .map((a) {
                    final selecionado = _anuncioSelecionado?.id == a.id;
                    return Marker(
                      point: LatLng(a.lat!, a.lng!),
                      width: 132,
                      height: 38,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _anuncioSelecionado = a;
                            _eventoSelecionado = null;
                            _clusterSelecionado = const [];
                          });
                        },
                        child: AnimatedScale(
                          scale: selecionado ? 1.12 : 1.0,
                          duration: const Duration(milliseconds: 180),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: ShapeDecoration(
                                color: const Color(0xFFFEF3C7),
                                shape: const StadiumBorder(
                                  side: BorderSide(
                                    color: Color(0xFFF59E0B),
                                    width: 1.8,
                                  ),
                                ),
                                shadows: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.16),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    a.emojiPlano,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      a.nomeEmpresa,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // Camada de Eventos e Clusters Geográficos da Área Visível
              MarkerLayer(
                markers: clusters.map((cluster) {
                  final contemSelecionado = _eventoSelecionado != null &&
                      cluster.eventos
                          .any((e) => e.id == _eventoSelecionado!.id);

                  return Marker(
                    point: cluster.centro,
                    width: 82,
                    height: 68,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _anuncioSelecionado = null;
                          _clusterSelecionado = cluster.eventos;
                          if (contemSelecionado &&
                              cluster.eventos.length > 1) {
                            _indiceNoCluster =
                                (_indiceNoCluster + 1) % cluster.eventos.length;
                          } else {
                            _indiceNoCluster = 0;
                          }
                          _eventoSelecionado =
                              cluster.eventos[_indiceNoCluster];
                        });

                        // Se for um cluster com vários itens e zoom baixo, aproxima suavemente
                        if (cluster.eventos.length > 1 &&
                            _zoomAtual < 15.5 &&
                            _mapaPronto) {
                          final novoZoom =
                              (_zoomAtual + 1.5).clamp(4.0, 18.0);
                          _mapController.move(cluster.centro, novoZoom);
                          _zoomAtual = novoZoom;
                          _limitesVisiveis =
                              _mapController.camera.visibleBounds;
                          _debounceArraste?.cancel();
                          _debounceArraste = Timer(
                            const Duration(milliseconds: 300),
                            _buscarEventosDaArea,
                          );
                        }
                      },
                      child: AnimatedScale(
                        scale: contemSelecionado ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 180),
                        child: Center(
                          child: cluster.eventos.length == 1
                              ? _PinoEventoUnico(
                                  evento: cluster.eventos.first,
                                  selecionado: contemSelecionado,
                                  corTema: widget.tema.seedColor,
                                )
                              : _PinoClusterEventos(
                                  cluster: cluster,
                                  selecionado: contemSelecionado,
                                  corTema: widget.tema.seedColor,
                                ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Barra Superior Flutuante (Glassmorphism) com status da área arrastada
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          if (_carregandoArea)
                            SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: widget.tema.seedColor,
                              ),
                            )
                          else
                            Icon(
                              Icons.radar_rounded,
                              size: 17,
                              color: widget.tema.seedColor,
                            ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _carregandoArea
                                  ? 'Radar · Buscando relatos nesta área...'
                                  : 'Radar · ${_eventos.length} relatos nesta área',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _exibirPinosPatrocinados =
                                    !_exibirPinosPatrocinados;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: ShapeDecoration(
                                color: _exibirPinosPatrocinados
                                    ? const Color(0xFFFEF3C7)
                                    : const Color(0xFFF1F5F9),
                                shape: const StadiumBorder(),
                              ),
                              child: Text(
                                '⭐ Parceiros (${_anuncios.length})',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: _exibirPinosPatrocinados
                                      ? const Color(0xFFB45309)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _categoriaFiltro,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(16),
                            dropdownColor: Colors.white,
                            icon: Icon(
                              Icons.unfold_more_rounded,
                              size: 19,
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
                              final sel = _categoriaFiltro == cat.slug;
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
                              setState(() {
                                _categoriaFiltro = novoSlug;
                                _eventoSelecionado = null;
                                _clusterSelecionado = const [];
                              });
                              _buscarEventosDaArea();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Botões Flutuantes de Navegação do Mapa (+, -, Centralizar)
        Positioned(
          right: 12,
          top: 112,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Aproximar rua (+)',
                  icon: const Icon(Icons.add_rounded, size: 20),
                  onPressed: () => _alterarZoomBotao(1.2),
                ),
                const Divider(height: 1, indent: 6, endIndent: 6),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Afastar bairro (-)',
                  icon: const Icon(Icons.remove_rounded, size: 20),
                  onPressed: () => _alterarZoomBotao(-1.2),
                ),
                const Divider(height: 1, indent: 6, endIndent: 6),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Minha localização GPS atual',
                  icon: const Icon(
                    Icons.gps_fixed_rounded,
                    size: 18,
                    color: Color(0xFF16A34A),
                  ),
                  onPressed: _irParaMinhaLocalizacaoGps,
                ),
                const Divider(height: 1, indent: 6, endIndent: 6),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Voltar para área central com relatos',
                  icon: Icon(
                    Icons.location_city_rounded,
                    size: 18,
                    color: widget.tema.seedColor,
                  ),
                  onPressed: _voltarParaCentroUrbano,
                ),
                const Divider(height: 1, indent: 6, endIndent: 6),
                PopupMenuButton<String>(
                  tooltip: 'Estilo do Mapa',
                  icon: const Icon(Icons.layers_outlined, size: 19),
                  onSelected: (novoEstilo) {
                    setState(() => _estiloMapbox = novoEstilo);
                  },
                  itemBuilder: (context) => _estilosMapboxDisponiveis.entries
                      .map(
                        (entry) => PopupMenuItem<String>(
                          value: entry.key,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _estiloMapbox == entry.key
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (_estiloMapbox == entry.key)
                                Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: widget.tema.seedColor,
                                ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),

        // Aviso quando o usuário arrasta para uma região sem relatos
        if (!_carregandoArea &&
            _eventos.isEmpty &&
            _anuncios.isEmpty &&
            _erroCarregamento == null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('🗺️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Nenhum relato nesta área visível. Arraste o mapa ou volte ao centro.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: _voltarParaCentroUrbano,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Centralizar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Card Flutuante do Evento ou Cluster Selecionado
        if (_eventoSelecionado != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _PreviewCardEventoFlutuante(
              evento: _eventoSelecionado!,
              api: widget.api,
              onUsuarioChanged: widget.onUsuarioChanged,
              corTema: widget.tema.seedColor,
              totalNoCluster: _clusterSelecionado.length,
              indiceNoCluster: _indiceNoCluster,
              onProximoNoCluster: _clusterSelecionado.length > 1
                  ? () {
                      setState(() {
                        _indiceNoCluster =
                            (_indiceNoCluster + 1) % _clusterSelecionado.length;
                        _eventoSelecionado =
                            _clusterSelecionado[_indiceNoCluster];
                      });
                    }
                  : null,
              onFechar: () => setState(() {
                _eventoSelecionado = null;
                _clusterSelecionado = const [];
              }),
              onVerDetalhes: () => EventoDetalheSheet.abrir(
                context,
                evento: _eventoSelecionado!,
                api: widget.api,
                onUsuarioChanged: widget.onUsuarioChanged,
              ),
            ),
          )
        else if (_anuncioSelecionado != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _PreviewCardAnuncioFlutuante(
              anuncio: _anuncioSelecionado!,
              onFechar: () => setState(() => _anuncioSelecionado = null),
            ),
          ),

        // Botão Flutuante de Criação Rápida de Relato com GPS
        Positioned(
          right: 16,
          bottom: (_eventoSelecionado != null || _anuncioSelecionado != null)
              ? 180
              : 20,
          child: FloatingActionButton.extended(
            heroTag: 'fab_criar_relato_gps',
            onPressed: _abrirCriacaoRelato,
            backgroundColor: widget.tema.seedColor,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add_location_alt_rounded, size: 21),
            label: const Text(
              'Relatar Aqui',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ClusterGeografico {
  LatLng centro;
  final List<Evento> eventos;

  _ClusterGeografico({
    required this.centro,
    required List<Evento> eventos,
  }) : eventos = List<Evento>.from(eventos);

  void adicionar(Evento novo) {
    final n = eventos.length;
    centro = LatLng(
      (centro.latitude * n + novo.lat) / (n + 1),
      (centro.longitude * n + novo.lng) / (n + 1),
    );
    eventos.add(novo);
  }
}

class _PinoEventoUnico extends StatelessWidget {
  final Evento evento;
  final bool selecionado;
  final Color corTema;

  const _PinoEventoUnico({
    required this.evento,
    required this.selecionado,
    required this.corTema,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: selecionado ? corTema : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: selecionado ? Colors.white : evento.categoriaCor,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: evento.categoriaCor.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        evento.icone,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}

class _PinoClusterEventos extends StatelessWidget {
  final _ClusterGeografico cluster;
  final bool selecionado;
  final Color corTema;

  const _PinoClusterEventos({
    required this.cluster,
    required this.selecionado,
    required this.corTema,
  });

  @override
  Widget build(BuildContext context) {
    final principal = cluster.eventos.first;
    final qtd = cluster.eventos.length;

    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: corTema.withValues(alpha: 0.22),
        shape: BoxShape.circle,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: selecionado ? const Color(0xFF0F172A) : corTema,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: corTema.withValues(alpha: 0.32),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '${principal.icone}$qtd',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PreviewCardEventoFlutuante extends StatefulWidget {
  final Evento evento;
  final ApiService api;
  final ValueChanged<ContaUsuario?>? onUsuarioChanged;
  final Color corTema;
  final int totalNoCluster;
  final int indiceNoCluster;
  final VoidCallback? onProximoNoCluster;
  final VoidCallback onFechar;
  final VoidCallback onVerDetalhes;

  const _PreviewCardEventoFlutuante({
    required this.evento,
    required this.api,
    this.onUsuarioChanged,
    required this.corTema,
    required this.totalNoCluster,
    required this.indiceNoCluster,
    this.onProximoNoCluster,
    required this.onFechar,
    required this.onVerDetalhes,
  });

  @override
  State<_PreviewCardEventoFlutuante> createState() =>
      _PreviewCardEventoFlutuanteState();
}

class _PreviewCardEventoFlutuanteState
    extends State<_PreviewCardEventoFlutuante> {
  int? _curtidasOverride;
  int? _dislikesOverride;
  String? _reacaoSelecionada;
  bool _enviandoReacao = false;
  String? _tipoCarregando;

  @override
  void didUpdateWidget(covariant _PreviewCardEventoFlutuante oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.evento.id != widget.evento.id) {
      _curtidasOverride = null;
      _dislikesOverride = null;
      _reacaoSelecionada = null;
      _enviandoReacao = false;
      _tipoCarregando = null;
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
                        'Entre para apoiar este relato',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Participe da rede colaborativa da cidade',
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
      await _alternarReacao(tipo);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao autenticar: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
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
        eventoId: widget.evento.id,
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
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(aviso),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    final evento = widget.evento;
    final corTema = widget.corTema;
    final totalNoCluster = widget.totalNoCluster;
    final indiceNoCluster = widget.indiceNoCluster;
    final onProximoNoCluster = widget.onProximoNoCluster;
    final onFechar = widget.onFechar;
    final onVerDetalhes = widget.onVerDetalhes;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (totalNoCluster > 1) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: corTema.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.layers_rounded, size: 15, color: corTema),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Grupo com $totalNoCluster relatos (${indiceNoCluster + 1}/$totalNoCluster)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: corTema,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onProximoNoCluster,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Text(
                        'Próximo ➔',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: corTema,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: evento.categoriaCor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Text(
                  evento.icone,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${evento.categoriaNome} #${evento.id}',
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
                      '📍 ${evento.localizacaoFormatada}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: ShapeDecoration(
                  color: evento.statusCorFundo,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  '${evento.statusIcone} ${evento.statusNome}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: evento.statusCorTexto,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onFechar,
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: 'Fechar card',
              ),
            ],
          ),
          if (evento.descricao.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              evento.descricao.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF334155),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _PillBotaoReacaoMapa(
                emoji: '👍',
                valor: _curtidasOverride ?? evento.curtidas,
                ativo: _reacaoSelecionada == 'like' ||
                    _reacaoSelecionada == 'apoiar',
                corAtiva: const Color(0xFF15803D),
                carregando: _enviandoReacao && _tipoCarregando == 'apoiar',
                onTap: () => _alternarReacao('apoiar'),
              ),
              const SizedBox(width: 6),
              _PillBotaoReacaoMapa(
                emoji: '👎',
                valor: _dislikesOverride ?? evento.dislikes,
                ativo: _reacaoSelecionada == 'dislike' ||
                    _reacaoSelecionada == 'discordar',
                corAtiva: const Color(0xFFB91C1C),
                carregando: _enviandoReacao && _tipoCarregando == 'discordar',
                onTap: () => _alternarReacao('discordar'),
              ),
              const SizedBox(width: 6),
              _PillBotaoReacaoMapa(
                emoji: '💬',
                valor: evento.comentarios,
                ativo: false,
                corAtiva: const Color(0xFF334155),
                onTap: onVerDetalhes,
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: onVerDetalhes,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.expand_less_rounded, size: 17),
                label: const Text(
                  'Abrir Detalhes',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillBotaoReacaoMapa extends StatelessWidget {
  final String emoji;
  final int valor;
  final bool ativo;
  final Color corAtiva;
  final bool carregando;
  final VoidCallback onTap;

  const _PillBotaoReacaoMapa({
    required this.emoji,
    required this.valor,
    required this.ativo,
    required this.corAtiva,
    this.carregando = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ativo ? corAtiva.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: carregando ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: ativo ? corAtiva : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (carregando)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    valueColor: AlwaysStoppedAnimation<Color>(corAtiva),
                  ),
                )
              else
                Text(emoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Text(
                '$valor',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: ativo ? corAtiva : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewCardAnuncioFlutuante extends StatelessWidget {
  final Anuncio anuncio;
  final VoidCallback onFechar;

  const _PreviewCardAnuncioFlutuante({
    required this.anuncio,
    required this.onFechar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(anuncio.emojiPlano, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anuncio.nomeEmpresa,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Parceiro ${anuncio.nivelPlano} · ${anuncio.segmento}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onFechar,
                icon: const Icon(Icons.close_rounded, size: 19),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            anuncio.titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: Color(0xFF0F172A),
            ),
          ),
          if (anuncio.endereco.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              '📍 ${anuncio.endereco}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
