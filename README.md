# AerLib

AerLib is a lightweight, clean, and highly responsive UI library for Roblox Luau developers. Designed with a dark glassmorphic layout, it features smooth animations, Lucide icon support, visual 2D color pickers, and interactive form elements.

---

## Installation

### Roblox Studio (Local Module)
Place `aerlib.lua` inside your project directory (e.g. `ReplicatedStorage`) and access it with:
```lua
local AerLib = require(game:GetService("ReplicatedStorage"):WaitForChild("aerlib"))
```

### Executor Environment (Loadstring)
Load the library dynamically in scripts:
```lua
local AerLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jdk-1337/aerlib/refs/heads/main/main.lua"))()
```

---

## Step-by-Step Guide

### Step 1: Initialize the Main Window
Create the master frame for your UI.
```lua
local Window = AerLib:CreateWindow("My Script Hub", "v1.0.0 - Stable")
```
*Note: Press `Right Control` to toggle the visibility of the window.*

### Step 2: Add Tabs
Tabs organize elements into different pages. They accept a name and an optional Lucide icon name.
```lua
local CombatTab = Window:CreateTab("Combat", "swords")
local SettingsTab = Window:CreateTab("Settings", "settings")
```

### Step 3: Create Sections
Sections act as card-style containers inside a tab to group related elements together.
```lua
local KillAuraSection = CombatTab:CreateSection("Kill Aura Settings")
local MovementSection = CombatTab:CreateSection("Movement Bypasses")
```

### Step 4: Add Interactive Elements
Now you can add interactive elements inside your sections. Below are examples of each supported element type.

---

## API & Element Reference

Every interactive element created returns a table containing getter and setter methods. Use **dot notation** (e.g. `Element.SetValue(...)`) to access them programmatically.

### Buttons
Creates a standard clickable button.
```lua
Section:CreateButton("Reset Character", function()
    local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = 0 end
end)
```

### Toggles
Creates a switch with an active state.
```lua
local auraToggle = Section:CreateToggle("Enable Kill Aura", false, function(state)
    print("Kill aura is now: " .. tostring(state))
end)

-- Programmatic usage:
local currentState = auraToggle.GetValue()
auraToggle.SetValue(not currentState)
```

### Sliders
Creates a numeric adjustment slider. Users can drag the slider or click the numeric badge to type in a value directly.
```lua
local speedSlider = Section:CreateSlider("WalkSpeed Modifier", 16, 150, 16, 0, function(val)
    local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = val end
end)

-- Programmatic usage:
speedSlider.SetValue(50)
local speed = speedSlider.GetValue()
```

### Dropdowns
Creates a collapsible selection list.
```lua
local configDropdown = Section:CreateDropdown("Selected Config", {"Default", "Rage", "Legit"}, "Default", function(selected)
    print("Active profile: " .. selected)
end)

-- Programmatic usage:
configDropdown.SetValue("Rage")
local active = configDropdown.GetValue()

-- Update options list dynamically:
configDropdown.SetOptions({"Default", "Rage", "Legit", "Custom"})
```

### TextBoxes
Creates a text entry box.
```lua
local prefixTextBox = Section:CreateTextBox("Command Prefix", "!", function(text)
    print("New command prefix: " .. text)
end)

-- Programmatic usage:
prefixTextBox.SetText("?")
local prefix = prefixTextBox.GetText()
```

### Keybinds
Creates a keybinding badge. Clicking the badge and pressing a key changes the bind.
```lua
local flyKeybind = Section:CreateKeybind("Fly Activation Bind", Enum.KeyCode.F, function(key, isNewBind)
    if not isNewBind then
        print("Fly shortcut pressed!")
    end
end)

-- Programmatic usage:
flyKeybind.SetKey(Enum.KeyCode.G)
local activeKey = flyKeybind.GetKey()
```

### Color Pickers
Creates a visual 2D color canvas and a vertical hue rainbow bar (with direct hex code entry support).
```lua
local espColorPicker = Section:CreateColorPicker("ESP Border Color", Color3.fromRGB(255, 0, 0), function(color)
    print("New ESP color values: ", color)
end)

-- Programmatic usage:
espColorPicker.SetValue(Color3.fromRGB(0, 255, 0))
local currentEspColor = espColorPicker.GetValue()
```

### Labels & Paragraphs
Labels are single-line texts; Paragraphs are formatted title/content blocks for informational descriptions.
```lua
local statusLabel = Section:CreateLabel("Status: Idle")
local docParagraph = Section:CreateParagraph("How to use", "Press the keybind associated with the cheat to toggle it.")

-- Programmatic updates:
statusLabel:SetText("Status: Farming")
docParagraph:SetTitle("Important Guide")
docParagraph:SetContent("Make sure your graphics are set to minimum to prevent lag.")
```

---

## Utility Features

### Dynamic Theme Customization
You can update the primary accent color of the UI dynamically at runtime.
```lua
-- Set the accent color (AccentColor, AccentHoverColor)
AerLib:SetAccentColor(Color3.fromRGB(99, 102, 241), Color3.fromRGB(129, 140, 248))
```

### Toast Notifications
Pops up a clean notification toast at the bottom right of the screen.
```lua
-- Parameters: Title, Message, Duration (seconds), Type ("info" | "success" | "warning" | "danger")
AerLib:Toast("Task Complete", "Settings saved successfully.", 4, "success")
```

---

## Full Example Script

```lua
local AerLib = require(game:GetService("ReplicatedStorage"):WaitForChild("aerlib"))

-- Setup Main Window
local Window = AerLib:CreateWindow("My First GUI", "v1.0 - Stable Edition")

-- Create Tab
local MainTab = Window:CreateTab("Main", "home")
local Combat = MainTab:CreateSection("Combat Automation")

-- Create Toggle and Slider
local autoFarm = Combat:CreateToggle("Auto Farm Enemies", false, function(state)
    print("Auto-farm toggle is " .. tostring(state))
end)

local farmRange = Combat:CreateSlider("Farming Range", 5, 50, 15, 0, function(val)
    print("Farming range updated to: " .. val)
end)

-- Settings Tab
local SettingsTab = Window:CreateTab("Settings", "settings")
local UIConfig = SettingsTab:CreateSection("Theme Customization")

UIConfig:CreateDropdown("Accent Theme", {"Pastel Blue", "Indigo", "Ruby Red"}, "Pastel Blue", function(selected)
    local accent, hover
    if selected == "Pastel Blue" then
        accent, hover = Color3.fromRGB(135, 206, 250), Color3.fromRGB(160, 220, 255)
    elseif selected == "Indigo" then
        accent, hover = Color3.fromRGB(99, 102, 241), Color3.fromRGB(129, 140, 248)
    elseif selected == "Ruby Red" then
        accent, hover = Color3.fromRGB(239, 68, 68), Color3.fromRGB(248, 113, 113)
    end
    AerLib:SetAccentColor(accent, hover)
    AerLib:Toast("Theme Updated", "UI accent changed to " .. selected, 3, "success")
end)
```
