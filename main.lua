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

-- Lucide Icon Library Engine
local LucideIcons = {}
local FallbackIcons = {
    home = "rbxassetid://10723407389",
    settings = "rbxassetid://10734950309",
    user = "rbxassetid://10747373176",
    shield = "rbxassetid://10734951847",
    activity = "rbxassetid://10709752035",
    eye = "rbxassetid://10723346959",
    sliders = "rbxassetid://10734963400",
    lock = "rbxassetid://10723434711",
    info = "rbxassetid://10723415903",
    play = "rbxassetid://10734923549",
    code = "rbxassetid://10709810463",
    palette = "rbxassetid://10734910430",
    folder = "rbxassetid://10723387563",
    terminal = "rbxassetid://10734982144",
    search = "rbxassetid://10734943674",
    trash = "rbxassetid://10747362393",
    bell = "rbxassetid://10709775704",
    check = "rbxassetid://10709790644",
    close = "rbxassetid://10734951535",
    crosshair = "rbxassetid://10709818534",
    sword = "rbxassetid://10734975486"
}
setmetatable(LucideIcons, { __index = FallbackIcons })

-- Try to load full Lucide mapping at runtime if executing in-game
if not RunService:IsStudio() then
    task.spawn(function()
        pcall(function()
            local content = game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/src/Icons.lua")
            local success, iconModule = pcall(loadstring(content))
            if success and type(iconModule) == "table" and iconModule.assets then
                for k, v in pairs(iconModule.assets) do
                    local cleanName = k:gsub("^lucide%-", "")
                    FallbackIcons[cleanName:lower()] = v
                end
            end
        end)
    end)
end

local AerLib = {
    Theme = {
        Background = Color3.fromRGB(13, 13, 13),
        Sidebar = Color3.fromRGB(15, 15, 15),
        Element = Color3.fromRGB(20, 20, 20),
        ElementBorder = Color3.fromRGB(40, 40, 40),
        Accent = Color3.fromRGB(135, 206, 250), -- Sleek Pastel Blue
        AccentHover = Color3.fromRGB(160, 220, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(160, 160, 160),
        PlaceholderText = Color3.fromRGB(100, 100, 100),
        Success = Color3.fromRGB(40, 200, 100),
        Danger = Color3.fromRGB(250, 80, 80),
        Warning = Color3.fromRGB(250, 180, 40),
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

local function HexToColor(hex)
    hex = hex:gsub("#", "")
    if #hex == 6 then
        local r = tonumber(hex:sub(1, 2), 16)
        local g = tonumber(hex:sub(3, 4), 16)
        local b = tonumber(hex:sub(5, 6), 16)
        if r and g and b then
            return Color3.fromRGB(r, g, b)
        end
    end
    return nil
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

-- Global theme manager to update accents dynamically
function AerLib:SetAccentColor(newAccent, newHover)
    self.Theme.Accent = newAccent
    self.Theme.AccentHover = newHover or newAccent
    
    for _, win in ipairs(self.Windows) do
        if win.ActiveTab then
            Tween(win.ActiveTab.Button, 0.2, { TextColor3 = newAccent })
            if win.ActiveTab.IconLabel then
                Tween(win.ActiveTab.IconLabel, 0.2, { ImageColor3 = newAccent })
            end
        end
        for _, desc in ipairs(win.MainFrame:GetDescendants()) do
            if desc:IsA("UIGradient") and desc.Name == "AccentGradient" then
                desc.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, newAccent),
                    ColorSequenceKeypoint.new(1, self.Theme.AccentHover)
                })
            elseif desc:IsA("UIStroke") and desc.Name == "AccentGlow" then
                desc.Color = newAccent
            elseif desc:IsA("TextBox") and desc.Name == "AccentValue" then
                desc.TextColor3 = newAccent
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
        Size = UDim2.new(1, 0, 0, 0),
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
    
    -- Sleek Header Gradient (dark grey vertical transition)
    local headerGradient = CreateInstance("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 22)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 15))
        }),
        Rotation = 90
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

function Window:CreateTab(name, icon)
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
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
    
    CreateInstance("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10)
    }, page)
    
    -- Resolve Icon Asset
    local iconAsset
    if icon then
        if typeof(icon) == "string" and icon:find("rbxassetid://") then
            iconAsset = icon
        else
            iconAsset = LucideIcons[tostring(icon):lower()]
        end
    end
    
    -- Tab Button Frame
    local tabBtn = CreateInstance("TextButton", {
        Size = UDim2.new(0, 130, 0, 32),
        BackgroundColor3 = self.Theme.Sidebar,
        Text = "",
        AutoButtonColor = false,
        ClipsDescendants = true
    }, self.SidebarScroll)
    
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, tabBtn)
    local tabStroke = CreateInstance("UIStroke", {
        Color = Color3.fromRGB(0, 0, 0),
        Thickness = 1,
        Transparency = 1
    }, tabBtn)
    
    local horizontalLayout = CreateInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, tabBtn)
    
    CreateInstance("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10)
    }, tabBtn)
    
    local tabIconLabel
    if iconAsset then
        tabIconLabel = CreateInstance("ImageLabel", {
            Size = UDim2.new(0, 16, 0, 16),
            BackgroundTransparency = 1,
            Image = iconAsset,
            ImageColor3 = self.Theme.TextSecondary,
            LayoutOrder = 1
        }, tabBtn)
    end
    
    local tabLabel = CreateInstance("TextLabel", {
        Size = UDim2.new(0, tabIconLabel and 86 or 110, 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = self.Theme.TextSecondary,
        Font = self.Theme.Font,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = 2
    }, tabBtn)
    
    local tabObj = setmetatable({
        Name = name,
        Page = page,
        Button = tabBtn,
        ButtonStroke = tabStroke,
        TextLabel = tabLabel,
        IconLabel = tabIconLabel,
        Window = self
    }, Tab)
    
    tabBtn.MouseEnter:Connect(function()
        if self.ActiveTab ~= tabObj then
            Tween(tabLabel, 0.15, { TextColor3 = self.Theme.Text })
            if tabIconLabel then
                Tween(tabIconLabel, 0.15, { ImageColor3 = self.Theme.Text })
            end
        end
    end)
    
    tabBtn.MouseLeave:Connect(function()
        if self.ActiveTab ~= tabObj then
            Tween(tabLabel, 0.15, { TextColor3 = self.Theme.TextSecondary })
            if tabIconLabel then
                Tween(tabIconLabel, 0.15, { ImageColor3 = self.Theme.TextSecondary })
            end
        end
    end)
    
    tabBtn.MouseButton1Click:Connect(function()
        self:SelectTab(tabObj)
    end)
    
    if not self.ActiveTab then
        self:SelectTab(tabObj)
    end
    
    self.SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, #self.SidebarScroll:GetChildren() * 38)
    
    return tabObj
end

function Window:SelectTab(tabObj)
    if self.ActiveTab then
        self.ActiveTab.Page.Visible = false
        Tween(self.ActiveTab.Button, 0.2, { BackgroundColor3 = self.Theme.Sidebar })
        Tween(self.ActiveTab.TextLabel, 0.2, { TextColor3 = self.Theme.TextSecondary })
        if self.ActiveTab.IconLabel then
            Tween(self.ActiveTab.IconLabel, 0.2, { ImageColor3 = self.Theme.TextSecondary })
        end
        Tween(self.ActiveTab.ButtonStroke, 0.2, { Transparency = 1 })
    end
    
    self.ActiveTab = tabObj
    tabObj.Page.Visible = true
    
    tabObj.Page.Position = UDim2.new(0, 0, 0, 15)
    Tween(tabObj.Page, 0.25, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
    
    Tween(tabObj.Button, 0.2, { BackgroundColor3 = self.Theme.Element })
    Tween(tabObj.TextLabel, 0.2, { TextColor3 = self.Theme.Accent })
    if tabObj.IconLabel then
        Tween(tabObj.IconLabel, 0.2, { ImageColor3 = self.Theme.Accent })
    end
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
    
    button.MouseEnter:Connect(function()
        Tween(border, 0.15, { Color = self.Window.Theme.Accent })
        btnGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, self.Window.Theme.Element),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 30))
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

-- Slider (With textbox input badge support)
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
    
    -- TextBox badge for interactive user-typing input
    local valueBox = CreateInstance("TextBox", {
        Size = UDim2.new(0, 50, 0, 18),
        Position = UDim2.new(1, -60, 0, 6),
        BackgroundColor3 = self.Window.Theme.Sidebar,
        Text = tostring(value),
        TextColor3 = self.Window.Theme.Accent,
        Font = self.Window.Theme.FontBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
        ClearTextOnFocus = false
    }, sliderFrame)
    valueBox.Name = "AccentValue"
    
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, valueBox)
    local valueBoxStroke = CreateInstance("UIStroke", {
        Color = self.Window.Theme.ElementBorder,
        Thickness = 0.5
    }, valueBox)
    
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
    
    valueBox.Focused:Connect(function()
        Tween(valueBoxStroke, 0.15, { Color = self.Window.Theme.Accent })
    end)
    
    local function UpdateSlider(input)
        local inputX = input.Position.X
        local trackAbsPos = track.AbsolutePosition.X
        local trackAbsSize = track.AbsoluteSize.X
        
        local percentage = math.clamp((inputX - trackAbsPos) / trackAbsSize, 0, 1)
        local rawValue = min + (max - min) * percentage
        
        local factor = 10^decimals
        value = math.round(rawValue * factor) / factor
        value = math.clamp(value, min, max)
        
        valueBox.Text = tostring(value)
        local visualScale = (value - min) / (max - min)
        progress.Size = UDim2.new(visualScale, 0, 1, 0)
        knob.Position = UDim2.new(visualScale, -6, 0.5, -6)
        
        task.spawn(callback, value)
    end
    
    valueBox.FocusLost:Connect(function(enterPressed)
        Tween(valueBoxStroke, 0.15, { Color = self.Window.Theme.ElementBorder })
        local num = tonumber(valueBox.Text)
        if num then
            num = math.clamp(num, min, max)
            local factor = 10^decimals
            value = math.round(num * factor) / factor
            valueBox.Text = tostring(value)
            
            local visualScale = (value - min) / (max - min)
            Tween(progress, 0.15, { Size = UDim2.new(visualScale, 0, 1, 0) })
            Tween(knob, 0.15, { Position = UDim2.new(visualScale, -6, 0.5, -6) })
            task.spawn(callback, value)
        else
            valueBox.Text = tostring(value)
        end
    end)
    
    sliderFrame.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not UserInputService:GetFocusedTextBox() then
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
            valueBox.Text = tostring(value)
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

-- COLOR PICKER REDESIGN: 2D Saturation-Value Canvas + Vertical Hue Bar (No Sliders)
function Section:CreateColorPicker(text, defaultColor, callback)
    local h, s, v = Color3.toHSV(defaultColor or Color3.fromRGB(135, 206, 250))
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
    
    -- Compact swatch preview on title row
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
    
    -- Sub-container holding the 2D picker items
    local contents = CreateInstance("Frame", {
        Size = UDim2.new(1, -20, 0, 105),
        Position = UDim2.new(0, 10, 0, 42),
        BackgroundTransparency = 1
    }, pickerFrame)
    
    -- 1. 2D Color Canvas (Sat & Val selector grid)
    local colorCanvas = CreateInstance("Frame", {
        Size = UDim2.new(0, 100, 0, 100),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0
    }, contents)
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, colorCanvas)
    CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 1 }, colorCanvas)
    
    local canvasGrad = CreateInstance("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(h, 1, 1))
        })
    }, colorCanvas)
    
    -- Darkness vertical overlay
    local darknessOverlay = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0
    }, colorCanvas)
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, darknessOverlay)
    
    CreateInstance("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new(Color3.new(0, 0, 0)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1), -- transparent top
            NumberSequenceKeypoint.new(1, 0)  -- dark bottom
        })
    }, darknessOverlay)
    
    -- Circular Canvas Selector Ring
    local canvasKnob = CreateInstance("Frame", {
        Size = UDim2.new(0, 8, 0, 8),
        Position = UDim2.new(s, -4, 1 - v, -4),
        BackgroundTransparency = 1
    }, colorCanvas)
    CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, canvasKnob)
    CreateInstance("UIStroke", { Color = Color3.new(255, 255, 255), Thickness = 1.5 }, canvasKnob)
    
    -- 2. Vertical Hue Bar (Rainbow selector)
    local hueBar = CreateInstance("Frame", {
        Size = UDim2.new(0, 14, 0, 100),
        Position = UDim2.new(0, 112, 0, 0),
        BorderSizePixel = 0
    }, contents)
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, hueBar)
    CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 1 }, hueBar)
    
    local rainbowColors = {
        ColorSequenceKeypoint.new(0/6, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(1/6, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(2/6, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(3/6, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(4/6, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(5/6, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(6/6, Color3.fromRGB(255, 0, 0))
    }
    
    CreateInstance("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new(rainbowColors)
    }, hueBar)
    
    local hueKnob = CreateInstance("Frame", {
        Size = UDim2.new(0, 18, 0, 6),
        Position = UDim2.new(0.5, -9, h, -3),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    }, hueBar)
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 2) }, hueKnob)
    CreateInstance("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 1 }, hueKnob)
    
    -- 3. Side details deck (swatch display + hex text box)
    local details = CreateInstance("Frame", {
        Size = UDim2.new(1, -136, 0, 100),
        Position = UDim2.new(0, 136, 0, 0),
        BackgroundTransparency = 1
    }, contents)
    
    local swatch = CreateInstance("Frame", {
        Size = UDim2.new(0, 36, 0, 36),
        Position = UDim2.new(0, 0, 0, 12),
        BackgroundColor3 = Color3.fromHSV(h, s, v)
    }, details)
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 18) }, swatch)
    local swatchBorder = CreateInstance("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.5, Thickness = 1 }, swatch)
    
    local hexBox = CreateInstance("TextBox", {
        Size = UDim2.new(1, -46, 0, 24),
        Position = UDim2.new(0, 46, 0, 10),
        BackgroundColor3 = self.Window.Theme.Sidebar,
        TextColor3 = self.Window.Theme.Text,
        Text = ColorToHex(Color3.fromHSV(h, s, v)),
        Font = self.Window.Theme.FontBold,
        TextSize = 11,
        ClearTextOnFocus = false
    }, details)
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, hexBox)
    local hexBoxStroke = CreateInstance("UIStroke", { Color = self.Window.Theme.ElementBorder, Thickness = 0.5 }, hexBox)
    
    local rgbLabel = CreateInstance("TextLabel", {
        Size = UDim2.new(1, -46, 0, 16),
        Position = UDim2.new(0, 46, 0, 38),
        BackgroundTransparency = 1,
        Text = math.round(preview.BackgroundColor3.R*255)..", "..math.round(preview.BackgroundColor3.G*255)..", "..math.round(preview.BackgroundColor3.B*255),
        TextColor3 = self.Window.Theme.TextSecondary,
        Font = self.Window.Theme.Font,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left
    }, details)
    
    local function TogglePicker(state)
        isOpened = state
        local targetHeight = isOpened and 158 or 38
        Tween(pickerFrame, 0.25, { Size = UDim2.new(1, 0, 0, targetHeight) }, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
    end
    
    clickArea.MouseButton1Click:Connect(function()
        TogglePicker(not isOpened)
    end)
    
    local function UpdateColor(skipCallback)
        local color = Color3.fromHSV(h, s, v)
        preview.BackgroundColor3 = color
        swatch.BackgroundColor3 = color
        hexBox.Text = ColorToHex(color)
        rgbLabel.Text = math.round(color.R*255)..", "..math.round(color.G*255)..", "..math.round(color.B*255)
        
        canvasGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(h, 1, 1))
        })
        
        if not skipCallback then
            task.spawn(callback, color)
        end
    end
    
    -- Input calculations
    local canvasActive = false
    local function UpdateCanvas(input)
        local absPos = colorCanvas.AbsolutePosition
        local absSize = colorCanvas.AbsoluteSize
        if absSize.X > 0 and absSize.Y > 0 then
            local relX = math.clamp((input.Position.X - absPos.X) / absSize.X, 0, 1)
            local relY = math.clamp((input.Position.Y - absPos.Y) / absSize.Y, 0, 1)
            s = relX
            v = 1 - relY
            canvasKnob.Position = UDim2.new(s, -4, 1 - v, -4)
            UpdateColor()
        end
    end
    
    colorCanvas.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            canvasActive = true
            UpdateCanvas(input)
        end
    end)
    
    local hueActive = false
    local function UpdateHue(input)
        local absPos = hueBar.AbsolutePosition
        local absSize = hueBar.AbsoluteSize
        if absSize.Y > 0 then
            local relY = math.clamp((input.Position.Y - absPos.Y) / absSize.Y, 0, 1)
            h = relY
            hueKnob.Position = UDim2.new(0.5, -9, h, -3)
            UpdateColor()
        end
    end
    
    hueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            hueActive = true
            UpdateHue(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            canvasActive = false
            hueActive = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if canvasActive and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateCanvas(input)
        elseif hueActive and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateHue(input)
        end
    end)
    
    -- TextBox Hex Focus styling & update
    hexBox.Focused:Connect(function()
        Tween(hexBoxStroke, 0.15, { Color = self.Window.Theme.Accent })
    end)
    
    hexBox.FocusLost:Connect(function(enterPressed)
        Tween(hexBoxStroke, 0.15, { Color = self.Window.Theme.ElementBorder })
        local parsedColor = HexToColor(hexBox.Text)
        if parsedColor then
            h, s, v = Color3.toHSV(parsedColor)
            canvasKnob.Position = UDim2.new(s, -4, 1 - v, -4)
            hueKnob.Position = UDim2.new(0.5, -9, h, -3)
            UpdateColor()
        else
            hexBox.Text = ColorToHex(Color3.fromHSV(h, s, v))
        end
    end)
    
    -- Init swatch color without invoking initial callback
    UpdateColor(true)
    
    return {
        SetValue = function(color)
            h, s, v = Color3.toHSV(color)
            Tween(canvasKnob, 0.15, { Position = UDim2.new(s, -4, 1 - v, -4) })
            Tween(hueKnob, 0.15, { Position = UDim2.new(0.5, -9, h, -3) })
            UpdateColor(true)
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
