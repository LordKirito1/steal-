# Steal An Egg Tracker 🥚

Sistema completo de telemetría, rastreo de servidores y **Server Hopping dirigido** para el juego de Roblox: **"Steal An Egg"**.

---

## 📁 Estructura del Proyecto

```text
Steal An egg scripte/
├── Client/                     # Scripts y módulos para el cliente Luau (Roblox)
│   ├── Modules/
│   │   ├── Config.luau         # Umbrales de rareza, URLs y alias de propiedades
│   │   ├── EggDetector.luau    # Monitoreo reactivo de Workspace con .ChildAdded
│   │   └── NetworkManager.luau # Cola por lotes (debounce) y comunicación HTTP
│   ├── Interface/
│   │   └── UIController.luau   # Interfaz gráfica (Rayfield / Fallback) y TeleportService
│   ├── Main.luau               # Punto de entrada modular (Roblox Studio / LocalScript)
│   └── StandaloneScript.luau   # Script monolítico "listo para pegar" en ejecutores
│
├── Backend/                    # Servidor REST central en Node.js + Express + Redis
│   ├── src/
│   │   ├── index.js            # Punto de entrada del servidor
│   │   ├── routes/eggsRoutes.js# Rutas POST /report y GET /search
│   │   ├── services/redisService.js # TTL automático (con fallback en memoria)
│   │   └── utils/validators.js # Validación de payloads y mapeo de rarezas
│   ├── package.json
│   ├── .env.example
│   └── .env
│
├── Backend_Python/             # Alternativa de backend en Python (FastAPI)
│   ├── app.py
│   └── requirements.txt
│
└── README.md
```

---

## 1. Detección y Lectura de Datos Local (Luau)

- **Inspección de Jerarquía:**
  `EggDetector.luau` utiliza un algoritmo de búsqueda adaptativo. Revisa carpetas conocidas (`Eggs`, `SpawnedEggs`, `MapEggs`, `DroppedEggs`) y busca coincidencias por nombre o atributos.
- **Extracción de Propiedades:**
  La función `extractProperty` examina:
  1. **Attributes nativos de Roblox** (`instance:GetAttribute("Rarity")`).
  2. **ValueObjects hijos** (`StringValue`, `IntValue`, `NumberValue`).
  3. **BillboardGuis / TextLabels** que el juego suele proyectar sobre el huevo.
  4. Nombres del modelo (inferencia heurística si contiene palabras clave).
- **Rendimiento:**
  Usa `.ChildAdded` y `.ChildRemoved` sobre el contenedor específico en lugar de bucles `while task.wait()` o escaneo continuo de todo el Workspace, protegiendo los FPS del juego.

### 🛠️ ¿Cómo adaptar las rutas si el juego actualiza sus nombres?
Abre [`Client/Modules/Config.luau`](file:///c:/Users/SANTANA/Documents/Steal%20An%20egg%20scripte/Client/Modules/Config.luau) (o el bloque `CONFIG` en `StandaloneScript.luau`):
- Si cambian la carpeta contenedora en Workspace, agrégala en `EGG_FOLDER_CANDIDATES`:
  ```lua
  Config.EGG_FOLDER_CANDIDATES = {
      "NombreDeNuevaCarpeta",
      "Eggs",
      ...
  }
  ```
- Si cambian los nombres de las propiedades o valores del huevo, agrégalos en `PROPERTY_ALIASES`:
  ```lua
  Config.PROPERTY_ALIASES = {
      Rarity = {"NuevaPropiedadRareza", "Rarity", "Tier"},
      Value  = {"NuevoMultiplicador", "Value", "Price"},
      Name   = {"NuevoNombreHuevo", "Name"}
  }
  ```

---

## 2. Comunicación y Telemetría (Cliente -> Backend)

- **Manejo de Ratelimits:**
  `NetworkManager.luau` agrupa los huevos detectados en una cola en memoria y los envía mediante un temporizador de debounce (`REPORT_COOLDOWN = 3s`). No satura el canal HTTP ni dispara bloqueos de red.
- **Estructura del Payload JSON:**
  ```json
  {
    "placeId": 123456789,
    "jobId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "serverRegion": "US",
    "reportTimestamp": 1730200000,
    "eggs": [
      {
        "id": "uuid-12345",
        "name": "Golden Dragon Egg",
        "rarity": "Legendary",
        "value": 15000,
        "spawnTime": 1730199990
      }
    ]
  }
  ```

---

---

## 3. API en la Nube 100% Gratis 24/7 (Para el Radar en Vivo)

Para que el Radar en Vivo te avise cuando aparezcan huevos en otros servidores (aunque tu PC esté apagada):

### 🌐 Opción 1: Render.com (Recomendada - 24/7 Gratis)
1. Entra a [render.com](https://render.com) e inicia sesión gratis con tu cuenta de **GitHub**.
2. Haz click en **"New"** -> **"Web Service"** y selecciona tu repositorio: `LordKirito1/steal-`.
3. Render detectará automáticamente el archivo [`render.yaml`](file:///h:/Project%20BS-Smart/PROYECTO%20NUEVOP/render.yaml) del proyecto.
4. Haz click en **"Create Web Service"**. En 1 minuto tendrás tu enlace HTTPS gratuito:
   ```text
   https://tu-api-steal.onrender.com
   ```
5. En Roblox, pulsa el botón **`⚙️`** en el menú y pega esa URL. ¡Listo! El radar ya estará conectado a la nube para siempre.

### ⚡ Opción 2: Túnel Rápido desde tu PC (Localtunnel)
Si prefieres correrlo en tu máquina:
1. Inicia el servidor:
   ```powershell
   cd Backend
   npm start
   ```
2. En otra terminal abre un túnel gratuito:
   ```powershell
   npx localtunnel --port 3000
   ```
3. Copia el link generado (ej. `https://xxxx.loca.lt`) y pégalo en el botón **`⚙️`** del script.

---

## 4. Interfaz Gráfica Dual Hub (Steal Panel & Chilli Finder)

### 🥚 Steal Panel (Robo en el Servidor Actual)
- **Vista en tiempo real:** Lista los mejores huevos y mascotas de los stands del servidor actual.
- **Detalles completos:** Muestra el nombre en color de rareza (*Hexed Pumpkin, Crowshade, Holy Peacock*), tasa de producción en verde brillante (`$123.1M/s`), multiplicador (`x6.15`), tag de evento (*Halloween*) y botón **`[ STEAL ]`**.
- **Acción instantánea:** Al pulsar **`STEAL`**, el jugador se teletransporta al stand y activa automáticamente el `ProximityPrompt`.
- **Filtros rápidos:** Botones de `[Auto Steal: ON/OFF]`, `[Halloween: ON/OFF]`, `[Eggs: All]` y ordenamiento por `Value`.
- **Speed Boost:** Slider superior `Boost speed [120]` para ajustar la velocidad de carrera (`WalkSpeed`).

### 🌶️ Chilli Finder con Radar en Vivo (Server Hopping)
- **🚨 Radar en Vivo:** Emite un **sonido de alerta** y despliega un **banner flotante superior** en el instante en que detecta un huevo valioso en otro servidor con botón directo **`[ UNIRSE AHORA ]`**.
- **Telemetría Automática:** Reporta tus propios servidores a la nube para que todas tus cuentas compartan la misma red de radar.
- **Monitoreo global:** Consulta en vivo servidores reportados con los huevos más valiosos del mundo (*Werewolf $54.14B/s x9.35*, etc.).
- **Filtros integrados:** `[FORCE JOIN: 60s]`, `[MIN VALUE: 1T/s]`, `[RARITY: Any]`, `[ACCOUNT: Free]`.
- **Botón `[ Join ]`:** Conexión directa al servidor mediante `TeleportService:TeleportToPlaceInstance`.
- **Pestañas y Control:** Alterna entre ambos paneles con un solo click y minimiza la ventana con el botón lateral rojo (`>`).

---

## 5. Ejecución Rápida en Roblox (Loadstring)

Pega esta línea directamente en tu ejecutor (Delta, Wave, Solara, Codex, Fluxus, etc.):

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/LordKirito1/steal-/main/Client/StandaloneScript.luau"))()
```



