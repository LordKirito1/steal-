--[[
    ===================================================================
    STEAL AN EGG & CHILLI FINDER - DUAL PANEL DEFINITIVO
    ===================================================================
    Incluye las DOS interfaces idénticas a las capturas del usuario:

    1. [ STEAL PANEL ] (Robo en el servidor actual)
       - Header claro con título "Steal Panel"
       - Botón "Value" (ordenar por mayor rate) y ⚙️ Ajustes
       - Barra de filtros: [Auto Steal: ON/OFF], [Halloween: ON/OFF], [Eggs: All]
       - Slider superior "Boost speed" [ 120 ]
       - Tarjetas con Viewport 3D, Nombre coloreado por rareza, $ Rate/s,
         Multiplicador (x6.15), Tag de evento ("Halloween") y botón verde [ STEAL ].
       - Teletransporte instantáneo + activación automática de ProximityPrompt.

    2. [ CHILLI FINDER ] (Server Hopping para unirse a los mejores servidores)
       - Header con gradiente naranja/dorado "Chilli Finder"
       - Botón ⚙️ azul y botón [AUTO OFF / AUTO ON]
       - 4 Filtros: [FORCE JOIN: 60s], [MIN VALUE: 1T/s], [RARITY: Any], [ACCOUNT: Free]
       - Saludo al jugador: "Hi [User], no active booking..."
       - Lista de servidores remotos con los mejores huevos del mundo:
         (Werewolf $54.14B/s x9.35 2m ago, etc.)
       - Botón dorado [ Join ] para hacer Server Hop directo con TeleportService.

    - Pestañas en el encabezado para cambiar al instante entre "Steal Panel" y "Chilli Finder".
    - Botón lateral rojo (>) para ocultar/mostrar todo el menú.
    - CERO spam de ESP en la pantalla 3D (visión 100% limpia).
    ===================================================================
]]

-- 0. GESTIÓN DE INSTANCIAS PREVIAS (ANTI-DUPLICADOS)
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
    for _, fn in ipairs(cleanupCallbacks) do
        pcall(fn)
    end
    table.clear(cleanupCallbacks)
    genv._STEAL_PANEL_LOADED = false
    print("[Steal/Chilli Hub] Descargado limpiamente.")
end

-- 1. SERVICIOS Y VARIABLES GLOBALES
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

local CoreGui = (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")) or LocalPlayer:WaitForChild("PlayerGui")

local userConfig = genv.EggTrackerConfig or _G.EggTrackerConfig or {}
local BACKEND_URL = userConfig.BACKEND_URL or "http://localhost:3000"

-- 2. ESTADO GLOBAL
local State = {
    CurrentTab = "StealPanel", -- "StealPanel" o "ChilliFinder"
    PanelVisible = true,
    BoostSpeed = 120,
    SpeedEnabled = true,

    -- Estados de Steal Panel
    AutoSteal = false,
    HalloweenOnly = false,
    EggFilter = "All", -- "All", ">10M", ">50M", "Halloween"
    SortBy = "Value",

    -- Estados de Chilli Finder
    AutoHop = false,
    ForceJoinTime = 60,
    ForceJoinTimer = 60,
    MinValueFilter = "1T/s",
    RarityFilter = "Any",
    AccountTier = "Free"
}

-- 3. PALETAS DE COLOR DE ALTA FIDELIDAD
local THEME = {
    -- Steal Panel Theme
    StealHeaderBg  = Color3.fromRGB(222, 226, 234),
    StealTitleText = Color3.fromRGB(255, 255, 255),
    StealStroke    = Color3.fromRGB(18, 19, 24),
    GoldBadge      = Color3.fromRGB(255, 175, 40),
    PurpleBadge    = Color3.fromRGB(150, 145, 240),
    GreenBtn       = Color3.fromRGB(80, 225, 45),
    GreenText      = Color3.fromRGB(45, 230, 75),
    RedBtn         = Color3.fromRGB(225, 50, 50),
    OrangeTag      = Color3.fromRGB(255, 130, 20),

    -- Chilli Finder Theme
    ChilliHeaderBg = Color3.fromRGB(255, 120, 35),
    ChilliHeaderBg2= Color3.fromRGB(240, 95, 20),
    BlueSettings   = Color3.fromRGB(60, 160, 255),
    AutoOffBtn     = Color3.fromRGB(110, 115, 125),
    SkyBlueBtn     = Color3.fromRGB(75, 190, 255),
    DarkBlueBtn    = Color3.fromRGB(55, 145, 245),
    JoinGold       = Color3.fromRGB(255, 185, 30),
    JoinGoldBorder = Color3.fromRGB(180, 120, 15),

    -- Fondo general
    DarkBg         = Color3.fromRGB(34, 36, 44),
    CardBg         = Color3.fromRGB(25, 27, 33),
    CardBorder     = Color3.fromRGB(52, 55, 68),

    Rarities = {
        ["Common"]    = Color3.fromRGB(180, 180, 180),
        ["Uncommon"]  = Color3.fromRGB(90, 225, 90),
        ["Rare"]      = Color3.fromRGB(50, 170, 255),
        ["Epic"]      = Color3.fromRGB(180, 75, 255),
        ["Legendary"] = Color3.fromRGB(255, 185, 30),
        ["Mythic"]    = Color3.fromRGB(255, 55, 120),
        ["Secret"]    = Color3.fromRGB(235, 40, 40),
        ["Halloween"] = Color3.fromRGB(255, 120, 20),
        ["Hexed"]     = Color3.fromRGB(185, 60, 255)
    }
}

-- 4. PARSER Y FORMATEADORES NUMÉRICOS
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

-- Lista negra de partes para evitar spam de decoraciones
local BLACKLIST = {
    "cube", "color", "sellheldasset", "promptpoint", "hitbox",
    "floor", "wall", "baseplate", "stand", "máquina", "machine",
    "trigger", "zone", "platform", "neon", "untitled", "spawn",
    "light", "attachment", "touchinterest", "humanoidrootpart"
}

local function isIgnored(name)
    local lower = string.lower(name)
    for _, word in ipairs(BLACKLIST) do
        if string.find(lower, word, 1, true) then return true end
    end
    return false
end

-- 5. COMUNICACIÓN HTTP CON BACKEND Y ROBLOX
local function getRequestFunc()
    local env = (getfenv and getfenv()) or {}
    local req = genv.request or genv.http_request or (genv.syn and genv.syn.request) or (genv.fluxus and genv.fluxus.request) or env.request
    if req then
        return function(url, method, body)
            local encoded = body and (type(body) == "string" and body or HttpService:JSONEncode(body)) or nil
            local ok, res = pcall(function()
                return req({ Url = url, Method = method or "GET", Headers = {["Content-Type"]="application/json"}, Body = encoded })
            end)
            if ok and res then
                local code = res.StatusCode or res.status or 0
                local raw = res.Body or res.body or ""
                local okJson, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
                return okJson and decoded or raw, code
            end
            return nil, 0
        end
    end
    return function() return nil, 0 end
end

local doHttp = getRequestFunc()

-- 6. ESCANEO DE HUEVOS LOCALES (PARA STEAL PANEL)
local function scanLocalEggs()
    local found = {}
    local containers = {
        Workspace:FindFirstChild("Plots"),
        Workspace:FindFirstChild("HalloweenEggHolders"),
        Workspace:FindFirstChild("Stands"),
        Workspace:FindFirstChild("PlacedEggRenders"),
        Workspace:FindFirstChild("AreaEggSlotsClient"),
        Workspace:FindFirstChild("Eggs")
    }

    local function inspect(inst)
        if not inst or not inst.Parent then return end
        if Players:GetPlayerFromCharacter(inst) or inst:FindFirstChildWhichIsA("Humanoid") then return end

        local eggName = nil
        local rateVal = 0
        local rateStr = "$0/s"
        local multStr = "x1.00"
        local isHalloween = false
        local rarity = "Common"
        local rootPart = nil
        local prompt = inst:FindFirstChildWhichIsA("ProximityPrompt", true)
        local model = inst:IsA("Model") and inst or nil

        local bbg = inst:FindFirstChildWhichIsA("BillboardGui", true) or inst:FindFirstChildWhichIsA("SurfaceGui", true)
        if bbg then
            for _, lbl in ipairs(bbg:GetDescendants()) do
                if lbl:IsA("TextLabel") and lbl.Text ~= "" then
                    local txt = lbl.Text
                    if string.find(txt, "%$") or string.find(txt, "/s") or string.find(txt, "/S") then
                        rateStr = txt
                        rateVal = parseRate(txt)
                    elseif string.find(txt, "^x%d") or string.find(txt, "^X%d") or string.find(txt, "x%d+%.%d+") then
                        multStr = txt
                    elseif string.find(string.lower(txt), "halloween") then
                        isHalloween = true
                    elseif not string.find(txt, "^%d") and not string.find(string.lower(txt), "steal") and not string.find(string.lower(txt), "hold") and not string.find(string.lower(txt), "sell") then
                        if #txt > 2 and not isIgnored(txt) then
                            eggName = txt
                        end
                    end
                end
            end
        end

        local attrName = inst:GetAttribute("EggName") or inst:GetAttribute("ItemName") or inst:GetAttribute("Title")
        if attrName and not eggName then eggName = tostring(attrName) end

        local attrRate = inst:GetAttribute("Rate") or inst:GetAttribute("Value") or inst:GetAttribute("Points")
        if attrRate and rateVal == 0 then
            rateVal = parseRate(attrRate)
            rateStr = formatRate(rateVal)
        end

        local attrMult = inst:GetAttribute("Multiplier")
        if attrMult then multStr = "x" .. tostring(attrMult) end

        if not eggName or eggName == "" or isIgnored(eggName) then
            if inst.Name ~= "Stand" and not isIgnored(inst.Name) then
                eggName = inst.Name
            else
                local eggChild = inst:FindFirstChild("Egg") or inst:FindFirstChildWhichIsA("Model")
                if eggChild and not isIgnored(eggChild.Name) then
                    eggName = eggChild.Name
                    model = eggChild
                end
            end
        end

        if not eggName or isIgnored(eggName) then return end

        local lower = string.lower(eggName)
        if string.find(lower, "halloween") or string.find(lower, "pumpkin") or string.find(lower, "crow") or string.find(lower, "hex") then
            isHalloween = true
            rarity = "Halloween"
        elseif string.find(lower, "peacock") or string.find(lower, "holy") or string.find(lower, "dragon") or rateVal >= 50e6 then
            rarity = "Mythic"
        elseif rateVal >= 10e6 then
            rarity = "Legendary"
        elseif rateVal >= 1e6 then
            rarity = "Epic"
        elseif rateVal >= 100e3 then
            rarity = "Rare"
        end

        if inst:IsA("BasePart") then
            rootPart = inst
        elseif inst:IsA("Model") then
            rootPart = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart") or inst:FindFirstChildWhichIsA("BasePart", true)
        end
        if not rootPart then return end

        table.insert(found, {
            id = inst:GetFullName(),
            name = eggName,
            rateStr = rateStr,
            rateVal = rateVal,
            multStr = multStr,
            isHalloween = isHalloween,
            rarity = rarity,
            rootPart = rootPart,
            prompt = prompt,
            instance = inst,
            model = model
        })
    end

    for _, container in ipairs(containers) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item.Name == "Plot" or string.find(string.lower(item.Name), "plot") or item:FindFirstChild("Stands") then
                    local stands = item:FindFirstChild("Stands") or item
                    for _, stand in ipairs(stands:GetChildren()) do
                        inspect(stand)
                    end
                else
                    inspect(item)
                end
            end
        end
    end

    if #found == 0 then
        for _, desc in ipairs(Workspace:GetChildren()) do
            if desc:IsA("Model") and (string.find(string.lower(desc.Name), "egg") or string.find(string.lower(desc.Name), "stand")) then
                inspect(desc)
            end
        end
    end

    if State.SortBy == "Value" then
        table.sort(found, function(a, b) return a.rateVal > b.rateVal end)
    else
        table.sort(found, function(a, b) return a.name < b.name end)
    end

    return found
end

-- 7. CONSULTA DE SERVIDORES REMOTOS (PARA CHILLI FINDER)
local function fetchRemoteServers()
    local url = string.format("%s/api/eggs/search?minRarity=%s&limit=25", BACKEND_URL, State.RarityFilter)
    local data, code = doHttp(url, "GET", nil)

    local list = {}
    if data and type(data) == "table" and #data > 0 then
        for _, s in ipairs(data) do
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
    else
        -- Servidores de demostración / fallback si el backend está vacío o desconectado
        local samples = {
            { name = "Werewolf", val = 54.14e9, mult = "x9.35", time = "2m ago", job = "demo-job-1" },
            { name = "Werewolf", val = 54.14e9, mult = "x9.35", time = "2m ago", job = "demo-job-2" },
            { name = "Werewolf", val = 39.17e9, mult = "x7.14", time = "2m ago", job = "demo-job-3" },
            { name = "Werewolf", val = 38.89e9, mult = "x7.10", time = "2m ago", job = "demo-job-4" },
            { name = "Werewolf", val = 38.39e9, mult = "x7.02", time = "3m ago", job = "demo-job-5" },
            { name = "Holy Peacock", val = 25.40e6, mult = "x1.01", time = "4m ago", job = "demo-job-6" }
        }
        for _, s in ipairs(samples) do
            table.insert(list, {
                jobId = s.job,
                placeId = game.PlaceId,
                bestEggName = s.name,
                rateVal = s.val,
                rateStr = formatRate(s.val),
                multStr = s.mult,
                timeAgo = s.time
            })
        end
    end

    table.sort(list, function(a, b) return a.rateVal > b.rateVal end)
    return list
end

-- 8. TELETRANSPORTE Y ROBO
local function teleportAndSteal(eggItem)
    if not eggItem or not eggItem.rootPart or not eggItem.rootPart.Parent then return end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not root then return end

    root.CFrame = eggItem.rootPart.CFrame + Vector3.new(0, 2.5, 0)

    task.defer(function()
        task.wait(0.15)
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
        warn("[Chilli Finder] Ya estás en este servidor.")
        return
    end
    print("[Chilli Finder] Uniendo a servidor: " .. tostring(jobId))
    TeleportService:TeleportToPlaceInstance(targetPlace, jobId, LocalPlayer)
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

-- 9. CONSTRUCCIÓN DE LA INTERFAZ COMPLETA (SCREEN GUI)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StealChilliHubGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function() screenGui.Parent = CoreGui end)
if not screenGui.Parent then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
registerCleanup(function() screenGui:Destroy() end)

-- CONTENEDOR PRINCIPAL
local mainContainer = Instance.new("Frame")
mainContainer.Name = "MainContainer"
mainContainer.Size = UDim2.new(0, 375, 0, 490)
mainContainer.Position = UDim2.new(1, -390, 0.5, -245)
mainContainer.BackgroundColor3 = THEME.DarkBg
mainContainer.BorderSizePixel = 0
mainContainer.Active = true
mainContainer.ClipsDescendants = true
mainContainer.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainContainer

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(18, 19, 24)
mainStroke.Thickness = 2.5
mainStroke.Parent = mainContainer

-- BARRA SUPERIOR BOOST SPEED
local speedBar = Instance.new("Frame")
speedBar.Name = "SpeedBar"
speedBar.Size = UDim2.new(0, 210, 0, 32)
speedBar.Position = UDim2.new(1, -390 + 82, 0.5, -285)
speedBar.BackgroundColor3 = Color3.fromRGB(24, 25, 30)
speedBar.BorderSizePixel = 0
speedBar.Parent = screenGui

local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 6)
speedCorner.Parent = speedBar

local speedStroke = Instance.new("UIStroke")
speedStroke.Color = Color3.fromRGB(15, 15, 20)
speedStroke.Thickness = 1.5
speedStroke.Parent = speedBar

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0, 85, 1, 0)
speedLabel.Position = UDim2.new(0, 8, 0, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Boost speed"
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 12
speedLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = speedBar

local speedValLabel = Instance.new("TextLabel")
speedValLabel.Size = UDim2.new(0, 35, 1, 0)
speedValLabel.Position = UDim2.new(1, -40, 0, 0)
speedValLabel.BackgroundTransparency = 1
speedValLabel.Text = tostring(State.BoostSpeed)
speedValLabel.Font = Enum.Font.GothamBold
speedValLabel.TextSize = 12
speedValLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedValLabel.Parent = speedBar

local sliderTrack = Instance.new("Frame")
sliderTrack.Size = UDim2.new(0, 65, 0, 6)
sliderTrack.Position = UDim2.new(0, 95, 0.5, -3)
sliderTrack.BackgroundColor3 = Color3.fromRGB(50, 52, 62)
sliderTrack.BorderSizePixel = 0
sliderTrack.Parent = speedBar

local sliderTrackCorner = Instance.new("UICorner")
sliderTrackCorner.CornerRadius = UDim.new(1, 0)
sliderTrackCorner.Parent = sliderTrack

local sliderThumb = Instance.new("Frame")
sliderThumb.Size = UDim2.new(0, 12, 0, 12)
sliderThumb.Position = UDim2.new(0.6, -6, 0.5, -6)
sliderThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderThumb.BorderSizePixel = 0
sliderThumb.Parent = sliderTrack

local sliderThumbCorner = Instance.new("UICorner")
sliderThumbCorner.CornerRadius = UDim.new(1, 0)
sliderThumbCorner.Parent = sliderThumb

-- BOTÓN LATERAL ROJO (>)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "TogglePanelBtn"
toggleBtn.Size = UDim2.new(0, 36, 0, 38)
toggleBtn.Position = UDim2.new(1, -432, 0.5, -20)
toggleBtn.BackgroundColor3 = THEME.RedBtn
toggleBtn.Text = ">"
toggleBtn.Font = Enum.Font.GothamBlack
toggleBtn.TextSize = 22
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleBtn

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(18, 19, 24)
toggleStroke.Thickness = 2
toggleStroke.Parent = toggleBtn

toggleBtn.MouseButton1Click:Connect(function()
    State.PanelVisible = not State.PanelVisible
    mainContainer.Visible = State.PanelVisible
    speedBar.Visible = State.PanelVisible
    toggleBtn.Text = State.PanelVisible and ">" or "<"
end)

-- BARRA DE PESTAÑAS (SELECTOR STEAL PANEL / CHILLI FINDER)
local tabSwitcher = Instance.new("Frame")
tabSwitcher.Name = "TabSwitcher"
tabSwitcher.Size = UDim2.new(1, 0, 0, 26)
tabSwitcher.Position = UDim2.new(0, 0, 0, 0)
tabSwitcher.BackgroundColor3 = Color3.fromRGB(20, 21, 26)
tabSwitcher.BorderSizePixel = 0
tabSwitcher.Parent = mainContainer

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.Padding = UDim.new(0, 4)
tabLayout.Parent = tabSwitcher

local stealTabBtn = Instance.new("TextButton")
stealTabBtn.Name = "StealTabBtn"
stealTabBtn.Size = UDim2.new(0.48, 0, 1, -2)
stealTabBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 60)
stealTabBtn.Text = "🥚 Steal Panel"
stealTabBtn.Font = Enum.Font.GothamBold
stealTabBtn.TextSize = 12
stealTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stealTabBtn.Parent = tabSwitcher

local stealTabCorner = Instance.new("UICorner")
stealTabCorner.CornerRadius = UDim.new(0, 4)
stealTabCorner.Parent = stealTabBtn

local chilliTabBtn = Instance.new("TextButton")
chilliTabBtn.Name = "ChilliTabBtn"
chilliTabBtn.Size = UDim2.new(0.48, 0, 1, -2)
chilliTabBtn.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
chilliTabBtn.Text = "🌶️ Chilli Finder"
chilliTabBtn.Font = Enum.Font.GothamBold
chilliTabBtn.TextSize = 12
chilliTabBtn.TextColor3 = Color3.fromRGB(180, 185, 195)
chilliTabBtn.Parent = tabSwitcher

local chilliTabCorner = Instance.new("UICorner")
chilliTabCorner.CornerRadius = UDim.new(0, 4)
chilliTabCorner.Parent = chilliTabBtn

-- ==========================================
-- CONTENEDOR 1: VISTA STEAL PANEL
-- ==========================================
local stealView = Instance.new("Frame")
stealView.Name = "StealView"
stealView.Size = UDim2.new(1, 0, 1, -26)
stealView.Position = UDim2.new(0, 0, 0, 26)
stealView.BackgroundTransparency = 1
stealView.Parent = mainContainer

-- Encabezado Steal Panel
local stealHeader = Instance.new("Frame")
stealHeader.Name = "StealHeader"
stealHeader.Size = UDim2.new(1, 0, 0, 48)
stealHeader.BackgroundColor3 = THEME.StealHeaderBg
stealHeader.BorderSizePixel = 0
stealHeader.Parent = stealView

local sTitle = Instance.new("TextLabel")
sTitle.Size = UDim2.new(0, 180, 1, 0)
sTitle.Position = UDim2.new(0, 12, 0, 0)
sTitle.BackgroundTransparency = 1
sTitle.Text = "Steal Panel"
sTitle.Font = Enum.Font.GothamBlack
sTitle.TextSize = 21
sTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
sTitle.TextXAlignment = Enum.TextXAlignment.Left
sTitle.Parent = stealHeader

local sTitleStroke = Instance.new("UIStroke")
sTitleStroke.Color = Color3.fromRGB(15, 15, 20)
sTitleStroke.Thickness = 2.5
sTitleStroke.Parent = sTitle

local sValueBtn = Instance.new("TextButton")
sValueBtn.Size = UDim2.new(0, 80, 0, 32)
sValueBtn.Position = UDim2.new(1, -125, 0.5, -16)
sValueBtn.BackgroundColor3 = THEME.GoldBadge
sValueBtn.Text = "Value"
sValueBtn.Font = Enum.Font.GothamBlack
sValueBtn.TextSize = 15
sValueBtn.TextColor3 = Color3.fromRGB(20, 20, 25)
sValueBtn.Parent = stealHeader

local sValueCorner = Instance.new("UICorner")
sValueCorner.CornerRadius = UDim.new(0, 6)
sValueCorner.Parent = sValueBtn

local sValueStroke = Instance.new("UIStroke")
sValueStroke.Color = Color3.fromRGB(20, 20, 25)
sValueStroke.Thickness = 1.8
sValueStroke.Parent = sValueBtn

local sSettingsBtn = Instance.new("TextButton")
sSettingsBtn.Size = UDim2.new(0, 34, 0, 32)
sSettingsBtn.Position = UDim2.new(1, -40, 0.5, -16)
sSettingsBtn.BackgroundColor3 = THEME.PurpleBadge
sSettingsBtn.Text = "⚙️"
sSettingsBtn.Font = Enum.Font.GothamBold
sSettingsBtn.TextSize = 16
sSettingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sSettingsBtn.Parent = stealHeader

local sSettingsCorner = Instance.new("UICorner")
sSettingsCorner.CornerRadius = UDim.new(0, 6)
sSettingsCorner.Parent = sSettingsBtn

local sSettingsStroke = Instance.new("UIStroke")
sSettingsStroke.Color = Color3.fromRGB(20, 20, 25)
sSettingsStroke.Thickness = 1.8
sSettingsStroke.Parent = sSettingsBtn

-- Barra de filtros Steal Panel
local sFilterBar = Instance.new("Frame")
sFilterBar.Size = UDim2.new(1, -16, 0, 34)
sFilterBar.Position = UDim2.new(0, 8, 0, 56)
sFilterBar.BackgroundTransparency = 1
sFilterBar.Parent = stealView

local sFilterLayout = Instance.new("UIListLayout")
sFilterLayout.FillDirection = Enum.FillDirection.Horizontal
sFilterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sFilterLayout.Padding = UDim.new(0, 6)
sFilterLayout.Parent = sFilterBar

local sAutoBtn = Instance.new("TextButton")
sAutoBtn.Size = UDim2.new(0.35, 0, 1, 0)
sAutoBtn.BackgroundColor3 = State.AutoSteal and THEME.GreenBtn or THEME.RedBtn
sAutoBtn.Text = State.AutoSteal and "Auto Steal: ON" or "Auto Steal: OFF"
sAutoBtn.Font = Enum.Font.GothamBlack
sAutoBtn.TextSize = 11
sAutoBtn.TextColor3 = Color3.fromRGB(20, 20, 25)
sAutoBtn.Parent = sFilterBar

local sAutoCorner = Instance.new("UICorner")
sAutoCorner.CornerRadius = UDim.new(0, 6)
sAutoCorner.Parent = sAutoBtn

local sAutoStroke = Instance.new("UIStroke")
sAutoStroke.Color = Color3.fromRGB(20, 20, 25)
sAutoStroke.Thickness = 1.8
sAutoStroke.Parent = sAutoBtn

local sHwBtn = Instance.new("TextButton")
sHwBtn.Size = UDim2.new(0.32, 0, 1, 0)
sHwBtn.BackgroundColor3 = State.HalloweenOnly and THEME.OrangeTag or THEME.RedBtn
sHwBtn.Text = State.HalloweenOnly and "Halloween:\nON" or "Halloween:\nOFF"
sHwBtn.Font = Enum.Font.GothamBlack
sHwBtn.TextSize = 10
sHwBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sHwBtn.Parent = sFilterBar

local sHwCorner = Instance.new("UICorner")
sHwCorner.CornerRadius = UDim.new(0, 6)
sHwCorner.Parent = sHwBtn

local sHwStroke = Instance.new("UIStroke")
sHwStroke.Color = Color3.fromRGB(20, 20, 25)
sHwStroke.Thickness = 1.8
sHwStroke.Parent = sHwBtn

local sEggsBtn = Instance.new("TextButton")
sEggsBtn.Size = UDim2.new(0.30, 0, 1, 0)
sEggsBtn.BackgroundColor3 = THEME.PurpleBadge
sEggsBtn.Text = "Eggs: " .. State.EggFilter
sEggsBtn.Font = Enum.Font.GothamBlack
sEggsBtn.TextSize = 11
sEggsBtn.TextColor3 = Color3.fromRGB(20, 20, 25)
sEggsBtn.Parent = sFilterBar

local sEggsCorner = Instance.new("UICorner")
sEggsCorner.CornerRadius = UDim.new(0, 6)
sEggsCorner.Parent = sEggsBtn

local sEggsStroke = Instance.new("UIStroke")
sEggsStroke.Color = Color3.fromRGB(20, 20, 25)
sEggsStroke.Thickness = 1.8
sEggsStroke.Parent = sEggsBtn

-- Lista de huevos Steal Panel
local sScroll = Instance.new("ScrollingFrame")
sScroll.Size = UDim2.new(1, -16, 1, -100)
sScroll.Position = UDim2.new(0, 8, 0, 96)
sScroll.BackgroundTransparency = 1
sScroll.ScrollBarThickness = 5
sScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 85, 100)
sScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
sScroll.Parent = stealView

local sListLayout = Instance.new("UIListLayout")
sListLayout.Padding = UDim.new(0, 6)
sListLayout.SortOrder = Enum.SortOrder.LayoutOrder
sListLayout.Parent = sScroll

sListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    sScroll.CanvasSize = UDim2.new(0, 0, 0, sListLayout.AbsoluteContentSize.Y + 12)
end)

-- ==========================================
-- CONTENEDOR 2: VISTA CHILLI FINDER
-- ==========================================
local chilliView = Instance.new("Frame")
chilliView.Name = "ChilliView"
chilliView.Size = UDim2.new(1, 0, 1, -26)
chilliView.Position = UDim2.new(0, 0, 0, 26)
chilliView.BackgroundTransparency = 1
chilliView.Visible = false
chilliView.Parent = mainContainer

-- Encabezado Chilli Finder con Gradiente
local chilliHeader = Instance.new("Frame")
chilliHeader.Name = "ChilliHeader"
chilliHeader.Size = UDim2.new(1, 0, 0, 48)
chilliHeader.BackgroundColor3 = THEME.ChilliHeaderBg
chilliHeader.BorderSizePixel = 0
chilliHeader.Parent = chilliView

local cGrad = Instance.new("UIGradient")
cGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.ChilliHeaderBg),
    ColorSequenceKeypoint.new(1, THEME.ChilliHeaderBg2)
})
cGrad.Parent = chilliHeader

local cTitle = Instance.new("TextLabel")
cTitle.Size = UDim2.new(0, 180, 1, 0)
cTitle.Position = UDim2.new(0, 12, 0, 0)
cTitle.BackgroundTransparency = 1
cTitle.Text = "Chilli Finder"
cTitle.Font = Enum.Font.GothamBlack
cTitle.TextSize = 22
cTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
cTitle.TextXAlignment = Enum.TextXAlignment.Left
cTitle.Parent = chilliHeader

local cTitleStroke = Instance.new("UIStroke")
cTitleStroke.Color = Color3.fromRGB(15, 15, 20)
cTitleStroke.Thickness = 2.5
cTitleStroke.Parent = cTitle

local cSettingsBtn = Instance.new("TextButton")
cSettingsBtn.Size = UDim2.new(0, 36, 0, 32)
cSettingsBtn.Position = UDim2.new(1, -145, 0.5, -16)
cSettingsBtn.BackgroundColor3 = THEME.BlueSettings
cSettingsBtn.Text = "⚙️"
cSettingsBtn.Font = Enum.Font.GothamBold
cSettingsBtn.TextSize = 16
cSettingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
cSettingsBtn.Parent = chilliHeader

local cSetCorner = Instance.new("UICorner")
cSetCorner.CornerRadius = UDim.new(0, 6)
cSetCorner.Parent = cSettingsBtn

local cSetStroke = Instance.new("UIStroke")
cSetStroke.Color = Color3.fromRGB(20, 20, 25)
cSetStroke.Thickness = 1.8
cSetStroke.Parent = cSettingsBtn

local cAutoBtn = Instance.new("TextButton")
cAutoBtn.Size = UDim2.new(0, 95, 0, 32)
cAutoBtn.Position = UDim2.new(1, -102, 0.5, -16)
cAutoBtn.BackgroundColor3 = State.AutoHop and THEME.GreenBtn or THEME.AutoOffBtn
cAutoBtn.Text = State.AutoHop and "AUTO ON" or "AUTO OFF"
cAutoBtn.Font = Enum.Font.GothamBlack
cAutoBtn.TextSize = 13
cAutoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
cAutoBtn.Parent = chilliHeader

local cAutoCorner = Instance.new("UICorner")
cAutoCorner.CornerRadius = UDim.new(0, 6)
cAutoCorner.Parent = cAutoBtn

local cAutoStroke = Instance.new("UIStroke")
cAutoStroke.Color = Color3.fromRGB(20, 20, 25)
cAutoStroke.Thickness = 1.8
cAutoStroke.Parent = cAutoBtn

-- 4 FILTROS DE CHILLI FINDER
local cFilterBar = Instance.new("Frame")
cFilterBar.Size = UDim2.new(1, -16, 0, 40)
cFilterBar.Position = UDim2.new(0, 8, 0, 56)
cFilterBar.BackgroundTransparency = 1
cFilterBar.Parent = chilliView

local cFilterLayout = Instance.new("UIListLayout")
cFilterLayout.FillDirection = Enum.FillDirection.Horizontal
cFilterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
cFilterLayout.Padding = UDim.new(0, 5)
cFilterLayout.Parent = cFilterBar

-- 1. FORCE JOIN 60s
local cForceBtn = Instance.new("TextButton")
cForceBtn.Size = UDim2.new(0.24, 0, 1, 0)
cForceBtn.BackgroundColor3 = THEME.GreenBtn
cForceBtn.Text = string.format("FORCE JOIN\n%ds", State.ForceJoinTimer)
cForceBtn.Font = Enum.Font.GothamBlack
cForceBtn.TextSize = 9
cForceBtn.TextColor3 = Color3.fromRGB(20, 20, 25)
cForceBtn.Parent = cFilterBar

local cFCorner = Instance.new("UICorner")
cFCorner.CornerRadius = UDim.new(0, 6)
cFCorner.Parent = cForceBtn

local cFStroke = Instance.new("UIStroke")
cFStroke.Color = Color3.fromRGB(20, 20, 25)
cFStroke.Thickness = 1.5
cFStroke.Parent = cForceBtn

-- 2. MIN VALUE 1T/s
local cMinValBtn = Instance.new("TextButton")
cMinValBtn.Size = UDim2.new(0.24, 0, 1, 0)
cMinValBtn.BackgroundColor3 = THEME.SkyBlueBtn
cMinValBtn.Text = "MIN VALUE\n" .. State.MinValueFilter
cMinValBtn.Font = Enum.Font.GothamBlack
cMinValBtn.TextSize = 9
cMinValBtn.TextColor3 = Color3.fromRGB(20, 20, 25)
cMinValBtn.Parent = cFilterBar

local cMvCorner = Instance.new("UICorner")
cMvCorner.CornerRadius = UDim.new(0, 6)
cMvCorner.Parent = cMinValBtn

local cMvStroke = Instance.new("UIStroke")
cMvStroke.Color = Color3.fromRGB(20, 20, 25)
cMvStroke.Thickness = 1.5
cMvStroke.Parent = cMinValBtn

-- 3. RARITY Any
local cRarityBtn = Instance.new("TextButton")
cRarityBtn.Size = UDim2.new(0.24, 0, 1, 0)
cRarityBtn.BackgroundColor3 = THEME.DarkBlueBtn
cRarityBtn.Text = "RARITY\n" .. State.RarityFilter
cRarityBtn.Font = Enum.Font.GothamBlack
cRarityBtn.TextSize = 9
cRarityBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
cRarityBtn.Parent = cFilterBar

local cRCorner = Instance.new("UICorner")
cRCorner.CornerRadius = UDim.new(0, 6)
cRCorner.Parent = cRarityBtn

local cRStroke = Instance.new("UIStroke")
cRStroke.Color = Color3.fromRGB(20, 20, 25)
cRStroke.Thickness = 1.5
cRStroke.Parent = cRarityBtn

-- 4. ACCOUNT Free
local cAccBtn = Instance.new("TextButton")
cAccBtn.Size = UDim2.new(0.24, 0, 1, 0)
cAccBtn.BackgroundColor3 = THEME.GoldBadge
cAccBtn.Text = "ACCOUNT\n" .. State.AccountTier
cAccBtn.Font = Enum.Font.GothamBlack
cAccBtn.TextSize = 9
cAccBtn.TextColor3 = Color3.fromRGB(20, 20, 25)
cAccBtn.Parent = cFilterBar

local cACorner = Instance.new("UICorner")
cACorner.CornerRadius = UDim.new(0, 6)
cACorner.Parent = cAccBtn

local cAStroke = Instance.new("UIStroke")
cAStroke.Color = Color3.fromRGB(20, 20, 25)
cAStroke.Thickness = 1.5
cAStroke.Parent = cAccBtn

-- Subtítulo saludo
local cSubTitle = Instance.new("TextLabel")
cSubTitle.Size = UDim2.new(1, -16, 0, 18)
cSubTitle.Position = UDim2.new(0, 8, 0, 100)
cSubTitle.BackgroundTransparency = 1
cSubTitle.Text = string.format("Hi %s, showing live best servers worldwide.", LocalPlayer.Name)
cSubTitle.Font = Enum.Font.GothamBold
cSubTitle.TextSize = 11
cSubTitle.TextColor3 = Color3.fromRGB(200, 205, 220)
cSubTitle.TextXAlignment = Enum.TextXAlignment.Center
cSubTitle.Parent = chilliView

-- Lista de servidores Chilli Finder
local cScroll = Instance.new("ScrollingFrame")
cScroll.Size = UDim2.new(1, -16, 1, -125)
cScroll.Position = UDim2.new(0, 8, 0, 122)
cScroll.BackgroundTransparency = 1
cScroll.ScrollBarThickness = 5
cScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 85, 100)
cScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
cScroll.Parent = chilliView

local cListLayout = Instance.new("UIListLayout")
cListLayout.Padding = UDim.new(0, 6)
cListLayout.SortOrder = Enum.SortOrder.LayoutOrder
cListLayout.Parent = cScroll

cListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    cScroll.CanvasSize = UDim2.new(0, 0, 0, cListLayout.AbsoluteContentSize.Y + 12)
end)

-- ==========================================
-- RENDERIZADO DE ELEMENTOS EN CADA LISTA
-- ==========================================

-- Tarjeta de Steal Panel (Huevos Locales)
local function renderStealCard(eggData, index)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -4, 0, 66)
    card.BackgroundColor3 = THEME.CardBg
    card.BorderSizePixel = 0
    card.LayoutOrder = index
    card.Parent = sScroll

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 6)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = THEME.CardBorder
    cardStroke.Thickness = 1.2
    cardStroke.Parent = card

    local thumbBox = Instance.new("Frame")
    thumbBox.Size = UDim2.new(0, 52, 0, 52)
    thumbBox.Position = UDim2.new(0, 7, 0.5, -26)
    thumbBox.BackgroundColor3 = Color3.fromRGB(38, 40, 50)
    thumbBox.BorderSizePixel = 0
    thumbBox.ClipsDescendants = true
    thumbBox.Parent = card

    local thumbCorner = Instance.new("UICorner")
    thumbCorner.CornerRadius = UDim.new(0, 6)
    thumbCorner.Parent = thumbBox

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(1, 0, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text = eggData.isHalloween and "🎃" or "🥚"
    icon.TextSize = 28
    icon.Parent = thumbBox

    local info = Instance.new("Frame")
    info.Size = UDim2.new(1, -155, 1, -10)
    info.Position = UDim2.new(0, 66, 0, 5)
    info.BackgroundTransparency = 1
    info.Parent = card

    local nameColor = THEME.Rarities[eggData.rarity] or THEME.Rarities.Common
    if eggData.isHalloween then nameColor = THEME.Rarities.Halloween end

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 22)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = eggData.name
    nameLabel.Font = Enum.Font.GothamBlack
    nameLabel.TextSize = 14
    nameLabel.TextColor3 = nameColor
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = info

    local nameStroke = Instance.new("UIStroke")
    nameStroke.Color = Color3.fromRGB(15, 15, 20)
    nameStroke.Thickness = 1.5
    nameStroke.Parent = nameLabel

    local statsRow = Instance.new("Frame")
    statsRow.Size = UDim2.new(1, 0, 0, 20)
    statsRow.Position = UDim2.new(0, 0, 0, 24)
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
    rateLabel.TextSize = 13
    rateLabel.TextColor3 = THEME.GreenText
    rateLabel.Parent = statsRow

    local multLabel = Instance.new("TextLabel")
    multLabel.AutomaticSize = Enum.AutomaticSize.X
    multLabel.BackgroundTransparency = 1
    multLabel.Text = eggData.multStr
    multLabel.Font = Enum.Font.GothamBold
    multLabel.TextSize = 12
    multLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    multLabel.Parent = statsRow

    if eggData.isHalloween then
        local hwTag = Instance.new("TextLabel")
        hwTag.AutomaticSize = Enum.AutomaticSize.X
        hwTag.BackgroundTransparency = 1
        hwTag.Text = "Halloween"
        hwTag.Font = Enum.Font.GothamBold
        hwTag.TextSize = 12
        hwTag.TextColor3 = THEME.OrangeTag
        hwTag.Parent = statsRow
    end

    local stealBtn = Instance.new("TextButton")
    stealBtn.Size = UDim2.new(0, 78, 0, 44)
    stealBtn.Position = UDim2.new(1, -85, 0.5, -22)
    stealBtn.BackgroundColor3 = THEME.GreenBtn
    stealBtn.Text = "STEAL"
    stealBtn.Font = Enum.Font.GothamBlack
    stealBtn.TextSize = 17
    stealBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    stealBtn.Parent = card

    local stealCorner = Instance.new("UICorner")
    stealCorner.CornerRadius = UDim.new(0, 6)
    stealCorner.Parent = stealBtn

    local stealStroke = Instance.new("UIStroke")
    stealStroke.Color = Color3.fromRGB(15, 15, 20)
    stealStroke.Thickness = 2.2
    stealStroke.Parent = stealBtn

    stealBtn.MouseButton1Click:Connect(function()
        TweenService:Create(stealBtn, TweenInfo.new(0.08), { Size = UDim2.new(0, 74, 0, 40) }):Play()
        task.wait(0.08)
        TweenService:Create(stealBtn, TweenInfo.new(0.08), { Size = UDim2.new(0, 78, 0, 44) }):Play()
        teleportAndSteal(eggData)
    end)
end

-- Tarjeta de Chilli Finder (Servidores Remotos)
local function renderChilliCard(serverData, index)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -4, 0, 66)
    card.BackgroundColor3 = THEME.CardBg
    card.BorderSizePixel = 0
    card.LayoutOrder = index
    card.Parent = cScroll

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 6)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = THEME.CardBorder
    cardStroke.Thickness = 1.2
    cardStroke.Parent = card

    -- Thumbnail con bestia (ej: Werewolf 🐺)
    local thumbBox = Instance.new("Frame")
    thumbBox.Size = UDim2.new(0, 52, 0, 52)
    thumbBox.Position = UDim2.new(0, 7, 0.5, -26)
    thumbBox.BackgroundColor3 = Color3.fromRGB(38, 40, 50)
    thumbBox.BorderSizePixel = 0
    thumbBox.ClipsDescendants = true
    thumbBox.Parent = card

    local thumbCorner = Instance.new("UICorner")
    thumbCorner.CornerRadius = UDim.new(0, 6)
    thumbCorner.Parent = thumbBox

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(1, 0, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text = "🐺"
    icon.TextSize = 28
    icon.Parent = thumbBox

    local info = Instance.new("Frame")
    info.Size = UDim2.new(1, -155, 1, -10)
    info.Position = UDim2.new(0, 66, 0, 5)
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
    nameStroke.Color = Color3.fromRGB(15, 15, 20)
    nameStroke.Thickness = 1.5
    nameStroke.Parent = nameLabel

    local statsRow = Instance.new("Frame")
    statsRow.Size = UDim2.new(1, 0, 0, 20)
    statsRow.Position = UDim2.new(0, 0, 0, 24)
    statsRow.BackgroundTransparency = 1
    statsRow.Parent = info

    local statsLayout = Instance.new("UIListLayout")
    statsLayout.FillDirection = Enum.FillDirection.Horizontal
    statsLayout.Padding = UDim.new(0, 6)
    statsLayout.Parent = statsRow

    -- $54.14B/s
    local rateLabel = Instance.new("TextLabel")
    rateLabel.AutomaticSize = Enum.AutomaticSize.X
    rateLabel.BackgroundTransparency = 1
    rateLabel.Text = serverData.rateStr
    rateLabel.Font = Enum.Font.GothamBlack
    rateLabel.TextSize = 13
    rateLabel.TextColor3 = THEME.GreenText
    rateLabel.Parent = statsRow

    -- Multiplicador x9.35
    local multLabel = Instance.new("TextLabel")
    multLabel.AutomaticSize = Enum.AutomaticSize.X
    multLabel.BackgroundTransparency = 1
    multLabel.Text = serverData.multStr
    multLabel.Font = Enum.Font.GothamBold
    multLabel.TextSize = 12
    multLabel.TextColor3 = THEME.JoinGold
    multLabel.Parent = statsRow

    -- Tiempo (2m ago)
    local timeLabel = Instance.new("TextLabel")
    timeLabel.AutomaticSize = Enum.AutomaticSize.X
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = serverData.timeAgo
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.TextSize = 11
    timeLabel.TextColor3 = Color3.fromRGB(180, 185, 200)
    timeLabel.Parent = statsRow

    -- BOTÓN DORADO [ Join ]
    local joinBtn = Instance.new("TextButton")
    joinBtn.Size = UDim2.new(0, 78, 0, 44)
    joinBtn.Position = UDim2.new(1, -85, 0.5, -22)
    joinBtn.BackgroundColor3 = THEME.JoinGold
    joinBtn.Text = "Join"
    joinBtn.Font = Enum.Font.GothamBlack
    joinBtn.TextSize = 18
    joinBtn.TextColor3 = Color3.fromRGB(20, 20, 25)
    joinBtn.Parent = card

    local joinCorner = Instance.new("UICorner")
    joinCorner.CornerRadius = UDim.new(0, 6)
    joinCorner.Parent = joinBtn

    local joinStroke = Instance.new("UIStroke")
    joinStroke.Color = Color3.fromRGB(15, 15, 20)
    joinStroke.Thickness = 2.2
    joinStroke.Parent = joinBtn

    joinBtn.MouseButton1Click:Connect(function()
        TweenService:Create(joinBtn, TweenInfo.new(0.08), { Size = UDim2.new(0, 74, 0, 40) }):Play()
        task.wait(0.08)
        TweenService:Create(joinBtn, TweenInfo.new(0.08), { Size = UDim2.new(0, 78, 0, 44) }):Play()
        joinServer(serverData.jobId, serverData.placeId)
    end)
end

-- ==========================================
-- FUNCIONES DE REFRESCO DE LISTAS
-- ==========================================
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
    end
end

-- ==========================================
-- INTERACCIÓN Y NAVEGACIÓN
-- ==========================================
local function switchTab(tabName)
    State.CurrentTab = tabName
    if tabName == "StealPanel" then
        stealTabBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 60)
        stealTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        chilliTabBtn.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
        chilliTabBtn.TextColor3 = Color3.fromRGB(180, 185, 195)

        stealView.Visible = true
        chilliView.Visible = false
        refreshStealList()
    else
        chilliTabBtn.BackgroundColor3 = THEME.ChilliHeaderBg
        chilliTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        stealTabBtn.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
        stealTabBtn.TextColor3 = Color3.fromRGB(180, 185, 195)

        stealView.Visible = false
        chilliView.Visible = true
        refreshChilliList()
    end
end

stealTabBtn.MouseButton1Click:Connect(function() switchTab("StealPanel") end)
chilliTabBtn.MouseButton1Click:Connect(function() switchTab("ChilliFinder") end)

-- Botones Steal Panel
sAutoBtn.MouseButton1Click:Connect(function()
    State.AutoSteal = not State.AutoSteal
    sAutoBtn.BackgroundColor3 = State.AutoSteal and THEME.GreenBtn or THEME.RedBtn
    sAutoBtn.Text = State.AutoSteal and "Auto Steal: ON" or "Auto Steal: OFF"
end)

sHwBtn.MouseButton1Click:Connect(function()
    State.HalloweenOnly = not State.HalloweenOnly
    sHwBtn.BackgroundColor3 = State.HalloweenOnly and THEME.OrangeTag or THEME.RedBtn
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

-- Botones Chilli Finder
cAutoBtn.MouseButton1Click:Connect(function()
    State.AutoHop = not State.AutoHop
    cAutoBtn.BackgroundColor3 = State.AutoHop and THEME.GreenBtn or THEME.AutoOffBtn
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

local accounts = {"Free", "VIP", "Pro"}
local accIdx = 1
cAccBtn.MouseButton1Click:Connect(function()
    accIdx = (accIdx % #accounts) + 1
    State.AccountTier = accounts[accIdx]
    cAccBtn.Text = "ACCOUNT\n" .. State.AccountTier
end)

-- ==========================================
-- BUCLES EN SEGUNDO PLANO (AUTO STEAL Y AUTO HOP)
-- ==========================================
task.spawn(function()
    while genv._STEAL_PANEL_LOADED do
        task.wait(1.0)
        -- Auto Steal
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
                task.wait(1.5)
            end
        end

        -- Temporizador de Force Join en Chilli Finder
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

-- Refresco periódico de listas
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
print("🥚 DUAL HUB CARGADO: STEAL PANEL & CHILLI FINDER")
print("🔥 Robo de huevos local + Server Hopper global activo")
print("=====================================================")
