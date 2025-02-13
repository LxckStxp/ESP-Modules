--[[ 
    Advanced CFrame Aimbot V2
    Features:
    - Enhanced UI with sliders
    - Multiple targeting options
    - Advanced prediction system
    - Customizable visual feedback
]]

-- First let me show you the UI design module, then I'll provide the main script.
-- UI Module:

local UIModule = {}

function UIModule.new()
    local ScreenGui = Instance.new("ScreenGui")
    local MainFrame = Instance.new("Frame")
    local TopBar = Instance.new("Frame")
    local Title = Instance.new("TextLabel")
    local Container = Instance.new("ScrollingFrame")
    local UIListLayout = Instance.new("UIListLayout")
    local UIPadding = Instance.new("UIPadding")

    -- Styling
    ScreenGui.Name = "AimbotV2"
    ScreenGui.Parent = game:GetService("CoreGui")

    MainFrame.Name = "MainFrame"
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0, 20, 0.3, 0)
    MainFrame.Size = UDim2.new(0, 250, 0, 400)
    MainFrame.Parent = ScreenGui
    MainFrame.ClipsDescendants = true

    -- Add shadow effect
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.BackgroundTransparency = 1
    Shadow.Position = UDim2.new(0, -15, 0, -15)
    Shadow.Size = UDim2.new(1, 30, 1, 30)
    Shadow.Image = "rbxassetid://6015897843"
    Shadow.ImageColor3 = Color3.new(0, 0, 0)
    Shadow.ImageTransparency = 0.5
    Shadow.Parent = MainFrame

    TopBar.Name = "TopBar"
    TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    TopBar.BorderSizePixel = 0
    TopBar.Size = UDim2.new(1, 0, 0, 30)
    TopBar.Parent = MainFrame

    Title.Name = "Title"
    Title.BackgroundTransparency = 1
    Title.Size = UDim2.new(1, 0, 1, 0)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "Advanced Aimbot"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 14
    Title.Parent = TopBar

    Container.Name = "Container"
    Container.BackgroundTransparency = 1
    Container.Position = UDim2.new(0, 0, 0, 30)
    Container.Size = UDim2.new(1, 0, 1, -30)
    Container.ScrollBarThickness = 2
    Container.Parent = MainFrame
    Container.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)

    UIListLayout.Parent = Container
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 5)

    UIPadding.Parent = Container
    UIPadding.PaddingLeft = UDim.new(0, 10)
    UIPadding.PaddingRight = UDim.new(0, 10)
    UIPadding.PaddingTop = UDim.new(0, 10)

    -- Make MainFrame draggable
    local UserInputService = game:GetService("UserInputService")
    local dragging
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)

    -- UI Elements Creation Functions
    local function createToggle(name, default)
        local ToggleFrame = Instance.new("Frame")
        local ToggleButton = Instance.new("TextButton")
        local ToggleTitle = Instance.new("TextLabel")

        ToggleFrame.Name = name .. "Toggle"
        ToggleFrame.BackgroundTransparency = 1
        ToggleFrame.Size = UDim2.new(1, 0, 0, 30)
        ToggleFrame.Parent = Container

        ToggleButton.Name = "Button"
        ToggleButton.Position = UDim2.new(1, -50, 0, 5)
        ToggleButton.Size = UDim2.new(0, 40, 0, 20)
        ToggleButton.BackgroundColor3 = default and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
        ToggleButton.BorderSizePixel = 0
        ToggleButton.Text = ""
        ToggleButton.Parent = ToggleFrame

        -- Add toggle circle
        local Circle = Instance.new("Frame")
        Circle.Size = UDim2.new(0, 16, 0, 16)
        Circle.Position = default and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)
        Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Circle.BorderSizePixel = 0
        Circle.Parent = ToggleButton

        -- Make circle round
        local UICorner = Instance.new("UICorner")
        UICorner.CornerRadius = UDim.new(1, 0)
        UICorner.Parent = Circle

        -- Round the toggle button
        local UICorner2 = Instance.new("UICorner")
        UICorner2.CornerRadius = UDim.new(0, 10)
        UICorner2.Parent = ToggleButton

        ToggleTitle.Name = "Title"
        ToggleTitle.BackgroundTransparency = 1
        ToggleTitle.Position = UDim2.new(0, 0, 0, 0)
        ToggleTitle.Size = UDim2.new(1, -60, 1, 0)
        ToggleTitle.Font = Enum.Font.Gotham
        ToggleTitle.Text = name
        ToggleTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        ToggleTitle.TextSize = 14
        ToggleTitle.TextXAlignment = Enum.TextXAlignment.Left
        ToggleTitle.Parent = ToggleFrame

        return ToggleButton, Circle
    end

    local function createSlider(name, min, max, default)
        local SliderFrame = Instance.new("Frame")
        local SliderTitle = Instance.new("TextLabel")
        local SliderBackground = Instance.new("Frame")
        local SliderFill = Instance.new("Frame")
        local SliderButton = Instance.new("TextButton")
        local ValueLabel = Instance.new("TextLabel")

        SliderFrame.Name = name .. "Slider"
        SliderFrame.BackgroundTransparency = 1
        SliderFrame.Size = UDim2.new(1, 0, 0, 45)
        SliderFrame.Parent = Container

        SliderTitle.Name = "Title"
        SliderTitle.BackgroundTransparency = 1
        SliderTitle.Position = UDim2.new(0, 0, 0, 0)
        SliderTitle.Size = UDim2.new(1, 0, 0, 20)
        SliderTitle.Font = Enum.Font.Gotham
        SliderTitle.Text = name
        SliderTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        SliderTitle.TextSize = 14
        SliderTitle.TextXAlignment = Enum.TextXAlignment.Left
        SliderTitle.Parent = SliderFrame

        SliderBackground.Name = "Background"
        SliderBackground.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        SliderBackground.BorderSizePixel = 0
        SliderBackground.Position = UDim2.new(0, 0, 0, 25)
        SliderBackground.Size = UDim2.new(1, 0, 0, 6)
        SliderBackground.Parent = SliderFrame

        -- Round the background
        local UICorner = Instance.new("UICorner")
        UICorner.CornerRadius = UDim.new(0, 3)
        UICorner.Parent = SliderBackground

        SliderFill.Name = "Fill"
        SliderFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        SliderFill.BorderSizePixel = 0
        SliderFill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
        SliderFill.Parent = SliderBackground

        -- Round the fill
        local UICorner2 = Instance.new("UICorner")
        UICorner2.CornerRadius = UDim.new(0, 3)
        UICorner2.Parent = SliderFill

        SliderButton.Name = "Button"
        SliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        SliderButton.Position = UDim2.new((default - min)/(max - min), -6, 0.5, -6)
        SliderButton.Size = UDim2.new(0, 12, 0, 12)
        SliderButton.Text = ""
        SliderButton.Parent = SliderBackground

        -- Make button round
        local UICorner3 = Instance.new("UICorner")
        UICorner3.CornerRadius = UDim.new(1, 0)
        UICorner3.Parent = SliderButton

        ValueLabel.Name = "Value"
        ValueLabel.BackgroundTransparency = 1
        ValueLabel.Position = UDim2.new(1, -45, 0, 0)
        ValueLabel.Size = UDim2.new(0, 45, 0, 20)
        ValueLabel.Font = Enum.Font.Gotham
        ValueLabel.Text = tostring(default)
        ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        ValueLabel.TextSize = 14
        ValueLabel.Parent = SliderFrame

        return SliderButton, SliderFill, ValueLabel
    end

    return {
        ScreenGui = ScreenGui,
        MainFrame = MainFrame,
        Container = Container,
        createToggle = createToggle,
        createSlider = createSlider
    }
end

return UIModule
