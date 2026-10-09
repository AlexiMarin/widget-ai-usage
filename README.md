# AI Usage

Widget de escritorio para macOS que muestra el uso de tu suscripción de Claude (sesión de 5 h, semanal y Opus/Sonnet) en anillos, al estilo del widget de Baterías. OpenAI llegará en una fase 2.

## Requisitos

- macOS 15 o posterior
- **Xcode** completo (App Store), no solo las Command Line Tools. Ábrelo una vez para aceptar la licencia.
- **XcodeGen**: `brew install xcodegen`
- **Certificado "Apple Development"**. Sirve una cuenta Apple gratuita:
  Xcode → Settings → Accounts → `+` → Apple ID → selecciona el equipo → *Manage Certificates…* → `+` → *Apple Development*.
- **Claude Code** instalado y con sesión iniciada (`claude`). El widget lee esa sesión del Keychain.

## Instalar

```sh
make install
```

Esto genera el proyecto, compila con tu certificado e instala `AI Usage.app` en `~/Applications`. Después:

1. Debe aparecer `✳︎ N%` en la barra de menú. En el menú, activa **Abrir al iniciar sesión**.
2. Clic derecho en el escritorio → **Editar widgets** → busca **AI Usage**.

`make check` comprueba solo los requisitos. Si tienes varios certificados de distintos equipos, elige uno con `make install TEAM_ID=XXXXXXXXXX`.

## Cómo funciona

- La app de la barra de menú lee cada 5 min la sesión de Claude Code (`Claude Code-credentials` en el Keychain), consulta `https://api.anthropic.com/api/oauth/usage` y deja el resultado en un App Group compartido con el widget.
- La app **nunca renueva la sesión** (eso cerraría tu sesión de Claude Code). Si caduca, el widget muestra "Token expirado". Se arregla solo al volver a usar Claude Code.
- Es el mismo endpoint que usa `/usage` en Claude Code. No está documentado y podría cambiar.
