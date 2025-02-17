-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Load UI Library
local CensuraDev = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/Censura.lua"))()

-- ESP System
local ESP = {
    Settings = {
        Enabled = false,
        TeamCheck = false,
        TeamColor = false,
        ViewAngle = {
            Enabled = false,
            Threshold = 45,
            Colors = {
                Looking = Color3.fromRGB(255, 50, 50),
                NotLooking = Color3.fromRGB(255, 255, 255)
            }
        },
        Ranges = {
            Close = {Range = 25, Scale = 1.2, Transparency = 0},
            Medium = {Range = 100, Scale = 1, Transparency = 0.2},
            Far = {Range = 300, Scale = 0.8, Transparency = 0.4}
        },
        Visual = {
            MaxDistance = 1000,
            FillTransparency = 0.5,
            OutlineTransparency = 0.3,
            TextSize = 14,
            Colors = {
                Enemy = Color3.fromRGB(255, 0, 0),
                Team = Color3.fromRGB(0, 255, 0),
                Outline = Color3.fromRGB(255, 255, 255)
            }
        }
    },
    
    Cache = {
        Components = {},
        LocalPlayer = Players.LocalPlayer,
        UpdateRate = 1/60,
        LastUpdate = 0
    }
}

-- Component Factory
local function CreateHighlight()
    local highlight = Instance.new("Highlight")
    highlight.FillTransparency = ESP.Settings.Visual.FillTransparency
    highlight.OutlineTransparency = ESP.Settings.Visual.OutlineTransparency
    highlight.OutlineColor = ESP.Settings.Visual.Colors.Outline
    return highlight
end

local function CreateInfoDisplay()
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESPInfo"
    billboard.Size = UDim2.new(0, 200, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = billboard
    
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "InfoText"
    infoLabel.Size = UDim2.new(1, 0, 0.6, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextColor3 = Color3.new(1, 1, 1)
    infoLabel.TextStrokeTransparency = 0
    infoLabel.TextSize = ESP.Settings.Visual.TextSize
    infoLabel.Font = Enum.Font.GothamBold
    infoLabel.Parent = container
    
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(0.5, 0, 0.05, 0)
    healthBar.Position = UDim2.new(0.25, 0, 0.7, 0)
    healthBar.BackgroundColor3 = Color3.new(1, 1, 1)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = container
    
    local healthCorner = Instance.new("UICorner")
    healthCorner.CornerRadius = UDim.new(1, 0)
    healthCorner.Parent = healthBar
    
    return billboard
end

-- ESP Functions
function ESP:GetPlayerComponents(player)
    if not self.Cache.Components[player] then
        self.Cache.Components[player] = {
            Highlight = CreateHighlight(),
            InfoDisplay = CreateInfoDisplay()
        }
    end
    return self.Cache.Components[player]
end

function ESP:GetViewAngle(player)
    local character = player.Character
    if not character or not character:FindFirstChild("Head") then return false end
    
    local headCFrame = character.Head.CFrame
    local lookVector = headCFrame.LookVector
    local toLocal = (self.Cache.LocalPlayer.Character.Head.Position - character.Head.Position).Unit
    local dot = lookVector:Dot(toLocal)
    local angle = math.acos(dot) * (180/math.pi)
    
    return angle <= self.Settings.ViewAngle.Threshold
end

function ESP:GetDistanceSettings(distance)
    local ranges = self.Settings.Ranges
    if distance <= ranges.Close.Range then return ranges.Close
    elseif distance <= ranges.Medium.Range then return ranges.Medium
    else return ranges.Far end
end

function ESP:UpdatePlayer(player)
    if player == self.Cache.LocalPlayer then return end
    
    local character = player.Character
    if not character or not character:FindFirstChild("Humanoid") or
       not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local distance = (character:GetPivot().Position - self.Cache.LocalPlayer.Character:GetPivot().Position).Magnitude
    if distance > self.Settings.Visual.MaxDistance then
        self:HidePlayer(player)
        return
    end
    
    if self.Settings.TeamCheck and player.Team == self.Cache.LocalPlayer.Team then
        self:HidePlayer(player)
        return
    end
    
    local components = self:GetPlayerComponents(player)
    local humanoid = character.Humanoid
    
    -- Update Highlight
    components.Highlight.Parent = character
    if self.Settings.TeamColor then
        components.Highlight.FillColor = player.TeamColor.Color
    else
        components.Highlight.FillColor = self.Settings.Visual.Colors.Enemy
    end
    
    -- Update Info Display
    local container = components.InfoDisplay.Container
    local isLooking = self.Settings.ViewAngle.Enabled and self:GetViewAngle(player)
    
    container.InfoText.Text = string.format("%s%s [%dm]",
        isLooking and "!" or "",
        player.Name,
        math.floor(distance)
    )
    
    if self.Settings.ViewAngle.Enabled then
        container.InfoText.TextColor3 = isLooking and 
            self.Settings.ViewAngle.Colors.Looking or 
            self.Settings.ViewAngle.Colors.NotLooking
    end
    
    -- Update Health Bar
    local healthPercent = humanoid.Health / humanoid.MaxHealth
    local healthBar = container.HealthBar
    
    TweenService:Create(healthBar, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0.5 * healthPercent, 0, 0.05, 0),
        BackgroundColor3 = Color3.new(1 - healthPercent, healthPercent, 0)
    }):Play()
    
    -- Apply Distance Effects
    local distanceSettings = self:GetDistanceSettings(distance)
    components.InfoDisplay.Size = UDim2.new(0, 200 * distanceSettings.Scale, 0, 40 * distanceSettings.Scale)
    
    TweenService:Create(container.InfoText, TweenInfo.new(0.3), {
        TextTransparency = distanceSettings.Transparency,
        TextStrokeTransparency = distanceSettings.Transparency
    }):Play()
    
    components.InfoDisplay.Parent = character.Head
end

function ESP:HidePlayer(player)
    local components = self.Cache.Components[player]
    if not components then return end
    
    components.Highlight.Parent = nil
    components.InfoDisplay.Parent = nil
end

function ESP:CleanupPlayer(player)
    local components = self.Cache.Components[player]
    if not components then return end
    
    components.Highlight:Destroy()
    components.InfoDisplay:Destroy()
    self.Cache.Components[player] = nil
end

-- Initialize ESP System
function ESP:Initialize()
    local ui = CensuraDev.new()
    
    ui:CreateToggle("ESP Enabled", false, function(value)
        self.Settings.Enabled = value
        if not value then
            for player, _ in pairs(self.Cache.Components) do
                self:HidePlayer(player)
            end
        end
    end)
    
    ui:CreateToggle("Team Check", false, function(value)
        self.Settings.TeamCheck = value
    end)
    
    ui:CreateToggle("Team Colors", false, function(value)
        self.Settings.TeamColor = value
    end)
    
    ui:CreateToggle("View Angle Indicator", false, function(value)
        self.Settings.ViewAngle.Enabled = value
    end)
    
    ui:CreateSlider("Max Distance", 100, 2000, 1000, function(value)
        self.Settings.Visual.MaxDistance = value
    end)
    
    -- Initialize existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= self.Cache.LocalPlayer then
            self:GetPlayerComponents(player)
        end
    end
    
    -- Player handling
    Players.PlayerAdded:Connect(function(player)
        if player ~= self.Cache.LocalPlayer then
            self:GetPlayerComponents(player)
        end
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayer(player)
    end)
    
    -- Update loop
    RunService.Heartbeat:Connect(function()
        if not self.Settings.Enabled then return end
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= self.Cache.LocalPlayer then
                self:UpdatePlayer(player)
            end
        end
    end)
    
    ui:Show()
end

ESP:Initialize()
