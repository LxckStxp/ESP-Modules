-- ESP.lua
local ESP = {
    Enabled = false,
    Cache = {},
    Settings = {
        ShowBox = true,
        ShowName = true,
        ShowDistance = true,
        ShowHealth = true,
        ShowTracer = false,
        TeamCheck = true,
        MaxDistance = 1000,
        TextSize = 14,
        BoxThickness = 1,
        Colors = {
            Player = Color3.fromRGB(255, 0, 0),
            NPC = Color3.fromRGB(255, 140, 0),
            Team = Color3.fromRGB(0, 255, 0),
            Box = Color3.fromRGB(255, 0, 0),
            Text = Color3.fromRGB(255, 255, 255),
            Health = Color3.fromRGB(0, 255, 0),
            HealthBG = Color3.fromRGB(255, 0, 0)
        }
    }
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Optimization
local V2New = Vector2.new
local V3New = Vector3.new
local Color3New = Color3.new
local DrawNew = Drawing.new
local mathFloor = math.floor
local FindFirstChild = game.FindFirstChild

-- Utility Functions
function ESP:IsAlive(entity)
    return entity and 
           FindFirstChild(entity, "Humanoid") and 
           FindFirstChild(entity, "HumanoidRootPart") and 
           entity.Humanoid.Health > 0
end

function ESP:CreateDrawings()
    return {
        Box = {
            Main = DrawNew("Square"),
            Outline = DrawNew("Square")
        },
        Tracer = DrawNew("Line"),
        Name = DrawNew("Text"),
        Distance = DrawNew("Text"),
        Health = {
            Bar = DrawNew("Square"),
            Background = DrawNew("Square"),
            Text = DrawNew("Text")
        }
    }
end

function ESP:InitDrawing(drawing, properties)
    for prop, value in pairs(properties) do
        drawing[prop] = value
    end
end

function ESP:CreateESP(entity)
    if self.Cache[entity] then return end
    
    local esp = self:CreateDrawings()
    
    -- Initialize Box
    self:InitDrawing(esp.Box.Main, {
        Thickness = self.Settings.BoxThickness,
        Color = self.Settings.Colors.Box,
        Filled = false,
        Visible = false,
        ZIndex = 1
    })
    
    self:InitDrawing(esp.Box.Outline, {
        Thickness = self.Settings.BoxThickness + 2,
        Color = Color3New(0, 0, 0),
        Filled = false,
        Visible = false,
        ZIndex = 0
    })
    
    -- Initialize Name
    self:InitDrawing(esp.Name, {
        Size = self.Settings.TextSize,
        Center = true,
        Outline = true,
        Color = self.Settings.Colors.Text,
        Visible = false
    })
    
    -- Initialize Distance
    self:InitDrawing(esp.Distance, {
        Size = self.Settings.TextSize,
        Center = true,
        Outline = true,
        Color = self.Settings.Colors.Text,
        Visible = false
    })
    
    -- Initialize Health Bar
    self:InitDrawing(esp.Health.Background, {
        Filled = true,
        Color = self.Settings.Colors.HealthBG,
        Visible = false
    })
    
    self:InitDrawing(esp.Health.Bar, {
        Filled = true,
        Color = self.Settings.Colors.Health,
        Visible = false
    })
    
    self:InitDrawing(esp.Health.Text, {
        Size = self.Settings.TextSize,
        Center = true,
        Outline = true,
        Color = self.Settings.Colors.Text,
        Visible = false
    })
    
    -- Initialize Tracer
    self:InitDrawing(esp.Tracer, {
        Thickness = 1,
        Color = self.Settings.Colors.Box,
        Visible = false
    })
    
    self.Cache[entity] = esp
    return esp
end

function ESP:RemoveESP(entity)
    local esp = self.Cache[entity]
    if esp then
        for _, drawing in pairs(esp) do
            if typeof(drawing) == "table" then
                for _, subDrawing in pairs(drawing) do
                    subDrawing:Remove()
                end
            else
                drawing:Remove()
            end
        end
        self.Cache[entity] = nil
    end
end

function ESP:UpdateESP()
    for entity, esp in pairs(self.Cache) do
        if not self.Enabled then
            for _, drawing in pairs(esp) do
                if typeof(drawing) == "table" then
                    for _, subDrawing in pairs(drawing) do
                        subDrawing.Visible = false
                    end
                else
                    drawing.Visible = false
                end
            end
            continue
        end
        
        if not self:IsAlive(entity) then
            self:RemoveESP(entity)
            continue
        end
        
        local humanoid = entity:FindFirstChild("Humanoid")
        local rootPart = entity:FindFirstChild("HumanoidRootPart")
        
        local vector, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
        if not onScreen then
            for _, drawing in pairs(esp) do
                if typeof(drawing) == "table" then
                    for _, subDrawing in pairs(drawing) do
                        subDrawing.Visible = false
                    end
                else
                    drawing.Visible = false
                end
            end
            continue
        end
        
        local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
        if distance > self.Settings.MaxDistance then
            for _, drawing in pairs(esp) do
                if typeof(drawing) == "table" then
                    for _, subDrawing in pairs(drawing) do
                        subDrawing.Visible = false
                    end
                else
                    drawing.Visible = false
                end
            end
            continue
        end
        
        -- Update Box
        if self.Settings.ShowBox then
            local size = V2New(2000 / vector.Z, 2500 / vector.Z)
            local position = V2New(vector.X - size.X / 2, vector.Y - size.Y / 2)
            
            esp.Box.Main.Size = size
            esp.Box.Main.Position = position
            esp.Box.Main.Visible = true
            
            esp.Box.Outline.Size = size
            esp.Box.Outline.Position = position
            esp.Box.Outline.Visible = true
        else
            esp.Box.Main.Visible = false
            esp.Box.Outline.Visible = false
        end
        
        -- Update Name
        if self.Settings.ShowName then
            esp.Name.Position = V2New(vector.X, vector.Y - 40)
            esp.Name.Text = entity.Name
            esp.Name.Visible = true
        else
            esp.Name.Visible = false
        end
        
        -- Update Distance
        if self.Settings.ShowDistance then
            esp.Distance.Position = V2New(vector.X, vector.Y + 40)
            esp.Distance.Text = mathFloor(distance) .. " studs"
            esp.Distance.Visible = true
        else
            esp.Distance.Visible = false
        end
        
        -- Update Health
        if self.Settings.ShowHealth and humanoid then
            local healthBarSize = V2New(3, 30)
            local healthBarPos = V2New(vector.X - 40, vector.Y - 15)
            local healthScale = humanoid.Health / humanoid.MaxHealth
            
            esp.Health.Background.Size = healthBarSize
            esp.Health.Background.Position = healthBarPos
            esp.Health.Background.Visible = true
            
            esp.Health.Bar.Size = V2New(3, healthBarSize.Y * healthScale)
            esp.Health.Bar.Position = V2New(healthBarPos.X, 
                                          healthBarPos.Y + healthBarSize.Y * (1 - healthScale))
            esp.Health.Bar.Visible = true
            
            esp.Health.Text.Position = V2New(healthBarPos.X, healthBarPos.Y - 20)
            esp.Health.Text.Text = mathFloor(humanoid.Health) .. "/" .. 
                                  mathFloor(humanoid.MaxHealth)
            esp.Health.Text.Visible = true
        else
            esp.Health.Background.Visible = false
            esp.Health.Bar.Visible = false
            esp.Health.Text.Visible = false
        end
    end
end

function ESP:Init()
    -- Player Connections
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(char)
            self:CreateESP(char)
        end)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        if player.Character then
            self:RemoveESP(player.Character)
        end
    end)
    
    -- Initialize existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            self:CreateESP(player.Character)
        end
        player.CharacterAdded:Connect(function(char)
            self:CreateESP(char)
        end)
    end
    
    -- Update loop
    RunService:BindToRenderStep("ESP", 1, function()
        self:UpdateESP()
    end)
end

function ESP:Cleanup()
    RunService:UnbindFromRenderStep("ESP")
    for entity, _ in pairs(self.Cache) do
        self:RemoveESP(entity)
    end
    self.Cache = {}
end

return ESP
