--[[
    ESP Interface Module
    Author: Professional Roblox Developer
    Version: 2.0.0
    
    This module creates an advanced interface for ESP controls using the Censura UI System
]]

-- Services & Modules
local Censura = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/Censura.lua"))()
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/ESP-Modules/main/Censura Integration/ESP.lua"))()

local Interface = {}

function Interface:Init()
    -- Create main window
    local window = Censura:CreateWindow("Advanced ESP v2.0.0")
    
    -- Main Controls Section
    local mainSection = window:AddSection("ESP Controls")
    
    mainSection:AddToggle({
        text = "Enable ESP",
        default = ESP.Enabled,
        callback = function(enabled)
            ESP.Enabled = enabled
        end
    })
    
    -- Visual Elements Section
    local visualSection = window:AddSection("Visual Elements")
    
    local visualToggles = {
        {name = "Show Boxes", setting = "ShowBox"},
        {name = "Show Names", setting = "ShowName"},
        {name = "Show Distance", setting = "ShowDistance"},
        {name = "Show Health", setting = "ShowHealth"},
        {name = "Show Tracers", setting = "ShowTracer"},
        {name = "Show Team", setting = "ShowTeam"},
        {name = "Show Weapon", setting = "ShowWeapon"}
    }
    
    for _, toggle in ipairs(visualToggles) do
        visualSection:AddToggle({
            text = toggle.name,
            default = ESP.Settings[toggle.setting],
            callback = function(enabled)
                ESP.Settings[toggle.setting] = enabled
            end
        })
    end
    
    -- Style Settings Section
    local styleSection = window:AddSection("Style Settings")
    
    -- Box Style Selector
    styleSection:AddButton({
        text = "Box Style: " .. ESP.Settings.BoxStyle,
        callback = function()
            local styles = {"Default", "Corner", "3D"}
            local currentIndex = table.find(styles, ESP.Settings.BoxStyle) or 1
            currentIndex = (currentIndex % #styles) + 1
            ESP.Settings.BoxStyle = styles[currentIndex]
            -- Update button text
            return "Box Style: " .. styles[currentIndex]
        end
    })
    
    -- Health Bar Style Selector
    styleSection:AddButton({
        text = "Health Bar: " .. ESP.Settings.HealthBarStyle,
        callback = function()
            local styles = {"Side", "Bottom"}
            local currentIndex = table.find(styles, ESP.Settings.HealthBarStyle) or 1
            currentIndex = (currentIndex % #styles) + 1
            ESP.Settings.HealthBarStyle = styles[currentIndex]
            return "Health Bar: " .. styles[currentIndex]
        end
    })
    
    -- Distance Settings Section
    local distanceSection = window:AddSection("Distance Settings")
    
    distanceSection:AddSlider({
        text = "Max Distance",
        min = 100,
        max = 5000,
        default = ESP.Settings.MaxDistance,
        callback = function(value)
            ESP.Settings.MaxDistance = value
        end
    })
    
    distanceSection:AddSlider({
        text = "Min Distance",
        min = 0,
        max = 100,
        default = ESP.Settings.MinDistance,
        callback = function(value)
            ESP.Settings.MinDistance = value
        end
    })
    
    -- Appearance Settings Section
    local appearanceSection = window:AddSection("Appearance")
    
    appearanceSection:AddSlider({
        text = "Text Size",
        min = 8,
        max = 24,
        default = ESP.Settings.TextSize,
        callback = function(value)
            ESP.Settings.TextSize = value
        end
    })
    
    appearanceSection:AddSlider({
        text = "Box Thickness",
        min = 1,
        max = 5,
        default = ESP.Settings.BoxThickness,
        callback = function(value)
            ESP.Settings.BoxThickness = value
        end
    })
    
    -- Color Settings Section
    local colorSection = window:AddSection("Colors")
    
    colorSection:AddToggle({
        text = "Rainbow Mode",
        default = ESP.Settings.RainbowMode,
        callback = function(enabled)
            ESP.Settings.RainbowMode = enabled
        end
    })
    
    colorSection:AddSlider({
        text = "Rainbow Speed",
        min = 0.1,
        max = 5,
        default = ESP.Settings.RainbowSpeed,
        callback = function(value)
            ESP.Settings.RainbowSpeed = value
        end
    })
    
    -- Advanced Settings Section
    local advancedSection = window:AddSection("Advanced Settings")
    
    advancedSection:AddToggle({
        text = "Fade with Distance",
        default = ESP.Settings.FadeWithDistance,
        callback = function(enabled)
            ESP.Settings.FadeWithDistance = enabled
        end
    })
    
    advancedSection:AddToggle({
        text = "Outline ESP",
        default = ESP.Settings.OutlineESP,
        callback = function(enabled)
            ESP.Settings.OutlineESP = enabled
        end
    })
    
    advancedSection:AddSlider({
        text = "Refresh Rate",
        min = 1,
        max = 60,
        default = ESP.Settings.RefreshRate,
        callback = function(value)
            ESP.Settings.RefreshRate = value
        end
    })
    
    -- Information Section
    local infoSection = window:AddSection("Information")
    
    infoSection:AddLabel({
        text = "Right Control to Toggle UI"
    })
    
    infoSection:AddLabel({
        text = "ESP Version: 2.0.0"
    })
    
    -- Store window reference
    self.Window = window
    
    -- Initialize ESP
    ESP:Init()
    
    return self
end

function Interface:Toggle()
    if self.Window then
        self.Window:Toggle()
    end
end

function Interface:Cleanup()
    if self.Window then
        self.Window:Hide()
    end
    ESP:Cleanup()
end

-- Example Usage:
--[[
    -- Initialize the interface
    local espInterface = Interface:Init()
    
    -- Toggle visibility
    espInterface:Toggle()
    
    -- Cleanup when done
    espInterface:Cleanup()
]]

return Interface
