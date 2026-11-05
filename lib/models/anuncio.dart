import 'package:flutter/material.dart';

class Estado {
  final int id;
  final int codigoIbge;
  final String sigla;
  final String nome;

  const Estado({
    required this.id,
    required this.codigoIbge,
    required this.sigla,
    required this.nome,
  });

  factory Estado.fromJson(Map<String, dynamic> json) {
    return Estado(
      id: json['id'] as int? ?? 0,
      codigoIbge: json['codigo_ibge'] as int? ?? 0,
      sigla: json['sigla'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
    );
  }
}

class Anuncio {
  final int id;
  final String? planoNome;
  final String nomeEmpresa;
  final String segmento;
  final String endereco;
  final String horarioFuncionamento;
  final String titulo;
  final String descricao;
  final String textoBotao;
  final String dominio;
  final String urlClique;
  final String? cidade;
  final String bairro;
  final List<String> categorias;
  final bool exibirNoMapa;
  final double? lat;
  final double? lng;
  final List<String> fotos;
  final int impressoes;
  final int limiteInsercoes;
  final int? insercoesRestantes;

  const Anuncio({
    required this.id,
    this.planoNome,
    required this.nomeEmpresa,
    required this.segmento,
    required this.endereco,
    required this.horarioFuncionamento,
    required this.titulo,
    required this.descricao,
    required this.textoBotao,
    required this.dominio,
    required this.urlClique,
    this.cidade,
    required this.bairro,
    required this.categorias,
    required this.exibirNoMapa,
    this.lat,
    this.lng,
    required this.fotos,
    required this.impressoes,
    required this.limiteInsercoes,
    this.insercoesRestantes,
  });

  factory Anuncio.fromJson(Map<String, dynamic> json) {
    final rawCategorias = json['categorias'] as List<dynamic>? ?? const [];
    final rawFotos = json['fotos'] as List<dynamic>? ?? const [];

    return Anuncio(
      id: json['id'] as int,
      planoNome: json['plano_nome'] as String?,
      nomeEmpresa: json['nome_empresa'] as String? ?? 'Parceiro Local',
      segmento: json['segmento'] as String? ?? 'Comércio & Serviços',
      endereco: json['endereco'] as String? ?? '',
      horarioFuncionamento: json['horario_funcionamento'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      descricao: json['descricao'] as String? ?? '',
      textoBotao: json['texto_botao'] as String? ?? 'Visitar parceiro',
      dominio: json['dominio'] as String? ?? '',
      urlClique: json['url_clique'] as String? ?? '',
      cidade: json['cidade'] as String?,
      bairro: json['bairro'] as String? ?? '',
      categorias: rawCategorias.map((e) => e.toString()).toList(),
      exibirNoMapa: json['exibir_no_mapa'] as bool? ?? false,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      fotos: rawFotos.map((e) => e.toString()).toList(),
      impressoes: json['impressoes'] as int? ?? 0,
      limiteInsercoes: json['limite_insercoes'] as int? ?? 0,
      insercoesRestantes: json['insercoes_restantes'] as int?,
    );
  }

  String get nivelPlano {
    final lower = (planoNome ?? '').toLowerCase();
    if (lower.contains('ouro')) return 'Ouro';
    if (lower.contains('prata')) return 'Prata';
    if (lower.contains('bronze')) return 'Bronze';
    return planoNome?.isNotEmpty == true ? planoNome! : 'Parceiro';
  }

  String get emojiPlano {
    switch (nivelPlano) {
      case 'Ouro':
        return '🥇';
      case 'Prata':
        return '🥈';
      case 'Bronze':
        return '🥉';
      default:
        return '⭐';
    }
  }

  Color get corFundoPlano {
    switch (nivelPlano) {
      case 'Ouro':
        return const Color(0xFFFEF3C7);
      case 'Prata':
        return const Color(0xFFF1F5F9);
      case 'Bronze':
        return const Color(0xFFFFEDD5);
      default:
        return const Color(0xFFEDE9FE);
    }
  }

  Color get corTextoPlano {
    switch (nivelPlano) {
      case 'Ouro':
        return const Color(0xFFB45309);
      case 'Prata':
        return const Color(0xFF334155);
      case 'Bronze':
        return const Color(0xFF9A3412);
      default:
        return const Color(0xFF6D28D9);
    }
  }
}
