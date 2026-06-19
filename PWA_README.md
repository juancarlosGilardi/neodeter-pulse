# Neo Deter — Marcaciones (PWA)

App de marcaciones convertida a **PWA** desde Flutter. Funciona en Android e
iPhone instalándola desde el navegador ("Agregar a la pantalla de inicio"), sin
tiendas ni cuenta de Apple.

## Arquitectura (backend único)

El navegador no puede conectarse a MySQL ni enviar correos por SMTP, así que se
agregó un **backend** que hace ambas cosas. Tanto la app web como la nativa
Android usan ese backend por HTTP. Esto además **elimina las credenciales de la
base de datos que estaban embebidas** en la app (riesgo de seguridad anterior).

```
App (Flutter web / Android)  →  Backend FastAPI  →  MySQL (marcaneodeter)
                                       └→ Correo SMTP (tabla empresa_neo)
```

- **`backend/`** — API FastAPI (Python). Endpoints: `POST /marcar`,
  `GET /marcaciones-hoy`, `GET /health`.
- **`lib/`** — Flutter. El acceso a datos vive en `lib/src/services/api_service.dart`
  y `lib/src/connection/db.dart` (ya no usan `mysql1` ni `mailer`).
- **`web/`** — manifest e índice del PWA (el service worker lo genera Flutter).

---

## 1. Probar en la PC

**Backend:**
```bash
cd backend
pip install -r requirements.txt          # el .env ya trae los datos de la BD
python -m uvicorn main:app --host 127.0.0.1 --port 8000
```

**App web (apuntando al backend local):**
```bash
flutter run -d chrome --dart-define=API_BASE=http://localhost:8000
```

La app Android nativa sigue funcionando igual:
```bash
flutter run -d <dispositivo-android> --dart-define=API_BASE=http://TU_BACKEND
```

---

## 2. Publicar para los celulares

### 2.1 Backend → host con HTTPS
Render / Railway / Fly.io (plan gratuito). Ejemplo Render:
- Build: `pip install -r requirements.txt`
- Start: `uvicorn main:app --host 0.0.0.0 --port $PORT`
- Variables de entorno (las del `.env`): `DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME`.
- Anota la URL, p. ej. `https://neodeter-api.onrender.com`.

### 2.2 App web (PWA) → compilar y subir
Compila apuntando a tu backend (la cámara exige HTTPS en producción):
```bash
flutter build web --release --dart-define=API_BASE=https://neodeter-api.onrender.com
```
Sube el contenido de **`build/web/`** a un host estático con HTTPS:
Netlify, Cloudflare Pages, Vercel o Firebase Hosting (todos gratis y con el MIME
correcto para el service worker).

> ⚠️ Si no pasas `--dart-define=API_BASE=...`, la app usa `http://localhost:8000`
> por defecto (solo sirve para desarrollo).

---

## 3. Instalar en el celular
- **Android (Chrome):** menú ⋮ → "Instalar aplicación" (o el aviso automático).
- **iPhone (Safari):** Compartir ⬆️ → "Agregar a inicio".

---

## 4. Notas
- **Cámara:** en web la autoriza el navegador (requiere HTTPS). `mobile_scanner`
  trae soporte web (decodifica por software); para un QR de pared conviene buen
  tamaño y buena luz.
- **Ubicación:** en web la pide el navegador; si se niega, se usa Lima centro por
  defecto (la marcación igual se registra).
- **Offline:** las marcaciones hechas sin conexión se guardan localmente y se
  sincronizan solas con el backend al volver la conexión (`sync_service.dart`).
- **Correo:** lo envía el backend (lee la config SMTP de la tabla `empresa_neo`),
  en segundo plano; si falla, la marcación igual queda registrada.
