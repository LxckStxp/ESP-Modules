-- ESPInterface.lua
local Censura = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/Censura.lua"))()
local ESP = loadstring(game:HttpGet("YOUR_ESP_MODULE_URL"))()

-- Create main window
local window = Censura:CreateWindow("Advanced ESP")

-- Main Controls Section
local mainSection = window:AddSection("ESP Controls")

mainSection:AddToggle("Enable ESP", ESP.Enabled, function(enabled)
    ESP.Enabled = enabled
end)

-- Visual Elements Section
local visualSection = window:AddSection("Visual Elements")

visualSection:AddToggle("Show Boxes", ESP.Settings.ShowBox, function(enabled)
    ESP.Settings.ShowBox = enabled
end)

visualSection:AddToggle("Show Names", ESP.Settings.ShowName, function(enabled)
    ESP.Settings.ShowName = enabled
end)

visualSection:AddToggle("Show Distance", ESP.Settings.ShowDistance, function(enabled)
    ESP.Settings.ShowDistance = enabled
end)

visualSection:AddToggle("Show Health", ESP.Settings.ShowHealth, function(enabled)
    ESP.Settings.ShowHealth = enabled
end)

visualSection:AddToggle("Team Check", ESP.Settings.TeamCheck, function(enabled)
    ESP.Settings.TeamCheck = enabled
end)

-- Settings Section
local settingsSection = window:AddSection("Settings")

settingsSection:AddSlider("Max Distance", 100, 5000, ESP.Settings.MaxDistance, function(value)
    ESP.Settings.MaxDistance = value
end)

settingsSection:AddSlider("Text Size", 8, 24, ESP.Settings.TextSize, function(value)
    ESP.Settings.TextSize = value
end)

settingsSection:AddSlider("Box Thickness", 1, 5, ESP.Settings.BoxThickness, function(value)
    ESP.Settings.BoxThickness = value
end)

-- Initialize ESP
ESP:Init()

-- Cleanup function
local function Cleanup()
    ESP:Cleanup()
    window:Hide()
end

return Cleanup
