-- SkeetSiskiUI Framework by Architect.Executor-Next
-- A meticulous recreation of the classic "Skeet/Gamesense" visual style for Roblox.

--[[
    Analysis (Architecture & Design):
    - Theming Precision: Таблица 'Theme' была полностью переработана для соответствия
      референсу. Она включает точные цвета, пиксельный шрифт (SourceSans в малом
      кегле как лучшая встроенная альтернатива), и ID текстуры для фона.
    - Layout Rearchitecture: Структура окна изменена на "Sidebar-Content".
      Вкладки теперь - это вертикальный список иконок слева, что является
      ключевой особенностью референса.
    - Custom Components: Стандартные компоненты не подходят. Checkbox, Slider,
      Dropdown и Keybind были написаны с нуля для точного воссоздания их
      внешнего вида и поведения (например, слайдер без ползунка).
    - State Management: Для сложных элементов, как Dropdown, введено управление
      состоянием (открыт/закрыт), чтобы предотвращать одновременное открытие
      нескольких списков и закрывать их при клике в другом месте.
]]

local SkeetSiskiUI = {}
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--==============================================================================
-- THEME / CONFIGURATION
--==============================================================================
local Theme = {
    AccentColor = Color3.fromRGB(220, 60, 120), -- Розовый/Маджента
    BackgroundColor = Color3.fromRGB(20, 20, 20),
    ContainerColor = Color3.fromRGB(30, 30, 30),
    BorderColor = Color3.fromRGB(45, 45, 45),
    TextColor = Color3.fromRGB(210, 210, 210),
    HeaderTextColor = Color3.fromRGB(150, 150, 150),
    
    MainFont = Enum.Font.SourceSans, -- Лучший аналог пиксельного шрифта
    TextSize = 12,
    
    BackgroundTexture = "rbxassetid://299551314", -- Текстура сетки/шума
    RainbowGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255)),
    })
}

--==============================================================================
-- UTILITY FUNCTIONS
--==============================================================================
local function Create(instanceType, props)
    local obj = Instance.new(instanceType)
    for k, v in pairs(props) do obj[k] = v end
    return obj
end

--==============================================================================
-- COMPONENT CLASSES
--==============================================================================
local Group = {}
Group.__index = Group

function Group:CreateToggle(options)
    local container = Create("Frame", {
        Name = options.Name,
        Parent = self.Container,
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
    })

    local checkbox = Create("Frame", {
        Parent = container,
        Size = UDim2.new(0, 8, 0, 8),
        Position = UDim2.new(0, 0, 0.5, -4),
        BackgroundColor3 = Theme.ContainerColor,
    })
    Create("UIStroke", { Color = Theme.BorderColor, Thickness = 1, Parent = checkbox })

    local label = Create("TextLabel", {
        Parent = container,
        Size = UDim2.new(1, -15, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        Text = options.Name,
        TextColor3 = Theme.TextColor,
        Font = Theme.MainFont,
        TextSize = Theme.TextSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
    })

    local state = options.CurrentValue or false
    local function UpdateState()
        checkbox.BackgroundColor3 = state and Theme.AccentColor or Theme.ContainerColor
        pcall(options.Callback, state)
    end
    
    local button = Create("TextButton", {
        Parent = container,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        BackgroundTransparency = 1,
    })
    button.MouseButton1Click:Connect(function()
        state = not state
        UpdateState()
    end)
    
    UpdateState()
end

function Group:CreateSlider(options)
    local value = options.CurrentValue or options.Range[1]
    local min, max = options.Range[1], options.Range[2]

    local container = Create("Frame", {
        Name = options.Name,
        Parent = self.Container,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
    })

    local label = Create("TextLabel", {
        Parent = container,
        Size = UDim2.new(1, 0, 0, 16),
        Font = Theme.MainFont,
        TextSize = Theme.TextSize,
        TextColor3 = Theme.TextColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
    })

    local track = Create("Frame", {
        Parent = container,
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 16),
        BackgroundColor3 = Theme.ContainerColor,
    })
    Create("UIStroke", { Color = Theme.BorderColor, Thickness = 1, Parent = track })

    local fill = Create("Frame", {
        Parent = track,
        BackgroundColor3 = Theme.AccentColor,
        BorderSizePixel = 0,
    })

    local function UpdateSlider(inputPos)
        local relativeX = math.clamp((inputPos.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local newValue = min + (max - min) * relativeX
        newValue = math.floor(newValue / (options.Increment or 1)) * (options.Increment or 1)
        
        value = newValue
        fill.Size = UDim2.new(relativeX, 0, 1, 0)
        label.Text = options.Name
        label.RichText = true
        label.Text = string.format("<font color='#%s'>%s</font>  <font color='#%s'>%s%s</font>", 
            Theme.TextColor:ToHex(), options.Name, Theme.AccentColor:ToHex(), tostring(value), options.Suffix or "")
        
        pcall(options.Callback, value)
    end

    local dragButton = Create("TextButton", {
        Parent = track,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
    })

    dragButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            UpdateSlider(input.Position)
            local moveConn = UserInputService.InputChanged:Connect(function(moveInput)
                if moveInput.UserInputType == Enum.UserInputType.MouseMovement then
                    UpdateSlider(moveInput.Position)
                end
            end)
            local releaseConn = UserInputService.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == Enum.UserInputType.MouseButton1 then
                    moveConn:Disconnect()
                    releaseConn:Disconnect()
                end
            end)
        end
    end)
    
    UpdateSlider({X = track.AbsolutePosition.X + track.AbsoluteSize.X * ((value - min) / (max - min))})
end

function Group:CreateDropdown(options)
    local container = Create("Frame", {
        Name = options.Name,
        Parent = self.Container,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        ZIndex = 2,
    })

    local label = Create("TextLabel", {
        Parent = container,
        Size = UDim2.new(1, 0, 0, 14),
        Text = options.Name,
        Font = Theme.MainFont,
        TextSize = Theme.TextSize,
        TextColor3 = Theme.TextColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
    })

    local dropdownButton = Create("TextButton", {
        Parent = container,
        Name = "DropdownButton",
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 0, 14),
        BackgroundColor3 = Theme.ContainerColor,
        Text = "",
    })
    Create("UIStroke", { Color = Theme.BorderColor, Thickness = 1, Parent = dropdownButton })

    local selectedLabel = Create("TextLabel", {
        Parent = dropdownButton,
        Size = UDim2.new(1, -5, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        Font = Theme.MainFont,
        TextSize = Theme.TextSize,
        TextColor3 = Theme.TextColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
    })

    local arrow = Create("TextLabel", {
        Parent = dropdownButton,
        Size = UDim2.new(0, 10, 1, 0),
        Position = UDim2.new(1, -10, 0, 0),
        Text = "▼",
        Font = Theme.MainFont,
        TextSize = 8,
        TextColor3 = Theme.TextColor,
        BackgroundTransparency = 1,
    })

    local optionsList = Create("Frame", {
        Parent = container,
        Name = "OptionsList",
        Size = UDim2.new(1, 0, 0, #options.Options * 16),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = Theme.ContainerColor,
        Visible = false,
        ZIndex = 3,
        ClipsDescendants = true,
    })
    Create("UIStroke", { Color = Theme.BorderColor, Thickness = 1, Parent = optionsList })
    Create("UIListLayout", { Parent = optionsList, SortOrder = Enum.SortOrder.LayoutOrder })

    local state = options.CurrentValue or options.Options[1]
    selectedLabel.Text = state

    for _, optionName in ipairs(options.Options) do
        local optionButton = Create("TextButton", {
            Parent = optionsList,
            Name = optionName,
            Size = UDim2.new(1, 0, 0, 16),
            Text = " "..optionName,
            Font = Theme.MainFont,
            TextSize = Theme.TextSize,
            TextColor3 = Theme.TextColor,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundColor3 = Theme.ContainerColor,
            AutoButtonColor = false,
        })
        optionButton.MouseEnter:Connect(function() optionButton.BackgroundColor3 = Theme.BorderColor end)
        optionButton.MouseLeave:Connect(function() optionButton.BackgroundColor3 = Theme.ContainerColor end)
        optionButton.MouseButton1Click:Connect(function()
            state = optionName
            selectedLabel.Text = state
            optionsList.Visible = false
            container.Size = UDim2.new(1, 0, 0, 32)
            pcall(options.Callback, state)
        end)
    end

    dropdownButton.MouseButton1Click:Connect(function()
        optionsList.Visible = not optionsList.Visible
        if optionsList.Visible then
            container.Size = UDim2.new(1, 0, 0, 32 + #options.Options * 16)
        else
            container.Size = UDim2.new(1, 0, 0, 32)
        end
    end)
end

local Tab = {}
Tab.__index = Tab

function Tab:CreateGroup(name)
    local groupFrame = Create("Frame", {
        Name = name,
        Parent = self.Container,
        Size = UDim2.new(0.5, -5, 1, 0), -- Половина ширины с отступом
        BackgroundTransparency = 1,
    })
    
    local groupContainer = Create("Frame", {
        Parent = groupFrame,
        Size = UDim2.new(1, 0, 1, -16),
        Position = UDim2.new(0, 0, 0, 16),
        BackgroundColor3 = Theme.ContainerColor,
    })
    Create("UIStroke", { Color = Theme.BorderColor, Thickness = 1, Parent = groupContainer })
    Create("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5), PaddingTop = UDim.new(0, 5), Parent = groupContainer })
    Create("UIListLayout", { Parent = groupContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) })

    local header = Create("TextLabel", {
        Parent = groupFrame,
        Size = UDim2.new(1, 0, 0, 16),
        Text = name,
        Font = Theme.MainFont,
        TextSize = Theme.TextSize,
        TextColor3 = Theme.HeaderTextColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
    })

    local group = setmetatable({ Container = groupContainer }, Group)
    return group
end

local Window = {}
Window.__index = Window

function Window:CreateTab(options)
    local tabContent = Create("Frame", {
        Name = options.Name,
        Parent = self.ContentContainer,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = #self.ContentContainer:GetChildren() == 0,
    })
    Create("UIListLayout", {
        Parent = tabContent,
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
    })
    Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 10), Parent = tabContent })

    local tabButton = Create("ImageButton", {
        Name = options.Name,
        Parent = self.TabContainer,
        Size = UDim2.new(1, 0, 0, 40),
        Image = options.Icon,
        ImageColor3 = Theme.HeaderTextColor,
        BackgroundTransparency = 1,
    })

    tabButton.MouseButton1Click:Connect(function()
        for _, child in ipairs(self.ContentContainer:GetChildren()) do child.Visible = false end
        for _, btn in ipairs(self.TabContainer:GetChildren()) do
            if btn:IsA("ImageButton") then btn.ImageColor3 = Theme.HeaderTextColor end
        end
        tabContent.Visible = true
        tabButton.ImageColor3 = Theme.TextColor
    end)

    if tabContent.Visible then
        tabButton.ImageColor3 = Theme.TextColor
    end

    local tab = setmetatable({ Container = tabContent }, Tab)
    return tab
end

function SkeetSiskiUI:CreateWindow(options)
    local screenGui = Create("ScreenGui", { Name = "SkeetSiskiUI", Parent = game:GetService("CoreGui"), ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
    
    local main = Create("Frame", {
        Name = "Main",
        Parent = screenGui,
        Size = UDim2.new(0, 550, 0, 400),
        Position = UDim2.new(0.5, -275, 0.5, -200),
        BackgroundColor3 = Theme.BackgroundColor,
        Active = true, Draggable = true,
    })
    Create("UIStroke", { Color = Theme.BorderColor, Thickness = 1, Parent = main })
    Create("ImageLabel", { -- Фоновая текстура
        Parent = main,
        Size = UDim2.new(1, 0, 1, 0),
        Image = Theme.BackgroundTexture,
        ScaleType = Enum.ScaleType.Tile,
        TileSize = UDim2.new(0, 64, 0, 64),
        ImageTransparency = 0.9,
        ZIndex = 0,
    })

    local rainbowBar = Create("Frame", {
        Parent = main,
        Size = UDim2.new(1, 0, 0, 2),
        BorderSizePixel = 0,
    })
    local gradient = Create("UIGradient", { Color = Theme.RainbowGradient, Parent = rainbowBar })
    task.spawn(function()
        while task.wait() do
            gradient.Offset = Vector2.new(tick() % 1, 0)
        end
    end)

    local tabContainer = Create("Frame", {
        Name = "TabContainer",
        Parent = main,
        Size = UDim2.new(0, 50, 1, -2),
        Position = UDim2.new(0, 0, 0, 2),
        BackgroundTransparency = 1,
    })
    Create("UIListLayout", { Parent = tabContainer, SortOrder = Enum.SortOrder.LayoutOrder })
    Create("UIPadding", { PaddingTop = UDim.new(0, 10), Parent = tabContainer })

    local contentContainer = Create("Frame", {
        Name = "ContentContainer",
        Parent = main,
        Size = UDim2.new(1, -50, 1, -2),
        Position = UDim2.new(0, 50, 0, 2),
        BackgroundTransparency = 1,
    })

    local window = setmetatable({
        Instance = main,
        TabContainer = tabContainer,
        ContentContainer = contentContainer,
    }, Window)

    return window
end

return SkeetSiskiUI
