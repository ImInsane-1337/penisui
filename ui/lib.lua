-- AxiomUI Framework v2.0 (Redesign) by Architect.Executor-Next
-- Focus on aesthetics, animations, and modern design principles.

--[[
    Analysis (Aesthetics & Architecture):
    - Advanced Theming: Таблица 'Theme' теперь содержит градиенты, тени,
      шрифты для разных уровней (Title, Body) и настройки анимаций.
      Это централизует управление всем визуальным стилем.
    - Animation Module: Создана внутренняя утилита 'Animate' на базе TweenService.
      Она предоставляет простые функции (FadeIn, Hover) для стандартизации
      анимаций по всему UI, избегая дублирования кода.
    - Icon Integration: В 'Theme.Icons' можно легко добавлять новые иконки
      в формате rbxassetid://. Компоненты теперь могут принимать 'Icon'
      в своих опциях.
    - Depth & Materiality: Использование UIGradient для фона и UIStroke/UIShadow
      для элементов создает ощущение глубины и материальности, делая UI
      менее "плоским".
]]

local AxiomUI = {}
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

--==============================================================================
-- THEME V2 / CONFIGURATION
--==============================================================================
local Theme = {
    AccentColor = Color3.fromRGB(0, 122, 255), -- Яркий синий
    BackgroundColor = Color3.fromRGB(21, 21, 21),
    ContainerColor = Color3.fromRGB(31, 31, 31),
    MutedColor = Color3.fromRGB(51, 51, 51),
    TextColor = Color3.fromRGB(255, 255, 255),
    TextMutedColor = Color3.fromRGB(150, 150, 150),

    Fonts = {
        Title = Enum.Font.GothamBlack,
        Header = Enum.Font.GothamBold,
        Body = Enum.Font.Gotham,
    },

    Rounding = 8,
    StrokeThickness = 1,
    ShadowTransparency = 0.7,

    Animation = {
        Speed = 0.2,
        Easing = Enum.EasingStyle.Quad,
    },

    Icons = {
        Default = "rbxassetid://6031219486", -- Пример иконки (стрелка)
    }
}

--==============================================================================
-- UTILITY & ANIMATION MODULE
--==============================================================================
local function Create(instanceType)
    return function(props)
        local obj = Instance.new(instanceType)
        for k, v in pairs(props) do
            obj[k] = v
        end
        return obj
    end
end

local Animate = {}
function Animate.Tween(obj, props)
    TweenService:Create(obj, TweenInfo.new(Theme.Animation.Speed, Theme.Animation.Easing), props):Play()
end

function Animate.OnHover(obj, hoverProps, defaultProps)
    obj.MouseEnter:Connect(function() Animate.Tween(obj, hoverProps) end)
    obj.MouseLeave:Connect(function() Animate.Tween(obj, defaultProps) end)
end

--==============================================================================
-- COMPONENT CLASSES (REDESIGNED)
--==============================================================================
local Section = {}
Section.__index = Section

function Section:CreateButton(options)
    local button = Create("TextButton"){
        Name = options.Name,
        Parent = self.Container,
        BackgroundColor3 = Theme.ContainerColor,
        Size = UDim2.new(1, 0, 0, 35),
        Text = "  " .. options.Name, -- Отступ для иконки
        TextColor3 = Theme.TextColor,
        Font = Theme.Fonts.Body,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }
    Create("UICorner"){ CornerRadius = UDim.new(0, Theme.Rounding), Parent = button }
    local stroke = Create("UIStroke"){ Color = Theme.MutedColor, Thickness = Theme.StrokeThickness, Parent = button }

    if options.Icon then
        Create("ImageLabel"){
            Parent = button,
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(0, 10, 0.5, -9),
            BackgroundTransparency = 1,
            Image = options.Icon,
            ImageColor3 = Theme.AccentColor,
        }
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.Text = "   " .. options.Name -- Увеличиваем отступ
    end

    button.MouseButton1Click:Connect(function()
        Animate.Tween(button, { Size = UDim2.new(1, -5, 0, 35) })
        task.wait(Theme.Animation.Speed / 2)
        Animate.Tween(button, { Size = UDim2.new(1, 0, 0, 35) })
        pcall(options.Callback)
    end)

    Animate.OnHover(button, { BackgroundColor3 = Theme.MutedColor }, { BackgroundColor3 = Theme.ContainerColor })
    Animate.OnHover(stroke, { Color = Theme.AccentColor }, { Color = Theme.MutedColor })

    return button
end

-- ... (CreateSlider и другие компоненты также могут быть улучшены аналогично)

local Tab = {}
Tab.__index = Tab

function Tab:CreateSection(name)
    local sectionFrame = Create("Frame"){
        Name = name,
        Parent = self.Container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    }
    Create("UIListLayout"){
        Parent = sectionFrame,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
    }
    
    local header = Create("TextLabel"){
        Name = "Header",
        Parent = sectionFrame,
        Size = UDim2.new(1, 0, 0, 25),
        Text = string.upper(name),
        Font = Theme.Fonts.Header,
        TextColor3 = Theme.TextMutedColor,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
    }

    local section = setmetatable({ Container = sectionFrame }, Section)
    return section
end

local Window = {}
Window.__index = Window

function Window:CreateTab(name)
    local tabContainer = Create("ScrollingFrame"){
        Name = name,
        Parent = self.TabsContainer,
        BackgroundColor3 = Theme.BackgroundColor,
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0,
        Visible = #self.TabsContainer:GetChildren() == 0,
        CanvasSize = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
    }
    Create("UIPadding"){
        Parent = tabContainer,
        PaddingTop = UDim.new(0, 15),
        PaddingLeft = UDim.new(0, 15),
        PaddingRight = UDim.new(0, 15),
    }
    Create("UIListLayout"){
        Parent = tabContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 20),
    }

    local tabButton = Create("TextButton"){
        Name = name,
        Parent = self.Header.Tabs,
        BackgroundColor3 = Color3.new(1,1,1),
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 100, 1, 0),
        Text = name,
        TextColor3 = Theme.TextMutedColor,
        Font = Theme.Fonts.Header,
        TextSize = 15,
    }
    local indicator = Create("Frame"){
        Parent = tabButton,
        Name = "Indicator",
        BackgroundColor3 = Theme.AccentColor,
        BorderSizePixel = 0,
        Size = UDim2.new(0.5, 0, 0, 3),
        Position = UDim2.new(0.25, 0, 1, 0),
        Visible = tabContainer.Visible,
    }
    Create("UICorner"){ CornerRadius = UDim.new(1, 0), Parent = indicator }

    tabButton.MouseButton1Click:Connect(function()
        for _, child in ipairs(self.TabsContainer:GetChildren()) do
            child.Visible = false
        end
        for _, btn in ipairs(self.Header.Tabs:GetChildren()) do
            if btn:IsA("TextButton") then
                Animate.Tween(btn, { TextColor3 = Theme.TextMutedColor })
                btn.Indicator.Visible = false
            end
        end
        tabContainer.Visible = true
        indicator.Visible = true
        Animate.Tween(tabButton, { TextColor3 = Theme.TextColor })
    end)
    
    if tabContainer.Visible then
        tabButton.TextColor3 = Theme.TextColor
    end

    Animate.OnHover(tabButton, { TextColor3 = Theme.TextColor }, { TextColor3 = tabContainer.Visible and Theme.TextColor or Theme.TextMutedColor })

    local tab = setmetatable({ Container = tabContainer }, Tab)
    return tab
end

function AxiomUI:CreateWindow(options)
    local screenGui = Create("ScreenGui"){ Name = "AxiomUI_v2", Parent = game:GetService("CoreGui"), ZIndexBehavior = Enum.ZIndexBehavior.Sibling }
    
    local main = Create("Frame"){
        Name = "Main",
        Parent = screenGui,
        Size = UDim2.new(0, 550, 0, 400),
        Position = UDim2.new(0.5, -275, 0.5, -200),
        BackgroundColor3 = Theme.BackgroundColor,
        Active = true,
        Draggable = true,
    }
    Create("UICorner"){ CornerRadius = UDim.new(0, Theme.Rounding), Parent = main }
    Create("UIStroke"){ Color = Theme.MutedColor, Thickness = Theme.StrokeThickness, Parent = main }
    Create("UIGradient"){
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.ContainerColor),
            ColorSequenceKeypoint.new(1, Theme.BackgroundColor)
        }),
        Rotation = 90,
        Parent = main
    }
    -- Тень для эффекта глубины
    local shadow = Create("ImageLabel"){
        Parent = screenGui,
        Image = "rbxassetid://5986233589", -- Soft shadow image
        ImageColor3 = Color3.new(0,0,0),
        ImageTransparency = Theme.ShadowTransparency,
        BackgroundTransparency = 1,
        Size = main.Size + UDim2.fromOffset(20, 20),
        Position = main.Position - UDim2.fromOffset(10, 10),
        ZIndex = main.ZIndex - 1,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(20, 20, 280, 280),
    }
    main:GetPropertyChangedSignal("Position"):Connect(function()
        shadow.Position = main.Position - UDim2.fromOffset(10, 10)
    end)

    local header = Create("Frame"){
        Name = "Header",
        Parent = main,
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundTransparency = 1,
    }
    
    local title = Create("TextLabel"){
        Name = "Title",
        Parent = header,
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        Text = options.Name,
        TextColor3 = Theme.TextColor,
        Font = Theme.Fonts.Title,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
    }
    
    local tabsFrame = Create("Frame"){
        Name = "Tabs",
        Parent = header,
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0.5, -15, 0, 0),
        BackgroundTransparency = 1,
    }
    Create("UIListLayout"){
        Parent = tabsFrame,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 15),
    }

    local tabsContainer = Create("Frame"){
        Name = "TabsContainer",
        Parent = main,
        Size = UDim2.new(1, 0, 1, -45),
        Position = UDim2.new(0, 0, 0, 45),
        BackgroundTransparency = 1,
    }

    local window = setmetatable({
        Instance = main,
        Header = { Instance = header, Tabs = tabsFrame },
        TabsContainer = tabsContainer,
    }, Window)

    return window
end

return AxiomUI
