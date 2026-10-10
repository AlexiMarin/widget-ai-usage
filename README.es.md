**Español** · [English](README.md)

# AI Usage

Widget de escritorio para macOS que muestra el uso de tu suscripción de Claude (sesión de 5 h y semanal) en anillos, al estilo del widget de Baterías. Cada widget muestra un proveedor, que eliges en los ajustes del widget. OpenAI llegará en una fase 2.

<p align="center">
  <img src="docs/images/widget-medium-dark.png" width="440" alt="Widget mediano en modo oscuro: sesión 38 %, semana 71 %">
</p>

> Las imágenes usan datos de ejemplo.

## Qué muestra

| Anillo | Significado |
|---|---|
|  **Sesión** | Límite de la ventana de 5 horas |
|  **Semana** | Límite semanal de todos los modelos |
|  |  |

El color cambia según el uso: **verde** por debajo del 60 %, **amarillo** hasta el 85 % y **rojo** a partir de ahí. El icono dentro de cada anillo indica qué límite es; las horas exactas de reinicio están en la app de la barra de menú.

<p align="center">
  <img src="docs/images/widget-medium-light.png" width="440" alt="Widget mediano en modo claro">
  <img src="docs/images/widget-small-dark.png" width="250" alt="Widget pequeño con sesión y semana">
</p>

Hay dos tamaños, **pequeño** y **mediano**, y los dos muestran sesión y semana. El mediano deja dos anillos vacíos, como el widget de Baterías. Ambos se adaptan al modo claro y al oscuro.

### Elegir proveedor

El nombre del proveedor aparece arriba del widget, así siempre está claro de quién es el uso que ves. Para cambiarlo: clic derecho en el widget → **Editar "AI Usage"** → **Proveedor**. Para ver varios proveedores, añade un widget por cada uno.

| Proveedor | Estado |
|---|---|
| Claude | Disponible |
| OpenAI | Próximamente (el widget muestra anillos vacíos y "Próximamente") |

### Barra de menú

Una app pequeña en la barra de menú muestra el % de la sesión, actualiza los datos cada 5 minutos y alimenta el widget.

<p align="center">
  <img src="docs/images/menu.png" width="300" alt="Menú con el detalle de uso, Actualizar, Abrir al iniciar sesión y Salir">
</p>

### Avisos

Si la sesión de Claude Code caduca, o la app lleva más de 30 minutos sin actualizar, el widget mantiene los últimos datos y muestra un aviso en naranja.

<p align="center">
  <img src="docs/images/widget-expired.png" width="440" alt="Widget con el aviso 'Token expirado — abre Claude Code'">
</p>

## Requisitos

- macOS 15 Sequoia o posterior
- **Claude Code** instalado y con sesión iniciada (`claude`). El widget lee esa sesión del Keychain.

## Instalar

1. Descarga `AIUsage-<versión>.zip` de la [última release](https://github.com/AlexiMarin/widget-ai-usage/releases/latest).
2. Descomprímelo y arrastra **AIUsage.app** a **Aplicaciones**.
3. Ábrela. Debe aparecer `✳︎ N%` en la barra de menú. En el menú, activa **Abrir al iniciar sesión**.
4. Clic derecho en el escritorio → **Editar widgets** → busca **AI Usage**.
5. Opcional: clic derecho en el widget → **Editar "AI Usage"** para elegir el proveedor (Claude por defecto).

### El widget no coincide con la barra de menú

macOS decide cuándo se redibujan los widgets y limita cuántas veces pueden actualizarse, así que el widget puede ir unos minutos por detrás de la barra de menú. Después de actualizar la app, quita el widget y vuelve a añadirlo para que macOS cargue la versión nueva.

### Abrir la app de nuevo

Si la cierras, el widget deja de actualizarse. Para volver a abrirla: `⌘ Espacio` → **AI Usage**, o `open -a AIUsage`.

### Desinstalar

1. En el menú, desactiva **Abrir al iniciar sesión** y pulsa **Salir**.
2. Quita el widget del escritorio.
3. Mueve **AIUsage.app** a la Papelera (está en Aplicaciones, o en `~/Applications` si la compilaste tú).

## Cómo funciona

```
Keychain (sesión de Claude Code)
        │  cada 5 min
        ▼
AIUsage.app (barra de menú) ──► api.anthropic.com/api/oauth/usage
        │
        ▼  snapshot.json (solo %, fechas y plan)
App Group compartido
        │
        ▼
Widget (sandbox, sin red)
```

- La app de la barra de menú lee la sesión de Claude Code (`Claude Code-credentials` en el Keychain), consulta el uso y deja el resultado en un App Group compartido con el widget.
- El token solo se guarda en memoria y solo se envía a `api.anthropic.com` por HTTPS. No se escribe en disco ni en logs.
- La app **nunca renueva la sesión** (eso cerraría tu sesión de Claude Code). Si caduca, se arregla sola al volver a usar Claude Code.
- Es el mismo endpoint que usa `/usage` en Claude Code. No está documentado y podría cambiar.

## Compilar desde el código

Solo si quieres modificar la app. Necesitas además:

- **Xcode** completo (App Store), no solo las Command Line Tools. Ábrelo una vez para aceptar la licencia.
- **XcodeGen**: `brew install xcodegen`
- **Certificado "Apple Development"**. Sirve una cuenta Apple gratuita:
  Xcode → Settings → Accounts → `+` → Apple ID → selecciona el equipo → *Manage Certificates…* → `+` → *Apple Development*.

```sh
git clone https://github.com/AlexiMarin/widget-ai-usage.git
cd widget-ai-usage
make install
```

Esto genera el proyecto, compila con tu certificado e instala `AIUsage.app` en `~/Applications`. `make check` comprueba solo los requisitos. Si tienes varios certificados de distintos equipos, elige uno con `make install TEAM_ID=XXXXXXXXXX`.

`make release` genera el zip firmado con Developer ID y notarizado para publicar una release (los pasos previos están en la cabecera de `scripts/release.sh`).
