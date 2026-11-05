import 'dart:convert';

class ContaUsuario {
  final String nome;
  final String email;
  final String cidade;
  final String estado;
  final String provedor; // 'email', 'google', 'x'
  final bool isGestor;
  final String? token;

  const ContaUsuario({
    required this.nome,
    required this.email,
    this.cidade = 'São José',
    this.estado = 'SC',
    this.provedor = 'email',
    this.isGestor = false,
    this.token,
  });

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'email': email,
        'cidade': cidade,
        'estado': estado,
        'provedor': provedor,
        'isGestor': isGestor,
        'token': token,
      };

  factory ContaUsuario.fromJson(Map<String, dynamic> json) => ContaUsuario(
        nome: json['nome'] as String? ?? 'Usuário',
        email: json['email'] as String? ?? '',
        cidade: json['cidade'] as String? ?? 'São José',
        estado: json['estado'] as String? ?? 'SC',
        provedor: json['provedor'] as String? ?? 'email',
        isGestor: json['isGestor'] == true,
        token: json['token'] as String?,
      );

  String toJsonString() => jsonEncode(toJson());

  static ContaUsuario? fromJsonString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return ContaUsuario.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }
}
