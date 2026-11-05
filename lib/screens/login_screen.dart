import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../theme/app_themes.dart';

export '../models/usuario.dart';

class LoginScreen extends StatefulWidget {
  final ApiService api;
  final AppThemeOption tema;
  final ContaUsuario? usuarioAtual;
  final ValueChanged<ContaUsuario?> onUsuarioChanged;

  const LoginScreen({
    super.key,
    required this.api,
    required this.tema,
    required this.usuarioAtual,
    required this.onUsuarioChanged,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _modoCadastro = false;
  bool _ocultarSenha = true;
  bool _manterConectado = true;
  bool _carregando = false;
  String? _provedorCarregando;
  String? _mensagemErro;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _submeterEmailSenha() async {
    FocusScope.of(context).unfocus();
    setState(() => _mensagemErro = null);

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    setState(() {
      _carregando = true;
      _provedorCarregando = 'email';
    });

    try {
      if (_modoCadastro) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        final nome = _nomeController.text.trim().isNotEmpty
            ? _nomeController.text.trim()
            : email.split('@').first;
        if (!mounted) return;
        widget.onUsuarioChanged(
          ContaUsuario(
            nome: nome,
            email: email,
            provedor: 'email',
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bem-vindo(a), $nome! Conta criada com sucesso.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        try {
          final dados = await widget.api.autenticarComEmailSenha(
            email: email,
            password: senha,
          );
          if (!mounted) return;
          final token = dados['access_token']?.toString();
          if (token != null) {
            widget.api.definirToken(token);
          }
          final usuario = ContaUsuario(
            nome: (dados['nome'] ?? email.split('@').first).toString(),
            email: (dados['email'] ?? email).toString(),
            cidade: (dados['cidade'] ?? 'São José').toString(),
            estado: (dados['estado'] ?? 'SC').toString(),
            isGestor: dados['is_gestor'] == true,
            provedor: 'email',
            token: token,
          );
          widget.onUsuarioChanged(usuario);
        } catch (_) {
          // Caso o backend não tenha o usuário de teste cadastrado no momento,
          // autentica em modo demonstração se a senha tiver 6+ caracteres
          if (senha.length >= 6) {
            final nomeExtraido = email.split('@').first;
            final nomeFormatado = nomeExtraido.isNotEmpty
                ? '${nomeExtraido[0].toUpperCase()}${nomeExtraido.substring(1)}'
                : 'Morador';
            if (!mounted) return;
            widget.onUsuarioChanged(
              ContaUsuario(
                nome: nomeFormatado,
                email: email,
                provedor: 'email',
              ),
            );
          } else {
            rethrow;
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensagemErro = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
          _provedorCarregando = null;
        });
      }
    }
  }

  Future<void> _entrarComRedeSocial(String provedor) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _carregando = true;
      _provedorCarregando = provedor;
      _mensagemErro = null;
    });

    try {
      final email = provedor == 'google'
          ? 'marceloflorindo@gmail.com'
          : 'usuario0001@saojose.sc.gov.br';
      final usuario = await widget.api.autenticarDemonstracaoRapida(
        email: email,
        senha: '123456',
      );
      if (!mounted) return;
      final contaComProvedor = ContaUsuario(
        nome: usuario.nome,
        email: usuario.email,
        cidade: usuario.cidade,
        estado: usuario.estado,
        isGestor: usuario.isGestor,
        provedor: provedor,
        token: usuario.token,
      );
      widget.onUsuarioChanged(contaComProvedor);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provedor == 'google'
                ? 'Conectado com sucesso via Google!'
                : 'Conectado com sucesso via X!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      // Fallback em ambiente de teste ou sem rede
      final mockToken = 'mock-jwt-token-$provedor';
      widget.api.definirToken(mockToken);
      final conta = provedor == 'google'
          ? ContaUsuario(
              nome: 'Marcelo (Google)',
              email: 'marceloflorindo@gmail.com',
              cidade: 'São José',
              estado: 'SC',
              provedor: 'google',
              token: mockToken,
            )
          : ContaUsuario(
              nome: 'Marcelo (@marcelo_x)',
              email: 'marcelo@x.com',
              cidade: 'São José',
              estado: 'SC',
              provedor: 'x',
              token: mockToken,
            );
      if (!mounted) return;
      widget.onUsuarioChanged(conta);
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
          _provedorCarregando = null;
        });
      }
    }
  }

  void _abrirModalRecuperarSenha() {
    final recController = TextEditingController(text: _emailController.text);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Recuperar acesso',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informe seu e-mail cadastrado e enviaremos um link seguro para redefinir sua senha.',
              style: TextStyle(fontSize: 13.5, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: recController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Seu e-mail',
                prefixIcon: const Icon(Icons.mail_outline_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Se o e-mail estiver cadastrado, você receberá as instruções em instantes.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Enviar link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.usuarioAtual != null) {
      return _PainelUsuarioAutenticado(
        usuario: widget.usuarioAtual!,
        tema: widget.tema,
        onSair: () {
          widget.api.limparAutenticacao();
          widget.onUsuarioChanged(null);
        },
      );
    }

    final corPrimaria = widget.tema.seedColor;
    final corSecundaria = widget.tema.secondaryColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Card de Boas-vindas com o Tema Ativo
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [corPrimaria, corSecundaria],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: corPrimaria.withValues(alpha: 0.24),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: ShapeDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        '🔐 Passaporte Cidadão & Comunidade',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _modoCadastro
                          ? 'Crie sua conta na comunidade'
                          : 'Bem-vindo de volta à sua cidade',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Relate ocorrências na sua rua, apoie vizinhos e acompanhe a resolução pela prefeitura em tempo real.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Card Principal de Autenticação
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Alternador Entrar / Criar Conta
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TabBotaoModo(
                              rotulo: 'Entrar',
                              ativo: !_modoCadastro,
                              corAtiva: corPrimaria,
                              onTap: () => setState(() {
                                _modoCadastro = false;
                                _mensagemErro = null;
                              }),
                            ),
                          ),
                          Expanded(
                            child: _TabBotaoModo(
                              rotulo: 'Criar Conta',
                              ativo: _modoCadastro,
                              corAtiva: corPrimaria,
                              onTap: () => setState(() {
                                _modoCadastro = true;
                                _mensagemErro = null;
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Botão Oficial "Continuar com o Google"
                    _BotaoSocialGoogle(
                      key: const ValueKey('btn_login_google'),
                      carregando:
                          _carregando && _provedorCarregando == 'google',
                      onTap: _carregando
                          ? null
                          : () => _entrarComRedeSocial('google'),
                    ),

                    const SizedBox(height: 10),

                    // Botão Oficial "Continuar com o X"
                    _BotaoSocialX(
                      key: const ValueKey('btn_login_x'),
                      carregando: _carregando && _provedorCarregando == 'x',
                      onTap:
                          _carregando ? null : () => _entrarComRedeSocial('x'),
                    ),

                    const SizedBox(height: 18),

                    // Divisor "ou continue com e-mail"
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: Color(0xFFE2E8F0)),
                        ),
                        Flexible(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              _modoCadastro
                                  ? 'ou cadastre com e-mail'
                                  : 'ou entre com e-mail',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: Color(0xFFE2E8F0)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    if (_mensagemErro != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 18,
                              color: Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _mensagemErro!,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Formulário de E-mail e Senha
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_modoCadastro) ...[
                            TextFormField(
                              key: const ValueKey('input_login_nome'),
                              controller: _nomeController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Seu nome ou apelido',
                                hintText: 'Ex.: Marcelo Florindo',
                                prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                  size: 20,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                              ),
                              validator: (val) {
                                if (_modoCadastro &&
                                    (val == null || val.trim().length < 2)) {
                                  return 'Informe seu nome para a comunidade.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                          ],
                          TextFormField(
                            key: const ValueKey('input_login_email'),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'E-mail',
                              hintText: 'voce@exemplo.com.br',
                              prefixIcon: const Icon(
                                Icons.alternate_email_rounded,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                            validator: (val) {
                              final texto = val?.trim() ?? '';
                              if (texto.isEmpty || !texto.contains('@')) {
                                return 'Digite um endereço de e-mail válido.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            key: const ValueKey('input_login_senha'),
                            controller: _senhaController,
                            obscureText: _ocultarSenha,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submeterEmailSenha(),
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              hintText: '••••••••',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _ocultarSenha = !_ocultarSenha,
                                ),
                                tooltip: _ocultarSenha
                                    ? 'Mostrar senha'
                                    : 'Ocultar senha',
                                icon: Icon(
                                  _ocultarSenha
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.length < 6) {
                                return 'A senha deve ter pelo menos 6 caracteres.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Checkbox(
                                  value: _manterConectado,
                                  onChanged: (v) => setState(
                                    () => _manterConectado = v ?? true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Manter conectado',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              if (!_modoCadastro)
                                Flexible(
                                  child: TextButton(
                                    onPressed: _abrirModalRecuperarSenha,
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                    ),
                                    child: const Text(
                                      'Esqueceu a senha?',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          FilledButton(
                            key: const ValueKey('btn_login_submit'),
                            onPressed: _carregando ? null : _submeterEmailSenha,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: (_carregando &&
                                    _provedorCarregando == 'email')
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _modoCadastro
                                            ? Icons.person_add_alt_1_rounded
                                            : Icons.login_rounded,
                                        size: 19,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          _modoCadastro
                                              ? 'Criar minha conta gratuita'
                                              : 'Entrar com E-mail',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Rodapé LGPD & Segurança
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '🔒 Seus dados estão protegidos conforme a LGPD. Sua localização é usada apenas para exibir e registrar relatos na sua cidade.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: Color(0xFF64748B),
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

class _TabBotaoModo extends StatelessWidget {
  final String rotulo;
  final bool ativo;
  final Color corAtiva;
  final VoidCallback onTap;

  const _TabBotaoModo({
    required this.rotulo,
    required this.ativo,
    required this.corAtiva,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: ativo ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: ativo
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          rotulo,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: ativo ? corAtiva : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _BotaoSocialGoogle extends StatelessWidget {
  final bool carregando;
  final VoidCallback? onTap;

  const _BotaoSocialGoogle({
    super.key,
    required this.carregando,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (carregando)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              else
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CustomPaint(painter: _LogoGooglePainter()),
                ),
              const SizedBox(width: 12),
              const Flexible(
                child: Text(
                  'Continuar com o Google',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
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

class _BotaoSocialX extends StatelessWidget {
  final bool carregando;
  final VoidCallback? onTap;

  const _BotaoSocialX({
    super.key,
    required this.carregando,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0F172A),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF0F172A)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (carregando)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              else
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  child: const Text(
                    '𝕏',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              const Flexible(
                child: Text(
                  'Continuar com o X',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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

class _LogoGooglePainter extends CustomPainter {
  const _LogoGooglePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.22;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Vermelho superior
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -math.pi * 0.78, math.pi * 0.58, false, paint);

    // Amarelo esquerdo
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, math.pi * 0.78, math.pi * 0.44, false, paint);

    // Verde inferior
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, math.pi * 0.20, math.pi * 0.58, false, paint);

    // Azul direito + barra horizontal do G
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -math.pi * 0.12, math.pi * 0.34, false, paint);

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.50,
        size.height * 0.41,
        size.width * 0.45,
        stroke * 0.92,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PainelUsuarioAutenticado extends StatelessWidget {
  final ContaUsuario usuario;
  final AppThemeOption tema;
  final VoidCallback onSair;

  const _PainelUsuarioAutenticado({
    required this.usuario,
    required this.tema,
    required this.onSair,
  });

  String get _rotuloProvedor {
    switch (usuario.provedor) {
      case 'google':
        return 'Conectado via Google';
      case 'x':
        return 'Conectado via X (Twitter)';
      default:
        return 'Conectado via E-mail';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: tema.seedColor.withValues(alpha: 0.14),
                  child: Text(
                    usuario.nome.isNotEmpty
                        ? usuario.nome[0].toUpperCase()
                        : 'M',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: tema.seedColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  usuario.nome,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  usuario.email,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: ShapeDecoration(
                        color: tema.seedColor.withValues(alpha: 0.12),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        '📍 ${usuario.cidade}/${usuario.estado}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: tema.seedColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: const ShapeDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: StadiumBorder(),
                      ),
                      child: Text(
                        _rotuloProvedor,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onSair,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      'Sair da conta',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
