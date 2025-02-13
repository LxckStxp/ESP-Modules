--[[ 
    Advanced ESP System for Roblox
    Features:
    - Highlights players in red and NPCs in orange
    - Shows name, health, and distance
    - Smooth, minimal UI with toggles
    - Right Control to toggle UI visibility
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

-- Constants
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Create ESP UI
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local OptionsFrame = Instance.new("Frame")
local UIListLayout = Instance.new("UIListLayout")

-- UI Styling
local function ApplyUIStyle()
    ScreenGui.Name = "ESPHUB"
    ScreenGui.Parent = CoreGui
    
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
    Title.Text = "Universal ESP"
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
end

-- ESP Settings
local ESPSettings = {
    Enabled = false,
    ShowBox = true,
    ShowName = true,
    ShowDistance = true,
    ShowHealth = true,
    MaxDistance = 1000,
    PlayerColor = Color3.fromRGB(255, 0, 0),    -- Red for players
    NPCColor = Color3.fromRGB(255, 165, 0),     -- Orange for NPCs
    TextColor = Color3.fromRGB(255, 255, 255),
    TextSize = 14
}

-- Toggle Creation Function
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

-- ESP Objects Storage
local ESPObjects = {}

-- Utility Functions
local function IsPlayer(character)
    return Players:GetPlayerFromCharacter(character) ~= nil
end

local function GetCharacterName(character)
    local player = Players:GetPlayerFromCharacter(character)
    return player and player.Name or character.Name
end

-- ESP Object Creation
local function CreateESPObject(character)
    if character == LocalPlayer.Character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local esp = {
        box = Drawing.new("Square"),
        name = Drawing.new("Text"),
        distance = Drawing.new("Text"),
        health = Drawing.new("Text"),
        character = character
    }
    
    -- Configure ESP elements
    esp.box.Thickness = 1
    esp.box.Filled = false
    esp.box.Color = IsPlayer(character) and ESPSettings.PlayerColor or ESPSettings.NPCColor
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
    
    ESPObjects[character] = esp
end

-- ESP Object Removal
local function RemoveESPObject(character)
    local esp = ESPObjects[character]
    if esp then
        for _, drawing in pairs(esp) do
            if typeof(drawing) == "table" and drawing.Remove then
                drawing:Remove()
            end
        end
        ESPObjects[character] = nil
    end
end

-- ESP Update Function
local function UpdateESP()
    for character, esp in pairs(ESPObjects) do
        if not ESPSettings.Enabled or not character:IsDescendantOf(workspace) then
            esp.box.Visible = false
            esp.name.Visible = false
            esp.distance.Visible = false
            esp.health.Visible = false
            continue
        end

        local humanoid = character:FindFirstChild("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")

        if not humanoid or not rootPart then
            esp.box.Visible = false
            esp.name.Visible = false
            esp.distance.Visible = false
            esp.health.Visible = false
            continue
        end

        local vector, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
        if not onScreen then
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
        esp.name.Text = GetCharacterName(character)
        esp.name.Visible = ESPSettings.ShowName

        esp.distance.Position = Vector2.new(vector.X, position.Y + size.Y + 5)
        esp.distance.Text = math.floor(distance) .. " studs"
        esp.distance.Visible = ESPSettings.ShowDistance

        esp.health.Position = Vector2.new(vector.X, position.Y - 35)
        esp.health.Text = math.floor(humanoid.Health) .. " HP"
        esp.health.Visible = ESPSettings.ShowHealth
    end
end

-- Initialize ESP System
local function Initialize()
    ApplyUIStyle()
    
    -- Create Toggles
    CreateToggle("Enabled", ESPSettings.Enabled)
    CreateToggle("ShowBox", ESPSettings.ShowBox)
    CreateToggle("ShowName", ESPSettings.ShowName)
    CreateToggle("ShowDistance", ESPSettings.ShowDistance)
    CreateToggle("ShowHealth", ESPSettings.ShowHealth)
    
    -- Scan existing humanoids
    for _, child in ipairs(workspace:GetDescendants()) do
        if child:IsA("Humanoid") and child.Parent then
            CreateESPObject(child.Parent)
        end
    end
    
    -- Watch for new humanoids
    workspace.DescendantAdded:Connect(function(child)
        if child:IsA("Humanoid") and child.Parent then
            CreateESPObject(child.Parent)
        end
    end)
    
    workspace.DescendantRemoving:Connect(function(child)
        if child:IsA("Humanoid") and child.Parent then
            RemoveESPObject(child.Parent)
        end
    end)
    
    -- Toggle UI Visibility
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.RightControl then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)
    
    -- Start ESP Update Loop
    RunService:BindToRenderStep("ESP", 1, UpdateESP)
end

-- Cleanup Function
local function Cleanup()
    RunService:UnbindFromRenderStep("ESP")
    for character, _ in pairs(ESPObjects) do
        RemoveESPObject(character)
    end
    ScreenGui:Destroy()
end

-- Start the ESP
Initialize()

return Cleanup
