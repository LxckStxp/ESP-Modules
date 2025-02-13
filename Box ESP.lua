-- Create ESP UI
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local OptionsFrame = Instance.new("Frame")
local UIListLayout = Instance.new("UIListLayout")

-- UI Setup
ScreenGui.Name = "ESPHUB"
ScreenGui.Parent = game:GetService("CoreGui")

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderColor3 = Color3.fromRGB(50, 50, 50)
MainFrame.Position = UDim2.new(0, 10, 0.3, 0)
MainFrame.Size = UDim2.new(0, 200, 0, 300)
MainFrame.Active = true
MainFrame.Draggable = true

Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "ESP Menu"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16

OptionsFrame.Name = "Options"
OptionsFrame.Parent = MainFrame
OptionsFrame.BackgroundTransparency = 1
OptionsFrame.Position = UDim2.new(0, 0, 0, 35)
OptionsFrame.Size = UDim2.new(1, 0, 1, -35)

UIListLayout.Parent = OptionsFrame
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- ESP Settings
local ESPSettings = {
    Enabled = false,
    ShowBox = true,
    ShowName = true,
    ShowDistance = true,
    ShowHealth = true,
    TeamCheck = true,
    MaxDistance = 1000,
    BoxColor = Color3.fromRGB(255, 0, 0),
    TextColor = Color3.fromRGB(255, 255, 255),
    TextSize = 14
}

-- Create Toggle Function
local function CreateToggle(name, default)
    local Toggle = Instance.new("TextButton")
    Toggle.Name = name
    Toggle.Parent = OptionsFrame
    Toggle.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Toggle.Size = UDim2.new(1, -10, 0, 30)
    Toggle.Position = UDim2.new(0, 5, 0, 0)
    Toggle.Font = Enum.Font.SourceSans
    Toggle.Text = name .. ": " .. tostring(default)
    Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    Toggle.TextSize = 14
    Toggle.AutoButtonColor = false

    local enabled = default
    Toggle.MouseButton1Click:Connect(function()
        enabled = not enabled
        Toggle.Text = name .. ": " .. tostring(enabled)
        Toggle.BackgroundColor3 = enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(35, 35, 35)
        ESPSettings[name] = enabled
    end)
    
    return Toggle
end

-- Create Toggles
CreateToggle("Enabled", ESPSettings.Enabled)
CreateToggle("ShowBox", ESPSettings.ShowBox)
CreateToggle("ShowName", ESPSettings.ShowName)
CreateToggle("ShowDistance", ESPSettings.ShowDistance)
CreateToggle("ShowHealth", ESPSettings.ShowHealth)
CreateToggle("TeamCheck", ESPSettings.TeamCheck)

-- ESP Functions
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

local ESPObjects = {}

local function CreateESPObject(player)
    if player == LocalPlayer then return end
    
    local esp = {
        box = Drawing.new("Square"),
        name = Drawing.new("Text"),
        distance = Drawing.new("Text"),
        health = Drawing.new("Text")
    }
    
    esp.box.Thickness = 1
    esp.box.Filled = false
    esp.box.Color = ESPSettings.BoxColor
    esp.box.Visible = false
    
    esp.name.Size = ESPSettings.TextSize
    esp.name.Center = true
    esp.name.Outline = true
    esp.name.Color = ESPSettings.TextColor
    esp.name.Visible = false
    
    esp.distance.Size = ESPSettings.TextSize
    esp.distance.Center = true
    esp.distance.Outline = true
    esp.distance.Color = ESPSettings.TextColor
    esp.distance.Visible = false
    
    esp.health.Size = ESPSettings.TextSize
    esp.health.Center = true
    esp.health.Outline = true
    esp.health.Color = ESPSettings.TextColor
    esp.health.Visible = false
    
    ESPObjects[player] = esp
end

local function RemoveESPObject(player)
    local esp = ESPObjects[player]
    if esp then
        for _, drawing in pairs(esp) do
            drawing:Remove()
        end
        ESPObjects[player] = nil
    end
end

local function UpdateESP()
    for player, esp in pairs(ESPObjects) do
        if not ESPSettings.Enabled then
            esp.box.Visible = false
            esp.name.Visible = false
            esp.distance.Visible = false
            esp.health.Visible = false
            continue
        end

        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            esp.box.Visible = false
            esp.name.Visible = false
            esp.distance.Visible = false
            esp.health.Visible = false
            continue
        end

        local humanoid = player.Character:FindFirstChild("Humanoid")
        local rootPart = player.Character.HumanoidRootPart

        local vector, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
        if not onScreen then
            esp.box.Visible = false
            esp.name.Visible = false
            esp.distance.Visible = false
            esp.health.Visible = false
            continue
        end

        if ESPSettings.TeamCheck and player.Team == LocalPlayer.Team then
            esp.box.Visible = false
            esp.name.Visible = false
            esp.distance.Visible = false
            esp.health.Visible = false
            continue
        end

        local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
        if distance > ESPSettings.MaxDistance then
            esp.box.Visible = false
            esp.name.Visible = false
            esp.distance.Visible = false
            esp.health.Visible = false
            continue
        end

        -- Update ESP Elements
        local size = Vector2.new(2000 / vector.Z, 2500 / vector.Z)
        local position = Vector2.new(vector.X - size.X / 2, vector.Y - size.Y / 2)

        esp.box.Size = size
        esp.box.Position = position
        esp.box.Visible = ESPSettings.ShowBox

        esp.name.Position = Vector2.new(vector.X, position.Y - 20)
        esp.name.Text = player.Name
        esp.name.Visible = ESPSettings.ShowName

        esp.distance.Position = Vector2.new(vector.X, position.Y + size.Y + 5)
        esp.distance.Text = math.floor(distance) .. " studs"
        esp.distance.Visible = ESPSettings.ShowDistance

        if humanoid then
            esp.health.Position = Vector2.new(vector.X, position.Y - 35)
            esp.health.Text = math.floor(humanoid.Health) .. " HP"
            esp.health.Visible = ESPSettings.ShowHealth
        end
    end
end

-- Connections
Players.PlayerAdded:Connect(CreateESPObject)
Players.PlayerRemoving:Connect(RemoveESPObject)

for _, player in ipairs(Players:GetPlayers()) do
    CreateESPObject(player)
end

RunService:BindToRenderStep("ESP", 1, UpdateESP)

-- Cleanup
local function Cleanup()
    RunService:UnbindFromRenderStep("ESP")
    for player, _ in pairs(ESPObjects) do
        RemoveESPObject(player)
    end
    ScreenGui:Destroy()
end

-- Toggle UI Visibility
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

return Cleanup
