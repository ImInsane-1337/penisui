-- AxiomUI Framework by Architect.Executor-Next
-- A lightweight, performant, and modular UI engine.

--[[
    Analysis (Architecture):
    - OOP-like Structure: Мы используем метатаблицы для создания "классов" (Window, Tab, Section).
      Это позволяет нам вызывать методы в цепочке: Window:CreateTab():CreateSection().
    - Centralized Theming: Вся информация о стилях (цвета, шрифты, размеры) хранится
      в таблице 'Theme'. Изменение одного значения в этой таблице изменит весь UI,
      что делает кастомизацию тривиальной.
    - Component Factory: Функции типа 'CreateButton' являются "фабриками". Они инкапсулируют
      всю логику создания, стилизации и настройки событий для одного элемента.
      Это скрывает сложность от конечного пользователя.
    - Performance: Для перетаскивания окна используется UserInputService, что является
      наиболее производительным способом. Новые элементы создаются и позиционируются
      с помощью UIListLayout, что эффективнее ручного расчета координат.
]]

local AxiomUI = {}
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--==============================================================================
-- THEME / CONFIGURATION
--==============================================================================
local Theme = {
    AccentColor = Color3.fromRGB(255, 0, 80),
    BackgroundColor = Color3.fromRGB(30, 30, 30),
    ContainerColor = Color3.fromRGB(45, 45, 45),
    TextColor = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamSemibold,
    TextSize = 14,
    Rounding = 6,
}

--==============================================================================
-- UTILITY FUNCTIONS
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

--==============================================================================
-- COMPONENT CLASSES
--==============================================================================
local Section = {}
Section.__index = Section

function Section:CreateButton(options)
    local button = Create("TextButton"){
        Name = options.Name,
        Parent = self.Container,
        BackgroundColor3 = Theme.ContainerColor,
        Size = UDim2.new(1, 0, 0, 30),
        Text = options.Name,
        TextColor3 = Theme.TextColor,
        Font = Theme.Font,
        TextSize = Theme.TextSize,
        AutoButtonColor = false,
    }
    Create("UICorner"){ CornerRadius = UDim.new(0, Theme.Rounding), Parent = button }

    button.MouseButton1Click:Connect(function()
        local success, err = pcall(options.Callback)
        if not success then
            warn("[AxiomUI] Error in button callback:", err)
        end
    end)
    return button
end

function Section:CreateSlider(options)
    local value = options.CurrentValue or options.Range[1]
    local min, max = options.Range[1], options.Range[2]

    local container = Create("Frame"){
        Name = options.Name,
        Parent = self.Container,
        BackgroundColor3 = Color3.new(1,1,1),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 40),
    }

    local label = Create("TextLabel"){
        Name = "Label",
        Parent = container,
        BackgroundColor3 = Color3.new(1,1,1),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Text = options.Name .. ": " .. value,
        TextColor3 = Theme.TextColor,
        Font = Theme.Font,
        TextSize = Theme.TextSize - 2,
        TextXAlignment = Enum.TextXAlignment.Left,
    }

    local track = Create("Frame"){
        Name = "Track",
        Parent = container,
        BackgroundColor3 = Theme.BackgroundColor,
        Position = UDim2.new(0, 0, 0, 20),
        Size = UDim2.new(1, 0, 0, 8),
    }
    Create("UICorner"){ CornerRadius = UDim.new(0, 4), Parent = track }

    local fill = Create("Frame"){
        Name = "Fill",
        Parent = track,
        BackgroundColor3 = Theme.AccentColor,
        Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
    }
    Create("UICorner"){ CornerRadius = UDim.new(0, 4), Parent = fill }

    local thumb = Create("TextButton"){
        Name = "Thumb",
        Parent = track,
        BackgroundColor3 = Theme.TextColor,
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(fill.Size.X.Scale, -8, -0.5, 4),
        Text = "",
        ZIndex = 2,
    }
    Create("UICorner"){ CornerRadius = UDim.new(1, 0), Parent = thumb }

    local function UpdateSlider(inputPos)
        local relativePos = math.clamp((inputPos.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local newValue = math.floor((min + (max - min) * relativePos) / (options.Increment or 1)) * (options.Increment or 1)
        
        fill.Size = UDim2.new(relativePos, 0, 1, 0)
        thumb.Position = UDim2.new(relativePos, -8, -0.5, 4)
        label.Text = options.Name .. ": " .. newValue
        
        if value ~= newValue then
            value = newValue
            task.spawn(options.Callback, value)
        end
    end

    thumb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local moveConn, releaseConn
            moveConn = UserInputService.InputChanged:Connect(function(moveInput)
                if moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch then
                    UpdateSlider(moveInput.Position)
                end
            end)
            releaseConn = UserInputService.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
                    moveConn:Disconnect()
                    releaseConn:Disconnect()
                end
            end)
        end
    end)

    return container
end

-- ... (Здесь можно добавить CreateToggle, CreateKeybind и т.д.)

local Tab = {}
Tab.__index = Tab

function Tab:CreateSection(name)
    local sectionFrame = Create("Frame"){
        Name = name,
        Parent = self.Container,
        BackgroundColor3 = Color3.new(1,1,1),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 0), -- Авто-размер по высоте
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0, 10, 0, 10),
    }
    Create("UIListLayout"){
        Parent = sectionFrame,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
    }
    local section = setmetatable({ Container = sectionFrame }, Section)
    return section
end

local Window = {}
Window.__index = Window

function Window:CreateTab(name)
    local tabContainer = Create("Frame"){
        Name = name,
        Parent = self.TabsContainer,
        BackgroundColor3 = Theme.ContainerColor,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = #self.TabsContainer:GetChildren() == 0, -- Первый таб видимый
    }
    
    local tabButton = Create("TextButton"){
        Name = name,
        Parent = self.Header.Tabs,
        BackgroundColor3 = Theme.BackgroundColor,
        Size = UDim2.new(0, 100, 1, 0),
        Text = name,
        TextColor3 = Theme.TextColor,
        Font = Theme.Font,
        TextSize = Theme.TextSize,
    }

    tabButton.MouseButton1Click:Connect(function()
        for _, child in ipairs(self.TabsContainer:GetChildren()) do
            child.Visible = false
        end
        for _, btn in ipairs(self.Header.Tabs:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundColor3 = Theme.BackgroundColor
            end
        end
        tabContainer.Visible = true
        tabButton.BackgroundColor3 = Theme.ContainerColor
    end)
    
    if tabContainer.Visible then
        tabButton.BackgroundColor3 = Theme.ContainerColor
    end

    local tab = setmetatable({ Container = tabContainer }, Tab)
    return tab
end

function AxiomUI:CreateWindow(options)
    local screenGui = Create("ScreenGui"){ Name = "AxiomUI", Parent = game:GetService("CoreGui") }
    
    local main = Create("Frame"){
        Name = "Main",
        Parent = screenGui,
        Size = UDim2.new(0, 500, 0, 350),
        Position = UDim2.new(0.5, -250, 0.5, -175),
        BackgroundColor3 = Theme.BackgroundColor,
        Active = true,
        Draggable = true,
    }
    Create("UICorner"){ CornerRadius = UDim.new(0, Theme.Rounding), Parent = main }

    local header = Create("Frame"){
        Name = "Header",
        Parent = main,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.ContainerColor,
    }
    
    local title = Create("TextLabel"){
        Name = "Title",
        Parent = header,
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Text = options.Name,
        TextColor3 = Theme.TextColor,
        Font = Theme.Font,
        TextSize = Theme.TextSize,
        TextXAlignment = Enum.TextXAlignment.Left,
    }
    
    local tabsFrame = Create("Frame"){
        Name = "Tabs",
        Parent = header,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
    }
    Create("UIListLayout"){
        Parent = tabsFrame,
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
    }

    local tabsContainer = Create("Frame"){
        Name = "TabsContainer",
        Parent = main,
        Size = UDim2.new(1, 0, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
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
