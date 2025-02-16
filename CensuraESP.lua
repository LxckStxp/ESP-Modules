--[[
    Advanced ESP System for Roblox
    Compatible with CensuraDev UI Library
    Optimized Version with Fixed Refresh Rate (144 FPS)
--]]

-- Load CensuraDev UI Library
local CensuraDev = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/CensuraDev.lua"))()

--// Utility Functions
local function GetDistanceFromCharacter(character)
    if not character or not game.Players.LocalPlayer.Character then return math.huge end
    return (character:GetPivot().Position - game.Players.LocalPlayer.Character:GetPivot().Position).Magnitude
end

local function IsAlive(player)
    return player.Character and player.Character:FindFirstChild("Humanoid") 
        and player.Character:FindFirstChild("Head") 
        and player.Character.Humanoid.Health > 0
end

--// ESP Configuration
local ESPSettings = {
    Enabled = false,
    TeamCheck = false,
    TeamColor = false,
    ShowNames = true,
    ShowHealth = true,
    ShowDistance = true,
    ShowTracers = false,
    RainbowMode = false,
    BaseColor = Color3.fromRGB(255, 0, 0),
    BaseTransparency = 0.5, -- Fixed value
    MaxDistance = 1000,
    MinDistance = 0,
    RefreshRate = 0.007, -- Fixed at ~144 FPS
    FontSize = 14,
    TracerOrigin = "Bottom",
    TracerThickness = 1,
    HiddenPlayerNames = {}
}

--// Storage Containers
local ESPContainer = {
    Highlights = {},
    GUIs = {},
    Tracers = {},
    Connections = {}
}

--// ESP Component Creation Functions
local function UpdateNameVisibility(player, show)
    if not player.Character then return end
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    if show and ESPSettings.HiddenPlayerNames[player] == nil then
        ESPSettings.HiddenPlayerNames[player] = humanoid.DisplayDistanceType
    end
    
    humanoid.DisplayDistanceType = show and Enum.HumanoidDisplayDistanceType.None or 
        (ESPSettings.HiddenPlayerNames[player] or Enum.HumanoidDisplayDistanceType.Viewer)
end

local function CreateESPGui(player)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESPGui"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextSize = ESPSettings.FontSize
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard
    
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "InfoLabel"
    infoLabel.Size = UDim2.new(1, 0, 0.5, 0)
    infoLabel.Position = UDim2.new(0, 0, 0.5, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextColor3 = Color3.new(1, 1, 1)
    infoLabel.TextStrokeTransparency = 0
    infoLabel.TextSize = ESPSettings.FontSize - 2
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.Parent = billboard
    
    return billboard
end

local function CreateHighlight(player)
    local highlight = Instance.new("Highlight")
    highlight.FillColor = ESPSettings.TeamColor and player.TeamColor.Color or ESPSettings.BaseColor
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = ESPSettings.BaseTransparency
    highlight.OutlineTransparency = ESPSettings.BaseTransparency
    return highlight
end

local function CreateTracer()
    local line = Drawing.new("Line")
    line.Thickness = ESPSettings.TracerThickness
    line.Color = ESPSettings.BaseColor
    line.Transparency = 1
    line.Visible = false
    return line
end

local function GetTracerOrigin()
    local camera = workspace.CurrentCamera
    local viewportSize = camera.ViewportSize
    return Vector2.new(viewportSize.X / 2, viewportSize.Y)
end

--// Main ESP Update Function
local function UpdateESPComponent(player)
    if not IsAlive(player) then return end
    
    UpdateNameVisibility(player, ESPSettings.Enabled and ESPSettings.ShowNames)
    
    if not ESPContainer.Highlights[player] then
        ESPContainer.Highlights[player] = CreateHighlight(player)
    end
    if not ESPContainer.GUIs[player] then
        ESPContainer.GUIs[player] = CreateESPGui(player)
    end
    if not ESPContainer.Tracers[player] and ESPSettings.ShowTracers then
        ESPContainer.Tracers[player] = CreateTracer()
    end
    
    local highlight = ESPContainer.Highlights[player]
    local gui = ESPContainer.GUIs[player]
    local tracer = ESPContainer.Tracers[player]
    
    highlight.Parent = player.Character
    gui.Parent = player.Character.Head
    
    local distance = GetDistanceFromCharacter(player.Character)
    
    if ESPSettings.RainbowMode then
        highlight.FillColor = Color3.fromHSV((tick() % 5) / 5, 1, 1)
    elseif ESPSettings.TeamColor then
        highlight.FillColor = player.TeamColor.Color
    else
        highlight.FillColor = ESPSettings.BaseColor
    end
    
    local nameLabel = gui.NameLabel
    local infoLabel = gui.InfoLabel
    
    -- Updated name format
    nameLabel.Text = ESPSettings.ShowNames and string.format("[%s]", player.Name) or ""
    
    -- Updated info format
    local infoText = ""
    if ESPSettings.ShowHealth and player.Character:FindFirstChild("Humanoid") then
        local health = math.floor(player.Character.Humanoid.Health)
        local maxHealth = math.floor(player.Character.Humanoid.MaxHealth)
        infoText = string.format("HP: %d/%d", health, maxHealth)
    end
    if ESPSettings.ShowDistance then
        infoText = infoText ~= "" 
            and string.format("%s | %dm", infoText, math.floor(distance))
            or string.format("%dm", math.floor(distance))
    end
    infoLabel.Text = infoText
    
    if ESPSettings.ShowTracers and tracer then
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local rootPart = character.HumanoidRootPart
            local rootPos = rootPart.Position
            local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(rootPos)
            
            if onScreen then
                tracer.Visible = true
                tracer.From = GetTracerOrigin()
                tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                tracer.Color = highlight.FillColor
                tracer.Transparency = ESPSettings.BaseTransparency
            else
                tracer.Visible = false
            end
        end
    end
end

--// Main ESP Update Loop
local function UpdateESP()
    while true do
        if ESPSettings.Enabled then
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player ~= game.Players.LocalPlayer then
                    local shouldShow = true
                    
                    if ESPSettings.TeamCheck and player.Team == game.Players.LocalPlayer.Team then
                        shouldShow = false
                    end
                    
                    if IsAlive(player) then
                        local distance = GetDistanceFromCharacter(player.Character)
                        if distance > ESPSettings.MaxDistance then
                            shouldShow = false
                        end
                    else
                        shouldShow = false
                    end
                    
                    if shouldShow then
                        UpdateESPComponent(player)
                    else
                        if ESPContainer.Highlights[player] then
                            ESPContainer.Highlights[player]:Destroy()
                            ESPContainer.Highlights[player] = nil
                        end
                        if ESPContainer.GUIs[player] then
                            ESPContainer.GUIs[player]:Destroy()
                            ESPContainer.GUIs[player] = nil
                        end
                        if ESPContainer.Tracers[player] then
                            ESPContainer.Tracers[player]:Remove()
                            ESPContainer.Tracers[player] = nil
                        end
                    end
                end
            end
        end
        task.wait(ESPSettings.RefreshRate)
    end
end

--// UI Setup
local ui = CensuraDev.new()

ui:CreateToggle("ESP Enabled", false, function(value)
    ESPSettings.Enabled = value
    if not value then
        for player, _ in pairs(ESPSettings.HiddenPlayerNames) do
            if player and player.Character then
                UpdateNameVisibility(player, false)
            end
        end
        ESPSettings.HiddenPlayerNames = {}
        
        for player, highlight in pairs(ESPContainer.Highlights) do
            highlight:Destroy()
        end
        for player, gui in pairs(ESPContainer.GUIs) do
            gui:Destroy()
        end
        for player, tracer in pairs(ESPContainer.Tracers) do
            tracer:Remove()
        end
        table.clear(ESPContainer.Highlights)
        table.clear(ESPContainer.GUIs)
        table.clear(ESPContainer.Tracers)
    end
end)

ui:CreateToggle("Team Check", false, function(value)
    ESPSettings.TeamCheck = value
end)

ui:CreateToggle("Team Colors", false, function(value)
    ESPSettings.TeamColor = value
end)

ui:CreateToggle("Show Names", true, function(value)
    ESPSettings.ShowNames = value
end)

ui:CreateToggle("Show Health", true, function(value)
    ESPSettings.ShowHealth = value
end)

ui:CreateToggle("Show Distance", true, function(value)
    ESPSettings.ShowDistance = value
end)

ui:CreateToggle("Show Tracers", false, function(value)
    ESPSettings.ShowTracers = value
    if not value then
        for player, tracer in pairs(ESPContainer.Tracers) do
            tracer:Remove()
        end
        table.clear(ESPContainer.Tracers)
    end
end)

ui:CreateToggle("Rainbow Mode", false, function(value)
    ESPSettings.RainbowMode = value
end)

ui:CreateSlider("Max Distance", 100, 2000, 1000, function(value)
    ESPSettings.MaxDistance = value
end)

--// Player Handling
local function InitializePlayer(player)
    if player == game.Players.LocalPlayer then return end
    
    local function CharacterAdded(character)
        if ESPSettings.Enabled then
            UpdateNameVisibility(player, ESPSettings.ShowNames)
            UpdateESPComponent(player)
        end
    end
    
    player.CharacterAdded:Connect(CharacterAdded)
    if player.Character then
        CharacterAdded(player.Character)
    end
end

game.Players.PlayerAdded:Connect(InitializePlayer)
game.Players.PlayerRemoving:Connect(function(player)
    UpdateNameVisibility(player, false)
    ESPSettings.HiddenPlayerNames[player] = nil
    
    if ESPContainer.Highlights[player] then
        ESPContainer.Highlights[player]:Destroy()
        ESPContainer.Highlights[player] = nil
    end
    if ESPContainer.GUIs[player] then
        ESPContainer.GUIs[player]:Destroy()
        ESPContainer.GUIs[player] = nil
    end
    if ESPContainer.Tracers[player] then
        ESPContainer.Tracers[player]:Remove()
        ESPContainer.Tracers[player] = nil
    end
end)

--// Initialize existing players
for _, player in ipairs(game.Players:GetPlayers()) do
    InitializePlayer(player)
end

--// Start ESP Update Loop
task.spawn(UpdateESP)

--// Show UI
ui:Show()
