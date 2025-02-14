-- Load Censura UI Library
local Censura = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/Censura.lua"))()

-- Utility Functions
local function GetDistanceFromCharacter(character)
    if not character or not game.Players.LocalPlayer.Character then return math.huge end
    return (character:GetPivot().Position - game.Players.LocalPlayer.Character:GetPivot().Position).Magnitude
end

local function IsAlive(player)
    return player.Character and player.Character:FindFirstChild("Humanoid") 
        and player.Character:FindFirstChild("Head") 
        and player.Character.Humanoid.Health > 0
end

-- ESP Configuration
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
    BaseTransparency = 0.5,
    MaxDistance = 1000,
    MinDistance = 0,
    RefreshRate = 0.1,
    FontSize = 14,
    TracerOrigin = "Bottom", -- "Bottom", "Top", "Mouse"
    TracerThickness = 1,
    HiddenPlayerNames = {} -- Store reference to hidden name tags
}

-- Storage
local ESPContainer = {
    Highlights = {},
    GUIs = {},
    Tracers = {},
    Connections = {}
}

-- Create Window
local Window = Censura:CreateWindow({
    title = "Advanced ESP",
    size = UDim2.new(0, 300, 0, 400),
    position = UDim2.new(0.5, -150, 0.5, -200)
})

-- Function to handle name visibility
local function UpdateNameVisibility(player, show)
    if not player.Character then return end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Store original name tag state if not already stored
    if show and ESPSettings.HiddenPlayerNames[player] == nil then
        ESPSettings.HiddenPlayerNames[player] = humanoid.DisplayDistanceType
    end
    
    -- Update name tag visibility
    humanoid.DisplayDistanceType = show and Enum.HumanoidDisplayDistanceType.None or 
        (ESPSettings.HiddenPlayerNames[player] or Enum.HumanoidDisplayDistanceType.Viewer)
end

-- Create ESP GUI Components
local function CreateESPGui(player)
    -- Create main BillboardGui container
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESPGui"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0) -- Position above player's head
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0 -- Prevent lighting from affecting visibility
    
    -- Create name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0 -- Add text stroke for better visibility
    nameLabel.TextSize = ESPSettings.FontSize
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard
    
    -- Create info label (health, distance)
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "InfoLabel"
    infoLabel.Size = UDim2.new(1, 0, 0.5, 0)
    infoLabel.Position = UDim2.new(0, 0, 0.5, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextColor3 = Color3.new(1, 1, 1)
    infoLabel.TextStrokeTransparency = 0
    infoLabel.TextSize = ESPSettings.FontSize - 2 -- Slightly smaller than name
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.Parent = billboard
    
    return billboard
end

-- Create Highlight Component
local function CreateHighlight(player)
    local highlight = Instance.new("Highlight")
    highlight.FillColor = ESPSettings.TeamColor and player.TeamColor.Color or ESPSettings.BaseColor
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = ESPSettings.BaseTransparency
    highlight.OutlineTransparency = ESPSettings.BaseTransparency
    return highlight
end

-- Create Tracer Component
local function CreateTracer()
    local line = Drawing.new("Line")
    line.Thickness = ESPSettings.TracerThickness
    line.Color = ESPSettings.BaseColor
    line.Transparency = 1
    line.Visible = false -- Initially invisible
    return line
end

-- Function to get tracer origin position
local function GetTracerOrigin()
    local camera = workspace.CurrentCamera
    local viewportSize = camera.ViewportSize
    
    if ESPSettings.TracerOrigin == "Bottom" then
        return Vector2.new(viewportSize.X / 2, viewportSize.Y)
    elseif ESPSettings.TracerOrigin == "Top" then
        return Vector2.new(viewportSize.X / 2, 0)
    elseif ESPSettings.TracerOrigin == "Mouse" then
        local mouse = game.Players.LocalPlayer:GetMouse()
        return Vector2.new(mouse.X, mouse.Y)
    end
    
    return Vector2.new(viewportSize.X / 2, viewportSize.Y) -- Default to bottom
end

-- Main ESP Component Update Function
local function UpdateESPComponent(player)
    if not IsAlive(player) then return end
    
    -- Update name visibility based on ESP state
    UpdateNameVisibility(player, ESPSettings.Enabled and ESPSettings.ShowNames)
    
    -- Create or get existing components
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
    
    -- Update component parents
    highlight.Parent = player.Character
    gui.Parent = player.Character.Head
    
    -- Calculate distance and transparency
    local distance = GetDistanceFromCharacter(player.Character)
    local transparencyFactor = math.clamp(
        (distance - ESPSettings.MinDistance) / (ESPSettings.MaxDistance - ESPSettings.MinDistance),
        0,
        1
    )
    local finalTransparency = math.clamp(ESPSettings.BaseTransparency + (transparencyFactor * 0.8), 0, 1)
    
    -- Update highlight properties
    highlight.FillTransparency = finalTransparency
    highlight.OutlineTransparency = finalTransparency
    
    if ESPSettings.RainbowMode then
        highlight.FillColor = Color3.fromHSV((tick() % 5) / 5, 1, 1)
    elseif ESPSettings.TeamColor then
        highlight.FillColor = player.TeamColor.Color
    else
        highlight.FillColor = ESPSettings.BaseColor
    end
    
    -- Update GUI labels
    local nameLabel = gui.NameLabel
    local infoLabel = gui.InfoLabel
    
    nameLabel.Text = ESPSettings.ShowNames and player.Name or ""
    
    -- Build info text
    local infoText = ""
    if ESPSettings.ShowHealth and player.Character:FindFirstChild("Humanoid") then
        local health = math.floor(player.Character.Humanoid.Health)
        local maxHealth = math.floor(player.Character.Humanoid.MaxHealth)
        infoText = string.format("HP: %d/%d", health, maxHealth)
    end
    if ESPSettings.ShowDistance then
        infoText = infoText .. string.format(" [%dm]", math.floor(distance))
    end
    infoLabel.Text = infoText
    
    -- Update tracer
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
                tracer.Transparency = finalTransparency
            else
                tracer.Visible = false
            end
        end
    end
end

-- Main ESP Update Loop
local function UpdateESP()
    while true do
        if ESPSettings.Enabled then
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player ~= game.Players.LocalPlayer then
                    local shouldShow = true
                    
                    -- Team Check
                    if ESPSettings.TeamCheck and player.Team == game.Players.LocalPlayer.Team then
                        shouldShow = false
                    end
                    
                    -- Distance Check
                    if IsAlive(player) then
                        local distance = GetDistanceFromCharacter(player.Character)
                        if distance > ESPSettings.MaxDistance then
                            shouldShow = false
                        end
                    else
                        shouldShow = false
                    end
                    
                    -- Update or clean up
                    if shouldShow then
                        UpdateESPComponent(player)
                    else
                        -- Clean up components
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

-- UI Controls Setup
Window:AddToggle({
    label = "ESP Enabled",
    callback = function(value)
        ESPSettings.Enabled = value
        if not value then
            -- Restore all name tags
            for player, _ in pairs(ESPSettings.HiddenPlayerNames) do
                if player and player.Character then
                    UpdateNameVisibility(player, false)
                end
            end
            ESPSettings.HiddenPlayerNames = {}
            
            -- Clean up all ESP components
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
    end
})

Window:AddToggle({
    label = "Team Check",
    callback = function(value)
        ESPSettings.TeamCheck = value
    end
})

Window:AddToggle({
    label = "Team Colors",
    callback = function(value)
        ESPSettings.TeamColor = value
    end
})

Window:AddToggle({
    label = "Show Names",
    callback = function(value)
        ESPSettings.ShowNames = value
        -- Update name visibility for all players
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer then
                UpdateNameVisibility(player, ESPSettings.Enabled and value)
            end
        end
    end
})

Window:AddToggle({
    label = "Show Health",
    callback = function(value)
        ESPSettings.ShowHealth = value
    end
})

Window:AddToggle({
    label = "Show Distance",
    callback = function(value)
        ESPSettings.ShowDistance = value
    end
})

Window:AddToggle({
    label = "Show Tracers",
    callback = function(value)
        ESPSettings.ShowTracers = value
        if not value then
            for player, tracer in pairs(ESPContainer.Tracers) do
                tracer:Remove()
            end
            table.clear(ESPContainer.Tracers)
        end
    end
})

Window:AddToggle({
    label = "Rainbow Mode",
    callback = function(value)
        ESPSettings.RainbowMode = value
    end
})

-- Sliders for customization
Window:AddSlider({
    label = "Max Distance",
    min = 100,
    max = 2000,
    default = 1000,
    callback = function(value)
        ESPSettings.MaxDistance = value
    end
})

Window:AddSlider({
    label = "Transparency",
    min = 0,
    max = 100,
    default = 50,
    callback = function(value)
        ESPSettings.BaseTransparency = value / 100
    end
})

Window:AddSlider({
    label = "Refresh Rate",
    min = 1,
    max = 60,
    default = 10,
    callback = function(value)
        ESPSettings.RefreshRate = 1 / value
    end
})

-- Player Handling
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

-- Player event connections
game.Players.PlayerAdded:Connect(InitializePlayer)
game.Players.PlayerRemoving:Connect(function(player)
    -- Restore name tag before player leaves
    UpdateNameVisibility(player, false)
    ESPSettings.HiddenPlayerNames[player] = nil
    
    -- Clean up ESP components
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

-- Initialize existing players
for _, player in ipairs(game.Players:GetPlayers()) do
    InitializePlayer(player)
end

-- Start ESP Update Loop
task.spawn(UpdateESP)
