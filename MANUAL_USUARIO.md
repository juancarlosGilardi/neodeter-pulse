# Manual de usuario — SIAPP-Acceso (control de asistencia por QR)

App para registrar tu jornada de trabajo **escaneando el código QR pegado en la
puerta de la oficina**. Cada marcación sigue un orden fijo: **Ingreso → Inicio de
refrigerio → Fin de refrigerio → Salida**. Funciona como app instalable (PWA) en
iPhone y Android, y también como app Android nativa, con el mismo código.

> Este manual describe lo que ve y hace el **trabajador**. Al final hay una
> sección breve para el **administrador** (QR de la puerta y correo).
>
> 📄 Versión con las pantallas en imagen: [Manual_Usuario_SIAPP-Acceso.pdf](Manual_Usuario_SIAPP-Acceso.pdf).

---

## 1. Antes de empezar

| Necesitas | Detalle |
|---|---|
| Teléfono con cámara | Para escanear el QR de la puerta. |
| Conexión a internet | Para grabar la marca. Sin señal se guarda en el equipo y se sincroniza sola al volver la conexión. |
| Permiso de cámara | La app lo pide la primera vez que escaneas. Es obligatorio. |
| Permiso de ubicación (opcional) | Si lo niegas, igual puedes marcar (se usa una ubicación por defecto). |

**Instalar la app en el celular:**
- **Android (Chrome):** menú ⋮ → "Instalar aplicación".
- **iPhone (Safari):** botón Compartir → "Agregar a inicio".

---

## 2. Guía de colores

SIAPP-Acceso usa colores para indicar el estado de cada cosa de un vistazo:

| Color | Significado |
|---|---|
| 🔵 Azul | **Tu turno**: la marca que te toca ahora (fila "NOW"). |
| 🔴 Grana | Marca **ya registrada**. |
| 🟠 Ámbar | Guardada en el equipo, **pendiente de sincronizar**. |
| ⚪ Gris | Paso **bloqueado** (aún no te toca). |
| 🟢 Verde | **En vivo / sincronizado**. |
| 🔴 Rojo | Error de lectura del QR. |

---

## 3. Flujo completo en 4 pasos

```
1) Crear perfil   →   2) Inicio (tablero)   →   3) Escanear QR   →   4) Confirmación
   nombre, correo,     resalta tu marca         apuntas a la         pantalla de
   DNI (una vez)       pendiente ("NOW")        puerta               éxito + hora
```

---

## 4. Pantalla "Crea tu perfil"

Aparece **solo la primera vez** (o si faltan datos). Los datos quedan guardados en
el equipo, así que no la verás de nuevo en ese teléfono.

| Campo | Regla |
|---|---|
| **Nombre completo** | Mínimo 2 caracteres. Solo letras y espacios. |
| **Correo electrónico** | Formato válido (`nombre@dominio.com`). |
| **DNI** | Exactamente **8 dígitos** numéricos. |

Al tocar **CREAR PERFIL**, el teléfono vibra y pasas al tablero de inicio.

---

## 5. Pantalla de Inicio (tablero)

Es la pantalla principal: un tablero con tu jornada.

### 5.1 Indicador de conexión (arriba a la derecha)
Es un chip que puedes **tocar para volver a verificar** la conexión:

| Lo que ves | Significa |
|---|---|
| **EN VIVO** (verde) | Hay conexión con el servidor. |
| **VERIFICANDO** (ámbar) | Comprobando la conexión. |
| **SIN RED** (rojo) | No se llega al servidor. Puedes marcar igual: queda guardado en el equipo. |

### 5.2 Anillo "TRABAJADO"
Muestra el **tiempo trabajado** en el día (desde tu ingreso, descontando el
refrigerio), el **porcentaje** de la jornada y cuánto falta. Si aún no marcas
ingreso, muestra `00:00` y "Marca tu ingreso".

### 5.3 Cronograma — los 4 hitos y sus estados

| Estado | Aspecto | Qué significa |
|---|---|---|
| **Registrado** | Círculo grana con check + la hora. | El paso ya está marcado. |
| **Tu turno (NOW)** | Fila **azul** resaltada con ícono de cámara. | Tócala (o el botón **FICHAR AHORA**) para escanear. |
| **Sincronizando · local** | Círculo ámbar. | Se marcó sin conexión; se subirá sola al volver la red. |
| **Bloqueado** | Candado y "Aún no disponible". | Todavía no te toca ese paso. |

### 5.4 Orden obligatorio
1. **Ingreso** — primero.
2. **Inicio de refrigerio** — solo después del ingreso.
3. **Fin de refrigerio** — solo después del inicio de refrigerio.
4. **Salida** — necesita el ingreso; si saliste a refrigerio, primero marca el fin.

> Solo el siguiente paso pendiente está activo (azul, "NOW"). El resto aparece
> bloqueado hasta que te toque.

---

## 6. Pantalla de la cámara (escáner)

- **Se lee solo:** no hay botón de captura. Cuando el QR entra en el recuadro
  (esquinas azules), el teléfono vibra y procesa.
- El **subtítulo** te recuerda qué marca estás haciendo (p. ej. "Fin de refrigerio").
- **Linterna** ⚡ si hay poca luz, y **cerrar** ✕ para volver al inicio.
- La primera vez, el navegador o el sistema pedirá **permiso de cámara**: acéptalo.

---

## 7. Confirmación: Éxito y Error

- **Éxito** — pantalla verde con un resumen: **Tipo**, **Hora** y **Estado**
  ("Sincronizado" en verde, o "Guardado local" en ámbar si no había conexión).
  Toca **VOLVER AL INICIO**.
- **Error** — pantalla roja si el QR no se pudo leer o no corresponde a tu oficina.
  Tienes **REINTENTAR** (vuelve a escanear) y **Volver al inicio**.

---

## 8. Preguntas frecuentes

**¿Tengo que crear el perfil cada vez?**
No. Es una sola vez por equipo. Si cambias de teléfono, lo repites.

**Dice que el QR no corresponde a la oficina.**
Estás leyendo un QR que no es el de tu empresa. Usa el QR pegado en tu puerta.

**No tengo señal, ¿pierdo la marca?**
No. Se guarda en el equipo (ámbar, "Sincronizando · local") y se sube sola cuando
vuelve la conexión.

**El paso está bloqueado (candado).**
Aún no te corresponde. Respeta el orden: Ingreso → Refrigerio → Salida.

**¿Y si niego la ubicación?**
Puedes marcar igual. El permiso de **cámara** sí es obligatorio para escanear.

**El QR no se lee en iPhone.**
Acerca el teléfono, usa la linterna y busca buena luz.

---

## 9. Para el administrador

### 9.1 El QR de la puerta
El QR es **texto** con campos separados por `|` (al menos 7 campos). El primero es
el RUC de la empresa y **debe coincidir** con el configurado en la app:

```
20XXXXXXXXX|Puerta Principal|-12.0464,-77.0428|-12.0464,-77.0428|1|activo|Oficina
   RUC            área              geo                geo         id   estado  extra
```

- Genéralo con cualquier "QR code generator" pegando ese texto.
- Usa el **RUC de tu organización** y las coordenadas reales de la oficina.
- Imprímelo **grande (≥ 12 cm)**, a buena altura y con buena luz.

### 9.2 Aviso por correo
Cada marcación envía un correo al administrador (configurado en el servidor). Si el
correo falla, la marca igual queda registrada.

---

*Manual de usuario · SIAPP-Acceso — Control de asistencia por QR.*
