------------------------------------------------------------
-- Advanced ESP System – Revised (No Team Check / Team Colors)
-- Version: 5.3
-- Dependencies: LSCommons, NamePlates, CensuraDev (UI)
------------------------------------------------------------

-- Dependencies (ensure these URLs are valid)
local LSCommons = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/LSCommons/main/LSCommons.lua"))()
local NamePlates = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/LSCommons/main/NamePlates.lua"))()
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/CensuraDev.lua"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

------------------------------------------------------------
-- ESP Configuration (Team-related options removed)
------------------------------------------------------------
local ESPConfig = {
    Enabled = false,
    ShowNames = true,
    ShowHealth = true,
    ShowDistance = true,
    ShowNPCs = true,
    RainbowMode = false,
    MaxDistance = 1000,
    Colors = {
        Player = Color3.fromRGB(255, 0, 0),    -- Default enemy/player color (red)
        NPC = Color3.fromRGB(255, 128, 0),       -- NPC color (orange)
        Outline = Color3.fromRGB(255, 255, 255)  -- Outline color (white)
    }
}

------------------------------------------------------------
-- ESP Object Class
------------------------------------------------------------
local ESPObject = {}
ESPObject.__index = ESPObject

-- Construct a new ESP object for a given target (player or NPC)
function ESPObject.new(target, isNPC)
    local self = setmetatable({}, ESPObject)
    self.Target = target
    self.IsNPC = isNPC

    -- Create a Highlight instance for outlining the character.
    self.Highlight = Instance.new("Highlight")
    self.Highlight.FillTransparency = 0.5
    self.Highlight.OutlineTransparency = 0.3
    self.Highlight.OutlineColor = ESPConfig.Colors.Outline

    -- Create a NamePlate using the NamePlates module.
    self.NamePlate = NamePlates.new({
        showName = ESPConfig.ShowNames,
        showHealth = ESPConfig.ShowHealth,
        showDistance = ESPConfig.ShowDistance,
        maxDistance = ESPConfig.MaxDistance
    })

    return self
end

-- Update the ESP object visuals every frame.
function ESPObject:Update()
    local character = (self.IsNPC and self.Target) or self.Target.Character
    if not character or not LSCommons.Players.isAlive(character) then
        self:Hide()
        return
    end

    local distance = LSCommons.Math.getDistanceFromPlayer(character:GetPivot().Position)
    if distance > ESPConfig.MaxDistance then
        self:Hide()
        return
    end

    -- Determine the display name
    local dispName = ""
    if self.IsNPC then
        local humanoid = character:FindFirstChild("Humanoid")
        dispName = (humanoid and humanoid.DisplayName and humanoid.DisplayName ~= "" and humanoid.DisplayName) or character.Name
    else
        dispName = self.Target.Name
    end

    -- Determine color: if Rainbow Mode is on, use rainbow color,
    -- for NPCs use the NPC color, otherwise use the default player color.
    local color
    if ESPConfig.RainbowMode then
        color = LSCommons.Visual.getRainbowColor()
    elseif self.IsNPC then
        color = ESPConfig.Colors.NPC
    else
        color = ESPConfig.Colors.Player
    end

    -- Apply the highlight and update its fill color.
    self.Highlight.Parent = character
    self.Highlight.FillColor = color

    -- Update and show the nameplate with the given data.
    self.NamePlate:Show()
    local health, maxHealth = LSCommons.Players.getHealthInfo(character)
    self.NamePlate:Update({
        name = dispName,
        health = health,
        maxHealth = maxHealth,
        distance = distance,
        color = color
    })

    -- Parent the nameplate to the Head for proper positioning, if available.
    if character:FindFirstChild("Head") then
        self.NamePlate:SetParent(character.Head)
    else
        self.NamePlate:SetParent(character)
    end
end

function ESPObject:Hide()
    self.Highlight.Parent = nil
    self.NamePlate:Hide()
end

function ESPObject:Destroy()
    self.Highlight:Destroy()
    self.NamePlate:Destroy()
end

------------------------------------------------------------
-- ESP Manager
------------------------------------------------------------
local ESPManager = {
    Objects = {},
    Connection = nil,
    Connections = {}  -- For event cleanup
}

function ESPManager:Add(target, isNPC)
    if ESPManager.Objects[target] then return end
    ESPManager.Objects[target] = ESPObject.new(target, isNPC)
end

function ESPManager:Remove(target)
    if not ESPManager.Objects[target] then return end
    ESPManager.Objects[target]:Destroy()
    ESPManager.Objects[target] = nil
end

function ESPManager:UpdateAll()
    for target, espObj in pairs(self.Objects) do
        if not target.Parent then
            self:Remove(target)
        else
            espObj:Update()
        end
    end
end

function ESPManager:Toggle(enabled)
    ESPConfig.Enabled = enabled

    for _, conn in pairs(self.Connections) do
        conn:Disconnect()
    end
    self.Connections = {}

    if not enabled then
        for target in pairs(self.Objects) do
            self:Remove(target)
        end
        if self.Connection then
            self.Connection:Disconnect()
            self.Connection = nil
        end
        return
    end

    -- Setup: Add existing players (skipping the local player)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            ESPManager:Add(player, false)
        end
    end

    -- Listen for new players.
    self.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            ESPManager:Add(player, false)
        end
    end)

    self.Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
        ESPManager:Remove(player)
    end)

    -- NPC handling.
    if ESPConfig.ShowNPCs then
        for _, obj in ipairs(workspace:GetChildren()) do
            if LSCommons.Players.isNPC(obj) then
                ESPManager:Add(obj, true)
            end
        end

        self.Connections.NPCAdded = workspace.ChildAdded:Connect(function(child)
            if LSCommons.Players.isNPC(child) then
                ESPManager:Add(child, true)
            end
        end)

        self.Connections.NPCRemoved = workspace.ChildRemoved:Connect(function(child)
            ESPManager:Remove(child)
        end)
    end

    -- Update loop.
    self.Connection = RunService.RenderStepped:Connect(function()
        ESPManager:UpdateAll()
    end)
end

------------------------------------------------------------
-- UI Setup
------------------------------------------------------------
local Window = UI.new("ESP")

Window:CreateToggle("ESP Enabled", ESPConfig.Enabled, function(value)
    ESPManager:Toggle(value)
end)

Window:CreateToggle("Show NPCs", ESPConfig.ShowNPCs, function(value)
    ESPConfig.ShowNPCs = value
    if ESPConfig.Enabled then
        ESPManager:Toggle(false)
        ESPManager:Toggle(true)
    end
end)

Window:CreateToggle("Show Names", ESPConfig.ShowNames, function(value)
    ESPConfig.ShowNames = value
    for _, espObj in pairs(ESPManager.Objects) do
        if espObj.NamePlate and espObj.NamePlate.config then
            espObj.NamePlate.config.showName = value
        end
    end
end)

Window:CreateToggle("Show Health", ESPConfig.ShowHealth, function(value)
    ESPConfig.ShowHealth = value
    for _, espObj in pairs(ESPManager.Objects) do
        if espObj.NamePlate and espObj.NamePlate.config then
            espObj.NamePlate.config.showHealth = value
        end
    end
end)

Window:CreateToggle("Show Distance", ESPConfig.ShowDistance, function(value)
    ESPConfig.ShowDistance = value
    for _, espObj in pairs(ESPManager.Objects) do
        if espObj.NamePlate and espObj.NamePlate.config then
            espObj.NamePlate.config.showDistance = value
        end
    end
end)

Window:CreateToggle("Rainbow Mode", ESPConfig.RainbowMode, function(value)
    ESPConfig.RainbowMode = value
end)

Window:CreateSlider("Max Distance", 100, 2000, ESPConfig.MaxDistance, function(value)
    ESPConfig.MaxDistance = value
    for _, espObj in pairs(ESPManager.Objects) do
        if espObj.NamePlate and espObj.NamePlate.config then
            espObj.NamePlate.config.maxDistance = value
        end
    end
end)

Window:Show()

------------------------------------------------------------
-- End of Revised ESP Script
------------------------------------------------------------
