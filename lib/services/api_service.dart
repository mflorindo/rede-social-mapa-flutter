import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/anuncio.dart';
import '../models/evento.dart';

class ApiService {
  static const String _envUrl = String.fromEnvironment('API_BASE_URL');
  static const String _envMapboxToken = String.fromEnvironment(
    'MAPBOX_TOKEN',
    defaultValue:
        '',
  );
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

  ApiService({http.Client? client}) : _client = client ?? http.Client();

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
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }
}
