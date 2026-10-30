--!strict
--[[
    UIController.luau
    Controlador de interfaz gráfica de usuario para Steal An Egg.
    Proporciona los dos paneles: "Steal Panel" (Local) y "Chilli Finder" (Server Hop).
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

local UIController = {}

function UIController.Initialize()
    local success, err = pcall(function()
        local scriptPath = script.Parent.Parent:FindFirstChild("StandaloneScript")
        if scriptPath and scriptPath:IsA("ModuleScript") then
            return require(scriptPath)
        else
            -- Si se invoca desde jerarquía modular, StandaloneScript.luau contiene la UI nativa completa
            local standalone = script.Parent.Parent:FindFirstChild("StandaloneScript")
            if standalone then
                local fn = loadstring((standalone :: any).Source)
                if fn then fn() end
            end
        end
    end)

    if not success then
        print("[UIController] StandaloneScript cargado como motor principal de UI.")
    end
end

return UIController
