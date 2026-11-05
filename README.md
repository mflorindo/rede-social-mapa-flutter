# Rede Social Mapa — Mobile (Flutter)

Aplicativo mobile em **Flutter** integrado à API REST (`/api/`) do backend Django.

## Estrutura

- `lib/main.dart`: Ponto de entrada do app e listagem/mapa de eventos.
- `lib/models/evento.dart`: Modelos tipados (`Evento`, `AnuncioResumo`) espelhando os schemas do Django Ninja.
- `lib/services/api_service.dart`: Cliente HTTP para consumir `/api/eventos/`, `/api/anuncios/` e `/api/estados/`.

## Como executar

1. Caso as pastas nativas (`android/`, `ios/`) ainda não tenham sido geradas na sua máquina local, rode dentro desta pasta (`flutter/`):
   ```bash
   flutter create . --project-name rede_social_mapa_mobile
   ```
2. Instale os pacotes e execute:
   ```bash
   flutter pub get
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
   ```
   *(No emulador Android, `10.0.2.2:8000` aponta para o `localhost:8000` da máquina host).*
