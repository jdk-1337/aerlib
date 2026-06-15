--[[
    AerLib - A Premium, Sleek, and Feature-Rich Roblox Luau UI Library
    Created with modern design principles (glassmorphism, smooth tweens, and complete customizability).
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Check run context to determine where to parent the ScreenGui
local ParentGui
if RunService:IsStudio() then
    ParentGui = LocalPlayer:WaitForChild("PlayerGui")
else
    local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
    ParentGui = success and coreGui or LocalPlayer:WaitForChild("PlayerGui")
end

local AerLib = {
    Theme = {
        Background = Color3.fromRGB(15, 17, 23),
        Sidebar = Color3.fromRGB(22, 24, 33),
        Element = Color3.fromRGB(30, 32, 44),
        ElementBorder = Color3.fromRGB(42, 45, 62),
        Accent = Color3.fromRGB(99, 102, 241), -- Sleek Indigo
        AccentHover = Color3.fromRGB(129, 140, 248),
        Text = Color3.fromRGB(243, 244, 246),
        TextSecondary = Color3.fromRGB(156, 163, 175),
        PlaceholderText = Color3.fromRGB(107, 114, 128),
        Success = Color3.fromRGB(34, 197, 94),
        Danger = Color3.fromRGB(239, 68, 68),
        Warning = Color3.fromRGB(245, 158, 11),
        Font = Enum.Font.GothamMedium,
        FontBold = Enum.Font.GothamBold
    },
    Windows = {},
    Toasts = {},
    Toggled = true,
    ToggleKey = Enum.KeyCode.RightControl
}

-- Utility Functions
local function CreateInstance(className, properties, parent)
    local obj = Instance.new(className)
    for prop, val in pairs(properties) do
        obj[prop] = val
    end
    if parent then
        obj.Parent = parent
    end
    return obj
end

local function Tween(object, duration, properties, easingStyle, easingDirection)
    local info = TweenInfo.new(
        duration or 0.2,
        easingStyle or Enum.EasingStyle.Quad,
        easingDirection or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(object, info, properties)
    tween:Play()
    return tween
end

local function MakeDraggable(dragFrame, targetFrame)
    local dragging, dragInput, dragStart, startPos
    
    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Tween(targetFrame, 0.1, {
                Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            })
        end
    end)
end

-- Toast Notification Manager
function AerLib:Toast(title, message, duration, type)
    type = type or "info"
    duration = duration or 3
    
    local toastColor = self.Theme.Accent
    if type == "success" then
        toastColor = self.Theme.Success
    elseif type == "danger" then
        toastColor = self.Theme.Danger
    elseif type == "warning" then
        toastColor = self.Theme.Warning
    end
    
    -- Ensure ToastContainer exists
    if not self.ToastContainer then
        self.ToastContainer = CreateInstance("ScreenGui", {
            Name = "AerLib_Toasts",
            ResetOnSpawn = false
        }, ParentGui)
        
        self.ToastList = CreateInstance("Frame", {
            Size = UDim2.new(0, 300, 1, -40),
            Position = UDim2.new(1, -320, 0, 20),
            BackgroundTransparency = 1
        }, self.ToastContainer)
        
        local layout = CreateInstance("UIListLayout", {
            Padding = UDim.new(0, 10),
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            SortOrder = Enum.SortOrder.LayoutOrder
        }, self.ToastList)
    end
    
    local toast = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 0), -- Animated height
        BackgroundColor3 = self.Theme.Background,
        BackgroundTransparency = 0.05,
        ClipsDescendants = true,
        LayoutOrder = #self.ToastList:GetChildren()
    }, self.ToastList)
    
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, toast)
    
    local border = CreateInstance("UIStroke", {
        Color = self.Theme.ElementBorder,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, toast)
    
    local accentBar = CreateInstance("Frame", {
        Size = UDim2.new(0, 4, 1, 0),
        BackgroundColor3 = toastColor,
        BorderSizePixel = 0
    }, toast)
    
    local contentFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, -14, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1
    }, toast)
    
    local toastTitle = CreateInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 6),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = self.Theme.Text,
        Font = self.Theme.FontBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    }, contentFrame)
    
    local toastMsg = CreateInstance("TextLabel", {
        Size = UDim2.new(1, 0, 1, -30),
        Position = UDim2.new(0, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = message,
        TextColor3 = self.Theme.TextSecondary,
        Font = self.Theme.Font,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    }, contentFrame)
    
    -- Animate Open
    Tween(toast, 0.3, { Size = UDim2.new(1, 0, 0, 70) })
    
    task.delay(duration, function()
        Tween(toast, 0.3, { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 })
        task.wait(0.3)
        toast:Destroy()
    end)
end

-- Window Class
local Window = {}
Window.__index = Window

function AerLib:CreateWindow(title, subtitle)
    local screenGui = CreateInstance("ScreenGui", {
        Name = "AerLib_" .. title:gsub("%s+", ""),
        ResetOnSpawn = false
    }, ParentGui)
    
    local mainFrame = CreateInstance("Frame", {
        Size = UDim2.new(0, 620, 0, 420),
        Position = UDim2.new(0.5, -310, 0.5, -210),
        BackgroundColor3 = self.Theme.Background,
        ClipsDescendants = true
    }, screenGui)
    
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, mainFrame)
    local mainStroke = CreateInstance("UIStroke", {
        Color = self.Theme.ElementBorder,
        Thickness = 1
    }, mainFrame)
    
    -- Title Bar / Drag Bar
    local titleBar = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundColor3 = self.Theme.Sidebar,
        BorderSizePixel = 0
    }, mainFrame)
    
    local titleText = CreateInstance("TextLabel", {
        Size = UDim2.new(0.5, 0, 0.6, 0),
        Position = UDim2.new(0, 16, 0.2, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = self.Theme.Text,
        Font = self.Theme.FontBold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left
    }, titleBar)
    
    if subtitle then
        titleText.Size = UDim2.new(0.5, 0, 0.4, 0)
        titleText.Position = UDim2.new(0, 16, 0.15, 0)
        
        CreateInstance("TextLabel", {
            Size = UDim2.new(0.5, 0, 0.3, 0),
            Position = UDim2.new(0, 16, 0.55, 0),
            BackgroundTransparency = 1,
            Text = subtitle,
            TextColor3 = self.Theme.TextSecondary,
            Font = self.Theme.Font,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left
        }, titleBar)
    end
    
    -- Close and Minimize buttons
    local buttonContainer = CreateInstance("Frame", {
        Size = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(1, -90, 0, 0),
        BackgroundTransparency = 1
    }, titleBar)
    
    local listLayout = CreateInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8)
    }, buttonContainer)
    
    local minBtn = CreateInstance("TextButton", {
        Size = UDim2.new(0, 24, 0, 24),
        BackgroundColor3 = self.Theme.Element,
        Text = "-",
        TextColor3 = self.Theme.TextSecondary,
        Font = self.Theme.FontBold,
        TextSize = 14,
        AutoButtonColor = false
    }, buttonContainer)
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, minBtn)
    CreateInstance("UIStroke", { Color = self.Theme.ElementBorder, Thickness = 1 }, minBtn)
    
    local closeBtn = CreateInstance("TextButton", {
        Size = UDim2.new(0, 24, 0, 24),
        BackgroundColor3 = self.Theme.Element,
        Text = "×",
        TextColor3 = self.Theme.TextSecondary,
        Font = self.Theme.FontBold,
        TextSize = 16,
        AutoButtonColor = false
    }, buttonContainer)
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, closeBtn)
    CreateInstance("UIStroke", { Color = self.Theme.ElementBorder, Thickness = 1 }, closeBtn)
    
    -- Sidebar (Tabs)
    local sidebar = CreateInstance("Frame", {
        Size = UDim2.new(0, 150, 1, -45),
        Position = UDim2.new(0, 0, 0, 45),
        BackgroundColor3 = self.Theme.Sidebar,
        BorderSizePixel = 0
    }, mainFrame)
    
    local sidebarScroll = CreateInstance("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -20),
        Position = UDim2.new(0, 0, 0, 10),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = self.Theme.ElementBorder,
        CanvasSize = UDim2.new(0, 0, 0, 0)
    }, sidebar)
    
    local tabLayout = CreateInstance("UIListLayout", {
        Padding = UDim.new(0, 6),
        HorizontalAlignment = Enum.HorizontalAlignment.Center
    }, sidebarScroll)
    
    -- Content Container
    local container = CreateInstance("Frame", {
        Size = UDim2.new(1, -150, 1, -45),
        Position = UDim2.new(0, 150, 0, 45),
        BackgroundTransparency = 1
    }, mainFrame)
    
    -- Toggle visibility handling
    local isMinimized = false
    minBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            Tween(mainFrame, 0.3, { Size = UDim2.new(0, 620, 0, 45) })
            sidebar.Visible = false
            container.Visible = false
            minBtn.Text = "+"
        else
            Tween(mainFrame, 0.3, { Size = UDim2.new(0, 620, 0, 420) })
            task.delay(0.1, function()
                sidebar.Visible = true
                container.Visible = true
            end)
            minBtn.Text = "-"
        end
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- Toggle UI Global Bind
    local connection
    connection = UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == self.ToggleKey then
            self.Toggled = not self.Toggled
            screenGui.Enabled = self.Toggled
        end
    end)
    
    screenGui.Destroying:Connect(function()
        connection:Disconnect()
    end)
    
    MakeDraggable(titleBar, mainFrame)
    
    local windowObj = setmetatable({
        Gui = screenGui,
        MainFrame = mainFrame,
        Container = container,
        SidebarScroll = sidebarScroll,
        Tabs = {},
        ActiveTab = nil,
        Theme = self.Theme
    }, Window)
    
    table.insert(self.Windows, windowObj)
    return windowObj
end

-- Tab Class
local Tab = {}
Tab.__index = Tab

function Window:CreateTab(name)
    local page = CreateInstance("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.Theme.ElementBorder,
        CanvasSize = UDim2.new(0, 0, 0, 0)
    }, self.Container)
    
    local layout = CreateInstance("UIListLayout", {
        Padding = UDim.new(0, 10),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder
    }, page)
    
    -- Auto-resize scroll canvas size
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
    
    -- Add padding
    CreateInstance("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10)
    }, page)
    
    -- Tab Button
    local tabBtn = CreateInstance("TextButton", {
        Size = UDim2.new(0, 130, 0, 32),
        BackgroundColor3 = self.Theme.Sidebar,
        Text = name,
        TextColor3 = self.Theme.TextSecondary,
        Font = self.Theme.Font,
        TextSize = 13,
        AutoButtonColor = false
    }, self.SidebarScroll)
    
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, tabBtn)
    local tabStroke = CreateInstance("UIStroke", {
        Color = Color3.fromRGB(0, 0, 0),
        Thickness = 1,
        Transparency = 1
    }, tabBtn)
    
    local tabObj = setmetatable({
        Name = name,
        Page = page,
        Button = tabBtn,
        ButtonStroke = tabStroke,
        Window = self
    }, Tab)
    
    tabBtn.MouseEnter:Connect(function()
        if self.ActiveTab ~= tabObj then
            Tween(tabBtn, 0.15, { TextColor3 = self.Theme.Text })
        end
    end)
    
    tabBtn.MouseLeave:Connect(function()
        if self.ActiveTab ~= tabObj then
            Tween(tabBtn, 0.15, { TextColor3 = self.Theme.TextSecondary })
        end
    end)
    
    tabBtn.MouseButton1Click:Connect(function()
        self:SelectTab(tabObj)
    end)
    
    -- Select first tab automatically
    if not self.ActiveTab then
        self:SelectTab(tabObj)
    end
    
    -- Adjust Sidebar Scrolling Canvas
    self.SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, #self.SidebarScroll:GetChildren() * 38)
    
    return tabObj
end

function Window:SelectTab(tabObj)
    if self.ActiveTab then
        self.ActiveTab.Page.Visible = false
        Tween(self.ActiveTab.Button, 0.2, { BackgroundColor3 = self.Theme.Sidebar, TextColor3 = self.Theme.TextSecondary })
        Tween(self.ActiveTab.ButtonStroke, 0.2, { Transparency = 1 })
    end
    
    self.ActiveTab = tabObj
    tabObj.Page.Visible = true
    Tween(tabObj.Button, 0.2, { BackgroundColor3 = self.Theme.Element, TextColor3 = self.Theme.Accent })
    Tween(tabObj.ButtonStroke, 0.2, { Color = self.Theme.ElementBorder, Transparency = 0 })
end

-- Section Class
local Section = {}
Section.__index = Section

function Tab:CreateSection(name)
    local sectionContainer = CreateInstance("Frame", {
        Size = UDim2.new(0.92, 0, 0, 40),
        BackgroundColor3 = self.Window.Theme.Sidebar,
        BackgroundTransparency = 0.3,
        LayoutOrder = #self.Page:GetChildren()
    }, self.Page)
    
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, sectionContainer)
    CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 1 }, sectionContainer)
    
    local sectionLayout = CreateInstance("UIListLayout", {
        Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder
    }, sectionContainer)
    
    CreateInstance("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10)
    }, sectionContainer)
    
    local headerText = CreateInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = name:upper(),
        TextColor3 = self.Window.Theme.Accent,
        Font = self.Window.Theme.FontBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 0
    }, sectionContainer)
    
    sectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sectionContainer.Size = UDim2.new(0.92, 0, 0, sectionLayout.AbsoluteContentSize.Y + 20)
    end)
    
    return setmetatable({
        Container = sectionContainer,
        Tab = self,
        Window = self.Window
    }, Section)
end

-- Element Builders

-- Button
function Section:CreateButton(text, callback)
    local btnFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = self.Window.Theme.Element,
        LayoutOrder = #self.Container:GetChildren()
    }, self.Container)
    
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, btnFrame)
    local border = CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 1 }, btnFrame)
    
    local textLabel = CreateInstance("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Window.Theme.Text,
        Font = self.Window.Theme.Font,
        TextSize = 13
    }, btnFrame)
    
    local button = CreateInstance("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false
    }, btnFrame)
    
    -- Visual Feedback
    button.MouseEnter:Connect(function()
        Tween(btnFrame, 0.15, { BackgroundColor3 = self.Window.Theme.Accent })
        Tween(border, 0.15, { Color = self.Window.Theme.AccentHover })
    end)
    
    button.MouseLeave:Connect(function()
        Tween(btnFrame, 0.15, { BackgroundColor3 = self.Window.Theme.Element })
        Tween(border, 0.15, { Color = self.Window.Theme.ElementBorder })
    end)
    
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Tween(btnFrame, 0.05, { Size = UDim2.new(0.98, 0, 0, 34) })
        end
    end)
    
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Tween(btnFrame, 0.1, { Size = UDim2.new(1, 0, 0, 36) })
        end
    end)
    
    button.MouseButton1Click:Connect(function()
        task.spawn(callback)
    end)
    
    return {
        SetText = function(val)
            textLabel.Text = val
        end
    }
end

-- Toggle
function Section:CreateToggle(text, default, callback)
    local state = default or false
    
    local toggleFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = self.Window.Theme.Element,
        LayoutOrder = #self.Container:GetChildren()
    }, self.Container)
    
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, toggleFrame)
    local border = CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 1 }, toggleFrame)
    
    local textLabel = CreateInstance("TextLabel", {
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Window.Theme.Text,
        Font = self.Window.Theme.Font,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    }, toggleFrame)
    
    -- Slider Switch Track
    local track = CreateInstance("Frame", {
        Size = UDim2.new(0, 38, 0, 20),
        Position = UDim2.new(1, -48, 0.5, -10),
        BackgroundColor3 = state and self.Window.Theme.Accent or self.Window.Theme.Sidebar
    }, toggleFrame)
    CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
    local trackBorder = CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 1 }, track)
    
    -- Slider Knob
    local knob = CreateInstance("Frame", {
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(state and 0.55 or 0.08, 0, 0.5, -7),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    }, track)
    CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
    
    local clickArea = CreateInstance("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = ""
    }, toggleFrame)
    
    local function UpdateToggle(newState)
        state = newState
        local targetKnobPos = state and 0.55 or 0.08
        local targetTrackColor = state and self.Window.Theme.Accent or self.Window.Theme.Sidebar
        
        Tween(knob, 0.2, { Position = UDim2.new(targetKnobPos, 0, 0.5, -7) })
        Tween(track, 0.2, { BackgroundColor3 = targetTrackColor })
        task.spawn(callback, state)
    end
    
    clickArea.MouseButton1Click:Connect(function()
        UpdateToggle(not state)
    end)
    
    return {
        SetValue = UpdateToggle,
        GetValue = function() return state end
    }
end

-- Slider
function Section:CreateSlider(text, min, max, default, decimals, callback)
    decimals = decimals or 0
    local value = math.clamp(default or min, min, max)
    
    local sliderFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = self.Window.Theme.Element,
        LayoutOrder = #self.Container:GetChildren()
    }, self.Container)
    
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, sliderFrame)
    local border = CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 1 }, sliderFrame)
    
    local titleLabel = CreateInstance("TextLabel", {
        Size = UDim2.new(0.5, 0, 0, 24),
        Position = UDim2.new(0, 10, 0, 4),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Window.Theme.Text,
        Font = self.Window.Theme.Font,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    }, sliderFrame)
    
    local valueLabel = CreateInstance("TextLabel", {
        Size = UDim2.new(0.4, 0, 0, 24),
        Position = UDim2.new(1, -95, 0, 4),
        BackgroundTransparency = 1,
        Text = tostring(value),
        TextColor3 = self.Window.Theme.Accent,
        Font = self.Window.Theme.FontBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right
    }, sliderFrame)
    
    -- Track background
    local track = CreateInstance("Frame", {
        Size = UDim2.new(1, -20, 0, 6),
        Position = UDim2.new(0, 10, 0, 36),
        BackgroundColor3 = self.Window.Theme.Sidebar,
        BorderSizePixel = 0
    }, sliderFrame)
    CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
    
    -- Filled progress track
    local progressScale = (value - min) / (max - min)
    local progress = CreateInstance("Frame", {
        Size = UDim2.new(progressScale, 0, 1, 0),
        BackgroundColor3 = self.Window.Theme.Accent,
        BorderSizePixel = 0
    }, track)
    CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, progress)
    
    -- Knob
    local knob = CreateInstance("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(progressScale, -6, 0.5, -6),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    }, track)
    CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
    CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 1 }, knob)
    
    local active = false
    
    local function UpdateSlider(input)
        local inputX = input.Position.X
        local trackAbsPos = track.AbsolutePosition.X
        local trackAbsSize = track.AbsoluteSize.X
        
        local percentage = math.clamp((inputX - trackAbsPos) / trackAbsSize, 0, 1)
        local rawValue = min + (max - min) * percentage
        
        -- Rounding logic
        local factor = 10^decimals
        value = math.round(rawValue * factor) / factor
        value = math.clamp(value, min, max)
        
        valueLabel.Text = tostring(value)
        local visualScale = (value - min) / (max - min)
        progress.Size = UDim2.new(visualScale, 0, 1, 0)
        knob.Position = UDim2.new(visualScale, -6, 0.5, -6)
        
        task.spawn(callback, value)
    end
    
    sliderFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            active = true
            UpdateSlider(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            active = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if active and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateSlider(input)
        end
    end)
    
    return {
        SetValue = function(val)
            val = math.clamp(val, min, max)
            local factor = 10^decimals
            value = math.round(val * factor) / factor
            valueLabel.Text = tostring(value)
            local visualScale = (value - min) / (max - min)
            Tween(progress, 0.15, { Size = UDim2.new(visualScale, 0, 1, 0) })
            Tween(knob, 0.15, { Position = UDim2.new(visualScale, -6, 0.5, -6) })
            task.spawn(callback, value)
        end,
        GetValue = function() return value end
    }
end

-- Dropdown
function Section:CreateDropdown(text, list, default, callback)
    local selected = default or list[1]
    local isOpened = false
    
    local dropdownFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = self.Window.Theme.Element,
        ClipsDescendants = true,
        LayoutOrder = #self.Container:GetChildren()
    }, self.Container)
    
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, dropdownFrame)
    local border = CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 1 }, dropdownFrame)
    
    local titleText = CreateInstance("TextLabel", {
        Size = UDim2.new(0.6, 0, 0, 38),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = text .. ": " .. tostring(selected),
        TextColor3 = self.Window.Theme.Text,
        Font = self.Window.Theme.Font,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    }, dropdownFrame)
    
    local arrow = CreateInstance("TextLabel", {
        Size = UDim2.new(0, 38, 0, 38),
        Position = UDim2.new(1, -38, 0, 0),
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = self.Window.Theme.TextSecondary,
        Font = self.Window.Theme.FontBold,
        TextSize = 10
    }, dropdownFrame)
    
    local clickArea = CreateInstance("TextButton", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        Text = ""
    }, dropdownFrame)
    
    -- List container for options
    local listContainer = CreateInstance("Frame", {
        Size = UDim2.new(1, -16, 0, 0),
        Position = UDim2.new(0, 8, 0, 38),
        BackgroundTransparency = 1
    }, dropdownFrame)
    
    local listLayout = CreateInstance("UIListLayout", {
        Padding = UDim.new(0, 4)
    }, listContainer)
    
    local options = {}
    
    local function ToggleDropdown(state)
        isOpened = state
        local targetHeight = isOpened and (38 + listLayout.AbsoluteContentSize.Y + 12) or 38
        local targetArrowRot = isOpened and 180 or 0
        
        Tween(dropdownFrame, 0.2, { Size = UDim2.new(1, 0, 0, targetHeight) })
        Tween(arrow, 0.2, { Rotation = targetArrowRot })
    end
    
    local function SelectOption(val)
        selected = val
        titleText.Text = text .. ": " .. tostring(selected)
        ToggleDropdown(false)
        task.spawn(callback, selected)
    end
    
    local function BuildOptions()
        -- Clear old options
        for _, opt in pairs(options) do
            opt:Destroy()
        end
        options = {}
        
        for _, item in ipairs(list) do
            local itemBtn = CreateInstance("TextButton", {
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundColor3 = self.Window.Theme.Sidebar,
                Text = tostring(item),
                TextColor3 = item == selected and self.Window.Theme.Accent or self.Window.Theme.TextSecondary,
                Font = self.Window.Theme.Font,
                TextSize = 12,
                AutoButtonColor = false
            }, listContainer)
            CreateInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, itemBtn)
            CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 0.5 }, itemBtn)
            
            itemBtn.MouseEnter:Connect(function()
                Tween(itemBtn, 0.15, { BackgroundColor3 = self.Window.Theme.Element, TextColor3 = self.Window.Theme.Text })
            end)
            
            itemBtn.MouseLeave:Connect(function()
                Tween(itemBtn, 0.15, { 
                    BackgroundColor3 = self.Window.Theme.Sidebar,
                    TextColor3 = item == selected and self.Window.Theme.Accent or self.Window.Theme.TextSecondary 
                })
            end)
            
            itemBtn.MouseButton1Click:Connect(function()
                SelectOption(item)
            end)
            
            table.insert(options, itemBtn)
        end
    end
    
    clickArea.MouseButton1Click:Connect(function()
        ToggleDropdown(not isOpened)
    end)
    
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if isOpened then
            dropdownFrame.Size = UDim2.new(1, 0, 0, 38 + listLayout.AbsoluteContentSize.Y + 12)
        end
    end)
    
    BuildOptions()
    
    return {
        SetValue = SelectOption,
        GetValue = function() return selected end,
        SetOptions = function(newList)
            list = newList
            BuildOptions()
            if isOpened then
                ToggleDropdown(true)
            end
        end
    }
end

-- TextBox
function Section:CreateTextBox(text, placeholder, callback)
    local textBoxFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = self.Window.Theme.Element,
        LayoutOrder = #self.Container:GetChildren()
    }, self.Container)
    
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, textBoxFrame)
    local border = CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 1 }, textBoxFrame)
    
    local titleLabel = CreateInstance("TextLabel", {
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Window.Theme.Text,
        Font = self.Window.Theme.Font,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    }, textBoxFrame)
    
    local inputBox = CreateInstance("TextBox", {
        Size = UDim2.new(0, 160, 0, 26),
        Position = UDim2.new(1, -170, 0.5, -13),
        BackgroundColor3 = self.Window.Theme.Sidebar,
        Text = "",
        PlaceholderText = placeholder or "Type here...",
        PlaceholderColor3 = self.Window.Theme.PlaceholderText,
        TextColor3 = self.Window.Theme.Text,
        ClearTextOnFocus = false,
        Font = self.Window.Theme.Font,
        TextSize = 12
    }, textBoxFrame)
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, inputBox)
    local inputBorder = CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 1 }, inputBox)
    
    inputBox.Focused:Connect(function()
        Tween(inputBorder, 0.15, { Color = self.Window.Theme.Accent })
    end)
    
    inputBox.FocusLost:Connect(function(enterPressed)
        Tween(inputBorder, 0.15, { Color = self.Window.Theme.ElementBorder })
        task.spawn(callback, inputBox.Text, enterPressed)
    end)
    
    return {
        SetText = function(val)
            inputBox.Text = val
            task.spawn(callback, val, false)
        end,
        GetText = function() return inputBox.Text end
    }
end

-- Keybind
function Section:CreateKeybind(text, defaultKey, callback)
    local bind = defaultKey or Enum.KeyCode.E
    local binding = false
    
    local keybindFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = self.Window.Theme.Element,
        LayoutOrder = #self.Container:GetChildren()
    }, self.Container)
    
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, keybindFrame)
    local border = CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 1 }, keybindFrame)
    
    local titleLabel = CreateInstance("TextLabel", {
        Size = UDim2.new(0.6, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Window.Theme.Text,
        Font = self.Window.Theme.Font,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    }, keybindFrame)
    
    local bindBox = CreateInstance("TextButton", {
        Size = UDim2.new(0, 80, 0, 24),
        Position = UDim2.new(1, -90, 0.5, -12),
        BackgroundColor3 = self.Window.Theme.Sidebar,
        Text = bind and bind.Name or "NONE",
        TextColor3 = self.Window.Theme.Accent,
        Font = self.Window.Theme.FontBold,
        TextSize = 11,
        AutoButtonColor = false
    }, keybindFrame)
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, bindBox)
    local bindBorder = CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 1 }, bindBox)
    
    bindBox.MouseButton1Click:Connect(function()
        binding = true
        bindBox.Text = "..."
        Tween(bindBorder, 0.15, { Color = self.Window.Theme.Accent })
    end)
    
    local inputConn
    inputConn = UserInputService.InputBegan:Connect(function(input, processed)
        if binding and not processed then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                bind = input.KeyCode
                binding = false
                bindBox.Text = bind.Name
                Tween(bindBorder, 0.15, { Color = self.Window.Theme.ElementBorder })
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                -- clicking away/resetting
                bind = nil
                binding = false
                bindBox.Text = "NONE"
                Tween(bindBorder, 0.15, { Color = self.Window.Theme.ElementBorder })
            end
        elseif not binding and not processed and bind and input.KeyCode == bind then
            task.spawn(callback)
        end
    end)
    
    keybindFrame.Destroying:Connect(function()
        inputConn:Disconnect()
    end)
    
    return {
        SetKey = function(key)
            bind = key
            bindBox.Text = bind and bind.Name or "NONE"
        end,
        GetKey = function() return bind end
    }
end

-- ColorPicker
function Section:CreateColorPicker(text, defaultColor, callback)
    local selectedColor = defaultColor or Color3.fromRGB(99, 102, 241)
    local isOpened = false
    
    local pickerFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = self.Window.Theme.Element,
        ClipsDescendants = true,
        LayoutOrder = #self.Container:GetChildren()
    }, self.Container)
    
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, pickerFrame)
    local border = CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 1 }, pickerFrame)
    
    local titleLabel = CreateInstance("TextLabel", {
        Size = UDim2.new(0.6, 0, 0, 38),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Window.Theme.Text,
        Font = self.Window.Theme.Font,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    }, pickerFrame)
    
    -- Color Preview Block
    local preview = CreateInstance("Frame", {
        Size = UDim2.new(0, 24, 0, 20),
        Position = UDim2.new(1, -34, 0.5, -10),
        BackgroundColor3 = selectedColor
    }, pickerFrame)
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, preview)
    local previewBorder = CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 1 }, preview)
    
    local clickArea = CreateInstance("TextButton", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        Text = ""
    }, pickerFrame)
    
    -- Expandable Color Adjustment Container (RGB Sliders)
    local rVal, gVal, bVal = math.round(selectedColor.R*255), math.round(selectedColor.G*255), math.round(selectedColor.B*255)
    
    local controlsFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, -20, 0, 95),
        Position = UDim2.new(0, 10, 0, 38),
        BackgroundTransparency = 1
    }, pickerFrame)
    
    local layout = CreateInstance("UIListLayout", {
        Padding = UDim.new(0, 4)
    }, controlsFrame)
    
    local function TogglePicker(state)
        isOpened = state
        local targetHeight = isOpened and 140 or 38
        Tween(pickerFrame, 0.2, { Size = UDim2.new(1, 0, 0, targetHeight) })
    end
    
    clickArea.MouseButton1Click:Connect(function()
        TogglePicker(not isOpened)
    end)
    
    local function UpdatePicker()
        selectedColor = Color3.fromRGB(rVal, gVal, bVal)
        preview.BackgroundColor3 = selectedColor
        task.spawn(callback, selectedColor)
    end
    
    -- Helper to build slider row
    local function CreateRGBSlider(name, max, defaultVal, colorTint, onUpdate)
        local row = CreateInstance("Frame", {
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundColor3 = self.Window.Theme.Sidebar
        }, controlsFrame)
        CreateInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, row)
        CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 0.5 }, row)
        
        local label = CreateInstance("TextLabel", {
            Size = UDim2.new(0, 20, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = colorTint,
            Font = self.Window.Theme.FontBold,
            TextSize = 11
        }, row)
        
        local track = CreateInstance("Frame", {
            Size = UDim2.new(1, -70, 0, 4),
            Position = UDim2.new(0, 32, 0.5, -2),
            BackgroundColor3 = self.Window.Theme.Element
        }, row)
        CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
        
        local progress = CreateInstance("Frame", {
            Size = UDim2.new(defaultVal/max, 0, 1, 0),
            BackgroundColor3 = colorTint
        }, track)
        CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, progress)
        
        local knob = CreateInstance("Frame", {
            Size = UDim2.new(0, 10, 0, 10),
            Position = UDim2.new(defaultVal/max, -5, 0.5, -5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        }, track)
        CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
        
        local valLabel = CreateInstance("TextLabel", {
            Size = UDim2.new(0, 30, 1, 0),
            Position = UDim2.new(1, -34, 0, 0),
            BackgroundTransparency = 1,
            Text = tostring(defaultVal),
            TextColor3 = self.Window.Theme.TextSecondary,
            Font = self.Window.Theme.Font,
            TextSize = 11
        }, row)
        
        local dragging = false
        
        local function UpdateSlider(input)
            local percentage = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local currentVal = math.round(percentage * max)
            
            progress.Size = UDim2.new(percentage, 0, 1, 0)
            knob.Position = UDim2.new(percentage, -5, 0.5, -5)
            valLabel.Text = tostring(currentVal)
            
            onUpdate(currentVal)
        end
        
        row.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                UpdateSlider(input)
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                UpdateSlider(input)
            end
        end)
    end
    
    CreateRGBSlider("R", 255, rVal, Color3.fromRGB(239, 68, 68), function(val)
        rVal = val
        UpdatePicker()
    end)
    
    CreateRGBSlider("G", 255, gVal, Color3.fromRGB(34, 197, 94), function(val)
        gVal = val
        UpdatePicker()
    end)
    
    CreateRGBSlider("B", 255, bVal, Color3.fromRGB(59, 130, 246), function(val)
        bVal = val
        UpdatePicker()
    end)
    
    return {
        SetValue = function(color)
            rVal, gVal, bVal = math.round(color.R*255), math.round(color.G*255), math.round(color.B*255)
            UpdatePicker()
        end,
        GetValue = function() return selectedColor end
    }
end

-- Label
function Section:CreateLabel(text)
    local labelFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
        LayoutOrder = #self.Container:GetChildren()
    }, self.Container)
    
    local label = CreateInstance("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Window.Theme.TextSecondary,
        Font = self.Window.Theme.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    }, labelFrame)
    
    return {
        SetText = function(val)
            label.Text = val
        end
    }
end

-- Paragraph
function Section:CreateParagraph(title, content)
    local paragraphFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = self.Window.Theme.Element,
        LayoutOrder = #self.Container:GetChildren()
    }, self.Container)
    
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, paragraphFrame)
    local border = CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 1 }, paragraphFrame)
    
    local titleLabel = CreateInstance("TextLabel", {
        Size = UDim2.new(1, -20, 0, 22),
        Position = UDim2.new(0, 10, 0, 4),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = self.Window.Theme.Text,
        Font = self.Window.Theme.FontBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    }, paragraphFrame)
    
    local contentLabel = CreateInstance("TextLabel", {
        Size = UDim2.new(1, -20, 1, -28),
        Position = UDim2.new(0, 10, 0, 24),
        BackgroundTransparency = 1,
        Text = content,
        TextColor3 = self.Window.Theme.TextSecondary,
        Font = self.Window.Theme.Font,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    }, paragraphFrame)
    
    -- Auto-height adjustment based on content
    local function UpdateHeight()
        local textBounds = contentLabel.TextBounds
        local height = math.max(60, textBounds.Y + 32)
        paragraphFrame.Size = UDim2.new(1, 0, 0, height)
    end
    
    contentLabel:GetPropertyChangedSignal("TextBounds"):Connect(UpdateHeight)
    UpdateHeight()
    
    return {
        SetTitle = function(val) titleLabel.Text = val end,
        SetContent = function(val) 
            contentLabel.Text = val 
            UpdateHeight()
        end
    }
end

return AerLib
