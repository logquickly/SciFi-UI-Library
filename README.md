# 🌌 Quantum UI Library

<div align="center">

![Version](https://img.shields.io/badge/Version-2.2.0-00d4ff?style=for-the-badge)
![Author](https://img.shields.io/badge/Author-log__quick-purple?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Roblox-red?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**A powerful, sci-fi themed UI library for Roblox with stunning visuals and advanced features.**

[Features](#-features) • [Installation](#-installation) • [Quick Start](#-quick-start) • [Documentation](#-documentation) • [Examples](#-examples)

<img src="https://i.imgur.com/placeholder.png" alt="Quantum UI Preview" width="600">

</div>

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🎨 Visual Design
- **Sci-Fi Holographic Theme** - Futuristic design with scanlines
- **Rainbow Gradient Borders** - Animated color-shifting borders
- **Smooth Animations** - Fluid transitions and effects
- **Loading Animation** - Stunning startup sequence with sounds
- **Screen Flash Effects** - Visual feedback on actions

</td>
<td width="50%">

### ⚙️ Core Features
- **Config System** - Save/Load/Auto-load configurations
- **Mobile Support** - Fully optimized for touch devices
- **Draggable Window** - Drag from title bar or any edge
- **Minimize to Button** - Collapse to floating button
- **Maximize Mode** - Fill screen with locked position

</td>
</tr>
</table>

### 🧩 UI Elements

| Element | Description |
|---------|-------------|
| **Toggle** | On/Off switch with animation |
| **Slider** | Adjustable value with range |
| **Dropdown** | Single or multi-select options |
| **Color Picker** | Circular wheel with presets & hex input |
| **Textbox** | Text input with placeholder |
| **Keybind** | Customizable key binding |
| **Button** | Clickable action button |
| **Label** | Simple text display |
| **Paragraph** | Title + content block |
| **Section** | Visual category separator |

---

## 📦 Installation

### Method 1: Load from GitHub (Recommended)

```lua
local QuantumUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/logquickly/SciFi-UI-Library/refs/heads/main/source.lua"))()
```

### Method 2: Local File

1. Download `source.lua`
2. Place in your executor's workspace
3. Load with:

```lua
local QuantumUI = loadstring(readfile("source.lua"))()
```

---

## 🚀 Quick Start

```lua
-- Load the library
local QuantumUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/logquickly/SciFi-UI-Library/refs/heads/main/source.lua"))()

-- Create a window
local Window = QuantumUI.new({
    Title = "My Script Hub",
    Subtitle = "v1.0.0",
    ThemeColor = Color3.fromRGB(0, 200, 255),
    Keybind = Enum.KeyCode.RightControl
})

-- Wait for loading animation
task.wait(3.5)

-- Create a tab
local MainTab = Window:AddTab({
    Name = "Main",
    Icon = "rbxassetid://6034287594"
})

-- Add elements
MainTab:AddToggle({
    Name = "Speed Hack",
    Default = false,
    Flag = "SpeedHack",
    Callback = function(state)
        print("Speed Hack:", state)
    end
})

-- Done! Settings tab is auto-created
```

---

## 📖 Documentation

### Window Options

```lua
local Window = QuantumUI.new({
    Title = "Window Title",           -- string: Window title
    Subtitle = "by Author",           -- string: Subtitle text
    ThemeColor = Color3.fromRGB(),    -- Color3: Main theme color
    Transparency = 0.3,               -- number: Background transparency (0-1)
    Size = UDim2.new(0, 600, 0, 450), -- UDim2: Window size
    Keybind = Enum.KeyCode.RightControl -- KeyCode: Toggle keybind
})
```

### Adding Tabs

```lua
local Tab = Window:AddTab({
    Name = "Tab Name",                -- string: Tab display name
    Icon = "rbxassetid://6034287594"  -- string: Tab icon asset ID
})
```

### UI Elements

<details>
<summary><b>📌 Section</b></summary>

```lua
Tab:AddSection({
    Name = "Section Name"  -- string: Section title
})
```

</details>

<details>
<summary><b>🔘 Button</b></summary>

```lua
Tab:AddButton({
    Name = "Button Name",  -- string: Button text
    Callback = function()  -- function: Click callback
        print("Clicked!")
    end
})
```

</details>

<details>
<summary><b>✅ Toggle</b></summary>

```lua
local Toggle = Tab:AddToggle({
    Name = "Toggle Name",     -- string: Toggle label
    Default = false,          -- boolean: Initial state
    Flag = "UniqueFlag",      -- string: Config save key
    Callback = function(state) -- function: State change callback
        print("Toggled:", state)
    end
})

-- Methods
Toggle:Set(true)       -- Set state
local state = Toggle:Get()  -- Get current state
```

</details>

<details>
<summary><b>📊 Slider</b></summary>

```lua
local Slider = Tab:AddSlider({
    Name = "Slider Name",     -- string: Slider label
    Min = 0,                  -- number: Minimum value
    Max = 100,                -- number: Maximum value
    Default = 50,             -- number: Initial value
    Increment = 1,            -- number: Step size
    Suffix = "%",             -- string: Value suffix
    Flag = "UniqueFlag",      -- string: Config save key
    Callback = function(value) -- function: Value change callback
        print("Value:", value)
    end
})

-- Methods
Slider:Set(75)          -- Set value
local value = Slider:Get()  -- Get current value
```

</details>

<details>
<summary><b>📋 Dropdown</b></summary>

```lua
-- Single Select
local Dropdown = Tab:AddDropdown({
    Name = "Dropdown Name",
    Items = {"Option 1", "Option 2", "Option 3"},
    Default = "Option 1",
    Flag = "UniqueFlag",
    Callback = function(selected)
        print("Selected:", selected)
    end
})

-- Multi Select
local MultiDropdown = Tab:AddDropdown({
    Name = "Multi Dropdown",
    Items = {"A", "B", "C", "D"},
    Multi = true,
    Default = {"A", "C"},
    Flag = "UniqueFlag",
    Callback = function(selected)
        for item, enabled in pairs(selected) do
            print(item, ":", enabled)
        end
    end
})

-- Methods
Dropdown:Set("Option 2")           -- Set selection
Dropdown:Refresh({"New", "Items"}) -- Update items list
local selected = Dropdown:Get()    -- Get current selection
```

</details>

<details>
<summary><b>🎨 Color Picker</b></summary>

```lua
local ColorPicker = Tab:AddColorPicker({
    Name = "Color Picker",
    Default = Color3.fromRGB(255, 0, 0),
    Presets = {                -- Optional custom presets
        Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(0, 255, 0),
        Color3.fromRGB(0, 0, 255),
    },
    Flag = "UniqueFlag",
    Callback = function(color)
        print("Color:", color)
    end
})

-- Methods
ColorPicker:Set(Color3.fromRGB(0, 255, 0))
local color = ColorPicker:Get()
```

</details>

<details>
<summary><b>📝 Textbox</b></summary>

```lua
local Textbox = Tab:AddTextbox({
    Name = "Textbox Name",
    Placeholder = "Enter text...",
    Default = "",
    ClearOnFocus = false,
    Flag = "UniqueFlag",
    Callback = function(text, enterPressed)
        print("Text:", text)
        if enterPressed then
            print("Enter was pressed!")
        end
    end
})

-- Methods
Textbox:Set("New text")
local text = Textbox:Get()
```

</details>

<details>
<summary><b>⌨️ Keybind</b></summary>

```lua
local Keybind = Tab:AddKeybind({
    Name = "Keybind Name",
    Default = Enum.KeyCode.F,
    Flag = "UniqueFlag",
    Callback = function(key)        -- Called when key is pressed
        print("Key pressed!")
    end,
    ChangedCallback = function(key) -- Called when keybind is changed
        print("New key:", key.Name)
    end
})

-- Methods
Keybind:Set(Enum.KeyCode.G)
local key = Keybind:Get()
```

</details>

<details>
<summary><b>📄 Label & Paragraph</b></summary>

```lua
-- Simple Label
local Label = Tab:AddLabel({
    Text = "This is a label"
})
Label:SetText("Updated text")

-- Paragraph (Title + Content)
local Paragraph = Tab:AddParagraph({
    Title = "Title Here",
    Content = "This is the paragraph content.\nSupports multiple lines."
})
Paragraph:SetTitle("New Title")
Paragraph:SetContent("New content here")
```

</details>

### Notifications

```lua
Window:Notify({
    Title = "Notification Title",
    Content = "This is the message content",
    Duration = 5,           -- seconds
    Type = "Success"        -- "Info", "Success", "Warning", "Error"
})
```

### Config System

The config system automatically saves all elements with a `Flag` parameter.

```lua
-- Elements with Flag are auto-saved
Tab:AddToggle({
    Name = "Feature",
    Flag = "MyFeature",  -- This will be saved!
    ...
})

-- Config functions are in the Settings tab:
-- 💾 Save Config - Save current settings
-- 📂 Load Config - Load saved settings
-- 🗑️ Delete Config - Remove a config
-- Auto Load Config - Set startup config
```

---

## 💡 Examples

### Complete Script Example

```lua
local QuantumUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/logquickly/SciFi-UI-Library/refs/heads/main/source.lua"))()

local Window = QuantumUI.new({
    Title = "Quantum Hub",
    Subtitle = "Premium Edition",
    ThemeColor = Color3.fromRGB(0, 200, 255)
})

task.wait(3.5)

-- ════════════════════════════════════
-- VISUALS TAB
-- ════════════════════════════════════
local VisualsTab = Window:AddTab({Name = "Visuals", Icon = "rbxassetid://6034509993"})

VisualsTab:AddSection({Name = "👁️ ESP Settings"})

VisualsTab:AddToggle({
    Name = "Player ESP",
    Flag = "ESP",
    Callback = function(state)
        -- ESP logic here
    end
})

VisualsTab:AddColorPicker({
    Name = "ESP Color",
    Default = Color3.fromRGB(255, 0, 0),
    Flag = "ESPColor"
})

VisualsTab:AddDropdown({
    Name = "ESP Type",
    Items = {"Box", "Corner", "3D"},
    Default = "Box",
    Flag = "ESPType"
})

VisualsTab:AddSection({Name = "🌍 World"})

VisualsTab:AddToggle({
    Name = "Fullbright",
    Flag = "Fullbright",
    Callback = function(state)
        game:GetService("Lighting").Brightness = state and 2 or 1
    end
})

VisualsTab:AddSlider({
    Name = "Time",
    Min = 0,
    Max = 24,
    Default = 14,
    Suffix = "h",
    Flag = "Time",
    Callback = function(value)
        game:GetService("Lighting").ClockTime = value
    end
})

-- ════════════════════════════════════
-- MAIN TAB
-- ════════════════════════════════════
local MainTab = Window:AddTab({Name = "Main", Icon = "rbxassetid://6034287594"})

MainTab:AddSection({Name = "🏃 Movement"})

MainTab:AddSlider({
    Name = "Speed",
    Min = 16,
    Max = 500,
    Default = 16,
    Flag = "Speed",
    Callback = function(value)
        local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = value end
    end
})

MainTab:AddToggle({
    Name = "Infinite Jump",
    Flag = "InfJump",
    Callback = function(state)
        _G.InfJump = state
    end
})

-- Infinite Jump Handler
game:GetService("UserInputService").JumpRequest:Connect(function()
    if _G.InfJump then
        local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

MainTab:AddSection({Name = "⌨️ Keybinds"})

MainTab:AddKeybind({
    Name = "Fly Key",
    Default = Enum.KeyCode.F,
    Flag = "FlyKey",
    Callback = function()
        -- Fly toggle logic
    end
})

-- Welcome notification
task.wait(0.5)
Window:Notify({
    Title = "Welcome!",
    Content = "Script loaded successfully!\nPress RightCtrl to toggle UI.",
    Duration = 5,
    Type = "Success"
})
```

---

## 🎮 Controls

| Action | Control |
|--------|---------|
| Toggle UI | `Right Control` (customizable) |
| Move Window | Drag title bar or any edge |
| Minimize | Click `—` button |
| Maximize | Click `□` button (fills screen, locks position) |
| Close to Button | Click `×` button |
| Restore | Click floating `Q` button |

---

## 📱 Mobile Support

Quantum UI is fully optimized for mobile devices:

- ✅ Touch-friendly buttons and sliders
- ✅ Draggable floating button
- ✅ Responsive layout
- ✅ Compact tab icons
- ✅ Optimized color picker size

---

## 🔧 Troubleshooting

<details>
<summary><b>Config not saving?</b></summary>

Make sure your executor supports file system functions:
- `writefile`
- `readfile`
- `makefolder`
- `isfolder`
- `isfile`
- `listfiles`
- `delfile`

</details>

<details>
<summary><b>UI not appearing?</b></summary>

1. Check console for errors
2. Ensure the script URL is correct
3. Try using a different executor
4. Wait for the loading animation (3.5 seconds)

</details>

<details>
<summary><b>Elements not working?</b></summary>

1. Ensure callbacks are functions
2. Check Flag names are unique
3. Verify parent tab exists

</details>

---

## 📄 License

This project is licensed under the MIT License - see below:

```
MIT License

Copyright (c) 2024 log_quick

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 Credits

<div align="center">

**Created with ❤️ by log_quick**

[![GitHub](https://img.shields.io/badge/GitHub-logquickly-181717?style=for-the-badge&logo=github)](https://github.com/logquickly)

**Star ⭐ this repo if you find it useful!**

</div>

---

<div align="center">

**Quantum UI v2.2.0** | Sci-Fi UI Library for Roblox

</div>
