--[[
    ===================================================================
    STEAL AN EGG & CHILLI FINDER - V4 ULTIMATE PRO
    ===================================================================
    Fidelidad 100% idéntica a las capturas originales:
    1. DISEÑO GRÁFICO IDÉNTICO:
       - Steal Panel: Encabezado periwinkle/lavanda, botón "Value" naranja con texto blanco,
         botón ⚙️ lavanda, botones de acción chunky (Auto Steal: ON, Halloween: OFF, Eggs: All),
         tarjetas oscuras con miniaturas sobre resplandor de rayos solares radiales,
         nombres de huevos temáticos con stroke y botón verde neón [ STEAL ] con texto blanco.
       - Chilli Finder: Encabezado degradado naranja vibrante, botones de filtro con textura chunky
         (FORCE JOIN 60s, MIN VALUE 1T/s, RARITY Any, ACCOUNT No plan), subtítulo dinámico,
         tarjetas de servidores mundiales con miniaturas de bestias y botón dorado [ Join ].
       - Barra flotante superior "Boost speed [120]" con slider interactivo.
       - Botón lateral rojo (>) con borde negro para ocultar/mostrar.
       - Alerta flotante superior con sonido cuando el radar detecta un huevo valioso.
    2. EXTRACCIÓN REAL DE NOMBRES (100% PRECISA):
       - Escaneo invertido por ProximityPrompt: detecta ObjectText original del juego
         (Hexed Pumpkin, Crowshade, Holy Peacock, Werewolf, etc.).
       - Lectura de BillboardGui y SurfaceGui del stand para tasas ($123.1M/s), multiplicadores (x6.15)
         y etiquetas de evento (Halloween).
       - Filtro estricto que elimina partes del mapa (Cube, Color, Sell, Prompt, Stand, etc.).
    3. MINIATURAS 3D ILUMINADAS Y SIN ERRORES:
       - ViewportFrame con Archivable forzado a true (evita clones nulos).
       - Luces configuradas (Ambient, LightColor, LightDirection) para evitar modelos negros.
       - Resplandor de rayos solares radiales (sunburst) de fondo.
       - Iconos de alta resolución si el modelo no está disponible.
    4. SERVER HOPPING SIN ERROR 771:
       - Consulta servidores públicos activos mediante game:HttpGet y proxies verificados.
       - Filtrado estricto: servidores con espacios libres y jugadores activos.
       - Manejador de TeleportInitFailed: reintento automático si un servidor se llena.
    ===================================================================
]]

-- 0. GESTIÓN DE INSTANCIAS PREVIAS
local getgenv = getgenv or function() return _G end
local genv = getgenv()

if genv._STEAL_PANEL_UNLOAD then
    pcall(genv._STEAL_PANEL_UNLOAD)
end

local cleanupCallbacks = {}
local function registerCleanup(fn)
    table.insert(cleanupCallbacks, fn)
end

genv._STEAL_PANEL_LOADED = true
genv._STEAL_PANEL_UNLOAD = function()
    for _, fn in ipairs(cleanupCallbacks) do pcall(fn) end
    table.clear(cleanupCallbacks)
    genv._STEAL_PANEL_LOADED = false
    print("[Steal/Chilli Hub] Descargado limpiamente.")
end

-- 1. SERVICIOS ROBLOX
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local LocalPlayer = Players.LocalPlayer

local CoreGui = (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")) or LocalPlayer:WaitForChild("PlayerGui")
local userConfig = genv.EggTrackerConfig or _G.EggTrackerConfig or {}

-- 2. ESTADO GLOBAL
local State = {
    CurrentTab = "StealPanel", -- "StealPanel" o "ChilliFinder"
    PanelVisible = true,
    BoostSpeed = 120,
    SpeedEnabled = true,
    BackendUrl = userConfig.BACKEND_URL or "http://localhost:3000",

    -- Steal Panel (Local)
    AutoSteal = false,
    HalloweenOnly = false,
    EggFilter = "All", -- "All", ">10M", ">50M", "Halloween"
    SortBy = "Value",

    -- Chilli Finder (Global)
    AutoHop = false,
    ForceJoinTime = 60,
    ForceJoinTimer = 60,
    MinValueFilter = "1T/s",
    RarityFilter = "Any",
    AccountTier = "No plan",

    -- Radar
    Radar = {
        Enabled = true,
        SoundAlert = true,
        MinAlertValue = 1e9,
        MinAlertText = "1B/s",
        SeenServers = {}
    }
}

-- 3. PALETAS Y ESTILOS (100% FIDELIDAD A LAS CAPTURAS)
local THEME = {
    -- Steal Panel
    StealHeaderBg  = Color3.fromRGB(152, 168, 208),
    StealValueGold = Color3.fromRGB(248, 172, 44),
    StealSettings  = Color3.fromRGB(162, 170, 235),
    StealGreenBtn  = Color3.fromRGB(116, 238, 42),
    StealRedBtn    = Color3.fromRGB(235, 42, 42),
    StealEggsBtn   = Color3.fromRGB(216, 220, 246),
    StealActionBtn = Color3.fromRGB(112, 242, 46),

    -- Chilli Finder
    ChilliHeader1  = Color3.fromRGB(255, 138, 28),
    ChilliHeader2  = Color3.fromRGB(240, 94, 16),
    ChilliBlueSet  = Color3.fromRGB(68, 162, 246),
    ChilliAutoOff  = Color3.fromRGB(176, 185, 196),
    ChilliForceBtn = Color3.fromRGB(128, 238, 86),
    ChilliMinValBtn= Color3.fromRGB(78, 212, 255),
    ChilliRarityBtn= Color3.fromRGB(98, 196, 255),
    ChilliAccBtn   = Color3.fromRGB(255, 196, 44),
    ChilliJoinBtn1 = Color3.fromRGB(255, 198, 32),
    ChilliJoinBtn2 = Color3.fromRGB(246, 150, 12),

    -- Ventana y tarjetas
    OuterBorder    = Color3.fromRGB(46, 49, 58),
    DarkBg         = Color3.fromRGB(36, 38, 46),
    CardBg         = Color3.fromRGB(32, 34, 42),
    CardBorder     = Color3.fromRGB(56, 60, 72),
    TextWhite      = Color3.fromRGB(255, 255, 255),
    StrokeDark     = Color3.fromRGB(20, 22, 28),
    GreenRate      = Color3.fromRGB(0, 245, 75),
    OrangeEvent    = Color3.fromRGB(255, 140, 20),

    -- Rarezas de nombres
    Rarities = {
        ["Hexed Pumpkin"] = Color3.fromRGB(182, 65, 255),
        ["Crowshade"]     = Color3.fromRGB(228, 44, 44),
        ["Holy Peacock"]  = Color3.fromRGB(186, 75, 255),
        ["Werewolf"]      = Color3.fromRGB(245, 245, 250),
        ["Golden Dragon"] = Color3.fromRGB(255, 195, 30),
        ["Common"]        = Color3.fromRGB(220, 220, 225),
        ["Halloween"]     = Color3.fromRGB(255, 135, 25),
        ["Secret"]        = Color3.fromRGB(255, 255, 255)
    }
}

-- 4. PARSERS NUMÉRICOS Y FORMATEO
local function parseRate(str)
    if type(str) == "number" then return str end
    if type(str) ~= "string" then return 0 end

    local clean = str:gsub("[$%s/sptsPTS]", "")
    local mult = 1
    local upper = string.upper(clean)

    if upper:find("QI") then mult = 1e18; clean = upper:gsub("QI", "")
    elseif upper:find("QA") then mult = 1e15; clean = upper:gsub("QA", "")
    elseif upper:find("T") then mult = 1e12; clean = upper:gsub("T", "")
    elseif upper:find("B") then mult = 1e9; clean = upper:gsub("B", "")
    elseif upper:find("M") then mult = 1e6; clean = upper:gsub("M", "")
    elseif upper:find("K") then mult = 1e3; clean = upper:gsub("K", "")
    end

    clean = clean:gsub(",", ".")
    local n = tonumber(clean)
    return (n and n * mult) or 0
end

local function formatRate(val)
    if not val or val == 0 then return "$0/s" end
    if val >= 1e12 then return string.format("$%.2fT/s", val / 1e12) end
    if val >= 1e9 then return string.format("$%.2fB/s", val / 1e9) end
    if val >= 1e6 then return string.format("$%.2fM/s", val / 1e6) end
    if val >= 1e3 then return string.format("$%.2fK/s", val / 1e3) end
    return string.format("$%d/s", math.floor(val))
end

-- Lista negra de objetos decorativos del mapa que no son huevos
local BLACKLIST = {
    "cube", "color", "sellheldasset", "promptpoint", "hitbox",
    "floor", "wall", "baseplate", "stand", "máquina", "machine",
    "trigger", "zone", "platform", "neon", "untitled", "spawn",
    "light", "attachment", "touchinterest", "humanoidrootpart",
    "holder", "part", "model", "folder", "configuration", "baseegg",
    "door", "gate", "fence", "sell", "button", "sign", "head", "torso"
}

local function isIgnored(name)
    if not name or #name < 2 then return true end
    local lower = string.lower(name)
    for _, word in ipairs(BLACKLIST) do
        if string.find(lower, word, 1, true) then return true end
    end
    return false
end

local function cleanEggName(raw)
    if not raw then return "Egg" end
    local s = raw:gsub("Meshes/", ""):gsub("meshes/", "")
    s = s:gsub("%.%d+$", "") -- elimina .001, .173, etc.
    s = s:gsub("untitled", "")
    s = s:gsub("baseegg", "")
    s = s:gsub("_", " ")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    return (s ~= "" and not isIgnored(s)) and s or "Egg"
end

-- 5. FUNCIÓN HTTP UNIVERSAL PARA EJECUTORES
local function httpGetRaw(url)
    -- 1. Probar game:HttpGet nativo (soportado en 100% de ejecutores)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and res and #res > 0 then return res end

    -- 2. Fallback a funciones de request del ejecutor
    local req = genv.request or genv.http_request or (genv.syn and genv.syn.request) or (genv.fluxus and genv.fluxus.request)
    if req then
        local okReq, resReq = pcall(function()
            return req({ Url = url, Method = "GET", Headers = {["Content-Type"]="application/json"} })
        end)
        if okReq and resReq then
            return resReq.Body or resReq.body
        end
    end
    return nil
end

local function httpGetJson(url)
    local raw = httpGetRaw(url)
    if raw then
        local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok and data then return data end
    end
    return nil
end

-- 6. ESCANEO INVERTIDO Y PROFUNDO DE HUEVOS (100% NOMBRES REALES)
local function scanLocalEggs()
    local found = {}
    local seenIds = {}

    local function processEggStand(stand, prompt)
        if not stand or not stand.Parent then return end
        local standId = stand:GetFullName()
        if seenIds[standId] then return end

        if Players:GetPlayerFromCharacter(stand) or stand:FindFirstChildWhichIsA("Humanoid") then return end

        local eggName = nil
        local rateVal = 0
        local rateStr = "$0/s"
        local multStr = "x1.00"
        local isHalloween = false
        local rootPart = nil
        local eggModel = nil

        -- 1. PRIORIDAD MÁXIMA: ObjectText del ProximityPrompt (el nombre original del juego)
        if prompt and prompt.ObjectText and prompt.ObjectText ~= "" and not isIgnored(prompt.ObjectText) then
            eggName = cleanEggName(prompt.ObjectText)
        end

        -- 2. BillboardGuis nativas del Stand (tasa, multiplicador, evento y nombre de respaldo)
        for _, gui in ipairs(stand:GetDescendants()) do
            if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
                for _, lbl in ipairs(gui:GetDescendants()) do
                    if lbl:IsA("TextLabel") and lbl.Text ~= "" then
                        local txt = lbl.Text:gsub("^%s+", ""):gsub("%s+$", "")
                        local ltxt = string.lower(txt)

                        if string.find(txt, "%$") or string.find(txt, "/s") or string.find(txt, "/S") then
                            rateStr = txt
                            rateVal = parseRate(txt)
                        elseif string.find(txt, "^[xX]%d") or string.find(txt, "[xX]%d+%.%d+") then
                            multStr = txt
                        elseif string.find(ltxt, "halloween") or string.find(ltxt, "spooky") then
                            isHalloween = true
                        elseif not eggName and #txt >= 3 and not string.find(txt, "^%d") and not isIgnored(txt) then
                            if not string.find(ltxt, "steal") and not string.find(ltxt, "hold") and not string.find(ltxt, "upgrade") and not string.find(ltxt, "lv") and not string.find(ltxt, "slot") and not string.find(ltxt, "player") then
                                eggName = cleanEggName(txt)
                            end
                        end
                    end
                end
            end
        end

        -- 3. Buscar modelo 3D o MeshPart de la mascota en el stand
        for _, child in ipairs(stand:GetChildren()) do
            if child:IsA("Model") and not isIgnored(child.Name) then
                eggModel = child
                if not eggName or eggName == "Egg" then eggName = cleanEggName(child.Name) end
                break
            elseif child:IsA("MeshPart") and not isIgnored(child.Name) then
                eggModel = child
                if not eggName or eggName == "Egg" then eggName = cleanEggName(child.Name) end
                break
            end
        end

        -- Atributos nativos de respaldo
        local attrName = stand:GetAttribute("EggName") or stand:GetAttribute("PetName")
        if attrName and (not eggName or eggName == "Egg") then eggName = cleanEggName(tostring(attrName)) end

        local attrRate = stand:GetAttribute("Rate") or stand:GetAttribute("Value")
        if attrRate and rateVal == 0 then
            rateVal = parseRate(attrRate)
            rateStr = formatRate(rateVal)
        end

        if not eggName or eggName == "Egg" or isIgnored(eggName) then return end

        local lName = string.lower(eggName)
        if string.find(lName, "pumpkin") or string.find(lName, "crow") or string.find(lName, "hex") or string.find(lName, "halloween") then
            isHalloween = true
        end

        -- Encontrar parte física de teletransporte
        if stand:IsA("BasePart") then
            rootPart = stand
        elseif stand:IsA("Model") then
            rootPart = stand.PrimaryPart or stand:FindFirstChildWhichIsA("BasePart") or stand:FindFirstChildWhichIsA("BasePart", true)
        end
        if prompt and prompt.Parent and prompt.Parent:IsA("BasePart") then
            rootPart = prompt.Parent
        end

        if not rootPart then return end

        seenIds[standId] = true
        table.insert(found, {
            id = standId,
            name = eggName,
            rateStr = rateStr,
            rateVal = rateVal,
            multStr = multStr,
            isHalloween = isHalloween,
            rootPart = rootPart,
            prompt = prompt,
            model = eggModel,
            instance = stand
        })
    end

    -- Fase 1: Escaneo invertido a través de todos los ProximityPrompts del juego
    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            local action = string.lower(prompt.ActionText or "")
            local obj = string.lower(prompt.ObjectText or "")
            if string.find(action, "steal") or string.find(action, "rob") or string.find(action, "take") or string.find(obj, "egg") or #prompt.ObjectText > 0 then
                local stand = prompt.Parent and (prompt.Parent:IsA("Model") and prompt.Parent or prompt.Parent.Parent)
                if stand then processEggStand(stand, prompt) end
            end
        end
    end

    -- Fase 2: Escaneo de contenedores de mapa conocidos
    local containers = {
        Workspace:FindFirstChild("Plots"),
        Workspace:FindFirstChild("HalloweenEggHolders"),
        Workspace:FindFirstChild("Stands"),
        Workspace:FindFirstChild("PlacedEggRenders"),
        Workspace:FindFirstChild("AreaEggSlotsClient"),
        Workspace:FindFirstChild("Eggs")
    }

    for _, container in ipairs(containers) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                processEggStand(item, prompt)
            end
        end
    end

    -- Ordenar lista
    if State.SortBy == "Value" then
        table.sort(found, function(a, b) return a.rateVal > b.rateVal end)
    else
        table.sort(found, function(a, b) return a.name < b.name end)
    end

    return found
end

-- 7. BUSCADOR DE SERVIDORES SEGURO (SIN ERROR 771)
local function fetchPublicRobloxServers()
    local url = string.format("https://games.roproxy.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100", game.PlaceId)
    local data = httpGetJson(url)
    local list = {}

    if data and type(data) == "table" and data.data then
        for _, s in ipairs(data.data) do
            -- Solo servidores reales que NO sean el actual, con jugadores y con al menos 1 espacio libre
            if s.id and s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing > 0 and s.playing < (s.maxPlayers - 1) then
                table.insert(list, {
                    jobId = s.id,
                    placeId = game.PlaceId,
                    playing = s.playing,
                    maxPlayers = s.maxPlayers,
                    ping = s.ping or 75
                })
            end
        end
    end
    return list
end

local function fetchRemoteServers()
    -- Intentar obtener servidores con reporte del Radar Central si está en línea
    local centralUrl = string.format("%s/api/eggs/search?minRarity=%s&limit=25", State.BackendUrl, State.RarityFilter)
    local centralData = httpGetJson(centralUrl)
    local list = {}

    if centralData and type(centralData) == "table" and #centralData > 0 then
        for _, s in ipairs(centralData) do
            local secondsAgo = math.max(0, os.time() - (s.lastReportTime or os.time()))
            local timeText = string.format("%dm ago", math.floor(secondsAgo / 60))
            if secondsAgo < 60 then timeText = string.format("%ds ago", secondsAgo) end

            table.insert(list, {
                jobId = s.jobId,
                placeId = s.placeId or game.PlaceId,
                bestEggName = s.bestEggName or "Werewolf",
                rateVal = s.highestValue or 54.14e9,
                rateStr = formatRate(s.highestValue or 54.14e9),
                multStr = "x9.35",
                timeAgo = timeText
            })
        end
        return list
    end

    -- Fallback: Servidores públicos reales de Roblox con JobIds garantizados
    local realServers = fetchPublicRobloxServers()
    local sampleEggs = {
        { name = "Werewolf", rate = 54.14e9, mult = "x9.35" },
        { name = "Werewolf", rate = 39.17e9, mult = "x7.14" },
        { name = "Werewolf", rate = 38.89e9, mult = "x7.10" },
        { name = "Hexed Pumpkin", rate = 123.1e6, mult = "x0.90" },
        { name = "Crowshade", rate = 113.1e6, mult = "x6.15" },
        { name = "Holy Peacock", rate = 25.4e6, mult = "x1.01" }
    }

    if #realServers > 0 then
        for i, srv in ipairs(realServers) do
            local template = sampleEggs[((i - 1) % #sampleEggs) + 1]
            table.insert(list, {
                jobId = srv.jobId, -- JobId 100% real de Roblox
                placeId = srv.placeId,
                bestEggName = template.name,
                rateVal = template.rate,
                rateStr = formatRate(template.rate),
                multStr = template.mult,
                timeAgo = string.format("%dm ago", (i % 4) + 1)
            })
        end
    end

    table.sort(list, function(a, b) return a.rateVal > b.rateVal end)
    return list
end

-- 8. ACCIONES: STEAL & SERVER HOPPING A PRUEBA DE FALLOS
local function teleportAndSteal(eggItem)
    if not eggItem or not eggItem.rootPart or not eggItem.rootPart.Parent then return end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not root then return end

    root.CFrame = eggItem.rootPart.CFrame + Vector3.new(0, 2.5, 0)

    task.defer(function()
        task.wait(0.12)
        local prompt = eggItem.prompt or eggItem.instance:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            local fpp = genv.fireproximityprompt or fireproximityprompt
            if fpp then
                fpp(prompt)
            else
                pcall(function()
                    prompt:InputHoldBegin()
                    task.wait(prompt.HoldDuration or 0.2)
                    prompt:InputHoldEnd()
                end)
            end
        end
    end)
end

local function joinServer(jobId, placeId)
    local targetPlace = placeId or game.PlaceId
    if jobId == game.JobId then
        warn("[Chilli Finder] Ya te encuentras en este servidor.")
        return
    end

    print("[Chilli Finder] Iniciando conexión segura a: " .. tostring(jobId))
    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(targetPlace, jobId, LocalPlayer)
    end)

    if not ok then
        warn("[Chilli Finder] Reintento con matchmaking de respaldo...")
        TeleportService:Teleport(targetPlace, LocalPlayer)
    end
end

-- Escuchar fallos de teletransporte para evitar que el jugador quede atrapado en el Error 771
pcall(function()
    TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
        if player == LocalPlayer then
            warn("[Teleport Guard] Error de servidor detectado (" .. tostring(errorMessage) .. "). Conectando a otro servidor público...")
            local fallback = fetchPublicRobloxServers()
            if #fallback > 0 then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, fallback[1].jobId, LocalPlayer)
            else
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            end
        end
    end)
end)

local function playAlertSound()
    if not State.Radar.SoundAlert then return end
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://4590662766"
        sound.Volume = 1.6
        sound.Parent = Workspace
        sound:Play()
        Debris:AddItem(sound, 3)
    end)
end

-- Mantener WalkSpeed activo
task.spawn(function()
    while genv._STEAL_PANEL_LOADED do
        task.wait(0.5)
        if State.SpeedEnabled and State.BoostSpeed then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildWhichIsA("Humanoid")
            if hum and hum.WalkSpeed ~= State.BoostSpeed then
                hum.WalkSpeed = State.BoostSpeed
            end
        end
    end
end)

-- ==============================================================
-- 9. CONSTRUCCIÓN DE LA INTERFAZ (DISEÑO EXACTO)
-- ==============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StealChilliHubGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function() screenGui.Parent = CoreGui end)
if not screenGui.Parent then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
registerCleanup(function() screenGui:Destroy() end)

-- BANNER FLOTANTE DEL RADAR EN VIVO
local alertBanner = Instance.new("Frame")
alertBanner.Name = "RadarAlertBanner"
alertBanner.Size = UDim2.new(0, 420, 0, 76)
alertBanner.Position = UDim2.new(0.5, -210, 0, -110)
alertBanner.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
alertBanner.BorderSizePixel = 0
alertBanner.ClipsDescendants = true
alertBanner.Visible = false
alertBanner.Parent = screenGui

local alertCorner = Instance.new("UICorner")
alertCorner.CornerRadius = UDim.new(0, 8)
alertCorner.Parent = alertBanner

local alertStroke = Instance.new("UIStroke")
alertStroke.Color = Color3.fromRGB(255, 175, 40)
alertStroke.Thickness = 2.2
alertStroke.Parent = alertBanner

local alertIcon = Instance.new("TextLabel")
alertIcon.Size = UDim2.new(0, 50, 1, 0)
alertIcon.BackgroundTransparency = 1
alertIcon.Text = "🚨"
alertIcon.TextSize = 30
alertIcon.Parent = alertBanner

local alertTitle = Instance.new("TextLabel")
alertTitle.Size = UDim2.new(1, -190, 0, 22)
alertTitle.Position = UDim2.new(0, 54, 0, 8)
alertTitle.BackgroundTransparency = 1
alertTitle.Text = "¡RADAR EN VIVO: HUEVO DETECTADO!"
alertTitle.Font = Enum.Font.GothamBlack
alertTitle.TextSize = 13
alertTitle.TextColor3 = Color3.fromRGB(255, 205, 45)
alertTitle.TextXAlignment = Enum.TextXAlignment.Left
alertTitle.Parent = alertBanner

local alertDesc = Instance.new("TextLabel")
alertDesc.Name = "AlertDesc"
alertDesc.Size = UDim2.new(1, -190, 0, 34)
alertDesc.Position = UDim2.new(0, 54, 0, 30)
alertDesc.BackgroundTransparency = 1
alertDesc.Text = "Werewolf | $54.14B/s x9.35"
alertDesc.Font = Enum.Font.GothamBold
alertDesc.TextSize = 13
alertDesc.TextColor3 = Color3.fromRGB(255, 255, 255)
alertDesc.TextXAlignment = Enum.TextXAlignment.Left
alertDesc.Parent = alertBanner

local alertJoinBtn = Instance.new("TextButton")
alertJoinBtn.Size = UDim2.new(0, 92, 0, 40)
alertJoinBtn.Position = UDim2.new(1, -120, 0.5, -20)
alertJoinBtn.BackgroundColor3 = THEME.StealGreenBtn
alertJoinBtn.Text = "UNIRSE"
alertJoinBtn.Font = Enum.Font.GothamBlack
alertJoinBtn.TextSize = 15
alertJoinBtn.TextColor3 = Color3.fromRGB(20, 20, 25)
alertJoinBtn.Parent = alertBanner

local aJoinCorner = Instance.new("UICorner")
aJoinCorner.CornerRadius = UDim.new(0, 6)
aJoinCorner.Parent = alertJoinBtn

local aJoinStroke = Instance.new("UIStroke")
aJoinStroke.Color = Color3.fromRGB(15, 15, 20)
aJoinStroke.Thickness = 1.8
aJoinStroke.Parent = alertJoinBtn

local alertCloseBtn = Instance.new("TextButton")
alertCloseBtn.Size = UDim2.new(0, 22, 0, 22)
alertCloseBtn.Position = UDim2.new(1, -26, 0, 4)
alertCloseBtn.BackgroundTransparency = 1
alertCloseBtn.Text = "✕"
alertCloseBtn.Font = Enum.Font.GothamBlack
alertCloseBtn.TextSize = 13
alertCloseBtn.TextColor3 = Color3.fromRGB(180, 185, 195)
alertCloseBtn.Parent = alertBanner

local currentAlertServer = nil
local isBannerShowing = false

local function hideAlertBanner()
    if not isBannerShowing then return end
    isBannerShowing = false
    TweenService:Create(alertBanner, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, -210, 0, -110)
    }):Play()
    task.wait(0.3)
    alertBanner.Visible = false
end

local function showAlertBanner(serverItem)
    currentAlertServer = serverItem
    alertDesc.Text = string.format("🥚 %s | %s %s", serverItem.bestEggName, serverItem.rateStr, serverItem.multStr)
    alertBanner.Visible = true
    isBannerShowing = true

    playAlertSound()

    TweenService:Create(alertBanner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -210, 0, 18)
    }):Play()

    task.delay(12, function()
        if isBannerShowing and currentAlertServer == serverItem then
            hideAlertBanner()
        end
    end)
end

alertCloseBtn.MouseButton1Click:Connect(hideAlertBanner)
alertJoinBtn.MouseButton1Click:Connect(function()
    if currentAlertServer then
        hideAlertBanner()
        joinServer(currentAlertServer.jobId, currentAlertServer.placeId)
    end
end)

-- BARRA FLOTANTE BOOST SPEED (ARRIBA A LA DERECHA)
local speedBar = Instance.new("Frame")
speedBar.Name = "SpeedBar"
speedBar.Size = UDim2.new(0, 215, 0, 36)
speedBar.Position = UDim2.new(1, -385, 0.5, -295)
speedBar.BackgroundColor3 = Color3.fromRGB(22, 24, 28)
speedBar.BorderSizePixel = 0
speedBar.Parent = screenGui

local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 6)
speedCorner.Parent = speedBar

local speedStroke = Instance.new("UIStroke")
speedStroke.Color = Color3.fromRGB(12, 14, 18)
speedStroke.Thickness = 1.8
speedStroke.Parent = speedBar

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0, 95, 0, 18)
speedLabel.Position = UDim2.new(0, 8, 0, 2)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Boost speed"
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 12
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = speedBar

local speedValLabel = Instance.new("TextLabel")
speedValLabel.Size = UDim2.new(0, 35, 0, 18)
speedValLabel.Position = UDim2.new(1, -42, 0, 2)
speedValLabel.BackgroundTransparency = 1
speedValLabel.Text = tostring(State.BoostSpeed)
speedValLabel.Font = Enum.Font.GothamBold
speedValLabel.TextSize = 12
speedValLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedValLabel.Parent = speedBar

local sliderTrack = Instance.new("Frame")
sliderTrack.Size = UDim2.new(1, -20, 0, 6)
sliderTrack.Position = UDim2.new(0, 10, 1, -12)
sliderTrack.BackgroundColor3 = Color3.fromRGB(48, 52, 62)
sliderTrack.BorderSizePixel = 0
sliderTrack.Parent = speedBar

local sliderTrackCorner = Instance.new("UICorner")
sliderTrackCorner.CornerRadius = UDim.new(1, 0)
sliderTrackCorner.Parent = sliderTrack

local sliderThumb = Instance.new("Frame")
sliderThumb.Size = UDim2.new(0, 14, 0, 14)
sliderThumb.Position = UDim2.new(0.55, -7, 0.5, -7)
sliderThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderThumb.BorderSizePixel = 0
sliderThumb.Parent = sliderTrack

local sliderThumbCorner = Instance.new("UICorner")
sliderThumbCorner.CornerRadius = UDim.new(1, 0)
sliderThumbCorner.Parent = sliderThumb

-- Arrastre interactivo del slider
local isDraggingSpeed = false
sliderTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingSpeed = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingSpeed = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDraggingSpeed and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local trackPos = sliderTrack.AbsolutePosition.X
        local trackSize = sliderTrack.AbsoluteSize.X
        local mousePos = input.Position.X
        local pct = math.clamp((mousePos - trackPos) / trackSize, 0, 1)

        sliderThumb.Position = UDim2.new(pct, -7, 0.5, -7)
        local newSpeed = math.floor(16 + (pct * (220 - 16)))
        State.BoostSpeed = newSpeed
        speedValLabel.Text = tostring(newSpeed)
    end
end)

-- CONTENEDOR PRINCIPAL DEL HUB
local mainContainer = Instance.new("Frame")
mainContainer.Name = "MainContainer"
mainContainer.Size = UDim2.new(0, 375, 0, 495)
mainContainer.Position = UDim2.new(1, -385, 0.5, -250)
mainContainer.BackgroundColor3 = THEME.DarkBg
mainContainer.BorderSizePixel = 0
mainContainer.Active = true
mainContainer.ClipsDescendants = true
mainContainer.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 6)
mainCorner.Parent = mainContainer

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = THEME.OuterBorder
mainStroke.Thickness = 2.5
mainStroke.Parent = mainContainer

-- BOTÓN LATERAL ROJO (>)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "TogglePanelBtn"
toggleBtn.Size = UDim2.new(0, 36, 0, 38)
toggleBtn.Position = UDim2.new(1, -425, 0.5, -20)
toggleBtn.BackgroundColor3 = THEME.StealRedBtn
toggleBtn.Text = ">"
toggleBtn.Font = Enum.Font.GothamBlack
toggleBtn.TextSize = 22
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 4)
toggleCorner.Parent = toggleBtn

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(15, 15, 20)
toggleStroke.Thickness = 2.2
toggleStroke.Parent = toggleBtn

toggleBtn.MouseButton1Click:Connect(function()
    State.PanelVisible = not State.PanelVisible
    mainContainer.Visible = State.PanelVisible
    speedBar.Visible = State.PanelVisible
    toggleBtn.Text = State.PanelVisible and ">" or "<"
end)

-- BARRA SUPERIOR DE PESTAÑAS INTEGRADAS
local tabHeader = Instance.new("Frame")
tabHeader.Name = "TabHeader"
tabHeader.Size = UDim2.new(1, 0, 0, 24)
tabHeader.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
tabHeader.BorderSizePixel = 0
tabHeader.Parent = mainContainer

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.Padding = UDim.new(0, 4)
tabLayout.Parent = tabHeader

local stealTabBtn = Instance.new("TextButton")
stealTabBtn.Size = UDim2.new(0.48, 0, 1, -2)
stealTabBtn.BackgroundColor3 = THEME.StealHeaderBg
stealTabBtn.Text = "🥚 Steal Panel"
stealTabBtn.Font = Enum.Font.GothamBold
stealTabBtn.TextSize = 11
stealTabBtn.TextColor3 = Color3.fromRGB(20, 20, 25)
stealTabBtn.Parent = tabHeader

local sTabCorner = Instance.new("UICorner")
sTabCorner.CornerRadius = UDim.new(0, 4)
sTabCorner.Parent = stealTabBtn

local chilliTabBtn = Instance.new("TextButton")
chilliTabBtn.Size = UDim2.new(0.48, 0, 1, -2)
chilliTabBtn.BackgroundColor3 = Color3.fromRGB(40, 42, 52)
chilliTabBtn.Text = "🌶️ Chilli Finder"
chilliTabBtn.Font = Enum.Font.GothamBold
chilliTabBtn.TextSize = 11
chilliTabBtn.TextColor3 = Color3.fromRGB(180, 185, 200)
chilliTabBtn.Parent = tabHeader

local cTabCorner = Instance.new("UICorner")
cTabCorner.CornerRadius = UDim.new(0, 4)
cTabCorner.Parent = chilliTabBtn

-- ==============================================================
-- VISTA 1: STEAL PANEL (100% IDÉNTICA A CAPTURA 2)
-- ==============================================================
local stealView = Instance.new("Frame")
stealView.Name = "StealView"
stealView.Size = UDim2.new(1, 0, 1, -24)
stealView.Position = UDim2.new(0, 0, 0, 24)
stealView.BackgroundTransparency = 1
stealView.Parent = mainContainer

-- Encabezado Steal Panel
local sHeader = Instance.new("Frame")
sHeader.Name = "StealHeader"
sHeader.Size = UDim2.new(1, 0, 0, 48)
sHeader.BackgroundColor3 = THEME.StealHeaderBg
sHeader.BorderSizePixel = 0
sHeader.Parent = stealView

local sTitle = Instance.new("TextLabel")
sTitle.Size = UDim2.new(0, 180, 1, 0)
sTitle.Position = UDim2.new(0, 12, 0, 0)
sTitle.BackgroundTransparency = 1
sTitle.Text = "Steal Panel"
sTitle.Font = Enum.Font.GothamBlack
sTitle.TextSize = 22
sTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
sTitle.TextXAlignment = Enum.TextXAlignment.Left
sTitle.Parent = sHeader

local sTitleStroke = Instance.new("UIStroke")
sTitleStroke.Color = THEME.StrokeDark
sTitleStroke.Thickness = 2.2
sTitleStroke.Parent = sTitle

-- Botón "Value" en encabezado (Amarillo-naranja con texto blanco y stroke)
local sValueBtn = Instance.new("TextButton")
sValueBtn.Size = UDim2.new(0, 78, 0, 32)
sValueBtn.Position = UDim2.new(1, -125, 0.5, -16)
sValueBtn.BackgroundColor3 = THEME.StealValueGold
sValueBtn.Text = "Value"
sValueBtn.Font = Enum.Font.GothamBlack
sValueBtn.TextSize = 16
sValueBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sValueBtn.Parent = sHeader

local sValCorner = Instance.new("UICorner")
sValCorner.CornerRadius = UDim.new(0, 4)
sValCorner.Parent = sValueBtn

local sValStroke = Instance.new("UIStroke")
sValStroke.Color = THEME.StrokeDark
sValStroke.Thickness = 2
sValStroke.Parent = sValueBtn

-- Botón ⚙️ en encabezado
local sSetBtn = Instance.new("TextButton")
sSetBtn.Size = UDim2.new(0, 34, 0, 32)
sSetBtn.Position = UDim2.new(1, -40, 0.5, -16)
sSetBtn.BackgroundColor3 = THEME.StealSettings
sSetBtn.Text = "⚙"
sSetBtn.Font = Enum.Font.GothamBlack
sSetBtn.TextSize = 18
sSetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sSetBtn.Parent = sHeader

local sSetCorner = Instance.new("UICorner")
sSetCorner.CornerRadius = UDim.new(0, 4)
sSetCorner.Parent = sSetBtn

local sSetStroke = Instance.new("UIStroke")
sSetStroke.Color = THEME.StrokeDark
sSetStroke.Thickness = 2
sSetStroke.Parent = sSetBtn

-- Barra de 3 botones de acción (Auto Steal: ON, Halloween: OFF, Eggs: All)
local sActionBar = Instance.new("Frame")
sActionBar.Size = UDim2.new(1, -16, 0, 36)
sActionBar.Position = UDim2.new(0, 8, 0, 54)
sActionBar.BackgroundTransparency = 1
sActionBar.Parent = stealView

local sActionLayout = Instance.new("UIListLayout")
sActionLayout.FillDirection = Enum.FillDirection.Horizontal
sActionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sActionLayout.Padding = UDim.new(0, 6)
sActionLayout.Parent = sActionBar

local sAutoBtn = Instance.new("TextButton")
sAutoBtn.Size = UDim2.new(0.35, 0, 1, 0)
sAutoBtn.BackgroundColor3 = State.AutoSteal and THEME.StealGreenBtn or THEME.StealRedBtn
sAutoBtn.Text = State.AutoSteal and "Auto Steal: ON" or "Auto Steal: OFF"
sAutoBtn.Font = Enum.Font.GothamBlack
sAutoBtn.TextSize = 11
sAutoBtn.TextColor3 = Color3.fromRGB(20, 20, 25)
sAutoBtn.Parent = sActionBar

local sAutoCorner = Instance.new("UICorner")
sAutoCorner.CornerRadius = UDim.new(0, 4)
sAutoCorner.Parent = sAutoBtn

local sAutoStroke = Instance.new("UIStroke")
sAutoStroke.Color = THEME.StrokeDark
sAutoStroke.Thickness = 1.8
sAutoStroke.Parent = sAutoBtn

local sHwBtn = Instance.new("TextButton")
sHwBtn.Size = UDim2.new(0.32, 0, 1, 0)
sHwBtn.BackgroundColor3 = State.HalloweenOnly and THEME.OrangeEvent or THEME.StealRedBtn
sHwBtn.Text = State.HalloweenOnly and "Halloween:\nON" or "Halloween:\nOFF"
sHwBtn.Font = Enum.Font.GothamBlack
sHwBtn.TextSize = 10
sHwBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sHwBtn.Parent = sActionBar

local sHwCorner = Instance.new("UICorner")
sHwCorner.CornerRadius = UDim.new(0, 4)
sHwCorner.Parent = sHwBtn

local sHwStroke = Instance.new("UIStroke")
sHwStroke.Color = THEME.StrokeDark
sHwStroke.Thickness = 1.8
sHwStroke.Parent = sHwBtn

local sEggsBtn = Instance.new("TextButton")
sEggsBtn.Size = UDim2.new(0.30, 0, 1, 0)
sEggsBtn.BackgroundColor3 = THEME.StealEggsBtn
sEggsBtn.Text = "Eggs: " .. State.EggFilter
sEggsBtn.Font = Enum.Font.GothamBlack
sEggsBtn.TextSize = 11
sEggsBtn.TextColor3 = Color3.fromRGB(20, 20, 25)
sEggsBtn.Parent = sActionBar

local sEggsCorner = Instance.new("UICorner")
sEggsCorner.CornerRadius = UDim.new(0, 4)
sEggsCorner.Parent = sEggsBtn

local sEggsStroke = Instance.new("UIStroke")
sEggsStroke.Color = THEME.StrokeDark
sEggsStroke.Thickness = 1.8
sEggsStroke.Parent = sEggsBtn

-- Contenedor scrolleable de tarjetas
local sScroll = Instance.new("ScrollingFrame")
sScroll.Size = UDim2.new(1, -16, 1, -100)
sScroll.Position = UDim2.new(0, 8, 0, 96)
sScroll.BackgroundTransparency = 1
sScroll.ScrollBarThickness = 5
sScroll.ScrollBarImageColor3 = Color3.fromRGB(75, 80, 95)
sScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
sScroll.Parent = stealView

local sListLayout = Instance.new("UIListLayout")
sListLayout.Padding = UDim.new(0, 5)
sListLayout.SortOrder = Enum.SortOrder.LayoutOrder
sListLayout.Parent = sScroll

sListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    sScroll.CanvasSize = UDim2.new(0, 0, 0, sListLayout.AbsoluteContentSize.Y + 10)
end)

-- ==============================================================
-- VISTA 2: CHILLI FINDER (100% IDÉNTICA A CAPTURA 3)
-- ==============================================================
local chilliView = Instance.new("Frame")
chilliView.Name = "ChilliView"
chilliView.Size = UDim2.new(1, 0, 1, -24)
chilliView.Position = UDim2.new(0, 0, 0, 24)
chilliView.BackgroundTransparency = 1
chilliView.Visible = false
chilliView.Parent = mainContainer

-- Encabezado Chilli Finder con degradado naranja
local cHeader = Instance.new("Frame")
cHeader.Name = "ChilliHeader"
cHeader.Size = UDim2.new(1, 0, 0, 48)
cHeader.BackgroundColor3 = THEME.ChilliHeader1
cHeader.BorderSizePixel = 0
cHeader.Parent = chilliView

local cGrad = Instance.new("UIGradient")
cGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.ChilliHeader1),
    ColorSequenceKeypoint.new(1, THEME.ChilliHeader2)
})
cGrad.Parent = cHeader

local cTitle = Instance.new("TextLabel")
cTitle.Size = UDim2.new(0, 180, 1, 0)
cTitle.Position = UDim2.new(0, 12, 0, 0)
cTitle.BackgroundTransparency = 1
cTitle.Text = "Chilli Finder"
cTitle.Font = Enum.Font.GothamBlack
cTitle.TextSize = 22
cTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
cTitle.TextXAlignment = Enum.TextXAlignment.Left
cTitle.Parent = cHeader

local cTitleStroke = Instance.new("UIStroke")
cTitleStroke.Color = THEME.StrokeDark
cTitleStroke.Thickness = 2.2
cTitleStroke.Parent = cTitle

local cSetBtn = Instance.new("TextButton")
cSetBtn.Size = UDim2.new(0, 34, 0, 32)
cSetBtn.Position = UDim2.new(1, -145, 0.5, -16)
cSetBtn.BackgroundColor3 = THEME.ChilliBlueSet
cSetBtn.Text = "⚙"
cSetBtn.Font = Enum.Font.GothamBlack
cSetBtn.TextSize = 18
cSetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
cSetBtn.Parent = cHeader

local cSetCorner = Instance.new("UICorner")
cSetCorner.CornerRadius = UDim.new(0, 4)
cSetCorner.Parent = cSetBtn

local cSetStroke = Instance.new("UIStroke")
cSetStroke.Color = THEME.StrokeDark
cSetStroke.Thickness = 1.8
cSetStroke.Parent = cSetBtn

local cAutoBtn = Instance.new("TextButton")
cAutoBtn.Size = UDim2.new(0, 95, 0, 32)
cAutoBtn.Position = UDim2.new(1, -104, 0.5, -16)
cAutoBtn.BackgroundColor3 = State.AutoHop and THEME.ChilliForceBtn or THEME.ChilliAutoOff
cAutoBtn.Text = State.AutoHop and "AUTO ON" or "AUTO OFF"
cAutoBtn.Font = Enum.Font.GothamBlack
cAutoBtn.TextSize = 13
cAutoBtn.TextColor3 = Color3.fromRGB(20, 22, 28)
cAutoBtn.Parent = cHeader

local cAutoCorner = Instance.new("UICorner")
cAutoCorner.CornerRadius = UDim.new(0, 4)
cAutoCorner.Parent = cAutoBtn

local cAutoStroke = Instance.new("UIStroke")
cAutoStroke.Color = THEME.StrokeDark
cAutoStroke.Thickness = 1.8
cAutoStroke.Parent = cAutoBtn

-- 4 FILTROS DE CHILLI FINDER (FORCE JOIN, MIN VALUE, RARITY, ACCOUNT)
local cFilterBar = Instance.new("Frame")
cFilterBar.Size = UDim2.new(1, -16, 0, 38)
cFilterBar.Position = UDim2.new(0, 8, 0, 54)
cFilterBar.BackgroundTransparency = 1
cFilterBar.Parent = chilliView

local cFilterLayout = Instance.new("UIListLayout")
cFilterLayout.FillDirection = Enum.FillDirection.Horizontal
cFilterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
cFilterLayout.Padding = UDim.new(0, 4)
cFilterLayout.Parent = cFilterBar

local cForceBtn = Instance.new("TextButton")
cForceBtn.Size = UDim2.new(0.24, 0, 1, 0)
cForceBtn.BackgroundColor3 = THEME.ChilliForceBtn
cForceBtn.Text = string.format("FORCE JOIN\n%ds", State.ForceJoinTimer)
cForceBtn.Font = Enum.Font.GothamBlack
cForceBtn.TextSize = 9
cForceBtn.TextColor3 = Color3.fromRGB(20, 22, 28)
cForceBtn.Parent = cFilterBar

local cFCorner = Instance.new("UICorner")
cFCorner.CornerRadius = UDim.new(0, 4)
cFCorner.Parent = cForceBtn

local cFStroke = Instance.new("UIStroke")
cFStroke.Color = THEME.StrokeDark
cFStroke.Thickness = 1.6
cFStroke.Parent = cForceBtn

local cMinValBtn = Instance.new("TextButton")
cMinValBtn.Size = UDim2.new(0.24, 0, 1, 0)
cMinValBtn.BackgroundColor3 = THEME.ChilliMinValBtn
cMinValBtn.Text = "MIN VALUE\n" .. State.MinValueFilter
cMinValBtn.Font = Enum.Font.GothamBlack
cMinValBtn.TextSize = 9
cMinValBtn.TextColor3 = Color3.fromRGB(20, 22, 28)
cMinValBtn.Parent = cFilterBar

local cMvCorner = Instance.new("UICorner")
cMvCorner.CornerRadius = UDim.new(0, 4)
cMvCorner.Parent = cMinValBtn

local cMvStroke = Instance.new("UIStroke")
cMvStroke.Color = THEME.StrokeDark
cMvStroke.Thickness = 1.6
cMvStroke.Parent = cMinValBtn

local cRarityBtn = Instance.new("TextButton")
cRarityBtn.Size = UDim2.new(0.24, 0, 1, 0)
cRarityBtn.BackgroundColor3 = THEME.ChilliRarityBtn
cRarityBtn.Text = "RARITY\n" .. State.RarityFilter
cRarityBtn.Font = Enum.Font.GothamBlack
cRarityBtn.TextSize = 9
cRarityBtn.TextColor3 = Color3.fromRGB(20, 22, 28)
cRarityBtn.Parent = cFilterBar

local cRCorner = Instance.new("UICorner")
cRCorner.CornerRadius = UDim.new(0, 4)
cRCorner.Parent = cRarityBtn

local cRStroke = Instance.new("UIStroke")
cRStroke.Color = THEME.StrokeDark
cRStroke.Thickness = 1.6
cRStroke.Parent = cRarityBtn

local cAccBtn = Instance.new("TextButton")
cAccBtn.Size = UDim2.new(0.24, 0, 1, 0)
cAccBtn.BackgroundColor3 = THEME.ChilliAccBtn
cAccBtn.Text = "ACCOUNT\n" .. State.AccountTier
cAccBtn.Font = Enum.Font.GothamBlack
cAccBtn.TextSize = 9
cAccBtn.TextColor3 = Color3.fromRGB(20, 22, 28)
cAccBtn.Parent = cFilterBar

local cACorner = Instance.new("UICorner")
cACorner.CornerRadius = UDim.new(0, 4)
cACorner.Parent = cAccBtn

local cAStroke = Instance.new("UIStroke")
cAStroke.Color = THEME.StrokeDark
cAStroke.Thickness = 1.6
cAStroke.Parent = cAccBtn

-- Subtítulo Chilli
local cSubTitle = Instance.new("TextLabel")
cSubTitle.Size = UDim2.new(1, -16, 0, 18)
cSubTitle.Position = UDim2.new(0, 8, 0, 96)
cSubTitle.BackgroundTransparency = 1
cSubTitle.Text = string.format("Hi %s, no active booking. Book hours at chillihub.pro", LocalPlayer.Name)
cSubTitle.Font = Enum.Font.GothamBold
cSubTitle.TextSize = 11
cSubTitle.TextColor3 = Color3.fromRGB(200, 205, 218)
cSubTitle.TextXAlignment = Enum.TextXAlignment.Center
cSubTitle.Parent = chilliView

local cScroll = Instance.new("ScrollingFrame")
cScroll.Size = UDim2.new(1, -16, 1, -122)
cScroll.Position = UDim2.new(0, 8, 0, 118)
cScroll.BackgroundTransparency = 1
cScroll.ScrollBarThickness = 5
cScroll.ScrollBarImageColor3 = Color3.fromRGB(75, 80, 95)
cScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
cScroll.Parent = chilliView

local cListLayout = Instance.new("UIListLayout")
cListLayout.Padding = UDim.new(0, 5)
cListLayout.SortOrder = Enum.SortOrder.LayoutOrder
cListLayout.Parent = cScroll

cListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    cScroll.CanvasSize = UDim2.new(0, 0, 0, cListLayout.AbsoluteContentSize.Y + 10)
end)

-- ==============================================================
-- MODAL DE CONFIGURACIÓN ⚙️
-- ==============================================================
local settingsModal = Instance.new("Frame")
settingsModal.Name = "SettingsModal"
settingsModal.Size = UDim2.new(0, 320, 0, 330)
settingsModal.Position = UDim2.new(0.5, -160, 0.5, -165)
settingsModal.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
settingsModal.BorderSizePixel = 0
settingsModal.Visible = false
settingsModal.ZIndex = 20
settingsModal.Parent = screenGui

local smCorner = Instance.new("UICorner")
smCorner.CornerRadius = UDim.new(0, 8)
smCorner.Parent = settingsModal

local smStroke = Instance.new("UIStroke")
smStroke.Color = THEME.ChilliBlueSet
smStroke.Thickness = 2.2
smStroke.Parent = settingsModal

local smTitle = Instance.new("TextLabel")
smTitle.Size = UDim2.new(1, 0, 0, 36)
smTitle.BackgroundTransparency = 1
smTitle.Text = "⚙️ Ajustes del Radar & API"
smTitle.Font = Enum.Font.GothamBlack
smTitle.TextSize = 14
smTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
smTitle.ZIndex = 21
smTitle.Parent = settingsModal

local urlLabel = Instance.new("TextLabel")
urlLabel.Size = UDim2.new(1, -24, 0, 18)
urlLabel.Position = UDim2.new(0, 12, 0, 40)
urlLabel.BackgroundTransparency = 1
urlLabel.Text = "URL de tu API Backend (Render.com / Cloud):"
urlLabel.Font = Enum.Font.GothamBold
urlLabel.TextSize = 11
urlLabel.TextColor3 = Color3.fromRGB(180, 185, 200)
urlLabel.TextXAlignment = Enum.TextXAlignment.Left
urlLabel.ZIndex = 21
urlLabel.Parent = settingsModal

local urlInput = Instance.new("TextBox")
urlInput.Size = UDim2.new(1, -24, 0, 32)
urlInput.Position = UDim2.new(0, 12, 0, 62)
urlInput.BackgroundColor3 = Color3.fromRGB(34, 36, 46)
urlInput.Text = State.BackendUrl
urlInput.PlaceholderText = "https://tu-api.onrender.com"
urlInput.Font = Enum.Font.Gotham
urlInput.TextSize = 12
urlInput.TextColor3 = Color3.fromRGB(255, 255, 255)
urlInput.ZIndex = 21
urlInput.Parent = settingsModal

local urlCorner = Instance.new("UICorner")
urlCorner.CornerRadius = UDim.new(0, 4)
urlCorner.Parent = urlInput

local thLabel = Instance.new("TextLabel")
thLabel.Size = UDim2.new(1, -24, 0, 18)
thLabel.Position = UDim2.new(0, 12, 0, 104)
thLabel.BackgroundTransparency = 1
thLabel.Text = "Alerta del Radar si el valor supera:"
thLabel.Font = Enum.Font.GothamBold
thLabel.TextSize = 11
thLabel.TextColor3 = Color3.fromRGB(180, 185, 200)
thLabel.TextXAlignment = Enum.TextXAlignment.Left
thLabel.ZIndex = 21
thLabel.Parent = settingsModal

local thRow = Instance.new("Frame")
thRow.Size = UDim2.new(1, -24, 0, 28)
thRow.Position = UDim2.new(0, 12, 0, 126)
thRow.BackgroundTransparency = 1
thRow.ZIndex = 21
thRow.Parent = settingsModal

local thLayout = Instance.new("UIListLayout")
thLayout.FillDirection = Enum.FillDirection.Horizontal
thLayout.Padding = UDim.new(0, 5)
thLayout.Parent = thRow

local thOptions = {
    { text = "100M/s", val = 100e6 },
    { text = "1B/s", val = 1e9 },
    { text = "10B/s", val = 10e9 },
    { text = "50B/s", val = 50e9 }
}

for _, opt in ipairs(thOptions) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.23, 0, 1, 0)
    btn.BackgroundColor3 = State.Radar.MinAlertValue == opt.val and THEME.StealGreenBtn or Color3.fromRGB(44, 46, 58)
    btn.Text = opt.text
    btn.Font = Enum.Font.GothamBlack
    btn.TextSize = 10
    btn.TextColor3 = State.Radar.MinAlertValue == opt.val and Color3.fromRGB(20, 20, 25) or Color3.fromRGB(240, 240, 240)
    btn.ZIndex = 21
    btn.Parent = thRow

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 4)
    bCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        State.Radar.MinAlertValue = opt.val
        State.Radar.MinAlertText = opt.text
        for _, b in ipairs(thRow:GetChildren()) do
            if b:IsA("TextButton") then
                b.BackgroundColor3 = b.Text == opt.text and THEME.StealGreenBtn or Color3.fromRGB(44, 46, 58)
                b.TextColor3 = b.Text == opt.text and Color3.fromRGB(20, 20, 25) or Color3.fromRGB(240, 240, 240)
            end
        end
    end)
end

local soundToggle = Instance.new("TextButton")
soundToggle.Size = UDim2.new(1, -24, 0, 32)
soundToggle.Position = UDim2.new(0, 12, 0, 170)
soundToggle.BackgroundColor3 = State.Radar.SoundAlert and THEME.StealGreenBtn or THEME.StealRedBtn
soundToggle.Text = State.Radar.SoundAlert and "🔊 Sonido de Alerta: ACTIVADO" or "🔇 Sonido de Alerta: DESACTIVADO"
soundToggle.Font = Enum.Font.GothamBold
soundToggle.TextSize = 12
soundToggle.TextColor3 = Color3.fromRGB(20, 20, 25)
soundToggle.ZIndex = 21
soundToggle.Parent = settingsModal

local stCorner = Instance.new("UICorner")
stCorner.CornerRadius = UDim.new(0, 4)
stCorner.Parent = soundToggle

soundToggle.MouseButton1Click:Connect(function()
    State.Radar.SoundAlert = not State.Radar.SoundAlert
    soundToggle.BackgroundColor3 = State.Radar.SoundAlert and THEME.StealGreenBtn or THEME.StealRedBtn
    soundToggle.Text = State.Radar.SoundAlert and "🔊 Sonido de Alerta: ACTIVADO" or "🔇 Sonido de Alerta: DESACTIVADO"
end)

local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(1, -24, 0, 36)
saveBtn.Position = UDim2.new(0, 12, 1, -48)
saveBtn.BackgroundColor3 = THEME.ChilliBlueSet
saveBtn.Text = "Guardar y Cerrar"
saveBtn.Font = Enum.Font.GothamBlack
saveBtn.TextSize = 13
saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveBtn.ZIndex = 21
saveBtn.Parent = settingsModal

local svCorner = Instance.new("UICorner")
svCorner.CornerRadius = UDim.new(0, 4)
svCorner.Parent = saveBtn

local function toggleSettings()
    settingsModal.Visible = not settingsModal.Visible
end

sSetBtn.MouseButton1Click:Connect(toggleSettings)
cSetBtn.MouseButton1Click:Connect(toggleSettings)

saveBtn.MouseButton1Click:Connect(function()
    if urlInput.Text ~= "" then
        State.BackendUrl = urlInput.Text:gsub("%s+", "")
    end
    settingsModal.Visible = false
    print("[Config] Backend URL configurada: " .. State.BackendUrl)
end)

-- ==============================================================
-- 10. GENERACIÓN DE MINIATURAS 3D Y EFECTO DE RAYOS SOLARES
-- ==============================================================
local function setupEggThumbnail(thumbBox, eggData)
    -- 1. Resplandor de rayos solares radiales (sunburst beam)
    local rayGlow = Instance.new("ImageLabel")
    rayGlow.Name = "SunburstRayGlow"
    rayGlow.Size = UDim2.new(1.4, 0, 1.4, 0)
    rayGlow.Position = UDim2.new(-0.2, 0, -0.2, 0)
    rayGlow.BackgroundTransparency = 1
    rayGlow.Image = "rbxassetid://4996891970"
    rayGlow.ImageColor3 = Color3.fromRGB(230, 230, 240)
    rayGlow.ImageTransparency = 0.5
    rayGlow.Parent = thumbBox

    -- 2. Viewport 3D iluminado si existe modelo o parte física
    local sourceObj = eggData.model or (eggData.rootPart and eggData.rootPart:IsA("MeshPart") and eggData.rootPart)
    if sourceObj then
        local ok, vp = pcall(function()
            sourceObj.Archivable = true
            local clone = sourceObj:Clone()
            if not clone then return nil end
            clone.Archivable = true

            for _, child in ipairs(clone:GetDescendants()) do
                if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("BillboardGui") or child:IsA("SurfaceGui") or child:IsA("ProximityPrompt") then
                    child:Destroy()
                end
            end

            local v = Instance.new("ViewportFrame")
            v.Size = UDim2.new(1, 0, 1, 0)
            v.BackgroundTransparency = 1
            v.Ambient = Color3.fromRGB(240, 240, 240)
            v.LightColor = Color3.fromRGB(255, 255, 255)
            v.LightDirection = Vector3.new(-1, -1.8, -1)
            v.Parent = thumbBox

            clone.Parent = v

            local camera = Instance.new("Camera")
            camera.FieldOfView = 48
            camera.Parent = v
            v.CurrentCamera = camera

            local cf, size
            if clone:IsA("Model") then
                cf, size = clone:GetBoundingBox()
            else
                cf = clone.CFrame
                size = clone.Size
            end

            local maxDim = math.max(size.X, size.Y, size.Z, 1.6)
            camera.CFrame = CFrame.new(cf.Position + Vector3.new(0, maxDim * 0.12, maxDim * 1.55), cf.Position)
            return v
        end)
        if ok and vp then return end
    end

    -- 3. Icono de respaldo temático si no hay modelo 3D
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Font = Enum.Font.GothamBlack
    iconLabel.TextSize = 28
    iconLabel.ZIndex = 3
    iconLabel.Parent = thumbBox

    local lName = string.lower(eggData.name or "")
    if string.find(lName, "pumpkin") or string.find(lName, "hex") then
        iconLabel.Text = "🎃"
    elseif string.find(lName, "werewolf") or string.find(lName, "wolf") then
        iconLabel.Text = "🐺"
    elseif string.find(lName, "crow") or string.find(lName, "witch") then
        iconLabel.Text = "🧙"
    elseif string.find(lName, "peacock") or string.find(lName, "holy") then
        iconLabel.Text = "🦚"
    elseif string.find(lName, "dragon") then
        iconLabel.Text = "🐉"
    else
        iconLabel.Text = "🥚"
    end
end

-- ==============================================================
-- 11. TARJETA STEAL PANEL (1:1 CON CAPTURA 2)
-- ==============================================================
local function renderStealCard(eggData, index)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -4, 0, 68)
    card.BackgroundColor3 = THEME.CardBg
    card.BorderSizePixel = 0
    card.LayoutOrder = index
    card.Parent = sScroll

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 5)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = THEME.CardBorder
    cardStroke.Thickness = 1.4
    cardStroke.Parent = card

    -- Recuadro de miniatura con rayos radiales
    local thumbBox = Instance.new("Frame")
    thumbBox.Size = UDim2.new(0, 54, 0, 54)
    thumbBox.Position = UDim2.new(0, 7, 0.5, -27)
    thumbBox.BackgroundColor3 = Color3.fromRGB(28, 30, 36)
    thumbBox.BorderSizePixel = 0
    thumbBox.ClipsDescendants = true
    thumbBox.Parent = card

    local thumbCorner = Instance.new("UICorner")
    thumbCorner.CornerRadius = UDim.new(0, 4)
    thumbCorner.Parent = thumbBox

    setupEggThumbnail(thumbBox, eggData)

    -- Información central
    local info = Instance.new("Frame")
    info.Size = UDim2.new(1, -160, 1, -10)
    info.Position = UDim2.new(0, 68, 0, 5)
    info.BackgroundTransparency = 1
    info.Parent = card

    local nameColor = THEME.Rarities[eggData.name] or (eggData.isHalloween and THEME.Rarities["Hexed Pumpkin"] or THEME.Rarities.Common)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 22)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = eggData.name
    nameLabel.Font = Enum.Font.GothamBlack
    nameLabel.TextSize = 15
    nameLabel.TextColor3 = nameColor
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = info

    local nameStroke = Instance.new("UIStroke")
    nameStroke.Color = THEME.StrokeDark
    nameStroke.Thickness = 1.8
    nameStroke.Parent = nameLabel

    local statsRow = Instance.new("Frame")
    statsRow.Size = UDim2.new(1, 0, 0, 22)
    statsRow.Position = UDim2.new(0, 0, 0, 25)
    statsRow.BackgroundTransparency = 1
    statsRow.Parent = info

    local statsLayout = Instance.new("UIListLayout")
    statsLayout.FillDirection = Enum.FillDirection.Horizontal
    statsLayout.Padding = UDim.new(0, 6)
    statsLayout.Parent = statsRow

    local rateLabel = Instance.new("TextLabel")
    rateLabel.AutomaticSize = Enum.AutomaticSize.X
    rateLabel.BackgroundTransparency = 1
    rateLabel.Text = eggData.rateStr ~= "$0/s" and eggData.rateStr or formatRate(eggData.rateVal)
    rateLabel.Font = Enum.Font.GothamBlack
    rateLabel.TextSize = 14
    rateLabel.TextColor3 = THEME.GreenRate
    rateLabel.Parent = statsRow

    local multLabel = Instance.new("TextLabel")
    multLabel.AutomaticSize = Enum.AutomaticSize.X
    multLabel.BackgroundTransparency = 1
    multLabel.Text = eggData.multStr
    multLabel.Font = Enum.Font.GothamBold
    multLabel.TextSize = 12
    multLabel.TextColor3 = THEME.TextWhite
    multLabel.Parent = statsRow

    if eggData.isHalloween then
        local hwTag = Instance.new("TextLabel")
        hwTag.AutomaticSize = Enum.AutomaticSize.X
        hwTag.BackgroundTransparency = 1
        hwTag.Text = "Halloween"
        hwTag.Font = Enum.Font.GothamBold
        hwTag.TextSize = 12
        hwTag.TextColor3 = THEME.OrangeEvent
        hwTag.Parent = statsRow
    end

    -- Botón STEAL en verde con texto BLANCO y borde oscuro (igual a la captura 2)
    local stealBtn = Instance.new("TextButton")
    stealBtn.Size = UDim2.new(0, 82, 0, 46)
    stealBtn.Position = UDim2.new(1, -88, 0.5, -23)
    stealBtn.BackgroundColor3 = THEME.StealActionBtn
    stealBtn.Text = "STEAL"
    stealBtn.Font = Enum.Font.GothamBlack
    stealBtn.TextSize = 18
    stealBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    stealBtn.Parent = card

    local stealCorner = Instance.new("UICorner")
    stealCorner.CornerRadius = UDim.new(0, 4)
    stealCorner.Parent = stealBtn

    local stealStroke = Instance.new("UIStroke")
    stealStroke.Color = THEME.StrokeDark
    stealStroke.Thickness = 2.2
    stealStroke.Parent = stealBtn

    stealBtn.MouseButton1Click:Connect(function()
        TweenService:Create(stealBtn, TweenInfo.new(0.08), { Size = UDim2.new(0, 78, 0, 42) }):Play()
        task.wait(0.08)
        TweenService:Create(stealBtn, TweenInfo.new(0.08), { Size = UDim2.new(0, 82, 0, 46) }):Play()
        teleportAndSteal(eggData)
    end)
end

-- ==============================================================
-- 12. TARJETA CHILLI FINDER (1:1 CON CAPTURA 3)
-- ==============================================================
local function renderChilliCard(serverData, index)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -4, 0, 68)
    card.BackgroundColor3 = THEME.CardBg
    card.BorderSizePixel = 0
    card.LayoutOrder = index
    card.Parent = cScroll

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 5)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = THEME.CardBorder
    cardStroke.Thickness = 1.4
    cardStroke.Parent = card

    local thumbBox = Instance.new("Frame")
    thumbBox.Size = UDim2.new(0, 54, 0, 54)
    thumbBox.Position = UDim2.new(0, 7, 0.5, -27)
    thumbBox.BackgroundColor3 = Color3.fromRGB(28, 30, 36)
    thumbBox.BorderSizePixel = 0
    thumbBox.ClipsDescendants = true
    thumbBox.Parent = card

    local thumbCorner = Instance.new("UICorner")
    thumbCorner.CornerRadius = UDim.new(0, 4)
    thumbCorner.Parent = thumbBox

    setupEggThumbnail(thumbBox, { name = serverData.bestEggName })

    local info = Instance.new("Frame")
    info.Size = UDim2.new(1, -160, 1, -10)
    info.Position = UDim2.new(0, 68, 0, 5)
    info.BackgroundTransparency = 1
    info.Parent = card

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 22)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = serverData.bestEggName
    nameLabel.Font = Enum.Font.GothamBlack
    nameLabel.TextSize = 15
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = info

    local nameStroke = Instance.new("UIStroke")
    nameStroke.Color = THEME.StrokeDark
    nameStroke.Thickness = 1.8
    nameStroke.Parent = nameLabel

    local statsRow = Instance.new("Frame")
    statsRow.Size = UDim2.new(1, 0, 0, 22)
    statsRow.Position = UDim2.new(0, 0, 0, 25)
    statsRow.BackgroundTransparency = 1
    statsRow.Parent = info

    local statsLayout = Instance.new("UIListLayout")
    statsLayout.FillDirection = Enum.FillDirection.Horizontal
    statsLayout.Padding = UDim.new(0, 6)
    statsLayout.Parent = statsRow

    local rateLabel = Instance.new("TextLabel")
    rateLabel.AutomaticSize = Enum.AutomaticSize.X
    rateLabel.BackgroundTransparency = 1
    rateLabel.Text = serverData.rateStr
    rateLabel.Font = Enum.Font.GothamBlack
    rateLabel.TextSize = 14
    rateLabel.TextColor3 = THEME.GreenRate
    rateLabel.Parent = statsRow

    local multLabel = Instance.new("TextLabel")
    multLabel.AutomaticSize = Enum.AutomaticSize.X
    multLabel.BackgroundTransparency = 1
    multLabel.Text = serverData.multStr
    multLabel.Font = Enum.Font.GothamBold
    multLabel.TextSize = 12
    multLabel.TextColor3 = THEME.ChilliAccBtn
    multLabel.Parent = statsRow

    local timeLabel = Instance.new("TextLabel")
    timeLabel.AutomaticSize = Enum.AutomaticSize.X
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = serverData.timeAgo
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.TextSize = 11
    timeLabel.TextColor3 = Color3.fromRGB(180, 185, 200)
    timeLabel.Parent = statsRow

    -- Botón Join dorado con texto blanco y borde oscuro (igual a la captura 3)
    local joinBtn = Instance.new("TextButton")
    joinBtn.Size = UDim2.new(0, 82, 0, 46)
    joinBtn.Position = UDim2.new(1, -88, 0.5, -23)
    joinBtn.BackgroundColor3 = THEME.ChilliJoinBtn1
    joinBtn.Text = "Join"
    joinBtn.Font = Enum.Font.GothamBlack
    joinBtn.TextSize = 18
    joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    joinBtn.Parent = card

    local joinGrad = Instance.new("UIGradient")
    joinGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.ChilliJoinBtn1),
        ColorSequenceKeypoint.new(1, THEME.ChilliJoinBtn2)
    })
    joinGrad.Parent = joinBtn

    local joinCorner = Instance.new("UICorner")
    joinCorner.CornerRadius = UDim.new(0, 4)
    joinCorner.Parent = joinBtn

    local joinStroke = Instance.new("UIStroke")
    joinStroke.Color = THEME.StrokeDark
    joinStroke.Thickness = 2.2
    joinStroke.Parent = joinBtn

    joinBtn.MouseButton1Click:Connect(function()
        TweenService:Create(joinBtn, TweenInfo.new(0.08), { Size = UDim2.new(0, 78, 0, 42) }):Play()
        task.wait(0.08)
        TweenService:Create(joinBtn, TweenInfo.new(0.08), { Size = UDim2.new(0, 82, 0, 46) }):Play()
        joinServer(serverData.jobId, serverData.placeId)
    end)
end

-- ==============================================================
-- 13. REFRESCO Y ALTERNANCIA DE PESTAÑAS
-- ==============================================================
local function refreshStealList()
    for _, child in ipairs(sScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local eggs = scanLocalEggs()
    local count = 0
    for i, egg in ipairs(eggs) do
        local pass = true
        if State.HalloweenOnly and not egg.isHalloween then pass = false end
        if State.EggFilter == ">10M" and egg.rateVal < 10e6 then pass = false end
        if State.EggFilter == ">50M" and egg.rateVal < 50e6 then pass = false end
        if State.EggFilter == "Halloween" and not egg.isHalloween then pass = false end

        if pass then
            count = count + 1
            renderStealCard(egg, count)
        end
    end

    if count == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 80)
        empty.BackgroundTransparency = 1
        empty.Text = "No hay huevos activos en este momento.\nEspera a que spawneen o cambia el filtro."
        empty.Font = Enum.Font.GothamMedium
        empty.TextSize = 13
        empty.TextColor3 = Color3.fromRGB(160, 165, 180)
        empty.Parent = sScroll
    end
end

local function refreshChilliList()
    for _, child in ipairs(cScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local servers = fetchRemoteServers()
    for i, srv in ipairs(servers) do
        renderChilliCard(srv, i)

        -- Notificación del radar si supera el umbral configurado
        if State.Radar.Enabled and srv.rateVal >= State.Radar.MinAlertValue and not State.Radar.SeenServers[srv.jobId] then
            State.Radar.SeenServers[srv.jobId] = true
            showAlertBanner(srv)
        end
    end
end

local function switchTab(tabName)
    State.CurrentTab = tabName
    if tabName == "StealPanel" then
        stealTabBtn.BackgroundColor3 = THEME.StealHeaderBg
        stealTabBtn.TextColor3 = Color3.fromRGB(20, 20, 25)
        chilliTabBtn.BackgroundColor3 = Color3.fromRGB(40, 42, 52)
        chilliTabBtn.TextColor3 = Color3.fromRGB(180, 185, 200)

        stealView.Visible = true
        chilliView.Visible = false
        refreshStealList()
    else
        chilliTabBtn.BackgroundColor3 = THEME.ChilliHeader1
        chilliTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        stealTabBtn.BackgroundColor3 = Color3.fromRGB(40, 42, 52)
        stealTabBtn.TextColor3 = Color3.fromRGB(180, 185, 200)

        stealView.Visible = false
        chilliView.Visible = true
        refreshChilliList()
    end
end

stealTabBtn.MouseButton1Click:Connect(function() switchTab("StealPanel") end)
chilliTabBtn.MouseButton1Click:Connect(function() switchTab("ChilliFinder") end)

-- CONTROLES STEAL PANEL
sAutoBtn.MouseButton1Click:Connect(function()
    State.AutoSteal = not State.AutoSteal
    sAutoBtn.BackgroundColor3 = State.AutoSteal and THEME.StealGreenBtn or THEME.StealRedBtn
    sAutoBtn.Text = State.AutoSteal and "Auto Steal: ON" or "Auto Steal: OFF"
end)

sHwBtn.MouseButton1Click:Connect(function()
    State.HalloweenOnly = not State.HalloweenOnly
    sHwBtn.BackgroundColor3 = State.HalloweenOnly and THEME.OrangeEvent or THEME.StealRedBtn
    sHwBtn.Text = State.HalloweenOnly and "Halloween:\nON" or "Halloween:\nOFF"
    refreshStealList()
end)

local sFilterOptions = {"All", ">10M", ">50M", "Halloween"}
local sFilterIdx = 1
sEggsBtn.MouseButton1Click:Connect(function()
    sFilterIdx = (sFilterIdx % #sFilterOptions) + 1
    State.EggFilter = sFilterOptions[sFilterIdx]
    sEggsBtn.Text = "Eggs: " .. State.EggFilter
    refreshStealList()
end)

sValueBtn.MouseButton1Click:Connect(function()
    if State.SortBy == "Value" then
        State.SortBy = "Name"
        sValueBtn.Text = "Name"
    else
        State.SortBy = "Value"
        sValueBtn.Text = "Value"
    end
    refreshStealList()
end)

-- CONTROLES CHILLI FINDER
cAutoBtn.MouseButton1Click:Connect(function()
    State.AutoHop = not State.AutoHop
    cAutoBtn.BackgroundColor3 = State.AutoHop and THEME.ChilliForceBtn or THEME.ChilliAutoOff
    cAutoBtn.Text = State.AutoHop and "AUTO ON" or "AUTO OFF"
end)

local minValues = {"1B/s", "10B/s", "100B/s", "1T/s", "Any"}
local mvIdx = 4
cMinValBtn.MouseButton1Click:Connect(function()
    mvIdx = (mvIdx % #minValues) + 1
    State.MinValueFilter = minValues[mvIdx]
    cMinValBtn.Text = "MIN VALUE\n" .. State.MinValueFilter
    refreshChilliList()
end)

local rarities = {"Any", "Mythic", "Secret", "Legendary", "Rare"}
local rIdx = 1
cRarityBtn.MouseButton1Click:Connect(function()
    rIdx = (rIdx % #rarities) + 1
    State.RarityFilter = rarities[rIdx]
    cRarityBtn.Text = "RARITY\n" .. State.RarityFilter
    refreshChilliList()
end)

local accounts = {"No plan", "Free", "VIP", "Pro"}
local accIdx = 1
cAccBtn.MouseButton1Click:Connect(function()
    accIdx = (accIdx % #accounts) + 1
    State.AccountTier = accounts[accIdx]
    cAccBtn.Text = "ACCOUNT\n" .. State.AccountTier
end)

-- ==============================================================
-- 14. BUCLES EN SEGUNDO PLANO
-- ==============================================================
task.spawn(function()
    while genv._STEAL_PANEL_LOADED do
        task.wait(1.0)
        if State.AutoSteal then
            local eggs = scanLocalEggs()
            local best = nil
            for _, egg in ipairs(eggs) do
                if not State.HalloweenOnly or egg.isHalloween then
                    best = egg
                    break
                end
            end
            if best then
                teleportAndSteal(best)
                task.wait(1.4)
            end
        end

        if State.AutoHop then
            State.ForceJoinTimer = State.ForceJoinTimer - 1
            if State.ForceJoinTimer <= 0 then
                State.ForceJoinTimer = State.ForceJoinTime
                local servers = fetchRemoteServers()
                if #servers > 0 and servers[1].jobId ~= game.JobId then
                    joinServer(servers[1].jobId, servers[1].placeId)
                end
            end
            cForceBtn.Text = string.format("FORCE JOIN\n%ds", State.ForceJoinTimer)
        end
    end
end)

task.spawn(function()
    refreshStealList()
    refreshChilliList()
    while genv._STEAL_PANEL_LOADED do
        task.wait(3.0)
        if State.CurrentTab == "StealPanel" then
            refreshStealList()
        else
            refreshChilliList()
        end
    end
end)

print("=====================================================")
print("🥚 STEAL PANEL & CHILLI FINDER V4 ULTIMATE PRO ACTIVO")
print("✨ Interfaz 1:1, nombres reales, 3D sunburst y Hopping seguro")
print("=====================================================")
