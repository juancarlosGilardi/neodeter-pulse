# Guía del proyecto — Marcación de Ingreso por QR

App para que los trabajadores **marquen su ingreso al trabajo escaneando un QR
pegado en la puerta de la oficina**. Funciona como **PWA** (instalable en iPhone
y Android desde el navegador) y también como app Android nativa, con el mismo
código.

> Este es el proyecto de "marcaciones de ingreso". Los otros dos proyectos de la
> carpeta padre (`qrArtisan`, `PwaArtisan`) son de **control de producción**
> (escanean órdenes de producción), no de asistencia — no los confundas con este.

---

## 1. Estado actual

| Pieza | Repositorio GitHub | Estado |
|---|---|---|
| **App / PWA** (Flutter web + Android) | `neodeter-pulse` (público) | En vivo: https://juancarlosgilardi.github.io/neodeter-pulse/ |
| **Backend** (FastAPI + MySQL + correo) | `neodeter-api` (privado) | Listo; falta desplegarlo en Render (tu login) |

La PWA ya carga, pero **no marca hasta que el backend esté desplegado** y
conectado. Pasos de despliegue: ver [`../DESPLIEGUE.md`](../DESPLIEGUE.md).

---

## 2. Cómo funciona (flujo del trabajador)

1. **Registro (una sola vez por equipo):** el trabajador abre la app y escribe
   **nombre, correo y DNI**. (El RUC de la empresa va oculto, fijo en
   `20101162282`.) Se guarda en el dispositivo (`SharedPreferences`).
2. **Marcar:** toca el botón de marcación, la cámara escanea el **QR de la
   puerta**, y la app:
   - valida que el RUC del QR coincida con el de la empresa,
   - toma la ubicación GPS (si el navegador la concede; si no, usa Lima centro),
   - envía todo al backend, que **inserta/actualiza** el registro del día en la
     tabla `marcaneodeter` y **envía un correo** al administrador.
3. **Tipos de marcación** (hoy hay 4): **Ingreso**, **Inicio de Refrigerio**,
   **Salida de Refrigerio**, **Salida**. Si solo quieres el ingreso, ver §10.

Reglas que aplica el backend (réplica de la lógica original):
- **Ingreso:** si ya marcó ingreso hoy → error "Ya ha marcado su ingreso…". Si
  no, inserta una fila nueva con `horaentrada`.
- **Refrigerio/Salida:** exige que exista el ingreso del día; si ya estaba
  marcado ese campo → error; si no, actualiza la columna correspondiente.

---

## 3. El QR de la puerta (lo más importante)

El contenido del QR es **texto** con campos separados por `|`. Debe tener **al
menos 7 campos**:

```
RUC | AREA | LAT,LNG | LAT,LNG | ESTABLECIMIENTO_ID | ESTADO | EXTRA
 0      1        2         3              4               5       6
```

| # | Campo | Regla | Ejemplo |
|---|---|---|---|
| 0 | **RUC** | 11 dígitos. **Debe coincidir** con el RUC de la app (`20101162282`). | `20101162282` |
| 1 | **Área / lugar** | texto ≤ 50 caracteres | `Puerta Principal` |
| 2 | (no se valida; suele repetir la geo) | | `-12.0464,-77.0428` |
| 3 | **LAT,LNG** del punto | se usa para validar cercanía (si la activas, §11) | `-12.0464,-77.0428` |
| 4 | **establecimiento_id** | entero > 0 | `1` |
| 5 | estado | libre | `activo` |
| 6 | extra | libre | `Oficina Lima` |

**Ejemplo de QR a imprimir para la puerta:**
```
20101162282|Puerta Principal|-12.0464,-77.0428|-12.0464,-77.0428|1|activo|Oficina Lima
```

Genera el QR con cualquier generador (p. ej. una web de "QR code generator")
pegando ese texto, o con Python:
```python
import qrcode
qrcode.make("20101162282|Puerta Principal|-12.0464,-77.0428|-12.0464,-77.0428|1|activo|Oficina Lima").save("qr_puerta.png")
```
Imprímelo en tamaño grande (≥ 12 cm) y a buena altura/luz para que el celular lo
lea fácil desde la puerta.

> Reemplaza `-12.0464,-77.0428` por las coordenadas reales de tu oficina (búscalas
> en Google Maps). Hoy no se exige cercanía, pero si activas la validación (§11)
> esas coordenadas serán el centro permitido.

---

## 4. Arquitectura

```
   App (PWA web / Android)
        │  HTTPS (JSON)
        ▼
   Backend FastAPI  ──►  MySQL  (tabla: marcaneodeter)
        │
        └──►  Correo SMTP  (config en tabla: empresa_neo)
```

El navegador **no puede** conectarse a MySQL ni enviar correo directo; por eso
todo pasa por el backend. La app nativa Android usa el **mismo** backend (no lleva
credenciales de BD adentro).

---

## 5. Estructura de archivos

```
marcacion-ingreso/
├─ lib/
│  ├─ main.dart                     # arranque; inicializa sincronización offline
│  ├─ main_screen.dart              # pantalla principal (estado, conexión)
│  ├─ main_screen_ui.dart           # UI: botones de marcación  ← editar para §10
│  ├─ main_screen_logic.dart        # orquesta escaneo + marcación
│  ├─ registro.dart                 # registro de nombre/correo/DNI (RUC oculto)
│  └─ src/
│     ├─ config/app_config.dart     # apiBaseUrl (URL del backend), versión
│     ├─ connection/db.dart         # validación QR/ubicación + llamadas al backend
│     └─ services/
│        ├─ api_service.dart        # cliente HTTP del backend  ← clave
│        ├─ qr_scanner_service.dart # escáner de cámara (web-safe)
│        ├─ offline_service.dart    # cola offline (SharedPreferences)
│        ├─ sync_service.dart       # sincroniza marcaciones offline al backend
│        ├─ platform_service.dart   # detección web/móvil
│        └─ schedule_validation_service.dart  # validación de horario (DESHABILITADA)
├─ web/                             # index.html + manifest.json del PWA
├─ .github/workflows/deploy-web.yml # compila y publica el PWA en Pages
├─ backend/                         # API FastAPI (repo aparte: neodeter-api)
│  ├─ main.py        # endpoints /marcar, /marcaciones-hoy, /health
│  ├─ marcaciones.py # lógica de insert/update en marcaneodeter
│  ├─ email_service.py
│  ├─ db.py · models.py · requirements.txt · render.yaml · .env(.example)
├─ PWA_README.md                    # resumen de la conversión a PWA
└─ GUIA.md                          # este documento
```

---

## 6. Base de datos (MySQL `marca_nuevo`)

**`marcaneodeter`** (un registro por persona y día; se actualiza en cada marca):
`id`, `fullname`, `email`, `dni`, `dispositivoid`, `geolocacion`,
`latitud_marcacion`, `longitud_marcacion`, `establecimiento_id`, `geoemp`,
`ruc`, `area`, `fechamarcacion` (DD/MM/YYYY), `horaentrada`,
`horaRefrigerioInicio`, `horaRefrigerioFin`, `horasalida`.

**`empresa_neo`** (config de correo; el backend lee la fila con `activo=1`):
`empresa`, `email_origen`, `email_password`, `email_destino`, `activo`.
El correo de aviso se envía a `email_destino` usando las credenciales SMTP de
`email_origen`/`email_password` (Gmail/Outlook/Yahoo según el dominio).

---

## 7. Configuración

- **URL del backend (`API_BASE`):** se fija al compilar.
  - Local: `flutter run -d chrome --dart-define=API_BASE=http://localhost:8000`
  - PWA en Pages: variable de repo `API_BASE` (el Action la usa).
  - Por defecto: `http://localhost:8000` (solo desarrollo). Ver `app_config.dart`.
- **Credenciales de BD:** solo en `backend/.env` (local) o variables de entorno
  del host. **Nunca** en GitHub.
- **RUC de la empresa:** `lib/registro.dart` (campo oculto, hoy `20101162282`).

---

## 8. Correr en local

```bash
# 1) Backend
cd backend
pip install -r requirements.txt        # el .env ya trae los datos de la BD
python -m uvicorn main:app --host 127.0.0.1 --port 8000

# 2) App web
cd ..
flutter pub get
flutter run -d chrome --dart-define=API_BASE=http://localhost:8000
```

## 9. Desplegar
Pasos completos en [`../DESPLIEGUE.md`](../DESPLIEGUE.md): backend en Render
(Blueprint + variables), luego fija la variable `API_BASE` del repo `neodeter-pulse`
y re-corre el Action de Pages.

---

## 10. Enfocar SOLO en "Ingreso" (tu objetivo)

Hoy la app ofrece 4 tipos de marcación. Si quieres que **solo se marque el
ingreso**:

- **Mínimo:** en `lib/main_screen_ui.dart`, deja únicamente el botón que llama a
  `onScanAndMark('Ingreso')` y oculta/elimina los de "Inicio de Refrigerio",
  "Salida de Refrigerio" y "Salida".
- El backend y la BD no necesitan cambios (siguen aceptando solo "Ingreso").
- Opcional: renombrar textos a "Marcar ingreso" para que sea inequívoco.

> Puedo hacer esta simplificación cuando confirmes (es un cambio de UI reversible).

---

## 11. Mejoras recomendadas (roadmap)

1. **Exigir presencia en la puerta (anti-trampa):** hoy `LocationValidator` existe
   pero **no se usa**. Conectarlo en `db.dart processMarking` para rechazar la
   marca si el GPS está a > 100 m del punto del QR. Requiere permiso de ubicación
   (en web, solo HTTPS).
2. **Evitar foto del QR / compartir:** rotar el QR periódicamente (incluir un token
   con fecha) o validar ubicación (punto 1).
3. **Panel de administración** para ver/exportar las marcaciones del día (hoy solo
   llega un correo por marca).
4. **Validación de horario:** `schedule_validation_service.dart` está deshabilitado;
   se puede reactivar para tolerancias de entrada.
5. **Mensajes y UX:** confirmación visual grande tras marcar; modo "kiosko" si se
   usa un único equipo en la puerta.
6. **Seguridad backend:** agregar autenticación (token) y limitar CORS al dominio
   real (hoy permite todos los orígenes).
7. **Notificaciones push** (solo móvil) si se quiere avisar al trabajador.

---

## 12. Limitaciones / pendientes

- El **backend aún no está desplegado** (necesita tu cuenta en Render). Hasta
  entonces la PWA carga pero no graba.
- La **lectura del QR en iPhone** (PWA) es por software (limitación de Safari):
  conviene QR grande y buena luz. En Android nativo es lectura nativa (más
  precisa).
- La **ubicación no se valida** (solo se guarda). Ver mejora #1.
- El **correo** depende de que `empresa_neo` tenga credenciales SMTP válidas; si
  fallan, la marca igual se registra.

---

## 13. Enlaces rápidos
- App en vivo: https://juancarlosgilardi.github.io/neodeter-pulse/
- Repo app: https://github.com/juancarlosGilardi/neodeter-pulse
- Repo backend (privado): https://github.com/juancarlosGilardi/neodeter-api
- Guía de despliegue: [`../DESPLIEGUE.md`](../DESPLIEGUE.md)
