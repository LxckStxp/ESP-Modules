--[[
    Advanced ESP System
    Version: 5.5
    Direct HumanoidHandler integration for universal entity tracking
]]

-- Dependencies
local HumanoidHandler = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/LSCommons/main/HumanoidHandler.lua"))()
local LSCommons = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/LSCommons/main/LSCommons.lua"))()
local NamePlates = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/LSCommons/main/NamePlates.lua"))()
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/CensuraDev.lua"))()

-- Services
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer

-- Initialize HumanoidHandler
HumanoidHandler.init()

-- Configuration
local ESPConfig = {
    Enabled = false,
    ShowNames = true,
    ShowHealth = true,
    ShowDistance = true,
    ShowNPCs = true,
    RainbowMode = false,
    MaxDistance = 1000,
    Colors = {
        Player = Color3.fromRGB(255, 0, 0),
        NPC = Color3.fromRGB(255, 128, 0),
        Outline = Color3.fromRGB(255, 255, 255)
    },
    UpdateRate = 1/60 -- 60 fps update rate
}

-- ESP Object Class
local ESPObject = {}
ESPObject.__index = ESPObject

function ESPObject.new(model, isNPC)
    local self = setmetatable({}, ESPObject)
    self.Model = model
    self.IsNPC = isNPC
    
    self.Highlight = Instance.new("Highlight")
    self.Highlight.FillTransparency = 0.5
    self.Highlight.OutlineTransparency = 0.3
    self.Highlight.OutlineColor = ESPConfig.Colors.Outline
    
    self.NamePlate = NamePlates.new({
        showName = ESPConfig.ShowNames,
        showHealth = ESPConfig.ShowHealth,
        showDistance = ESPConfig.ShowDistance,
        maxDistance = ESPConfig.MaxDistance
    })
    
    return self
end

function ESPObject:Update()
    -- Validate model using HumanoidHandler
    if not HumanoidHandler.isValidHumanoid(self.Model) then
        self:Hide()
        return
    end
    
    -- Get humanoid info directly from HumanoidHandler
    local humanoidInfo = HumanoidHandler.getHumanoidInfo(self.Model)
    if not humanoidInfo then
        self:Hide()
        return
    end
    
    -- Check distance
    local distance = HumanoidHandler.getHumanoidDistance(LocalPlayer.Character, self.Model)
    if distance > ESPConfig.MaxDistance then
        self:Hide()
        return
    end
    
    -- Update visuals
    local color = ESPConfig.RainbowMode and LSCommons.Visual.getRainbowColor() or 
                 (self.IsNPC and ESPConfig.Colors.NPC or ESPConfig.Colors.Player)
    
    -- Update highlight
    self.Highlight.Parent = self.Model
    self.Highlight.FillColor = color
    
    -- Update nameplate
    self.NamePlate:Show()
    self.NamePlate:Update({
        name = humanoidInfo.DisplayName,
        health = humanoidInfo.Health,
        maxHealth = humanoidInfo.MaxHealth,
        distance = distance,
        color = color
    })
    
    -- Set nameplate position
    local head = self.Model:FindFirstChild("Head")
    self.NamePlate:SetParent(head or self.Model)
end

function ESPObject:Hide()
    self.Highlight.Parent = nil
    self.NamePlate:Hide()
end

function ESPObject:Destroy()
    self.Highlight:Destroy()
    self.NamePlate:Destroy()
end

-- ESP Manager
local ESPManager = {
    Objects = {},
    LastUpdate = 0
}

function ESPManager:Add(model, isNPC)
    if self.Objects[model] then return end
    self.Objects[model] = ESPObject.new(model, isNPC)
end

function ESPManager:Remove(model)
    if not self.Objects[model] then return end
    self.Objects[model]:Destroy()
    self.Objects[model] = nil
end

function ESPManager:UpdateAll()
    local currentTime = tick()
    if currentTime - self.LastUpdate < ESPConfig.UpdateRate then return end
    self.LastUpdate = currentTime
    
    -- Get valid humanoids directly from HumanoidHandler
    local players = HumanoidHandler.getValidPlayers()
    local npcs = ESPConfig.ShowNPCs and HumanoidHandler.getValidNPCs() or {}
    
    -- Remove invalid objects
    for model in pairs(self.Objects) do
        if not (table.find(players, model) or table.find(npcs, model)) then
            self:Remove(model)
        end
    end
    
    -- Update players
    for _, model in ipairs(players) do
        if model ~= LocalPlayer.Character then
            if not self.Objects[model] then
                self:Add(model, false)
            end
            self.Objects[model]:Update()
        end
    end
    
    -- Update NPCs
    if ESPConfig.ShowNPCs then
        for _, model in pairs(npcs) do
            if not self.Objects[model] then
                self:Add(model, true)
            end
            self.Objects[model]:Update()
        end
    end
end

function ESPManager:Toggle(enabled)
    ESPConfig.Enabled = enabled
    
    if not enabled then
        for model in pairs(self.Objects) do
            self:Remove(model)
        end
        if self.Connection then
            self.Connection:Disconnect()
            self.Connection = nil
        end
        return
    end
    
    self.Connection = RunService.RenderStepped:Connect(function()
        if ESPConfig.Enabled then
            self:UpdateAll()
        end
    end)
end

-- UI Setup
local Window = UI.new("ESP")

Window:CreateToggle("ESP Enabled", false, function(value)
    ESPManager:Toggle(value)
end)

Window:CreateToggle("Show NPCs", false, function(value)
    ESPConfig.ShowNPCs = value
    if ESPConfig.Enabled then
        ESPManager:Toggle(false)
        ESPManager:Toggle(true)
    end
end)

Window:CreateToggle("Show Names", true, function(value)
    ESPConfig.ShowNames = value
    for _, espObj in pairs(ESPManager.Objects) do
        if espObj.NamePlate then
            espObj.NamePlate.config.showName = value
        end
    end
end)

Window:CreateToggle("Show Health", true, function(value)
    ESPConfig.ShowHealth = value
    for _, espObj in pairs(ESPManager.Objects) do
        if espObj.NamePlate then
            espObj.NamePlate.config.showHealth = value
        end
    end
end)

Window:CreateToggle("Show Distance", true, function(value)
    ESPConfig.ShowDistance = value
    for _, espObj in pairs(ESPManager.Objects) do
        if espObj.NamePlate then
            espObj.NamePlate.config.showDistance = value
        end
    end
end)

Window:CreateToggle("Rainbow Mode", false, function(value)
    ESPConfig.RainbowMode = value
end)

Window:CreateSlider("Max Distance", 100, 2000, 1000, function(value)
    ESPConfig.MaxDistance = value
    for _, espObj in pairs(ESPManager.Objects) do
        if espObj.NamePlate then
            espObj.NamePlate.config.maxDistance = value
        end
    end
end)

Window:Show()

-- Cleanup on script stop
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child:IsA("ScreenGui") then
        HumanoidHandler.cleanup()
        ESPManager:Toggle(false)
    end
end)
