import 'package:flutter/material.dart';

class FotoEvento {
  final int id;
  final String url;
  final int ordem;

  const FotoEvento({
    required this.id,
    required this.url,
    required this.ordem,
  });

  factory FotoEvento.fromJson(Map<String, dynamic> json) {
    return FotoEvento(
      id: json['id'] as int? ?? 0,
      url: json['url'] as String? ?? '',
      ordem: json['ordem'] as int? ?? 0,
    );
  }
}

class ComentarioEvento {
  final int id;
  final String autor;
  final String texto;
  final int? paiId;
  final DateTime? criadoEm;
  final DateTime? editadoEm;

  const ComentarioEvento({
    required this.id,
    required this.autor,
    required this.texto,
    this.paiId,
    this.criadoEm,
    this.editadoEm,
  });

  factory ComentarioEvento.fromJson(Map<String, dynamic> json) {
    return ComentarioEvento(
      id: json['id'] as int? ?? 0,
      autor: json['autor'] as String? ?? 'Morador',
      texto: json['texto'] as String? ?? '',
      paiId: json['pai_id'] as int?,
      criadoEm: json['criado_em'] != null
          ? DateTime.tryParse(json['criado_em'].toString())
          : null,
      editadoEm: json['editado_em'] != null
          ? DateTime.tryParse(json['editado_em'].toString())
          : null,
    );
  }
}

class AnuncioResumo {
  final int id;
  final String nomeEmpresa;
  final String segmento;
  final String titulo;
  final String descricao;
  final String textoBotao;
  final String urlClique;
  final List<String> fotos;

  const AnuncioResumo({
    required this.id,
    required this.nomeEmpresa,
    required this.segmento,
    required this.titulo,
    required this.descricao,
    required this.textoBotao,
    required this.urlClique,
    required this.fotos,
  });

  factory AnuncioResumo.fromJson(Map<String, dynamic> json) {
    final rawFotos = json['fotos'] as List<dynamic>? ?? const [];
    return AnuncioResumo(
      id: json['id'] as int? ?? 0,
      nomeEmpresa: json['nome_empresa'] as String? ?? 'Parceiro Local',
      segmento: json['segmento'] as String? ?? 'Comércio & Serviços',
      titulo: json['titulo'] as String? ?? '',
      descricao: json['descricao'] as String? ?? '',
      textoBotao: json['texto_botao'] as String? ?? 'Saiba mais',
      urlClique: json['url_clique'] as String? ?? '',
      fotos: rawFotos.map((e) => e.toString()).toList(),
    );
  }
}

class CategoriaFiltro {
  final String slug;
  final String nome;
  final String icone;

  const CategoriaFiltro({
    required this.slug,
    required this.nome,
    required this.icone,
  });

  static const List<CategoriaFiltro> todas = [
    CategoriaFiltro(slug: '', nome: 'Todas', icone: '✨'),
    CategoriaFiltro(slug: 'buraco', nome: 'Buraco', icone: '🕳️'),
    CategoriaFiltro(slug: 'alagamento', nome: 'Alagamento', icone: '🌊'),
    CategoriaFiltro(slug: 'iluminacao', nome: 'Iluminação', icone: '💡'),
    CategoriaFiltro(slug: 'lixo', nome: 'Lixo', icone: '🗑️'),
    CategoriaFiltro(slug: 'outro', nome: 'Outro', icone: '📍'),
  ];
}

class Evento {
  final int id;
  final String categoria;
  final String categoriaNome;
  final String icone;
  final String status;
  final String statusNome;
  final String statusIcone;
  final String descricao;
  final double lat;
  final double lng;
  final String estado;
  final String cidade;
  final String bairro;
  final String autor;
  final int curtidas;
  final int dislikes;
  final int comentarios;
  final String? fotoCapa;
  final DateTime? criadoEm;

  const Evento({
    required this.id,
    required this.categoria,
    required this.categoriaNome,
    required this.icone,
    required this.status,
    required this.statusNome,
    required this.statusIcone,
    required this.descricao,
    required this.lat,
    required this.lng,
    required this.estado,
    required this.cidade,
    required this.bairro,
    required this.autor,
    required this.curtidas,
    required this.dislikes,
    required this.comentarios,
    this.fotoCapa,
    this.criadoEm,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      id: json['id'] as int,
      categoria: json['categoria'] as String? ?? 'outro',
      categoriaNome: json['categoria_nome'] as String? ?? 'Outro',
      icone: json['icone'] as String? ?? '📍',
      status: json['status'] as String? ?? 'novo',
      statusNome: json['status_nome'] as String? ?? 'Novo',
      statusIcone: json['status_icone'] as String? ?? '🆕',
      descricao: json['descricao'] as String? ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      estado: json['estado'] as String? ?? '',
      cidade: json['cidade'] as String? ?? '',
      bairro: json['bairro'] as String? ?? '',
      autor: json['autor'] as String? ?? 'Morador',
      curtidas: json['curtidas'] as int? ?? 0,
      dislikes: json['dislikes'] as int? ?? 0,
      comentarios: json['comentarios'] as int? ?? 0,
      fotoCapa: json['foto_capa'] as String?,
      criadoEm: json['criado_em'] != null
          ? DateTime.tryParse(json['criado_em'].toString())
          : null,
    );
  }

  String get localizacaoFormatada {
    final partes = <String>[
      if (bairro.trim().isNotEmpty) bairro.trim(),
      if (cidade.trim().isNotEmpty && estado.trim().isNotEmpty)
        '${cidade.trim()}/${estado.trim()}'
      else if (cidade.trim().isNotEmpty)
        cidade.trim()
      else if (estado.trim().isNotEmpty)
        estado.trim(),
    ];
    return partes.isEmpty ? 'Localização no mapa' : partes.join(' · ');
  }

  Color get statusCorFundo {
    switch (status) {
      case 'novo':
        return const Color(0xFFDBEAFE);
      case 'analise':
      case 'em_analise':
        return const Color(0xFFFEF3C7);
      case 'andamento':
      case 'em_andamento':
        return const Color(0xFFFFEDD5);
      case 'resolvido':
        return const Color(0xFFDCFCE7);
      case 'rejeitado':
      case 'invalido':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color get statusCorTexto {
    switch (status) {
      case 'novo':
        return const Color(0xFF1D4ED8);
      case 'analise':
      case 'em_analise':
        return const Color(0xFFB45309);
      case 'andamento':
      case 'em_andamento':
        return const Color(0xFFC2410C);
      case 'resolvido':
        return const Color(0xFF15803D);
      case 'rejeitado':
      case 'invalido':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFF334155);
    }
  }

  Color get categoriaCor {
    switch (categoria) {
      case 'buraco':
        return const Color(0xFFEA580C);
      case 'alagamento':
        return const Color(0xFF0284C7);
      case 'iluminacao':
        return const Color(0xFFD97706);
      case 'lixo':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF6D28D9);
    }
  }
}

class EventoDetalhe extends Evento {
  final List<FotoEvento> fotos;
  final List<ComentarioEvento> listaComentarios;
  final AnuncioResumo? anuncio;

  const EventoDetalhe({
    required super.id,
    required super.categoria,
    required super.categoriaNome,
    required super.icone,
    required super.status,
    required super.statusNome,
    required super.statusIcone,
    required super.descricao,
    required super.lat,
    required super.lng,
    required super.estado,
    required super.cidade,
    required super.bairro,
    required super.autor,
    required super.curtidas,
    required super.dislikes,
    required super.comentarios,
    super.fotoCapa,
    super.criadoEm,
    this.fotos = const [],
    this.listaComentarios = const [],
    this.anuncio,
  });

  factory EventoDetalhe.fromJson(Map<String, dynamic> json) {
    final base = Evento.fromJson(json);
    final rawFotos = json['fotos'] as List<dynamic>? ?? const [];
    final rawComentarios = json['lista_comentarios'] as List<dynamic>? ?? const [];
    final rawAnuncio = json['anuncio'] as Map<String, dynamic>?;

    return EventoDetalhe(
      id: base.id,
      categoria: base.categoria,
      categoriaNome: base.categoriaNome,
      icone: base.icone,
      status: base.status,
      statusNome: base.statusNome,
      statusIcone: base.statusIcone,
      descricao: base.descricao,
      lat: base.lat,
      lng: base.lng,
      estado: base.estado,
      cidade: base.cidade,
      bairro: base.bairro,
      autor: base.autor,
      curtidas: base.curtidas,
      dislikes: base.dislikes,
      comentarios: base.comentarios,
      fotoCapa: base.fotoCapa,
      criadoEm: base.criadoEm,
      fotos: rawFotos
          .map((item) => FotoEvento.fromJson(item as Map<String, dynamic>))
          .toList(),
      listaComentarios: rawComentarios
          .map((item) => ComentarioEvento.fromJson(item as Map<String, dynamic>))
          .toList(),
      anuncio: rawAnuncio != null ? AnuncioResumo.fromJson(rawAnuncio) : null,
    );
  }

  factory EventoDetalhe.fromEvento(Evento e) {
    return EventoDetalhe(
      id: e.id,
      categoria: e.categoria,
      categoriaNome: e.categoriaNome,
      icone: e.icone,
      status: e.status,
      statusNome: e.statusNome,
      statusIcone: e.statusIcone,
      descricao: e.descricao,
      lat: e.lat,
      lng: e.lng,
      estado: e.estado,
      cidade: e.cidade,
      bairro: e.bairro,
      autor: e.autor,
      curtidas: e.curtidas,
      dislikes: e.dislikes,
      comentarios: e.comentarios,
      fotoCapa: e.fotoCapa,
      criadoEm: e.criadoEm,
      fotos: e.fotoCapa != null
          ? [FotoEvento(id: 0, url: e.fotoCapa!, ordem: 0)]
          : const [],
    );
  }
}
