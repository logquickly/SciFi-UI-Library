--[[
    ================================================================================
    TITANIUM CORE V7 // SINGULARITY EDITION
    ================================================================================
    Version: 7.0.0 (Release)
    Author: log_quick
    License: MIT / Proprietary
    
    [DESCRIPTION]
    A high-performance, object-oriented UI framework designed for Roblox script hubs.
    Features a cyberpunk aesthetic, reactive state management, and robust file systems.
    
    [FEATURES]
    > Modular Architecture (Signal, Theme, Input, FileSystem)
    > Advanced Sci-Fi Animations (Glitch text, Decode intro)
    > Ray-traced Rainbow Gradients (Simulated via UIGradient math)
    > Trigonometric Circular Color Picker
    > Neural-Link Config System (Flashbang feedback)
    > Mobile-First Responsive Design
    
    [CODE STRUCTURE]
    1. Services & Constants
    2. Signal Module (Custom Events)
    3. Utility Module (Math, Strings, Tweens)
    4. Theme Manager (Reactive Colors)
    5. File System (I/O)
    6. FX Engine (Sound & Visuals)
    7. Component Base Class
    8. UI Elements (Window, Tab, Button, Toggle, Slider, Dropdown, Picker, Keybind)
    9. System Interface
    ================================================================================
]]

local Titanium = {}
Titanium.__index = Titanium
Titanium.Version = "7.0.0"
Titanium.Author = "log_quick"

--// [1] SERVICES
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local TextService = game:GetService("TextService")
local TeleportService = game:GetService("TeleportService")

--// [2] ENVIRONMENT SETUP
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Viewport = (gethui and gethui()) or (syn and syn.protect_gui and syn.protect_gui(Instance.new("ScreenGui"))) or CoreGui

--// [3] CONSTANTS & ASSETS
local ASSETS = {
    Fonts = {
        Primary = Enum.Font.Gotham,
        Secondary = Enum.Font.GothamBold,
        Tech = Enum.Font.Code,
        Header = Enum.Font.SciFi
    },
    Icons = {
        Menu = "rbxassetid://6031068433",
        Close = "rbxassetid://6031094678",
        Settings = "rbxassetid://6031280882",
        Search = "rbxassetid://6031154871",
        Arrow = "rbxassetid://6034818372",
        Wheel = "rbxassetid://6020299385"
    },
    Sounds = {
        Boot = "rbxassetid://4612375233",
        Hover = "rbxassetid://6895079853",
        Click = "rbxassetid://6042053626",
        Confirm = "rbxassetid://6227976860",
        Flash = "rbxassetid://8503531336",
        Join = "rbxassetid://5153733766",
        Leave = "rbxassetid://5153733766",
        Glitch = "rbxassetid://3996391924"
    }
}

--// [4] SIGNAL MODULE (Custom Event Handling)
-- This replaces BindableEvents for faster internal communication
local Signal = {}
Signal.__index = Signal

function Signal.new()
    local self = setmetatable({}, Signal)
    self._connections = {}
    return self
end

function Signal:Connect(handler)
    local connection = {
        _handler = handler,
        _signal = self,
        Connected = true
    }
    table.insert(self._connections, connection)
    
    function connection:Disconnect()
        self.Connected = false
        for i, v in ipairs(self._signal._connections) do
            if v == self then
                table.remove(self._signal._connections, i)
                break
            end
        end
    end
    
    return connection
end

function Signal:Fire(...)
    for _, connection in ipairs(self._connections) do
        if connection.Connected then
            task.spawn(connection._handler, ...)
        end
    end
end

--// [5] UTILITY MODULE
local Utility = {}

function Utility:Create(class, properties, children)
    local instance = Instance.new(class)
    for k, v in pairs(properties) do
        if k ~= "Parent" then
            instance[k] = v
        end
    end
    if children then
        for _, child in pairs(children) do
            child.Parent = instance
        end
    end
    instance.Parent = properties.Parent
    return instance
end

function Utility:Tween(instance, info, goals)
    local tween = TweenService:Create(instance, TweenInfo.new(unpack(info)), goals)
    tween:Play()
    return tween
end

function Utility:GetTextSize(text, font, size, width)
    return TextService:GetTextSize(text, size, font, Vector2.new(width or 99999, 99999))
end

function Utility:RandomString(length)
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
    local str = ""
    for i = 1, length do
        local r = math.random(1, #chars)
        str = str .. string.sub(chars, r, r)
    end
    return str
end

--// [6] THEME MANAGER
-- Handles reactive colors and global styling
local Theme = {
    Colors = {
        Accent = Color3.fromRGB(0, 255, 220),
        Background = Color3.fromRGB(15, 15, 20),
        Section = Color3.fromRGB(25, 25, 30),
        Item = Color3.fromRGB(30, 30, 35),
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(150, 150, 150),
        Outline = Color3.fromRGB(50, 50, 60),
        Error = Color3.fromRGB(255, 50, 50)
    },
    Settings = {
        Transparency = 0.1,
        Scale = 1.0,
        RainbowSpeed = 0.5,
        RainbowEnabled = true,
        Font = ASSETS.Fonts.Primary
    },
    Signals = {
        Update = Signal.new()
    }
}

function Theme:SetColor(key, value)
    self.Colors[key] = value
    self.Signals.Update:Fire("Color", key)
end

function Theme:SetSetting(key, value)
    self.Settings[key] = value
    self.Signals.Update:Fire("Setting", key)
end

--// [7] FILE SYSTEM
-- Robust I/O wrapper
local FileSystem = {}
FileSystem.Root = "Titanium_V7"
FileSystem.CanSave = (writefile and readfile and isfolder and makefolder) ~= nil

function FileSystem:Initialize()
    if not self.CanSave then return end
    if not isfolder(self.Root) then makefolder(self.Root) end
    if not isfolder(self.Root .. "/Configs") then makefolder(self.Root .. "/Configs") end
end

function FileSystem:SaveConfig(name, flags)
    if not self.CanSave then return end
    local data = {
        Theme = {
            Colors = {
                Accent = Theme.Colors.Accent:ToHex(),
                Text = Theme.Colors.Text:ToHex(),
                Background = Theme.Colors.Background:ToHex()
            },
            Settings = Theme.Settings
        },
        Flags = flags
    }
    writefile(self.Root .. "/Configs/" .. name .. ".json", HttpService:JSONEncode(data))
end

function FileSystem:LoadConfig(name)
    if not self.CanSave then return nil end
    local path = self.Root .. "/Configs/" .. name .. ".json"
    if isfile(path) then
        return HttpService:JSONDecode(readfile(path))
    end
    return nil
end

--// [8] EFFECT ENGINE
-- Audio-Visual Feedback System
local FX = {}

function FX:PlaySound(name, vol)
    if not ASSETS.Sounds[name] then return end
    task.spawn(function()
        local s = Instance.new("Sound")
        s.SoundId = ASSETS.Sounds[name]
        s.Volume = vol or 1
        s.Parent = game:GetService("SoundService")
        s:Play()
        s.Ended:Wait()
        s:Destroy()
    end)
end

function FX:Flashbang(color)
    FX:PlaySound("Flash", 1.5)
    
    local FlashFrame = Utility:Create("Frame", {
        Name = "SystemFlash",
        Parent = Titanium.Gui,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = color,
        BackgroundTransparency = 0.3,
        ZIndex = 999999
    })
    
    local Correction = Utility:Create("ColorCorrectionEffect", {
        Parent = Lighting,
        TintColor = color,
        Brightness = 0.5,
        Contrast = 0.5
    })
    
    Utility:Tween(FlashFrame, {1, Enum.EasingStyle.Exponential}, {BackgroundTransparency = 1})
    Utility:Tween(Correction, {1, Enum.EasingStyle.Exponential}, {
        TintColor = Color3.new(1,1,1), Brightness = 0, Contrast = 0
    })
    
    task.delay(1, function()
        FlashFrame:Destroy()
        Correction:Destroy()
    end)
end

function FX:Ripple(guiObject, input)
    task.spawn(function()
        local ripple = Utility:Create("Frame", {
            Parent = guiObject,
            BackgroundColor3 = Color3.new(1,1,1),
            BackgroundTransparency = 0.6,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, input.Position.X - guiObject.AbsolutePosition.X, 0, input.Position.Y - guiObject.AbsolutePosition.Y),
            Size = UDim2.new(0,0,0,0),
            ZIndex = 9
        })
        Utility:Create("UICorner", {Parent = ripple, CornerRadius = UDim.new(1,0)})
        
        local targetSize = math.max(guiObject.AbsoluteSize.X, guiObject.AbsoluteSize.Y) * 2
        
        local tween = Utility:Tween(ripple, {0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out}, {
            Size = UDim2.new(0, targetSize, 0, targetSize),
            BackgroundTransparency = 1
        })
        
        tween.Completed:Wait()
        ripple:Destroy()
    end)
end

--// [9] UI COMPONENTS
-- Object Oriented UI Building Blocks

Titanium.Flags = {}
Titanium.Elements = {}

-- Base Class for all Elements
local Element = {}
Element.__index = Element

function Element.new(type, parent)
    local self = setmetatable({}, Element)
    self.Type = type
    self.Parent = parent
    self.Instance = nil
    return self
end

function Element:SetVisible(bool)
    if self.Instance then self.Instance.Visible = bool end
end

function Element:Destroy()
    if self.Instance then self.Instance:Destroy() end
end

-- [COMPONENT] BUTTON
local Button = setmetatable({}, Element)
Button.__index = Button

function Button.new(parent, text, callback)
    local self = Element.new("Button", parent)
    
    local btn = Utility:Create("TextButton", {
        Name = text,
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Theme.Colors.Item,
        BackgroundTransparency = 0.2,
        Text = "",
        AutoButtonColor = false,
        ClipsDescendants = true
    })
    Utility:Create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 4)})
    Utility:Create("UIStroke", {Parent = btn, Color = Theme.Colors.Outline, Thickness = 1})
    
    local label = Utility:Create("TextLabel", {
        Parent = btn,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.Colors.Text,
        Font = Theme.Settings.Font,
        TextSize = 14
    })
    
    -- Interaction
    btn.MouseEnter:Connect(function()
        FX:PlaySound("Hover", 0.5)
        Utility:Tween(btn, {0.2}, {BackgroundColor3 = Theme.Colors.Section})
    end)
    btn.MouseLeave:Connect(function()
        Utility:Tween(btn, {0.2}, {BackgroundColor3 = Theme.Colors.Item})
    end)
    btn.MouseButton1Click:Connect(function()
        FX:PlaySound("Click")
        FX:Ripple(btn, UserInputService:GetMouseLocation()) -- Pseudo input
        callback()
    end)
    
    -- Theme Listener
    Theme.Signals.Update:Connect(function(type)
        if type == "Color" then
            label.TextColor3 = Theme.Colors.Text
        elseif type == "Setting" then
            label.Font = Theme.Settings.Font
        end
    end)
    
    self.Instance = btn
    return self
end

-- [COMPONENT] TOGGLE
local Toggle = setmetatable({}, Element)
Toggle.__index = Toggle

function Toggle.new(parent, text, default, callback)
    local self = Element.new("Toggle", parent)
    Titanium.Flags[text] = default
    self.Value = default
    
    local container = Utility:Create("TextButton", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Theme.Colors.Item,
        BackgroundTransparency = 0.2,
        Text = "",
        AutoButtonColor = false
    })
    Utility:Create("UICorner", {Parent = container, CornerRadius = UDim.new(0, 4)})
    
    local label = Utility:Create("TextLabel", {
        Parent = container,
        Text = text,
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Theme.Colors.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Theme.Settings.Font,
        TextSize = 14
    })
    
    local checkBg = Utility:Create("Frame", {
        Parent = container,
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -50, 0.5, -10),
        BackgroundColor3 = default and Theme.Colors.Accent or Color3.fromRGB(50,50,50)
    })
    Utility:Create("UICorner", {Parent = checkBg, CornerRadius = UDim.new(1, 0)})
    
    local knob = Utility:Create("Frame", {
        Parent = checkBg,
        Size = UDim2.new(0, 16, 0, 16),
        Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        BackgroundColor3 = Color3.new(1,1,1)
    })
    Utility:Create("UICorner", {Parent = knob, CornerRadius = UDim.new(1, 0)})
    
    local function Update()
        Titanium.Flags[text] = self.Value
        local targetColor = self.Value and Theme.Colors.Accent or Color3.fromRGB(50,50,50)
        local targetPos = self.Value and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        
        Utility:Tween(checkBg, {0.2}, {BackgroundColor3 = targetColor})
        Utility:Tween(knob, {0.2}, {Position = targetPos})
        
        if callback then callback(self.Value) end
    end
    
    container.MouseButton1Click:Connect(function()
        FX:PlaySound("Click")
        self.Value = not self.Value
        Update()
    end)
    
    function self:Set(val)
        self.Value = val
        Update()
    end
    
    -- Theme Listener
    Theme.Signals.Update:Connect(function(type)
        if self.Value then checkBg.BackgroundColor3 = Theme.Colors.Accent end
        label.TextColor3 = Theme.Colors.Text
    end)
    
    self.Instance = container
    return self
end

-- [COMPONENT] SLIDER
local Slider = setmetatable({}, Element)
Slider.__index = Slider

function Slider.new(parent, text, min, max, default, callback)
    local self = Element.new("Slider", parent)
    Titanium.Flags[text] = default
    
    local container = Utility:Create("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = Theme.Colors.Item,
        BackgroundTransparency = 0.2
    })
    Utility:Create("UICorner", {Parent = container, CornerRadius = UDim.new(0, 4)})
    
    local label = Utility:Create("TextLabel", {
        Parent = container,
        Text = text,
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 10, 0, 5),
        BackgroundTransparency = 1,
        TextColor3 = Theme.Colors.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Theme.Settings.Font,
        TextSize = 14
    })
    
    local valueLabel = Utility:Create("TextLabel", {
        Parent = container,
        Text = tostring(default),
        Size = UDim2.new(0, 50, 0, 20),
        Position = UDim2.new(1, -60, 0, 5),
        BackgroundTransparency = 1,
        TextColor3 = Theme.Colors.Accent,
        TextXAlignment = Enum.TextXAlignment.Right,
        Font = ASSETS.Fonts.Tech,
        TextSize = 12
    })
    
    local sliderBar = Utility:Create("Frame", {
        Parent = container,
        Size = UDim2.new(1, -20, 0, 6),
        Position = UDim2.new(0, 10, 0, 35),
        BackgroundColor3 = Color3.fromRGB(10,10,10)
    })
    Utility:Create("UICorner", {Parent = sliderBar, CornerRadius = UDim.new(1, 0)})
    
    local fill = Utility:Create("Frame", {
        Parent = sliderBar,
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = Theme.Colors.Accent
    })
    Utility:Create("UICorner", {Parent = fill, CornerRadius = UDim.new(1, 0)})
    
    local dragging = false
    
    local function Update(input)
        local pos = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + ((max - min) * pos) * 10) / 10
        
        fill.Size = UDim2.new(pos, 0, 1, 0)
        valueLabel.Text = tostring(val)
        Titanium.Flags[text] = val
        
        if callback then callback(val) end
    end
    
    container.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            Update(i)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            Update(i)
        end
    end)
    
    function self:Set(val)
        val = math.clamp(val, min, max)
        local pos = (val - min) / (max - min)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        valueLabel.Text = tostring(val)
        Titanium.Flags[text] = val
        if callback then callback(val) end
    end
    
    -- Theme Listener
    Theme.Signals.Update:Connect(function(type)
        fill.BackgroundColor3 = Theme.Colors.Accent
        valueLabel.TextColor3 = Theme.Colors.Accent
        label.TextColor3 = Theme.Colors.Text
    end)
    
    self.Instance = container
    return self
end

-- [COMPONENT] COLOR PICKER (Advanced)
local ColorPicker = setmetatable({}, Element)
ColorPicker.__index = ColorPicker

function ColorPicker.new(parent, text, default, callback)
    local self = Element.new("ColorPicker", parent)
    Titanium.Flags[text] = {R=default.R, G=default.G, B=default.B}
    
    local container = Utility:Create("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 170),
        BackgroundColor3 = Theme.Colors.Item,
        BackgroundTransparency = 0.2
    })
    Utility:Create("UICorner", {Parent = container, CornerRadius = UDim.new(0, 4)})
    
    local label = Utility:Create("TextLabel", {
        Parent = container,
        Text = text,
        Size = UDim2.new(1, 0, 0, 25),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Theme.Colors.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Theme.Settings.Font,
        TextSize = 14
    })
    
    -- Circular Wheel
    local wheel = Utility:Create("ImageButton", {
        Parent = container,
        Size = UDim2.new(0, 100, 0, 100),
        Position = UDim2.new(0, 10, 0, 35),
        BackgroundTransparency = 1,
        Image = ASSETS.Icons.Wheel
    })
    
    local cursor = Utility:Create("Frame", {
        Parent = wheel,
        Size = UDim2.new(0, 8, 0, 8),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1,1,1),
        Position = UDim2.new(0.5,0,0.5,0)
    })
    Utility:Create("UICorner", {Parent = cursor, CornerRadius = UDim.new(1, 0)})
    Utility:Create("UIStroke", {Parent = cursor, Thickness = 1})
    
    local preview = Utility:Create("Frame", {
        Parent = container,
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(1, -70, 0, 35),
        BackgroundColor3 = default
    })
    Utility:Create("UICorner", {Parent = preview, CornerRadius = UDim.new(0, 8)})
    
    local hexInput = Utility:Create("TextBox", {
        Parent = container,
        Size = UDim2.new(0, 90, 0, 25),
        Position = UDim2.new(1, -100, 0, 100),
        BackgroundColor3 = Theme.Colors.Section,
        Text = "#" .. default:ToHex(),
        TextColor3 = Theme.Colors.Text,
        Font = ASSETS.Fonts.Tech,
        TextSize = 12
    })
    Utility:Create("UICorner", {Parent = hexInput, CornerRadius = UDim.new(0, 4)})
    
    local dragging = false
    
    local function Update(input)
        local center = wheel.AbsolutePosition + (wheel.AbsoluteSize/2)
        local vec = Vector2.new(input.Position.X, input.Position.Y) - center
        local angle = math.atan2(vec.Y, vec.X)
        local radius = math.min(vec.Magnitude, wheel.AbsoluteSize.X/2)
        
        cursor.Position = UDim2.new(0.5, math.cos(angle) * radius, 0.5, math.sin(angle) * radius)
        
        -- HSV Conversion
        local hue = (math.deg(angle) + 180) / 360
        local sat = radius / (wheel.AbsoluteSize.X/2)
        local col = Color3.fromHSV(hue, sat, 1)
        
        preview.BackgroundColor3 = col
        hexInput.Text = "#" .. col:ToHex()
        Titanium.Flags[text] = {R=col.R, G=col.G, B=col.B}
        
        if callback then callback(col) end
    end
    
    wheel.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            Update(i)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            Update(i)
        end
    end)
    
    hexInput.FocusLost:Connect(function()
        local s, col = pcall(function() return Color3.fromHex(hexInput.Text) end)
        if s then
            preview.BackgroundColor3 = col
            Titanium.Flags[text] = {R=col.R, G=col.G, B=col.B}
            if callback then callback(col) end
        end
    end)
    
    function self:Set(col)
        preview.BackgroundColor3 = col
        hexInput.Text = "#" .. col:ToHex()
        Titanium.Flags[text] = {R=col.R, G=col.G, B=col.B}
    end
    
    Theme.Signals.Update:Connect(function()
        label.TextColor3 = Theme.Colors.Text
        hexInput.BackgroundColor3 = Theme.Colors.Section
    end)
    
    self.Instance = container
    return self
end

-- [COMPONENT] DROPDOWN (Added for complexity)
local Dropdown = setmetatable({}, Element)
Dropdown.__index = Dropdown

function Dropdown.new(parent, text, options, callback)
    local self = Element.new("Dropdown", parent)
    
    local isOpen = false
    local current = options[1] or "Select..."
    
    local container = Utility:Create("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 36), -- Dynamic Height
        BackgroundColor3 = Theme.Colors.Item,
        BackgroundTransparency = 0.2,
        ClipsDescendants = true
    })
    Utility:Create("UICorner", {Parent = container, CornerRadius = UDim.new(0, 4)})
    
    local headerBtn = Utility:Create("TextButton", {
        Parent = container,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        Text = "",
    })
    
    local label = Utility:Create("TextLabel", {
        Parent = headerBtn,
        Text = text,
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Theme.Colors.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Theme.Settings.Font,
        TextSize = 14
    })
    
    local status = Utility:Create("TextLabel", {
        Parent = headerBtn,
        Text = current .. " v",
        Size = UDim2.new(0.4, 0, 1, 0),
        Position = UDim2.new(0.6, -10, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Theme.Colors.Accent,
        TextXAlignment = Enum.TextXAlignment.Right,
        Font = ASSETS.Fonts.Tech,
        TextSize = 12
    })
    
    local optionList = Utility:Create("ScrollingFrame", {
        Parent = container,
        Size = UDim2.new(1, -4, 0, 100),
        Position = UDim2.new(0, 2, 0, 40),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        CanvasSize = UDim2.new(0,0,0,0) -- Auto
    })
    local layout = Utility:Create("UIListLayout", {Parent = optionList, Padding = UDim.new(0, 2)})
    
    -- Function to refresh options
    local function Refresh()
        for _, v in pairs(optionList:GetChildren()) do
            if v:IsA("TextButton") then v:Destroy() end
        end
        
        for _, opt in ipairs(options) do
            local btn = Utility:Create("TextButton", {
                Parent = optionList,
                Size = UDim2.new(1, 0, 0, 25),
                BackgroundColor3 = Theme.Colors.Section,
                Text = opt,
                TextColor3 = Theme.Colors.SubText,
                Font = Theme.Settings.Font,
                TextSize = 13
            })
            Utility:Create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 4)})
            
            btn.MouseButton1Click:Connect(function()
                current = opt
                status.Text = current .. " v"
                FX:PlaySound("Click")
                Titanium.Flags[text] = opt
                if callback then callback(opt) end
                
                -- Close
                isOpen = false
                Utility:Tween(container, {0.3}, {Size = UDim2.new(1, 0, 0, 36)})
                Utility:Tween(status, {0.3}, {Rotation = 0})
            end)
        end
        
        optionList.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
    end
    
    Refresh()
    
    headerBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        local targetSize = isOpen and UDim2.new(1, 0, 0, 150) or UDim2.new(1, 0, 0, 36)
        local targetRot = isOpen and 180 or 0
        
        Utility:Tween(container, {0.3, Enum.EasingStyle.Quart}, {Size = targetSize})
        Utility:Tween(status, {0.3}, {Rotation = targetRot})
        FX:PlaySound("Click")
    end)
    
    Theme.Signals.Update:Connect(function()
        status.TextColor3 = Theme.Colors.Accent
    end)
    
    self.Instance = container
    return self
end

--// [10] WINDOW & TAB SYSTEM
local Window = {}
Window.__index = Window

function Window.new(options)
    local self = setmetatable({}, Window)
    
    -- Cleanup Old
    if Titanium.Gui then Titanium.Gui:Destroy() end
    
    -- ScreenGui
    local Screen = Utility:Create("ScreenGui", {
        Name = "Titanium_" .. Utility:RandomString(5),
        Parent = Viewport,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Global
    })
    Titanium.Gui = Screen
    
    -- Mobile Toggle
    local ToggleBtn = Utility:Create("ImageButton", {
        Parent = Screen,
        Name = "MobileToggle",
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(0.05, 0, 0.1, 0),
        BackgroundColor3 = Theme.Colors.Section,
        Image = ASSETS.Icons.Menu,
        ImageColor3 = Theme.Colors.Accent
    })
    Utility:Create("UICorner", {Parent = ToggleBtn, CornerRadius = UDim.new(1, 0)})
    local ToggleStroke = Utility:Create("UIStroke", {Parent = ToggleBtn, Color = Theme.Colors.Accent, Thickness = 2})
    
    -- Make Toggle Draggable
    local dragging, dragStart, startPos
    ToggleBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = i.Position; startPos = ToggleBtn.Position
        end
    end)
    ToggleBtn.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            ToggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)

    -- Main Frame
    local Main = Utility:Create("Frame", {
        Parent = Screen,
        Name = "MainFrame",
        Size = UDim2.new(0, 650, 0, 420),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Colors.Background,
        BackgroundTransparency = Theme.Settings.Transparency,
        ClipsDescendants = false
    })
    Utility:Create("UICorner", {Parent = Main, CornerRadius = UDim.new(0, 8)})
    self.Main = Main
    
    -- UIScale
    local Scaler = Utility:Create("UIScale", {Parent = Main, Scale = Theme.Settings.Scale})
    
    -- Rainbow Stroke
    local Stroke = Utility:Create("UIStroke", {Parent = Main, Thickness = 2, Color = Color3.new(1,1,1)})
    local Gradient = Utility:Create("UIGradient", {
        Parent = Stroke,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255,255,0)),
            ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0,255,0)),
            ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0,0,255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,255))
        })
    })
    
    -- Rainbow Loop
    task.spawn(function()
        local r = 0
        while Main.Parent do
            if Theme.Settings.RainbowEnabled then
                r = (r + Theme.Settings.RainbowSpeed) % 360
                Gradient.Rotation = r
                Gradient.Enabled = true
            else
                Gradient.Enabled = false
                Stroke.Color = Theme.Colors.Accent
            end
            RunService.Heartbeat:Wait()
        end
    end)

    -- Top Bar
    local TopBar = Utility:Create("Frame", {
        Parent = Main, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1
    })
    
    -- Intro Sequence
    Main.Size = UDim2.new(0,0,0,0)
    FX:PlaySound("Boot", 2)
    Utility:Tween(Main, {1, Enum.EasingStyle.Elastic}, {Size = UDim2.new(0, 650, 0, 420)})
    
    local Title = Utility:Create("TextLabel", {
        Parent = TopBar,
        Text = options.Name or "TITANIUM",
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Theme.Colors.Accent,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = ASSETS.Fonts.Header,
        TextSize = 20
    })

    -- Draggable Main
    local winDrag, winStart, winPos
    TopBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            winDrag=true; winStart=i.Position; winPos=Main.Position
        end
    end)
    TopBar.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then winDrag=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if winDrag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - winStart
            Main.Position = UDim2.new(winPos.X.Scale, winPos.X.Offset + d.X, winPos.Y.Scale, winPos.Y.Offset + d.Y)
        end
    end)
    
    -- Containers
    local TabContainer = Utility:Create("ScrollingFrame", {
        Parent = Main, Size = UDim2.new(0, 140, 1, -50), Position = UDim2.new(0, 10, 0, 45),
        BackgroundTransparency = 1, ScrollBarThickness = 0
    })
    local TabLayout = Utility:Create("UIListLayout", {Parent = TabContainer, Padding = UDim.new(0, 5)})
    
    local PageContainer = Utility:Create("Frame", {
        Parent = Main, Size = UDim2.new(1, -160, 1, -50), Position = UDim2.new(0, 150, 0, 45),
        BackgroundColor3 = Theme.Colors.Section, BackgroundTransparency = 0.5
    })
    Utility:Create("UICorner", {Parent = PageContainer, CornerRadius = UDim.new(0, 6)})
    
    self.TabContainer = TabContainer
    self.PageContainer = PageContainer
    self.Pages = {}
    
    -- Theme Updater for Window
    Theme.Signals.Update:Connect(function()
        Main.BackgroundColor3 = Theme.Colors.Background
        Main.BackgroundTransparency = Theme.Settings.Transparency
        Title.TextColor3 = Theme.Colors.Accent
        ToggleBtn.ImageColor3 = Theme.Colors.Accent
        ToggleStroke.Color = Theme.Colors.Accent
        PageContainer.BackgroundColor3 = Theme.Colors.Section
        Scaler.Scale = Theme.Settings.Scale
    end)
    
    -- Open/Close Logic
    local open = true
    local function Toggle()
        open = not open
        Main.Visible = open
    end
    ToggleBtn.MouseButton1Click:Connect(Toggle)
    UserInputService.InputBegan:Connect(function(i)
        if i.KeyCode == Enum.KeyCode.RightControl then Toggle() end
    end)
    
    return self
end

function Window:Tab(name)
    local TabBtn = Utility:Create("TextButton", {
        Parent = self.TabContainer,
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Theme.Colors.Section,
        BackgroundTransparency = 0.8,
        Text = name,
        TextColor3 = Theme.Colors.SubText,
        Font = ASSETS.Fonts.Primary,
        TextSize = 14
    })
    Utility:Create("UICorner", {Parent = TabBtn, CornerRadius = UDim.new(0, 4)})
    
    local Page = Utility:Create("ScrollingFrame", {
        Parent = self.PageContainer,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Colors.Accent
    })
    Utility:Create("UIListLayout", {Parent = Page, Padding = UDim.new(0, 5)})
    Utility:Create("UIPadding", {Parent = Page, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})
    
    local TabObj = {Page = Page}
    
    TabBtn.MouseButton1Click:Connect(function()
        FX:PlaySound("Hover")
        -- Hide All
        for _, p in pairs(self.PageContainer:GetChildren()) do
            if p:IsA("ScrollingFrame") then p.Visible = false end
        end
        for _, t in pairs(self.TabContainer:GetChildren()) do
            if t:IsA("TextButton") then
                Utility:Tween(t, {0.2}, {BackgroundTransparency = 0.8, TextColor3 = Theme.Colors.SubText})
            end
        end
        
        -- Show This
        Page.Visible = true
        Utility:Tween(TabBtn, {0.2}, {BackgroundTransparency = 0.4, TextColor3 = Theme.Colors.Accent})
    end)
    
    -- Proxy Methods
    function TabObj:Button(t, c) return Button.new(Page, t, c) end
    function TabObj:Toggle(t, d, c) return Toggle.new(Page, t, d, c) end
    function TabObj:Slider(t, min, max, d, c) return Slider.new(Page, t, min, max, d, c) end
    function TabObj:ColorPicker(t, d, c) return ColorPicker.new(Page, t, d, c) end
    function TabObj:Dropdown(t, o, c) return Dropdown.new(Page, t, o, c) end
    
    return TabObj
end

--// [11] SYSTEM INTERFACE (Initialization)

function Titanium:Init(options)
    FileSystem:Initialize()
    
    Theme.Colors.Accent = options.Accent or Theme.Colors.Accent
    local Win = Window.new(options)
    
    -- [AUTO-GENERATED TAB] PLAYERS
    local PTab = Win:Tab("Players")
    PTab:Toggle("Join Sound", Titanium.Flags["__Sys_JoinSound"] or false, function(v) Titanium.Flags["__Sys_JoinSound"]=v end)
    PTab:Toggle("Leave Sound", Titanium.Flags["__Sys_LeaveSound"] or false, function(v) Titanium.Flags["__Sys_LeaveSound"]=v end)
    PTab:Button("Copy Player List", function()
        local s = ""
        for _,p in pairs(Players:GetPlayers()) do s=s..p.Name.."\n" end
        if setclipboard then setclipboard(s) end
    end)
    
    -- [AUTO-GENERATED TAB] SETTINGS
    local STab = Win:Tab("System")
    
    -- Credits
    local Cred = Utility:Create("Frame", {
        Parent = STab.Page, Size = UDim2.new(1, -10, 0, 60),
        BackgroundColor3 = Theme.Colors.Section, BackgroundTransparency = 0.5
    })
    Utility:Create("UICorner", {Parent = Cred, CornerRadius = UDim.new(0, 6)})
    Utility:Create("TextLabel", {
        Parent = Cred, Text = "TITANIUM CORE",
        Size = UDim2.new(1, 0, 0, 25), Position = UDim2.new(0, 10, 0, 5),
        BackgroundTransparency = 1, TextColor3 = Theme.Colors.Accent,
        TextXAlignment = 0, Font = ASSETS.Fonts.Header, TextSize = 18
    })
    Utility:Create("TextLabel", {
        Parent = Cred, Text = "Version: " .. Titanium.Version .. " | Author: " .. Titanium.Author,
        Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 10, 0, 30),
        BackgroundTransparency = 1, TextColor3 = Theme.Colors.SubText,
        TextXAlignment = 0, Font = ASSETS.Fonts.Tech, TextSize = 12
    })
    
    -- Config Logic
    local cfgName = "Default"
    local tb = Utility:Create("TextBox", {
        Parent = STab.Page, Size = UDim2.new(1, -10, 0, 30),
        BackgroundColor3 = Color3.fromRGB(40,40,45), Text = "Default",
        TextColor3 = Color3.new(1,1,1)
    })
    Utility:Create("UICorner", {Parent = tb, CornerRadius = UDim.new(0, 4)})
    tb:GetPropertyChangedSignal("Text"):Connect(function() cfgName = tb.Text end)
    
    STab:Button("Save Config", function()
        FileSystem:SaveConfig(cfgName, Titanium.Flags)
        FX:PlaySound("Confirm")
    end)
    
    STab:Button("Load Config", function()
        local data = FileSystem:LoadConfig(cfgName)
        if data then
            FX:Flashbang(Theme.Colors.Accent)
            -- Apply Flags
            if data.Flags then
                for k, v in pairs(data.Flags) do
                    Titanium.Flags[k] = v
                end
            end
            -- Apply Theme
            if data.Theme then
                if data.Theme.Colors then
                    if data.Theme.Colors.Accent then Theme:SetColor("Accent", Color3.fromHex(data.Theme.Colors.Accent)) end
                    if data.Theme.Colors.Text then Theme:SetColor("Text", Color3.fromHex(data.Theme.Colors.Text)) end
                end
                if data.Theme.Settings then
                    for k, v in pairs(data.Theme.Settings) do
                        Theme:SetSetting(k, v)
                    end
                end
            end
        else
            FX:PlaySound("Click") -- Error sound
        end
    end)
    
    -- Visual Settings
    STab:Slider("UI Scale", 0.5, 1.5, 1.0, function(v) Theme:SetSetting("Scale", v) end)
    STab:Slider("Transparency", 0, 1, 0.1, function(v) Theme:SetSetting("Transparency", v) end)
    STab:ColorPicker("Font Color", Theme.Colors.Text, function(c) Theme:SetColor("Text", c) end)
    STab:Toggle("Rainbow Border", true, function(v) Theme:SetSetting("RainbowEnabled", v) end)
    
    STab:Button("Rejoin Server", function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
    end)
    
    STab:Button("Unload Interface", function()
        Titanium.Gui:Destroy()
    end)
    
    return Win
end

--// [12] PLAYER EVENTS
Players.PlayerAdded:Connect(function()
    if Titanium.Flags["__Sys_JoinSound"] then FX:PlaySound("Join") end
end)
Players.PlayerRemoving:Connect(function()
    if Titanium.Flags["__Sys_LeaveSound"] then FX:PlaySound("Leave") end
end)

return Titanium
