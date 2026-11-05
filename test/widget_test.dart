import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rede_social_mapa_mobile/main.dart';
import 'package:rede_social_mapa_mobile/models/anuncio.dart';
import 'package:rede_social_mapa_mobile/models/evento.dart';
import 'package:rede_social_mapa_mobile/services/api_service.dart';
import 'package:rede_social_mapa_mobile/theme/app_themes.dart';
import 'package:rede_social_mapa_mobile/widgets/evento_detalhe_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  test('Evento.fromJson e EventoDetalhe.fromJson convertem payload da API Django Ninja', () {
    final evento = Evento.fromJson({
      'id': 42,
      'categoria': 'buraco',
      'categoria_nome': 'Buraco na pista',
      'icone': '🕳️',
      'status': 'novo',
      'status_nome': 'Novo',
      'status_icone': '🆕',
      'descricao': 'Buraco na Av. Central',
      'lat': -27.5932,
      'lng': -48.6138,
      'estado': 'SC',
      'cidade': 'São José',
      'bairro': 'Kobrasol',
      'autor': 'Marcelo',
      'curtidas': 5,
      'dislikes': 1,
      'comentarios': 3,
      'foto_capa': null,
    });

    expect(evento.id, 42);
    expect(evento.categoria, 'buraco');
    expect(evento.cidade, 'São José');
    expect(evento.curtidas, 5);
    expect(evento.localizacaoFormatada, 'Kobrasol · São José/SC');

    final detalhe = EventoDetalhe.fromJson({
      'id': 42,
      'categoria': 'buraco',
      'categoria_nome': 'Buraco na pista',
      'icone': '🕳️',
      'status': 'andamento',
      'status_nome': 'Em andamento',
      'status_icone': '🚓',
      'descricao': 'Equipe da secretaria acionada.',
      'lat': -27.5932,
      'lng': -48.6138,
      'estado': 'SC',
      'cidade': 'São José',
      'bairro': 'Kobrasol',
      'autor': 'Marcelo',
      'curtidas': 12,
      'dislikes': 0,
      'comentarios': 1,
      'foto_capa': null,
      'fotos': [],
      'lista_comentarios': [
        {
          'id': 9,
          'autor': 'Ana Paula',
          'texto': 'Passei hoje cedo e já sinalizaram com cones!',
          'pai_id': null,
          'criado_em': '2026-11-04T12:00:00Z',
          'editado_em': null,
        }
      ],
      'anuncio': {
        'id': 7,
        'nome_empresa': 'Auto Center Kobrasol',
        'segmento': 'Oficina e Alinhamento',
        'titulo': 'Alinhamento 3D com 20% OFF',
        'descricao': 'Desconto exclusivo para moradores do Kobrasol.',
        'texto_botao': 'Agendar agora',
        'url_clique': '/anuncios/7/ir/',
        'fotos': [],
      },
    });

    expect(detalhe.listaComentarios.length, 1);
    expect(detalhe.listaComentarios.first.autor, 'Ana Paula');
    expect(detalhe.anuncio?.nomeEmpresa, 'Auto Center Kobrasol');
  });

  test('Anuncio.fromJson identifica planos Ouro, Prata e Bronze corretamente', () {
    final anuncio = Anuncio.fromJson({
      'id': 10,
      'plano_nome': 'Plano Ouro',
      'nome_empresa': 'Padaria Pão Quente',
      'segmento': 'Gastronomia',
      'endereco': 'Rua Central, 100',
      'horario_funcionamento': 'Seg a Sáb 6h às 20h',
      'titulo': 'Café colonial completo',
      'descricao': 'Pães artesanais todos os dias.',
      'texto_botao': 'Ver cardápio',
      'dominio': 'paoquente.com.br',
      'url_clique': '/anuncios/10/ir/',
      'cidade': 'São José/SC',
      'bairro': 'Kobrasol',
      'categorias': ['buraco', 'iluminacao'],
      'exibir_no_mapa': true,
      'lat': -27.59,
      'lng': -48.61,
      'fotos': [],
      'impressoes': 120,
      'limite_insercoes': 1000,
      'insercoes_restantes': 880,
    });

    expect(anuncio.nivelPlano, 'Ouro');
    expect(anuncio.emojiPlano, '🥇');
  });

  testWidgets('Renderiza seletor de 4 temas, 3 abas e abre Bottom Sheet de detalhes', (tester) async {
    final mockClient = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/eventos/42')) {
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'id': 42,
            'categoria': 'buraco',
            'categoria_nome': 'Buraco na pista',
            'icone': '🕳️',
            'status': 'novo',
            'status_nome': 'Novo',
            'status_icone': '🆕',
            'descricao': 'Cratera próxima ao cruzamento principal.',
            'lat': -27.5932,
            'lng': -48.6138,
            'estado': 'SC',
            'cidade': 'São José',
            'bairro': 'Kobrasol',
            'autor': 'Marcelo',
            'curtidas': 8,
            'dislikes': 1,
            'comentarios': 1,
            'foto_capa': null,
            'fotos': [],
            'lista_comentarios': [
              {
                'id': 1,
                'autor': 'Carlos Eduardo',
                'texto': 'Realmente precisa de reparo urgente.',
                'pai_id': null,
                'criado_em': '2026-11-04T10:00:00Z',
                'editado_em': null,
              }
            ],
            'anuncio': {
              'id': 3,
              'nome_empresa': 'Borracharia Avenida',
              'segmento': 'Automotivo',
              'titulo': 'Conserto e vulcanização 24h',
              'descricao': 'Atendimento rápido no bairro.',
              'texto_botao': 'Chamar no WhatsApp',
              'url_clique': '/anuncios/3/ir/',
              'fotos': [],
            },
          })),
          200,
        );
      }
      if (path.endsWith('/eventos/')) {
        return http.Response.bytes(
          utf8.encode(jsonEncode([
            {
              'id': 42,
              'categoria': 'buraco',
              'categoria_nome': 'Buraco na pista',
              'icone': '🕳️',
              'status': 'novo',
              'status_nome': 'Novo',
              'status_icone': '🆕',
              'descricao': 'Cratera próxima ao cruzamento principal.',
              'lat': -27.5932,
              'lng': -48.6138,
              'estado': 'SC',
              'cidade': 'São José',
              'bairro': 'Kobrasol',
              'autor': 'Marcelo',
              'curtidas': 8,
              'dislikes': 1,
              'comentarios': 1,
              'foto_capa': null,
            }
          ])),
          200,
        );
      }
      if (path.endsWith('/anuncios/')) {
        return http.Response.bytes(
          utf8.encode(jsonEncode([
            {
              'id': 3,
              'plano_nome': 'Ouro',
              'nome_empresa': 'Borracharia Avenida',
              'segmento': 'Automotivo',
              'endereco': 'Av. Central, 500',
              'horario_funcionamento': '24 Horas',
              'titulo': 'Conserto e vulcanização 24h',
              'descricao': 'Atendimento rápido no bairro.',
              'texto_botao': 'Chamar no WhatsApp',
              'dominio': 'borrachariaavenida.com.br',
              'url_clique': '/anuncios/3/ir/',
              'cidade': 'São José/SC',
              'bairro': 'Kobrasol',
              'categorias': ['buraco'],
              'exibir_no_mapa': true,
              'lat': -27.594,
              'lng': -48.614,
              'fotos': [],
              'impressoes': 45,
              'limite_insercoes': 500,
              'insercoes_restantes': 455,
            }
          ])),
          200,
        );
      }
      return http.Response.bytes(utf8.encode('[]'), 200);
    });

    final api = ApiService(client: mockClient);

    await tester.pumpWidget(RedeSocialMapaApp(apiService: api));
    await tester.pumpAndSettle();

    // Verifica os 4 temas e alternância para Oceano
    expect(AppThemes.opcoes.length, 4);
    expect(find.text('Floresta'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tema_oceano')));
    await tester.pumpAndSettle();
    expect(find.text('Oceano'), findsOneWidget);

    // Verifica que o card do evento aparece na aba Explorar
    expect(find.text('Buraco na pista #42'), findsWidgets);

    // Abre o Bottom Sheet de Detalhes do Evento
    await tester.tap(find.text('Buraco na pista #42').first);
    await tester.pumpAndSettle();

    expect(find.text('Comentários da Comunidade'), findsOneWidget);
    expect(find.text('Realmente precisa de reparo urgente.'), findsOneWidget);
    expect(find.text('Borracharia Avenida'), findsOneWidget);

    // Fecha o Bottom Sheet
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Navega para a aba Mapa Radar
    await tester.tap(find.text('Mapa Radar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Radar ·'), findsOneWidget);

    // Navega para a aba Parceiros
    await tester.tap(find.text('Parceiros'));
    await tester.pumpAndSettle();
    expect(find.text('Parceiros da Cidade'), findsOneWidget);
    expect(find.text('🥇 Plano Ouro'), findsOneWidget);
  });

  testWidgets('Layout responsivo em tela mobile estreita (360x740) sem overflow e com clusterização', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final eventosProximos = List.generate(
      25,
      (i) => {
        'id': 100 + i,
        'categoria': i.isEven ? 'buraco' : 'iluminacao',
        'categoria_nome': i.isEven ? 'Buraco na pista' : 'Falta de iluminação',
        'icone': i.isEven ? '🕳️' : '💡',
        'status': 'novo',
        'status_nome': 'Novo',
        'status_icone': '🆕',
        'descricao': 'Relato próximo #$i na mesma avenida',
        'lat': -27.5930 + (i % 5) * 0.0002,
        'lng': -48.6130 + (i ~/ 5) * 0.0002,
        'estado': 'SC',
        'cidade': 'São José',
        'bairro': 'Kobrasol',
        'autor': 'Morador $i',
        'curtidas': i,
        'dislikes': 0,
        'comentarios': 0,
        'foto_capa': null,
      },
    );

    final mockClient = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/eventos/')) {
        return http.Response.bytes(
          utf8.encode(jsonEncode(eventosProximos)),
          200,
        );
      }
      return http.Response.bytes(utf8.encode('[]'), 200);
    });

    final api = ApiService(client: mockClient);
    await tester.pumpWidget(RedeSocialMapaApp(apiService: api));
    await tester.pumpAndSettle();

    // Título completo visível no mobile sem overflow
    expect(find.text('Rede Social Mapa'), findsOneWidget);
    expect(find.text('Zeladoria · Tema Floresta'), findsOneWidget);

    // Abre Mapa Radar em 360px e garante ausência de RenderFlex overflow
    await tester.tap(find.text('Mapa Radar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Radar · 25 relatos'), findsOneWidget);

    // Abre a aba Entrar (Login com E-mail/Senha, Google e X) em 360px
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Continuar com o Google'), findsOneWidget);
    expect(find.text('Continuar com o X'), findsOneWidget);
    expect(find.byKey(const ValueKey('input_login_email')), findsOneWidget);
    expect(find.byKey(const ValueKey('input_login_senha')), findsOneWidget);

    // Testa autenticação social com o botão do X
    await tester.tap(find.byKey(const ValueKey('btn_login_x')));
    await tester.pumpAndSettle();
    expect(find.text('Conectado via X (Twitter)'), findsOneWidget);

    // Garante que o botão da barra inferior mudou de 'Entrar' para 'Sair'
    expect(find.text('Sair'), findsWidgets);
    expect(find.text('Entrar'), findsNothing);

    // Clica no botão Sair da barra inferior e confirma no bottom sheet
    await tester.tap(find.text('Sair').last);
    await tester.pumpAndSettle();
    expect(find.text('Encerrar Sessão'), findsOneWidget);
    await tester.tap(find.text('Sim, sair da conta'));
    await tester.pumpAndSettle();

    // Garante que o usuário foi deslogado e o botão voltou para 'Entrar'
    expect(find.text('Entrar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('ApiService.reagirEvento envia payload apoiar e discordar com token Bearer', () async {
    String? tokenEnviado;
    String? bodyEnviado;

    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/curtir')) {
        tokenEnviado = request.headers['Authorization'];
        bodyEnviado = request.body;
        final decoded = jsonDecode(request.body) as Map<String, dynamic>;
        final tipo = decoded['tipo'];
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'acao': 'adicionado',
            'tipo': tipo == 'apoiar' ? 'like' : 'dislike',
            'apoiado': tipo == 'apoiar',
            'discordado': tipo == 'discordar',
            'curtidas': tipo == 'apoiar' ? 1 : 0,
            'dislikes': tipo == 'discordar' ? 1 : 0,
          })),
          200,
        );
      }
      return http.Response.bytes(utf8.encode('{}'), 404);
    });

    final api = ApiService(client: mockClient, authToken: 'jwt-token-123');

    // 1. Testa Apoiar
    final resApoiar = await api.reagirEvento(eventoId: 42, tipo: 'apoiar');
    expect(tokenEnviado, 'Bearer jwt-token-123');
    expect(jsonDecode(bodyEnviado!)['tipo'], 'apoiar');
    expect(resApoiar['apoiado'], isTrue);
    expect(resApoiar['curtidas'], 1);

    // 2. Testa Discordar
    final resDiscordar = await api.reagirEvento(eventoId: 42, tipo: 'discordar');
    expect(jsonDecode(bodyEnviado!)['tipo'], 'discordar');
    expect(resDiscordar['discordado'], isTrue);
    expect(resDiscordar['dislikes'], 1);
  });

  testWidgets('EventoDetalheSheet: Apoiar e Discordar com fluxo de autenticação e feedback', (tester) async {
    final eventoBase = Evento.fromJson({
      'id': 42,
      'categoria': 'buraco',
      'categoria_nome': 'Buraco na pista',
      'icone': '🕳️',
      'status': 'novo',
      'status_nome': 'Novo',
      'status_icone': '🆕',
      'descricao': 'Buraco na pista',
      'lat': -27.5932,
      'lng': -48.6138,
      'estado': 'SC',
      'cidade': 'São José',
      'bairro': 'Kobrasol',
      'autor': 'Morador',
      'curtidas': 0,
      'dislikes': 0,
      'comentarios': 0,
      'foto_capa': null,
    });

    final detalheJson = {
      'id': 42,
      'categoria': 'buraco',
      'categoria_nome': 'Buraco na pista',
      'icone': '🕳️',
      'status': 'novo',
      'status_nome': 'Novo',
      'status_icone': '🆕',
      'descricao': 'Buraco na pista',
      'lat': -27.5932,
      'lng': -48.6138,
      'estado': 'SC',
      'cidade': 'São José',
      'bairro': 'Kobrasol',
      'autor': 'Morador',
      'curtidas': 0,
      'dislikes': 0,
      'comentarios': 0,
      'foto_capa': null,
      'criado_em': DateTime.now().toIso8601String(),
      'fotos': <Map<String, dynamic>>[],
      'lista_comentarios': <Map<String, dynamic>>[],
      'anuncio': null,
    };

    final mockClient = MockClient((request) async {
      if (request.url.path == '/api/eventos/42') {
        return http.Response.bytes(utf8.encode(jsonEncode(detalheJson)), 200);
      }
      if (request.url.path.endsWith('/curtir')) {
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'acao': 'adicionado',
            'tipo': 'like',
            'apoiado': true,
            'discordado': false,
            'curtidas': 1,
            'dislikes': 0,
          })),
          200,
        );
      }
      if (request.url.path.endsWith('/comentarios')) {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'id': 99,
            'autor': 'Marcelo',
            'texto': body['texto'],
            'pai_id': null,
            'criado_em': DateTime.now().toIso8601String(),
            'editado_em': null,
          })),
          201,
        );
      }
      return http.Response.bytes(utf8.encode('{}'), 404);
    });

    final api = ApiService(client: mockClient, authToken: 'fake-jwt-token');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: ElevatedButton(
                onPressed: () => EventoDetalheSheet.abrir(
                  ctx,
                  evento: eventoBase,
                  api: api,
                ),
                child: const Text('Abrir Detalhe'),
              ),
            ),
          ),
        ),
      ),
    );

    // Abre a sheet
    await tester.tap(find.text('Abrir Detalhe'));
    await tester.pumpAndSettle();

    // Verifica que os botões de Apoiar e Discordar estão visíveis
    expect(find.text('Apoiar (0)'), findsOneWidget);
    expect(find.text('Discordar (0)'), findsOneWidget);

    // Clica em Apoiar
    await tester.tap(find.text('Apoiar (0)'));
    await tester.pumpAndSettle();

    // Contador deve atualizar para Apoiar (1) e feedback visível no sheet
    expect(find.text('Apoiar (1)'), findsOneWidget);
    expect(find.text('Você apoiou este relato! 👍'), findsOneWidget);

    // Rola até o campo de comentário e publica
    final btnComentar = find.byTooltip('Publicar comentário');
    await tester.ensureVisible(btnComentar);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'Já avisei a prefeitura deste buraco!',
    );
    await tester.tap(btnComentar);
    await tester.pumpAndSettle();

    expect(find.text('Já avisei a prefeitura deste buraco!'), findsOneWidget);
    expect(find.text('Comentário publicado! 💬'), findsOneWidget);
  });
}
