import 'package:flutter/material.dart';

enum AppThemeKey {
  floresta,
  oceano,
  porDoSol,
  violeta,
}

class AppThemeOption {
  final AppThemeKey key;
  final String nome;
  final Color seedColor;
  final Color secondaryColor;
  final IconData icone;

  const AppThemeOption({
    required this.key,
    required this.nome,
    required this.seedColor,
    required this.secondaryColor,
    required this.icone,
  });
}

class AppThemes {
  static const List<AppThemeOption> opcoes = [
    AppThemeOption(
      key: AppThemeKey.floresta,
      nome: 'Floresta',
      seedColor: Color(0xFF4D7C0F),
      secondaryColor: Color(0xFF15803D),
      icone: Icons.park_rounded,
    ),
    AppThemeOption(
      key: AppThemeKey.oceano,
      nome: 'Oceano',
      seedColor: Color(0xFF0369A1),
      secondaryColor: Color(0xFF0284C7),
      icone: Icons.water_drop_rounded,
    ),
    AppThemeOption(
      key: AppThemeKey.porDoSol,
      nome: 'Pôr do Sol',
      seedColor: Color(0xFFC2410C),
      secondaryColor: Color(0xFFEA580C),
      icone: Icons.wb_twilight_rounded,
    ),
    AppThemeOption(
      key: AppThemeKey.violeta,
      nome: 'Violeta',
      seedColor: Color(0xFF6D28D9),
      secondaryColor: Color(0xFF7C3AED),
      icone: Icons.auto_awesome_rounded,
    ),
  ];

  static AppThemeOption porChave(AppThemeKey key) {
    return opcoes.firstWhere(
      (o) => o.key == key,
      orElse: () => opcoes.first,
    );
  }

  static ThemeData construirTema(AppThemeOption opcao) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: opcao.seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: colorScheme.primary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        backgroundColor: Colors.white,
        selectedColor: opcao.seedColor.withValues(alpha: 0.14),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: opcao.seedColor.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selecionado = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selecionado ? FontWeight.w800 : FontWeight.w600,
            color: selecionado ? opcao.seedColor : const Color(0xFF64748B),
          );
        }),
      ),
    );
  }
}
