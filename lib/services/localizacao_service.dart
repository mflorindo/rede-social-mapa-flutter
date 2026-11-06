import 'package:geolocator/geolocator.dart';

class LocalizacaoService {
  /// Obtém a localização GPS atual do aparelho celular com tratamento de permissões
  static Future<Position> obterPosicaoAtual() async {
    final servicoHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicoHabilitado) {
      throw Exception(
        'O serviço de localização (GPS) do celular está desativado. Por favor, ative-o nas configurações.',
      );
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.denied) {
        throw Exception(
          'Permissão de localização negada pelo usuário.',
        );
      }
    }

    if (permissao == LocationPermission.deniedForever) {
      throw Exception(
        'A permissão de localização foi negada permanentemente. É necessário liberar nas configurações do aplicativo.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (_) {
      // Fallback para última posição conhecida se o GPS demorar para fixar
      final ultima = await Geolocator.getLastKnownPosition();
      if (ultima != null) return ultima;
      rethrow;
    }
  }
}
