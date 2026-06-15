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
        Background = Color3.fromRGB(13, 14, 20),
        Sidebar = Color3.fromRGB(18, 20, 29),
        Element = Color3.fromRGB(24, 27, 38),
        ElementBorder = Color3.fromRGB(38, 41, 56),
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

local function ColorToHex(color)
    local r = math.round(color.R * 255)
    local g = math.round(color.G * 255)
    local b = math.round(color.B * 255)
    return string.format("#%02X%02X%02X", r, g, b)
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

-- Global theme manager to update accents dynamically across all windows and custom UIGradients
function AerLib:SetAccentColor(newAccent, newHover)
    self.Theme.Accent = newAccent
    self.Theme.AccentHover = newHover or newAccent
    
    for _, win in ipairs(self.Windows) do
        if win.ActiveTab then
            Tween(win.ActiveTab.Button, 0.2, { TextColor3 = newAccent })
        end
        for _, desc in ipairs(win.MainFrame:GetDescendants()) do
            if desc:IsA("UIGradient") and desc.Name == "AccentGradient" then
                desc.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, newAccent),
                    ColorSequenceKeypoint.new(1, self.Theme.AccentHover)
                })
            elseif desc:IsA("UIStroke") and desc.Name == "AccentGlow" then
                desc.Color = newAccent
            elseif desc:IsA("TextLabel") and desc.Name == "AccentValue" then
                desc.TextColor3 = newAccent
            end
        end
    end
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
        Size = UDim2.new(0, 630, 0, 430),
        Position = UDim2.new(0.5, -315, 0.5, -215),
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
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = self.Theme.Sidebar,
        BorderSizePixel = 0
    }, mainFrame)
    
    -- Sleek Header Gradient
    local headerGradient = CreateInstance("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 33, 46)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 20, 29))
        }),
        Rotation = 0
    }, titleBar)
    
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
        Size = UDim2.new(0, 150, 1, -48),
        Position = UDim2.new(0, 0, 0, 48),
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
        Size = UDim2.new(1, -150, 1, -48),
        Position = UDim2.new(0, 150, 0, 48),
        BackgroundTransparency = 1
    }, mainFrame)
    
    -- Toggle visibility handling
    local isMinimized = false
    minBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            Tween(mainFrame, 0.3, { Size = UDim2.new(0, 630, 0, 48) })
            sidebar.Visible = false
            container.Visible = false
            minBtn.Text = "+"
        else
            Tween(mainFrame, 0.3, { Size = UDim2.new(0, 630, 0, 430) })
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
    
    -- Premium slide-up animation effect on tab switch
    tabObj.Page.Position = UDim2.new(0, 0, 0, 15)
    Tween(tabObj.Page, 0.25, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
    
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
    headerText.Name = "AccentValue"
    
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
    
    -- Custom UIGradient for active/hover states
    local btnGradient = CreateInstance("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, self.Window.Theme.Element),
            ColorSequenceKeypoint.new(1, self.Window.Theme.Element)
        })
    }, btnFrame)
    btnGradient.Name = "BtnGrad"
    
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
    
    -- Hover effect: border glows accent color and background applies smooth gradient
    button.MouseEnter:Connect(function()
        Tween(border, 0.15, { Color = self.Window.Theme.Accent })
        btnGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, self.Window.Theme.Element),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 39, 54))
        })
    end)
    
    button.MouseLeave:Connect(function()
        Tween(border, 0.15, { Color = self.Window.Theme.ElementBorder })
        btnGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, self.Window.Theme.Element),
            ColorSequenceKeypoint.new(1, self.Window.Theme.Element)
        })
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
    
    -- Switch Track
    local track = CreateInstance("Frame", {
        Size = UDim2.new(0, 38, 0, 20),
        Position = UDim2.new(1, -48, 0.5, -10),
        BackgroundColor3 = state and self.Window.Theme.Accent or self.Window.Theme.Sidebar
    }, toggleFrame)
    CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
    local trackBorder = CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 1 }, track)
    
    local trackGradient = CreateInstance("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, self.Window.Theme.Accent),
            ColorSequenceKeypoint.new(1, self.Window.Theme.AccentHover)
        }),
        Enabled = state
    }, track)
    trackGradient.Name = "AccentGradient"
    
    -- Knob
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
    
    -- Glow effect on hover
    clickArea.MouseEnter:Connect(function()
        Tween(border, 0.15, { Color = self.Window.Theme.Accent })
    end)
    clickArea.MouseLeave:Connect(function()
        Tween(border, 0.15, { Color = self.Window.Theme.ElementBorder })
    end)
    
    local function UpdateToggle(newState)
        state = newState
        local targetKnobPos = state and 0.55 or 0.08
        local targetTrackColor = state and self.Window.Theme.Accent or self.Window.Theme.Sidebar
        
        trackGradient.Enabled = state
        Tween(knob, 0.2, { Position = UDim2.new(targetKnobPos, 0, 0.5, -7) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
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
    valueLabel.Name = "AccentValue"
    
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
    
    local progressGradient = CreateInstance("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, self.Window.Theme.Accent),
            ColorSequenceKeypoint.new(1, self.Window.Theme.AccentHover)
        })
    }, progress)
    progressGradient.Name = "AccentGradient"
    
    -- Knob
    local knob = CreateInstance("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(progressScale, -6, 0.5, -6),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    }, track)
    CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
    CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 1 }, knob)
    
    local active = false
    
    sliderFrame.MouseEnter:Connect(function()
        Tween(border, 0.15, { Color = self.Window.Theme.Accent })
    end)
    sliderFrame.MouseLeave:Connect(function()
        Tween(border, 0.15, { Color = self.Window.Theme.ElementBorder })
    end)
    
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
    
    dropdownFrame.MouseEnter:Connect(function()
        Tween(border, 0.15, { Color = self.Window.Theme.Accent })
    end)
    dropdownFrame.MouseLeave:Connect(function()
        Tween(border, 0.15, { Color = self.Window.Theme.ElementBorder })
    end)
    
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
    
    textBoxFrame.MouseEnter:Connect(function()
        Tween(border, 0.15, { Color = self.Window.Theme.Accent })
    end)
    textBoxFrame.MouseLeave:Connect(function()
        if not inputBox:IsFocused() then
            Tween(border, 0.15, { Color = self.Window.Theme.ElementBorder })
        end
    end)
    
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
    bindBox.Name = "AccentValue"
    
    keybindFrame.MouseEnter:Connect(function()
        Tween(border, 0.15, { Color = self.Window.Theme.Accent })
    end)
    keybindFrame.MouseLeave:Connect(function()
        Tween(border, 0.15, { Color = self.Window.Theme.ElementBorder })
    end)
    
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

-- COLOR PICKER REDESIGN: HSV rainbow spectrum controller decks with Hex/RGB text preview swatches
function Section:CreateColorPicker(text, defaultColor, callback)
    local h, s, v = Color3.toHSV(defaultColor or Color3.fromRGB(99, 102, 241))
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
    
    -- Swatch Preview
    local preview = CreateInstance("Frame", {
        Size = UDim2.new(0, 24, 0, 20),
        Position = UDim2.new(1, -34, 0.5, -10),
        BackgroundColor3 = Color3.fromHSV(h, s, v)
    }, pickerFrame)
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, preview)
    local previewBorder = CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 1 }, preview)
    
    local clickArea = CreateInstance("TextButton", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        Text = ""
    }, pickerFrame)
    
    pickerFrame.MouseEnter:Connect(function()
        Tween(border, 0.15, { Color = self.Window.Theme.Accent })
    end)
    pickerFrame.MouseLeave:Connect(function()
        Tween(border, 0.15, { Color = self.Window.Theme.ElementBorder })
    end)
    
    -- Layout Grid when expanded
    local contents = CreateInstance("Frame", {
        Size = UDim2.new(1, -20, 0, 105),
        Position = UDim2.new(0, 10, 0, 42),
        BackgroundTransparency = 1
    }, pickerFrame)
    
    -- Color Info Side-deck (Preview details block)
    local details = CreateInstance("Frame", {
        Size = UDim2.new(0, 110, 1, 0),
        BackgroundColor3 = self.Window.Theme.Sidebar,
        BorderSizePixel = 0
    }, contents)
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, details)
    CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 0.5 }, details)
    
    local swatch = CreateInstance("Frame", {
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0.5, -20, 0, 10),
        BackgroundColor3 = Color3.fromHSV(h, s, v)
    }, details)
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 20) }, swatch) -- Rounded color sphere
    local swatchBorder = CreateInstance("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.5, Thickness = 1.5 }, swatch)
    
    local hexLabel = CreateInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, 56),
        BackgroundTransparency = 1,
        Text = ColorToHex(Color3.fromHSV(h, s, v)),
        TextColor3 = self.Window.Theme.Text,
        Font = self.Window.Theme.FontBold,
        TextSize = 10
    }, details)
    
    local rgbLabel = CreateInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 0, 72),
        BackgroundTransparency = 1,
        Text = math.round(preview.BackgroundColor3.R*255)..", "..math.round(preview.BackgroundColor3.G*255)..", "..math.round(preview.BackgroundColor3.B*255),
        TextColor3 = self.Window.Theme.TextSecondary,
        Font = self.Window.Theme.Font,
        TextSize = 9
    }, details)
    
    -- Sliders Deck (Hue, Saturation, Value)
    local sliders = CreateInstance("Frame", {
        Size = UDim2.new(1, -125, 1, 0),
        Position = UDim2.new(0, 125, 0, 0),
        BackgroundTransparency = 1
    }, contents)
    
    local slidersLayout = CreateInstance("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, sliders)
    
    local function TogglePicker(state)
        isOpened = state
        local targetHeight = isOpened and 160 or 38
        Tween(pickerFrame, 0.25, { Size = UDim2.new(1, 0, 0, targetHeight) }, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
    end
    
    clickArea.MouseButton1Click:Connect(function()
        TogglePicker(not isOpened)
    end)
    
    -- Dynamic update handler
    local satGradient, valGradient
    
    local function UpdateColor()
        local color = Color3.fromHSV(h, s, v)
        preview.BackgroundColor3 = color
        swatch.BackgroundColor3 = color
        hexLabel.Text = ColorToHex(color)
        rgbLabel.Text = math.round(color.R*255)..", "..math.round(color.G*255)..", "..math.round(color.B*255)
        
        -- Update gradients dynamically to reflect current HUE
        if satGradient then
            satGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(h, 1, 1))
            })
        end
        if valGradient then
            valGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(h, 1, 1))
            })
        end
        
        task.spawn(callback, color)
    end
    
    -- Custom Slider track constructor
    local function AddPickerSlider(name, defaultPct, layoutOrder, colorSequence, onSlide)
        local row = CreateInstance("Frame", {
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundColor3 = self.Window.Theme.Sidebar,
            LayoutOrder = layoutOrder
        }, sliders)
        CreateInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, row)
        CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 0.5 }, row)
        
        local sliderLabel = CreateInstance("TextLabel", {
            Size = UDim2.new(0, 20, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = self.Window.Theme.TextSecondary,
            Font = self.Window.Theme.FontBold,
            TextSize = 11
        }, row)
        
        local track = CreateInstance("Frame", {
            Size = UDim2.new(1, -44, 0, 8),
            Position = UDim2.new(0, 36, 0.5, -4),
            BackgroundColor3 = Color3.fromRGB(0,0,0)
        }, row)
        CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
        
        local trackGrad = CreateInstance("UIGradient", {
            Color = colorSequence
        }, track)
        
        local knob = CreateInstance("Frame", {
            Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new(defaultPct, -6, 0.5, -6),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        }, track)
        CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
        CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 1 }, knob)
        
        local active = false
        
        local function UpdateSlide(input)
            local percentage = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            knob.Position = UDim2.new(percentage, -6, 0.5, -6)
            onSlide(percentage)
        end
        
        row.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                active = true
                UpdateSlide(input)
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                active = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if active and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                UpdateSlide(input)
            end
        end)
        
        return trackGrad, knob, track
    end
    
    -- Hue Slider (Rainbow)
    local rainbowColors = {
        ColorSequenceKeypoint.new(0/6, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(1/6, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(2/6, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(3/6, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(4/6, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(5/6, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(6/6, Color3.fromRGB(255, 0, 0))
    }
    
    AddPickerSlider("H", h, 1, ColorSequence.new(rainbowColors), function(val)
        h = val
        UpdateColor()
    end)
    
    -- Saturation Slider (White -> Hue)
    local satGradObj, satKnob, satTrack = AddPickerSlider("S", s, 2, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(h, 1, 1))
    }), function(val)
        s = val
        UpdateColor()
    end)
    satGradient = satGradObj
    
    -- Value/Brightness Slider (Black -> Hue)
    local valGradObj, valKnob, valTrack = AddPickerSlider("V", v, 3, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(h, 1, 1))
    }), function(val)
        v = val
        UpdateColor()
    end)
    valGradient = valGradObj
    
    return {
        SetValue = function(color)
            h, s, v = Color3.toHSV(color)
            UpdateColor()
            -- Set slider knobs positions
            Tween(satKnob, 0.15, { Position = UDim2.new(s, -6, 0.5, -6) })
            Tween(valKnob, 0.15, { Position = UDim2.new(v, -6, 0.5, -6) })
            -- Find Hue knob in parents
            task.spawn(function()
                local hueKnob = sliders:GetChildren()[1]:FindFirstChild("Knob", true)
                if hueKnob then
                    Tween(hueKnob, 0.15, { Position = UDim2.new(h, -6, 0.5, -6) })
                end
            end)
        end,
        GetValue = function() return Color3.fromHSV(h, s, v) end
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
