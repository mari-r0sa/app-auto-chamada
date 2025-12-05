# app_automatizar_chamada

Este aplicativo tem como objetivo realizar a chamada de forma automática, sem interferência do professor.

## Para testar
Para testar em diferentes dispositivos, substitua o baseUrl em lib/services/api_service.dart por:
* *Na web*: localhost
* *Emulador Android*: 10.0.2.2
* *Celular físico*: IP da máquina que está rodando o back-end

Para gerar o APK:
flutter clean
flutter pub get
flutter build apk --release
