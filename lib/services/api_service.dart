import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/anuncio.dart';
import '../models/evento.dart';
import '../models/usuario.dart';

class ApiService {
  static const String _envUrl = String.fromEnvironment('API_BASE_URL');
  static const String _envMapboxToken = String.fromEnvironment(
    'MAPBOX_TOKEN',
    defaultValue: '',
  );
  static const String _chaveToken = 'auth_token';
  static const String _chaveUsuario = 'usuario_logado';

  String? _cachedMapboxToken;

  static String get baseUrl {
    if (_envUrl.isNotEmpty) return _envUrl;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return 'http://localhost:8000/api';
    }
    return 'http://10.0.2.2:8000/api';
  }

  static String get serverOrigin {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.authority}';
  }

  static String? resolverUrlMidia(String? caminho) {
    if (caminho == null || caminho.trim().isEmpty) return null;
    if (caminho.startsWith('http://') || caminho.startsWith('https://')) {
      return caminho;
    }
    final prefixo = caminho.startsWith('/') ? '' : '/';
    return '$serverOrigin$prefixo$caminho';
  }

  final http.Client _client;
  String? _authToken;

  ApiService({http.Client? client, String? authToken})
      : _client = client ?? http.Client(),
        _authToken = authToken;

  String? get authToken => _authToken;
  bool get estaAutenticado => _authToken != null && _authToken!.trim().isNotEmpty;

  void definirToken(String? token) {
    _authToken = token;
  }

  Future<void> salvarSessao(String token, [ContaUsuario? usuario]) async {
    _authToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chaveToken, token);
      if (usuario != null) {
        await prefs.setString(_chaveUsuario, usuario.toJsonString());
      }
    } catch (_) {}
  }

  Future<String?> carregarTokenSalvo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_chaveToken);
      if (token != null && token.isNotEmpty) {
        _authToken = token;
        return token;
      }
    } catch (_) {}
    return null;
  }

  Future<ContaUsuario?> carregarUsuarioSalvo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_chaveUsuario);
      return ContaUsuario.fromJsonString(raw);
    } catch (_) {}
    return null;
  }

  Future<void> limparAutenticacao() async {
    _authToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chaveToken);
      await prefs.remove(_chaveUsuario);
    } catch (_) {}
  }

  Future<List<Evento>> listarEventos({
    String? categoria,
    String? status,
    String? estado,
    String? cidade,
    double? minLat,
    double? maxLat,
    double? minLng,
    double? maxLng,
    bool incluirResolvidos = false,
    int limite = 100,
  }) async {
    final params = <String, String>{
      'limite': limite.toString(),
      if (incluirResolvidos) 'incluir_resolvidos': 'true',
      if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
      if (status != null && status.isNotEmpty) 'status': status,
      if (estado != null && estado.isNotEmpty) 'estado': estado,
      if (cidade != null && cidade.isNotEmpty) 'cidade': cidade,
      if (minLat != null) 'min_lat': minLat.toStringAsFixed(6),
      if (maxLat != null) 'max_lat': maxLat.toStringAsFixed(6),
      if (minLng != null) 'min_lng': minLng.toStringAsFixed(6),
      if (maxLng != null) 'max_lng': maxLng.toStringAsFixed(6),
    };
    final uri = Uri.parse('$baseUrl/eventos/').replace(queryParameters: params);
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Falha ao carregar eventos (${response.statusCode})');
    }
    final List<dynamic> dados =
        jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return dados
        .map((item) => Evento.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<EventoDetalhe> obterEvento(int eventoId) async {
    final uri = Uri.parse('$baseUrl/eventos/$eventoId');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
        'Falha ao carregar detalhes do evento #$eventoId (${response.statusCode})',
      );
    }
    final Map<String, dynamic> dados =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return EventoDetalhe.fromJson(dados);
  }

  Future<List<Anuncio>> listarAnuncios({
    int? cidadeId,
    String? bairro,
    String? categoria,
    bool apenasMapa = false,
    double? minLat,
    double? maxLat,
    double? minLng,
    double? maxLng,
  }) async {
    final params = <String, String>{
      if (cidadeId != null) 'cidade_id': cidadeId.toString(),
      if (bairro != null && bairro.isNotEmpty) 'bairro': bairro,
      if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
      if (apenasMapa) 'apenas_mapa': 'true',
      if (minLat != null) 'min_lat': minLat.toStringAsFixed(6),
      if (maxLat != null) 'max_lat': maxLat.toStringAsFixed(6),
      if (minLng != null) 'min_lng': minLng.toStringAsFixed(6),
      if (maxLng != null) 'max_lng': maxLng.toStringAsFixed(6),
    };
    final uri = Uri.parse('$baseUrl/anuncios/')
        .replace(queryParameters: params.isEmpty ? null : params);
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Falha ao carregar parceiros (${response.statusCode})');
    }
    final List<dynamic> dados =
        jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return dados
        .map((item) => Anuncio.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> registrarCliqueAnuncio(int anuncioId) async {
    final uri = Uri.parse('$baseUrl/anuncios/$anuncioId/clique');
    final response = await _client.post(uri);
    if (response.statusCode != 200) {
      throw Exception('Falha ao registrar clique (${response.statusCode})');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<List<Estado>> listarEstados() async {
    final uri = Uri.parse('$baseUrl/estados');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Falha ao carregar estados (${response.statusCode})');
    }
    final List<dynamic> dados =
        jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return dados
        .map((item) => Estado.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<String> obterMapboxToken() async {
    if (_envMapboxToken.isNotEmpty) return _envMapboxToken;
    if (_cachedMapboxToken != null) return _cachedMapboxToken!;
    try {
      final uri = Uri.parse('$baseUrl/config');
      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          final token = (decoded['mapbox_token'] ?? '').toString().trim();
          _cachedMapboxToken = token;
          return token;
        }
      }
    } catch (_) {
      // Fallback silencioso caso offline ou em ambiente de teste
    }
    return '';
  }

  Future<Map<String, dynamic>> autenticarComEmailSenha({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );
    if (response.statusCode != 200) {
      String mensagem = 'E-mail ou senha inválidos.';
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
          mensagem = decoded['detail'].toString();
        }
      } catch (_) {}
      throw Exception(mensagem);
    }
    final dados =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (dados['access_token'] != null) {
      final token = dados['access_token'].toString();
      _authToken = token;
      final usuario = ContaUsuario(
        nome: (dados['nome'] ?? email.split('@').first).toString(),
        email: (dados['email'] ?? email).toString(),
        cidade: (dados['cidade'] ?? 'São José').toString(),
        estado: (dados['estado'] ?? 'SC').toString(),
        isGestor: dados['is_gestor'] == true,
        provedor: 'email',
        token: token,
      );
      await salvarSessao(token, usuario);
    }
    return dados;
  }

  /// Autenticação rápida de demonstração conectando diretamente na API
  Future<ContaUsuario> autenticarDemonstracaoRapida({
    String email = 'marceloflorindo@gmail.com',
    String senha = '123456',
  }) async {
    final dados = await autenticarComEmailSenha(
      email: email,
      password: senha,
    );
    final token = (dados['access_token'] ?? '').toString();
    final usuario = ContaUsuario(
      nome: (dados['nome'] ?? 'Marcelo').toString(),
      email: (dados['email'] ?? email).toString(),
      cidade: (dados['cidade'] ?? 'São José').toString(),
      estado: (dados['estado'] ?? 'SC').toString(),
      isGestor: dados['is_gestor'] == true,
      provedor: 'email',
      token: token,
    );
    await salvarSessao(token, usuario);
    return usuario;
  }

  /// Registra ou alterna reação de apoio (like) ou discordância (dislike) em um evento
  Future<Map<String, dynamic>> reagirEvento({
    required int eventoId,
    required String tipo, // 'apoiar' / 'like' ou 'discordar' / 'dislike'
  }) async {
    final uri = Uri.parse('$baseUrl/eventos/$eventoId/curtir');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_authToken != null && _authToken!.isNotEmpty)
        'Authorization': 'Bearer $_authToken',
    };
    final response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode({
        'tipo': tipo,
      }),
    );
    if (response.statusCode != 200) {
      String mensagem = 'Erro ao registrar reação.';
      if (response.statusCode == 401) {
        mensagem = 'Você precisa estar logado para apoiar ou discordar.';
      } else {
        try {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
            mensagem = decoded['detail'].toString();
          }
        } catch (_) {}
      }
      throw Exception(mensagem);
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  /// Registra reação em um comentário de evento
  Future<Map<String, dynamic>> reagirComentario({
    required int comentarioId,
    required String tipo,
  }) async {
    final uri = Uri.parse('$baseUrl/eventos/comentarios/$comentarioId/curtir');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_authToken != null && _authToken!.isNotEmpty)
        'Authorization': 'Bearer $_authToken',
    };
    final response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode({
        'tipo': tipo,
      }),
    );
    if (response.statusCode != 200) {
      String mensagem = 'Erro ao registrar reação no comentário.';
      if (response.statusCode == 401) {
        mensagem = 'Você precisa estar logado para reagir aos comentários.';
      } else {
        try {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
            mensagem = decoded['detail'].toString();
          }
        } catch (_) {}
      }
      throw Exception(mensagem);
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  /// Adiciona um novo comentário a um evento
  Future<ComentarioEvento> adicionarComentario({
    required int eventoId,
    required String texto,
    int? paiId,
  }) async {
    final uri = Uri.parse('$baseUrl/eventos/$eventoId/comentarios');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_authToken != null && _authToken!.isNotEmpty)
        'Authorization': 'Bearer $_authToken',
    };
    final response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode({
        'texto': texto.trim(),
        if (paiId != null) 'pai_id': paiId,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      String mensagem = 'Erro ao enviar comentário.';
      if (response.statusCode == 401) {
        mensagem = 'Você precisa estar logado para comentar.';
      } else {
        try {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
            mensagem = decoded['detail'].toString();
          }
        } catch (_) {}
      }
      throw Exception(mensagem);
    }
    final dados =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return ComentarioEvento.fromJson(dados);
  }

  /// Publica um novo evento/relato com coordenadas geográficas do usuário
  Future<Evento> criarEvento({
    required String categoria,
    required String descricao,
    required double lat,
    required double lng,
  }) async {
    final uri = Uri.parse('$baseUrl/eventos/');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_authToken != null && _authToken!.isNotEmpty)
        'Authorization': 'Bearer $_authToken',
    };
    final response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode({
        'categoria': categoria,
        'descricao': descricao.trim(),
        'lat': lat,
        'lng': lng,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      String mensagem = 'Erro ao criar relato.';
      if (response.statusCode == 401) {
        mensagem = 'Você precisa estar logado para publicar um relato.';
      } else {
        try {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
            mensagem = decoded['detail'].toString();
          }
        } catch (_) {}
      }
      throw Exception(mensagem);
    }
    final dados =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return Evento.fromJson(dados);
  }
}
