# Configuración por empresa (multi-tenant por despliegue)

SIAPP-Acceso es **multi-tenant por despliegue**: cada empresa tiene su propia
instancia (su build de la app + su base de datos/backend). No hay datos
compartidos entre empresas, así que el aislamiento es total. Personalizar una
empresa = pasar unas variables al compilar la app y al configurar el backend.
No se edita código fuente.

---

## 1. App (Flutter) — variables `--dart-define`

| Variable | Para qué | Por defecto |
|---|---|---|
| `COMPANY_RUC` | RUC de la empresa. **El QR de la puerta debe llevar este mismo RUC.** | `20101162282` |
| `APP_NAME` | Texto de marca en el encabezado del tablero. | `SIAPP ACCESO` |
| `COMPANY_NAME` | Nombre de empresa/producto (título de la app). | `SIAPP-Acceso` |
| `BRAND_ACCENT` | Color de acento (hex sin `#`): anillo, fila activa, íconos. | `3A86E0` (azul) |
| `BRAND_ACTION` | Color de acción/botones (hex sin `#`): CREAR PERFIL, FICHAR, marcas hechas. | `A50044` (grana) |
| `API_BASE` | URL del backend de esa empresa. | `http://localhost:8000` |

> Con los colores por defecto se respeta exactamente la paleta "Pulse". Si los
> sobreescribes, los degradados y tonos se derivan automáticamente del color dado.

**Ejemplo — build web para la empresa "ACME" (verde corporativo):**
```bash
flutter build web --release \
  --dart-define=API_BASE=https://acme-api.tu-host.com \
  --dart-define=COMPANY_RUC=20123456789 \
  --dart-define=APP_NAME="ACME ACCESO" \
  --dart-define=COMPANY_NAME="ACME S.A." \
  --dart-define=BRAND_ACCENT=1D9E75 \
  --dart-define=BRAND_ACTION=0F6E56
```

**Android (mismo set de `--dart-define`):**
```bash
flutter build apk --release --dart-define=COMPANY_RUC=20123456789 ...
```

---

## 2. Backend (FastAPI) — variables `.env`

| Variable | Para qué | Por defecto |
|---|---|---|
| `DB_HOST` `DB_PORT` `DB_USER` `DB_PASSWORD` `DB_NAME` | Conexión a la BD de esa empresa. | — |
| `COMPANY_NAME` | Nombre en el título de la API y respaldo del correo. | `SIAPP-Acceso` |
| `BRAND_ACCENT` | Color de acento del correo de confirmación (hex). | `#3A86E0` |
| `ALLOWED_ORIGINS` | Dominios permitidos (CORS), separados por comas. En producción pon el dominio real de la app. | `*` |

Ver plantilla en [`backend/.env.example`](backend/.env.example).

El **correo** además toma el nombre y las credenciales SMTP de la tabla
`empresa_neo` (fila con `activo=1`) de la BD de esa empresa.

---

## 3. El QR de la puerta

El primer campo del QR es el RUC y **debe coincidir con `COMPANY_RUC`** de ese
despliegue (si no, la app rechaza el QR). Genera un QR por puerta/establecimiento:

```
20123456789|Puerta Principal|-12.0464,-77.0428|-12.0464,-77.0428|1|activo|Oficina
   = COMPANY_RUC
```

---

## 4. Checklist para dar de alta una empresa nueva

1. **Base de datos**: crea la BD con las tablas `marcaneodeter` y `empresa_neo`,
   y carga en `empresa_neo` la fila de correo (`activo=1`).
2. **Backend**: despliega con su `.env` (BD + `COMPANY_NAME` + `ALLOWED_ORIGINS`).
   Anota su URL.
3. **App**: compila con los `--dart-define` de la empresa (RUC, nombre, colores,
   `API_BASE` = la URL del paso 2) y publícala.
4. **QR**: genera e imprime el QR con el RUC de la empresa.

> Cada empresa = pasos 1-4 con sus propios valores. Nada se comparte entre
> empresas; para migrar a un modelo multi-tenant **compartido** (una sola BD/API
> para todas, aislando por RUC) haría falta agregar autenticación y filtrar
> todas las consultas por tenant — ver la conversación de diseño.
