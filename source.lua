--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║                        QUANTUM UI LIBRARY                        ║
    ║                     Version 2.0.0 - Sci-Fi Edition              ║
    ║                         Created by log_quick                     ║
    ║                                                                  ║
    ║  Features:                                                       ║
    ║  • Sci-Fi Holographic Design                                    ║
    ║  • Rainbow Gradient Borders                                     ║
    ║  • Advanced Config System                                       ║
    ║  • Mobile Optimized                                             ║
    ║  • Sound Effects & Animations                                   ║
    ╚══════════════════════════════════════════════════════════════════╝
--]]

local QuantumUI = {}
QuantumUI.__index = QuantumUI
QuantumUI.Version = "2.0.0"
QuantumUI.Author = "log_quick"
QuantumUI.Windows = {}
QuantumUI.Configs = {}
QuantumUI.CurrentConfig = nil
QuantumUI.ThemeColor = Color3.fromRGB(0, 200, 255)
QuantumUI.Transparency = 0.3
QuantumUI.RainbowEnabled = true
QuantumUI.RainbowSpeed = 1
QuantumUI.RainbowColors = {
    Color3.fromRGB(255, 0, 0),
    Color3.fromRGB(255, 127, 0),
    Color3.fromRGB(255, 255, 0),
    Color3.fromRGB(0, 255, 0),
    Color3.fromRGB(0, 0, 255),
    Color3.fromRGB(75, 0, 130),
    Color3.fromRGB(143, 0, 255)
}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Mobile Detection
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Sound IDs
local Sounds = {
    Click = "rbxassetid://6895079853",
    Hover = "rbxassetid://6895079709",
    Toggle = "rbxassetid://6895079565",
    Open = "rbxassetid://6895079422",
    Close = "rbxassetid://6895079278",
    ConfigLoad = "rbxassetid://6026984224",
    ConfigSave = "rbxassetid://6895079134",
    Startup = "rbxassetid://5853855460",
    Error = "rbxassetid://6895078990"
}

-- Utility Functions
local Utility = {}

function Utility.Create(className, properties, children)
    local instance = Instance.new(className)
    for prop, value in pairs(properties or {}) do
        instance[prop] = value
    end
    for _, child in pairs(children or {}) do
        child.Parent = instance
    end
    return instance
end

function Utility.Tween(object, properties, duration, style, direction)
    local tweenInfo = TweenInfo.new(
        duration or 0.3,
        style or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

function Utility.PlaySound(soundId, volume)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 0.5
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    return sound
end

function Utility.Ripple(parent, position, color)
    local ripple = Utility.Create("Frame", {
        Name = "Ripple",
        Parent = parent,
        BackgroundColor3 = color or Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Position = UDim2.new(0, position.X - parent.AbsolutePosition.X, 0, position.Y - parent.AbsolutePosition.Y),
        Size = UDim2.new(0, 0, 0, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 100
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0)})
    })
    
    local maxSize = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2
    Utility.Tween(ripple, {Size = UDim2.new(0, maxSize, 0, maxSize), BackgroundTransparency = 1}, 0.5)
    
    task.delay(0.5, function()
        ripple:Destroy()
    end)
end

function Utility.CreateGradient(colors, rotation)
    local gradient = Instance.new("UIGradient")
    local colorSequence = {}
    for i, color in ipairs(colors) do
        table.insert(colorSequence, ColorSequenceKeypoint.new((i-1)/(#colors-1), color))
    end
    gradient.Color = ColorSequence.new(colorSequence)
    gradient.Rotation = rotation or 0
    return gradient
end

function Utility.HSVToRGB(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end
    return Color3.new(r, g, b)
end

function Utility.RGBToHSV(color)
    local r, g, b = color.R, color.G, color.B
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, v
    v = max
    local d = max - min
    s = max == 0 and 0 or d / max
    if max == min then
        h = 0
    else
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        h = h / 6
    end
    return h, s, v
end

-- Screen Flash Effect
function Utility.ScreenFlash(color, duration)
    local flash = Utility.Create("Frame", {
        Name = "ScreenFlash",
        Parent = LocalPlayer:WaitForChild("PlayerGui"),
        BackgroundColor3 = color,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 99999
    })
    
    Utility.Tween(flash, {BackgroundTransparency = 1}, duration or 0.5)
    task.delay(duration or 0.5, function()
        flash:Destroy()
    end)
end

-- Config System
local ConfigSystem = {}

function ConfigSystem.GetFolder()
    local success, result = pcall(function()
        return isfolder and isfolder("QuantumUI")
    end)
    
    if success and not result then
        pcall(function()
            makefolder("QuantumUI")
            makefolder("QuantumUI/Configs")
        end)
    end
    return "QuantumUI/Configs"
end

function ConfigSystem.SaveConfig(name, data)
    local folder = ConfigSystem.GetFolder()
    local success, err = pcall(function()
        writefile(folder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    end)
    return success, err
end

function ConfigSystem.LoadConfig(name)
    local folder = ConfigSystem.GetFolder()
    local success, result = pcall(function()
        return HttpService:JSONDecode(readfile(folder .. "/" .. name .. ".json"))
    end)
    return success and result or nil
end

function ConfigSystem.GetConfigs()
    local folder = ConfigSystem.GetFolder()
    local configs = {}
    local success, files = pcall(function()
        return listfiles(folder)
    end)
    
    if success then
        for _, file in ipairs(files) do
            local name = file:match("([^/\\]+)%.json$")
            if name then
                table.insert(configs, name)
            end
        end
    end
    return configs
end

function ConfigSystem.DeleteConfig(name)
    local folder = ConfigSystem.GetFolder()
    local success = pcall(function()
        delfile(folder .. "/" .. name .. ".json")
    end)
    return success
end

-- Rainbow Border Handler
local RainbowHandler = {}
RainbowHandler.Connections = {}
RainbowHandler.Objects = {}

function RainbowHandler.Add(object, customColors)
    table.insert(RainbowHandler.Objects, {
        Object = object,
        Colors = customColors or QuantumUI.RainbowColors
    })
end

function RainbowHandler.Remove(object)
    for i, obj in ipairs(RainbowHandler.Objects) do
        if obj.Object == object then
            table.remove(RainbowHandler.Objects, i)
            break
        end
    end
end

function RainbowHandler.Start()
    if RainbowHandler.Connection then return end
    
    local hue = 0
    RainbowHandler.Connection = RunService.RenderStepped:Connect(function(dt)
        if not QuantumUI.RainbowEnabled then return end
        
        hue = (hue + dt * QuantumUI.RainbowSpeed * 0.1) % 1
        
        for _, data in ipairs(RainbowHandler.Objects) do
            if data.Object and data.Object.Parent then
                local gradient = data.Object:FindFirstChildOfClass("UIGradient")
                if gradient then
                    local colors = {}
                    local numColors = #data.Colors
                    for i = 1, numColors do
                        local colorHue = (hue + (i - 1) / numColors) % 1
                        colors[i] = ColorSequenceKeypoint.new((i - 1) / (numColors - 1), Utility.HSVToRGB(colorHue, 1, 1))
                    end
                    gradient.Color = ColorSequence.new(colors)
                end
            end
        end
    end)
end

function RainbowHandler.Stop()
    if RainbowHandler.Connection then
        RainbowHandler.Connection:Disconnect()
        RainbowHandler.Connection = nil
    end
end

-- Main Library
function QuantumUI.new(options)
    options = options or {}
    
    local self = setmetatable({}, QuantumUI)
    self.Title = options.Title or "Quantum UI"
    self.Subtitle = options.Subtitle or "by log_quick"
    self.ThemeColor = options.ThemeColor or Color3.fromRGB(0, 200, 255)
    self.Transparency = options.Transparency or 0.3
    self.Size = options.Size or (IsMobile and UDim2.new(0.95, 0, 0.85, 0) or UDim2.new(0, 600, 0, 450))
    self.MinSize = Vector2.new(400, 300)
    self.Tabs = {}
    self.Elements = {}
    self.ConfigData = {}
    self.Keybind = options.Keybind or Enum.KeyCode.RightControl
    self.AutoLoadConfig = options.AutoLoadConfig or nil
    self.Visible = true
    
    QuantumUI.ThemeColor = self.ThemeColor
    QuantumUI.Transparency = self.Transparency
    
    self:Initialize()
    
    return self
end

function QuantumUI:Initialize()
    -- Create ScreenGui
    self.ScreenGui = Utility.Create("ScreenGui", {
        Name = "QuantumUI_" .. HttpService:GenerateGUID(false),
        Parent = game:GetService("CoreGui"),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        DisplayOrder = 999
    })
    
    -- Loading Screen
    self:CreateLoadingScreen()
end

function QuantumUI:CreateLoadingScreen()
    local loadingFrame = Utility.Create("Frame", {
        Name = "LoadingScreen",
        Parent = self.ScreenGui,
        BackgroundColor3 = Color3.fromRGB(10, 10, 20),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 1000
    })
    
    -- Holographic Grid Background
    local gridContainer = Utility.Create("Frame", {
        Name = "GridContainer",
        Parent = loadingFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ClipsDescendants = true
    })
    
    -- Create animated grid lines
    for i = 1, 20 do
        local line = Utility.Create("Frame", {
            Name = "GridLine_H_" .. i,
            Parent = gridContainer,
            BackgroundColor3 = self.ThemeColor,
            BackgroundTransparency = 0.9,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, i / 20 - 0.025, 0)
        })
    end
    
    for i = 1, 30 do
        local line = Utility.Create("Frame", {
            Name = "GridLine_V_" .. i,
            Parent = gridContainer,
            BackgroundColor3 = self.ThemeColor,
            BackgroundTransparency = 0.9,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 1, 1, 0),
            Position = UDim2.new(i / 30 - 0.0167, 0, 0, 0)
        })
    end
    
    -- Logo Container
    local logoContainer = Utility.Create("Frame", {
        Name = "LogoContainer",
        Parent = loadingFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 200, 0, 200),
        Position = UDim2.new(0.5, 0, 0.4, 0),
        AnchorPoint = Vector2.new(0.5, 0.5)
    })
    
    -- Hexagon Shape (Sci-Fi Logo)
    local hexagonOuter = Utility.Create("ImageLabel", {
        Name = "HexagonOuter",
        Parent = logoContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Image = "rbxassetid://6031280882",
        ImageColor3 = self.ThemeColor,
        ImageTransparency = 0.3
    })
    
    local hexagonInner = Utility.Create("ImageLabel", {
        Name = "HexagonInner",
        Parent = logoContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.7, 0, 0.7, 0),
        Position = UDim2.new(0.15, 0, 0.15, 0),
        Image = "rbxassetid://6031280882",
        ImageColor3 = self.ThemeColor,
        ImageTransparency = 0.5
    })
    
    -- Q Letter in center
    local qLetter = Utility.Create("TextLabel", {
        Name = "QLetter",
        Parent = logoContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, 0, 0.5, 0),
        Position = UDim2.new(0.25, 0, 0.25, 0),
        Font = Enum.Font.GothamBold,
        Text = "Q",
        TextColor3 = self.ThemeColor,
        TextScaled = true,
        TextTransparency = 0
    })
    
    -- Rotating Ring
    local ring = Utility.Create("ImageLabel", {
        Name = "Ring",
        Parent = logoContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1.2, 0, 1.2, 0),
        Position = UDim2.new(-0.1, 0, -0.1, 0),
        Image = "rbxassetid://6034281467",
        ImageColor3 = self.ThemeColor,
        ImageTransparency = 0.5
    })
    
    -- Title
    local title = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = loadingFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 50),
        Position = UDim2.new(0, 0, 0.6, 20),
        Font = Enum.Font.GothamBold,
        Text = "QUANTUM UI",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 36,
        TextTransparency = 1
    })
    
    -- Subtitle
    local subtitle = Utility.Create("TextLabel", {
        Name = "Subtitle",
        Parent = loadingFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0.6, 70),
        Font = Enum.Font.Gotham,
        Text = "INITIALIZING SYSTEMS...",
        TextColor3 = self.ThemeColor,
        TextSize = 16,
        TextTransparency = 1
    })
    
    -- Loading Bar Container
    local loadingBarContainer = Utility.Create("Frame", {
        Name = "LoadingBarContainer",
        Parent = loadingFrame,
        BackgroundColor3 = Color3.fromRGB(30, 30, 40),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Size = UDim2.new(0.4, 0, 0, 8),
        Position = UDim2.new(0.3, 0, 0.75, 0)
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0)})
    })
    
    -- Loading Bar
    local loadingBar = Utility.Create("Frame", {
        Name = "LoadingBar",
        Parent = loadingBarContainer,
        BackgroundColor3 = self.ThemeColor,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0)
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0)}),
        Utility.CreateGradient({
            self.ThemeColor,
            Color3.fromRGB(255, 255, 255)
        }, 0)
    })
    
    -- Loading Percentage
    local loadingPercent = Utility.Create("TextLabel", {
        Name = "LoadingPercent",
        Parent = loadingFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0.75, 15),
        Font = Enum.Font.Code,
        Text = "0%",
        TextColor3 = self.ThemeColor,
        TextSize = 14,
        TextTransparency = 1
    })
    
    -- Status Text
    local statusText = Utility.Create("TextLabel", {
        Name = "StatusText",
        Parent = loadingFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0.82, 0),
        Font = Enum.Font.Code,
        Text = "> Establishing connection...",
        TextColor3 = Color3.fromRGB(100, 255, 100),
        TextSize = 12,
        TextTransparency = 1
    })
    
    -- Animation
    local rotationAngle = 0
    local rotationConnection
    
    rotationConnection = RunService.RenderStepped:Connect(function(dt)
        rotationAngle = rotationAngle + dt * 60
        ring.Rotation = rotationAngle
        hexagonOuter.Rotation = -rotationAngle * 0.3
        hexagonInner.Rotation = rotationAngle * 0.5
    end)
    
    -- Play startup sound
    Utility.PlaySound(Sounds.Startup, 0.7)
    
    -- Fade in elements
    task.spawn(function()
        task.wait(0.3)
        Utility.Tween(title, {TextTransparency = 0}, 0.5)
        task.wait(0.2)
        Utility.Tween(subtitle, {TextTransparency = 0}, 0.5)
        Utility.Tween(loadingPercent, {TextTransparency = 0}, 0.5)
        Utility.Tween(statusText, {TextTransparency = 0}, 0.5)
        
        -- Loading Progress
        local loadingSteps = {
            {percent = 15, text = "> Loading UI components..."},
            {percent = 30, text = "> Initializing theme engine..."},
            {percent = 45, text = "> Setting up config system..."},
            {percent = 60, text = "> Preparing animations..."},
            {percent = 75, text = "> Optimizing for device..."},
            {percent = 90, text = "> Finalizing setup..."},
            {percent = 100, text = "> Ready!"}
        }
        
        for _, step in ipairs(loadingSteps) do
            Utility.Tween(loadingBar, {Size = UDim2.new(step.percent / 100, 0, 1, 0)}, 0.3)
            loadingPercent.Text = step.percent .. "%"
            statusText.Text = step.text
            Utility.PlaySound(Sounds.Click, 0.2)
            task.wait(0.2 + math.random() * 0.15)
        end
        
        task.wait(0.3)
        
        -- Fade out loading screen
        Utility.Tween(loadingFrame, {BackgroundTransparency = 1}, 0.5)
        for _, child in ipairs(loadingFrame:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("ImageLabel") then
                Utility.Tween(child, {
                    TextTransparency = child:IsA("TextLabel") and 1 or nil,
                    ImageTransparency = child:IsA("ImageLabel") and 1 or nil
                }, 0.5)
            elseif child:IsA("Frame") then
                Utility.Tween(child, {BackgroundTransparency = 1}, 0.5)
            end
        end
        
        task.wait(0.5)
        rotationConnection:Disconnect()
        loadingFrame:Destroy()
        
        -- Create main window
        self:CreateMainWindow()
    end)
end

function QuantumUI:CreateMainWindow()
    -- Main Container
    self.MainFrame = Utility.Create("Frame", {
        Name = "MainFrame",
        Parent = self.ScreenGui,
        BackgroundColor3 = Color3.fromRGB(15, 15, 25),
        BackgroundTransparency = self.Transparency,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ClipsDescendants = true
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 12)})
    })
    
    -- Rainbow Border
    local borderFrame = Utility.Create("Frame", {
        Name = "BorderFrame",
        Parent = self.MainFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 4, 1, 4),
        Position = UDim2.new(0, -2, 0, -2),
        ZIndex = 0
    })
    
    local borderStroke = Utility.Create("UIStroke", {
        Name = "RainbowStroke",
        Parent = self.MainFrame,
        Color = self.ThemeColor,
        Thickness = 2,
        Transparency = 0.3
    })
    
    local borderGradient = Utility.CreateGradient(QuantumUI.RainbowColors, 0)
    borderGradient.Parent = borderStroke
    
    RainbowHandler.Add(borderStroke)
    RainbowHandler.Start()
    
    -- Holographic Overlay
    local holoOverlay = Utility.Create("Frame", {
        Name = "HoloOverlay",
        Parent = self.MainFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 1
    })
    
    -- Scanline Effect
    local scanlines = Utility.Create("ImageLabel", {
        Name = "Scanlines",
        Parent = holoOverlay,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Image = "rbxassetid://594768915",
        ImageTransparency = 0.95,
        ScaleType = Enum.ScaleType.Tile,
        TileSize = UDim2.new(0, 100, 0, 100),
        ZIndex = 2
    })
    
    -- Top Bar
    local topBar = Utility.Create("Frame", {
        Name = "TopBar",
        Parent = self.MainFrame,
        BackgroundColor3 = Color3.fromRGB(20, 20, 35),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 50),
        ZIndex = 10
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 12)})
    })
    
    -- Fix top bar corners
    local topBarFix = Utility.Create("Frame", {
        Name = "TopBarFix",
        Parent = topBar,
        BackgroundColor3 = Color3.fromRGB(20, 20, 35),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 1, -20),
        ZIndex = 9
    })
    
    -- Logo in top bar
    local logoIcon = Utility.Create("TextLabel", {
        Name = "LogoIcon",
        Parent = topBar,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0, 10, 0, 5),
        Font = Enum.Font.GothamBold,
        Text = "Q",
        TextColor3 = self.ThemeColor,
        TextSize = 28,
        ZIndex = 11
    })
    
    -- Title
    local titleLabel = Utility.Create("TextLabel", {
        Name = "TitleLabel",
        Parent = topBar,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 200, 0, 25),
        Position = UDim2.new(0, 55, 0, 5),
        Font = Enum.Font.GothamBold,
        Text = self.Title,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 11
    })
    
    -- Subtitle
    local subtitleLabel = Utility.Create("TextLabel", {
        Name = "SubtitleLabel",
        Parent = topBar,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 200, 0, 15),
        Position = UDim2.new(0, 55, 0, 30),
        Font = Enum.Font.Gotham,
        Text = self.Subtitle,
        TextColor3 = Color3.fromRGB(150, 150, 150),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 11
    })
    
    -- Control Buttons Container
    local controlButtons = Utility.Create("Frame", {
        Name = "ControlButtons",
        Parent = topBar,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 90, 0, 30),
        Position = UDim2.new(1, -100, 0, 10),
        ZIndex = 11
    })
    
    -- Minimize Button
    local minimizeBtn = Utility.Create("TextButton", {
        Name = "MinimizeBtn",
        Parent = controlButtons,
        BackgroundColor3 = Color3.fromRGB(255, 190, 0),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 25, 0, 25),
        Position = UDim2.new(0, 0, 0, 0),
        Font = Enum.Font.GothamBold,
        Text = "—",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 16,
        ZIndex = 12
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 6)})
    })
    
    -- Maximize Button
    local maximizeBtn = Utility.Create("TextButton", {
        Name = "MaximizeBtn",
        Parent = controlButtons,
        BackgroundColor3 = Color3.fromRGB(0, 200, 100),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 25, 0, 25),
        Position = UDim2.new(0, 30, 0, 0),
        Font = Enum.Font.GothamBold,
        Text = "□",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        ZIndex = 12
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 6)})
    })
    
    -- Close Button
    local closeBtn = Utility.Create("TextButton", {
        Name = "CloseBtn",
        Parent = controlButtons,
        BackgroundColor3 = Color3.fromRGB(255, 80, 80),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 25, 0, 25),
        Position = UDim2.new(0, 60, 0, 0),
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 20,
        ZIndex = 12
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 6)})
    })
    
    -- Tab Container (Left Side)
    local tabContainer = Utility.Create("Frame", {
        Name = "TabContainer",
        Parent = self.MainFrame,
        BackgroundColor3 = Color3.fromRGB(18, 18, 30),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Size = UDim2.new(0, IsMobile and 50 or 150, 1, -50),
        Position = UDim2.new(0, 0, 0, 50),
        ZIndex = 5
    })
    
    local tabList = Utility.Create("ScrollingFrame", {
        Name = "TabList",
        Parent = tabContainer,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, -10),
        Position = UDim2.new(0, 0, 0, 5),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = self.ThemeColor,
        ZIndex = 6
    }, {
        Utility.Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5)
        }),
        Utility.Create("UIPadding", {
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 5),
            PaddingTop = UDim.new(0, 5)
        })
    })
    
    -- Content Container
    local contentContainer = Utility.Create("Frame", {
        Name = "ContentContainer",
        Parent = self.MainFrame,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, IsMobile and -50 or -150, 1, -50),
        Position = UDim2.new(0, IsMobile and 50 or 150, 0, 50),
        ZIndex = 5
    })
    
    -- Store references
    self.TopBar = topBar
    self.TabContainer = tabContainer
    self.TabList = tabList
    self.ContentContainer = contentContainer
    self.ControlButtons = controlButtons
    
    -- Setup dragging
    self:SetupDragging()
    
    -- Setup control buttons
    self:SetupControlButtons(minimizeBtn, maximizeBtn, closeBtn)
    
    -- Setup keybind
    self:SetupKeybind()
    
    -- Animate window open
    Utility.PlaySound(Sounds.Open, 0.5)
    Utility.Tween(self.MainFrame, {Size = self.Size}, 0.5, Enum.EasingStyle.Back)
    
    -- Auto load config if set
    if self.AutoLoadConfig then
        task.spawn(function()
            task.wait(0.5)
            local config = ConfigSystem.LoadConfig(self.AutoLoadConfig)
            if config then
                self:ApplyConfig(config)
            end
        end)
    end
    
    -- Add settings tab automatically
    task.spawn(function()
        task.wait(0.6)
        self:CreateSettingsTab()
    end)
end

function QuantumUI:SetupDragging()
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    local function updateDrag(input)
        local delta = input.Position - dragStart
        local targetPos = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        Utility.Tween(self.MainFrame, {Position = targetPos}, 0.1)
    end
    
    self.TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    self.TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                updateDrag(input)
            end
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch) then
            updateDrag(input)
        end
    end)
end

function QuantumUI:SetupControlButtons(minimize, maximize, close)
    -- Minimize
    minimize.MouseButton1Click:Connect(function()
        Utility.PlaySound(Sounds.Click, 0.3)
        Utility.Ripple(minimize, Vector2.new(minimize.AbsolutePosition.X + minimize.AbsoluteSize.X/2, 
                                              minimize.AbsolutePosition.Y + minimize.AbsoluteSize.Y/2))
        
        if self.MainFrame.Size.Y.Offset > 60 then
            self._savedSize = self.MainFrame.Size
            Utility.Tween(self.MainFrame, {Size = UDim2.new(self.MainFrame.Size.X.Scale, self.MainFrame.Size.X.Offset, 0, 50)}, 0.3)
        else
            Utility.Tween(self.MainFrame, {Size = self._savedSize or self.Size}, 0.3)
        end
    end)
    
    -- Maximize
    local isMaximized = false
    maximize.MouseButton1Click:Connect(function()
        Utility.PlaySound(Sounds.Click, 0.3)
        Utility.Ripple(maximize, Vector2.new(maximize.AbsolutePosition.X + maximize.AbsoluteSize.X/2,
                                              maximize.AbsolutePosition.Y + maximize.AbsoluteSize.Y/2))
        
        if isMaximized then
            Utility.Tween(self.MainFrame, {Size = self.Size, Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.3)
        else
            Utility.Tween(self.MainFrame, {Size = UDim2.new(0.95, 0, 0.9, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.3)
        end
        isMaximized = not isMaximized
    end)
    
    -- Close
    close.MouseButton1Click:Connect(function()
        Utility.PlaySound(Sounds.Close, 0.3)
        self:Hide()
    end)
    
    -- Hover effects
    for _, btn in ipairs({minimize, maximize, close}) do
        btn.MouseEnter:Connect(function()
            Utility.PlaySound(Sounds.Hover, 0.1)
            Utility.Tween(btn, {BackgroundTransparency = 0.2}, 0.2)
        end)
        btn.MouseLeave:Connect(function()
            Utility.Tween(btn, {BackgroundTransparency = 0.5}, 0.2)
        end)
    end
end

function QuantumUI:SetupKeybind()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == self.Keybind then
            self:Toggle()
        end
    end)
end

function QuantumUI:Show()
    self.Visible = true
    self.MainFrame.Visible = true
    Utility.PlaySound(Sounds.Open, 0.5)
    Utility.Tween(self.MainFrame, {Size = self.Size}, 0.3, Enum.EasingStyle.Back)
end

function QuantumUI:Hide()
    self.Visible = false
    Utility.Tween(self.MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Quart)
    task.delay(0.3, function()
        if not self.Visible then
            self.MainFrame.Visible = false
        end
    end)
end

function QuantumUI:Toggle()
    if self.Visible then
        self:Hide()
    else
        self:Show()
    end
end

function QuantumUI:Destroy()
    RainbowHandler.Stop()
    self.ScreenGui:Destroy()
end

-- Tab Creation
function QuantumUI:AddTab(options)
    options = options or {}
    local tabName = options.Name or "Tab"
    local tabIcon = options.Icon or "rbxassetid://6031280882"
    
    local tab = {}
    tab.Name = tabName
    tab.Elements = {}
    
    -- Tab Button
    local tabButton = Utility.Create("TextButton", {
        Name = tabName .. "_Tab",
        Parent = self.TabList,
        BackgroundColor3 = Color3.fromRGB(30, 30, 45),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, IsMobile and 45 or 40),
        Font = Enum.Font.GothamSemibold,
        Text = IsMobile and "" or tabName,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextSize = 14,
        ZIndex = 7
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 8)})
    })
    
    -- Tab Icon
    local iconLabel = Utility.Create("ImageLabel", {
        Name = "Icon",
        Parent = tabButton,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(0, IsMobile and 12 or 10, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Image = tabIcon,
        ImageColor3 = Color3.fromRGB(200, 200, 200),
        ZIndex = 8
    })
    
    if not IsMobile then
        tabButton.TextXAlignment = Enum.TextXAlignment.Left
        tabButton.Text = "      " .. tabName
    end
    
    -- Selection Indicator
    local indicator = Utility.Create("Frame", {
        Name = "Indicator",
        Parent = tabButton,
        BackgroundColor3 = self.ThemeColor,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 0.6, 0),
        Position = UDim2.new(0, 0, 0.2, 0),
        Visible = false,
        ZIndex = 8
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 2)})
    })
    
    -- Tab Content Page
    local tabPage = Utility.Create("ScrollingFrame", {
        Name = tabName .. "_Page",
        Parent = self.ContentContainer,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -20, 1, -20),
        Position = UDim2.new(0, 10, 0, 10),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.ThemeColor,
        Visible = false,
        ZIndex = 6
    }, {
        Utility.Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10)
        }),
        Utility.Create("UIPadding", {
            PaddingTop = UDim.new(0, 5),
            PaddingBottom = UDim.new(0, 5)
        })
    })
    
    tab.Button = tabButton
    tab.Page = tabPage
    tab.Indicator = indicator
    tab.Icon = iconLabel
    
    -- Tab Selection
    tabButton.MouseButton1Click:Connect(function()
        Utility.PlaySound(Sounds.Click, 0.3)
        self:SelectTab(tab)
    end)
    
    -- Hover Effects
    tabButton.MouseEnter:Connect(function()
        Utility.PlaySound(Sounds.Hover, 0.1)
        Utility.Tween(tabButton, {BackgroundTransparency = 0.3}, 0.2)
    end)
    
    tabButton.MouseLeave:Connect(function()
        if self.SelectedTab ~= tab then
            Utility.Tween(tabButton, {BackgroundTransparency = 0.5}, 0.2)
        end
    end)
    
    table.insert(self.Tabs, tab)
    
    -- Update canvas size
    local layout = self.TabList:FindFirstChildOfClass("UIListLayout")
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.TabList.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)
    
    -- Select first tab
    if #self.Tabs == 1 then
        self:SelectTab(tab)
    end
    
    -- Add element creation functions to tab
    setmetatable(tab, {__index = self})
    tab.ParentPage = tabPage
    
    function tab:AddSection(options)
        return self:CreateSection(tabPage, options)
    end
    
    function tab:AddButton(options)
        return self:CreateButton(tabPage, options)
    end
    
    function tab:AddToggle(options)
        return self:CreateToggle(tabPage, options)
    end
    
    function tab:AddSlider(options)
        return self:CreateSlider(tabPage, options)
    end
    
    function tab:AddDropdown(options)
        return self:CreateDropdown(tabPage, options)
    end
    
    function tab:AddTextbox(options)
        return self:CreateTextbox(tabPage, options)
    end
    
    function tab:AddColorPicker(options)
        return self:CreateColorPicker(tabPage, options)
    end
    
    function tab:AddKeybind(options)
        return self:CreateKeybind(tabPage, options)
    end
    
    function tab:AddLabel(options)
        return self:CreateLabel(tabPage, options)
    end
    
    function tab:AddParagraph(options)
        return self:CreateParagraph(tabPage, options)
    end
    
    return tab
end

function QuantumUI:SelectTab(tab)
    -- Deselect all tabs
    for _, t in ipairs(self.Tabs) do
        t.Page.Visible = false
        t.Indicator.Visible = false
        Utility.Tween(t.Button, {BackgroundTransparency = 0.5}, 0.2)
        Utility.Tween(t.Icon, {ImageColor3 = Color3.fromRGB(200, 200, 200)}, 0.2)
    end
    
    -- Select new tab
    tab.Page.Visible = true
    tab.Indicator.Visible = true
    self.SelectedTab = tab
    
    Utility.Tween(tab.Button, {BackgroundTransparency = 0.2}, 0.2)
    Utility.Tween(tab.Icon, {ImageColor3 = self.ThemeColor}, 0.2)
end

-- Section
function QuantumUI:CreateSection(parent, options)
    options = options or {}
    local sectionName = options.Name or "Section"
    
    local sectionFrame = Utility.Create("Frame", {
        Name = sectionName .. "_Section",
        Parent = parent,
        BackgroundColor3 = Color3.fromRGB(25, 25, 40),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 35),
        ZIndex = 7
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 8)})
    })
    
    local sectionLabel = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = sectionFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Font = Enum.Font.GothamBold,
        Text = sectionName,
        TextColor3 = self.ThemeColor,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8
    })
    
    -- Decorative Line
    local line = Utility.Create("Frame", {
        Name = "Line",
        Parent = sectionFrame,
        BackgroundColor3 = self.ThemeColor,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Size = UDim2.new(0.3, 0, 0, 2),
        Position = UDim2.new(0, 10, 1, -5),
        ZIndex = 8
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0)}),
        Utility.CreateGradient({self.ThemeColor, Color3.fromRGB(255, 255, 255)}, 0)
    })
    
    self:UpdateContentSize(parent)
    
    return sectionFrame
end

-- Button
function QuantumUI:CreateButton(parent, options)
    options = options or {}
    local buttonName = options.Name or "Button"
    local callback = options.Callback or function() end
    
    local buttonFrame = Utility.Create("Frame", {
        Name = buttonName .. "_Button",
        Parent = parent,
        BackgroundColor3 = Color3.fromRGB(30, 30, 45),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 45),
        ZIndex = 7
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
        Utility.Create("UIStroke", {
            Color = self.ThemeColor,
            Thickness = 1,
            Transparency = 0.7
        })
    })
    
    local button = Utility.Create("TextButton", {
        Name = "Button",
        Parent = buttonFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamSemibold,
        Text = buttonName,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        ZIndex = 8
    })
    
    -- Glow effect
    local glow = Utility.Create("ImageLabel", {
        Name = "Glow",
        Parent = buttonFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 10, 1, 10),
        Position = UDim2.new(0, -5, 0, -5),
        Image = "rbxassetid://5028857084",
        ImageColor3 = self.ThemeColor,
        ImageTransparency = 0.9,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(24, 24, 276, 276),
        ZIndex = 6
    })
    
    button.MouseButton1Click:Connect(function()
        Utility.PlaySound(Sounds.Click, 0.3)
        Utility.Ripple(buttonFrame, Vector2.new(Mouse.X, Mouse.Y), self.ThemeColor)
        
        -- Flash effect
        Utility.Tween(buttonFrame, {BackgroundColor3 = self.ThemeColor}, 0.1)
        task.wait(0.1)
        Utility.Tween(buttonFrame, {BackgroundColor3 = Color3.fromRGB(30, 30, 45)}, 0.2)
        
        callback()
    end)
    
    button.MouseEnter:Connect(function()
        Utility.PlaySound(Sounds.Hover, 0.1)
        Utility.Tween(glow, {ImageTransparency = 0.7}, 0.2)
        Utility.Tween(buttonFrame:FindFirstChildOfClass("UIStroke"), {Transparency = 0.3}, 0.2)
    end)
    
    button.MouseLeave:Connect(function()
        Utility.Tween(glow, {ImageTransparency = 0.9}, 0.2)
        Utility.Tween(buttonFrame:FindFirstChildOfClass("UIStroke"), {Transparency = 0.7}, 0.2)
    end)
    
    self:UpdateContentSize(parent)
    
    local buttonObj = {
        Frame = buttonFrame,
        SetText = function(_, text)
            button.Text = text
        end
    }
    
    return buttonObj
end

-- Toggle
function QuantumUI:CreateToggle(parent, options)
    options = options or {}
    local toggleName = options.Name or "Toggle"
    local default = options.Default or false
    local callback = options.Callback or function() end
    local flag = options.Flag
    
    local toggled = default
    
    local toggleFrame = Utility.Create("Frame", {
        Name = toggleName .. "_Toggle",
        Parent = parent,
        BackgroundColor3 = Color3.fromRGB(30, 30, 45),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 45),
        ZIndex = 7
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 8)})
    })
    
    local label = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = toggleFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        Font = Enum.Font.GothamSemibold,
        Text = toggleName,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8
    })
    
    local toggleContainer = Utility.Create("Frame", {
        Name = "ToggleContainer",
        Parent = toggleFrame,
        BackgroundColor3 = Color3.fromRGB(50, 50, 65),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 50, 0, 26),
        Position = UDim2.new(1, -60, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        ZIndex = 8
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0)})
    })
    
    local toggleIndicator = Utility.Create("Frame", {
        Name = "Indicator",
        Parent = toggleContainer,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(0, 3, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        ZIndex = 9
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0)})
    })
    
    local function updateToggle(state, skipCallback)
        toggled = state
        
        if toggled then
            Utility.Tween(toggleContainer, {BackgroundColor3 = self.ThemeColor}, 0.2)
            Utility.Tween(toggleIndicator, {Position = UDim2.new(1, -23, 0.5, 0)}, 0.2)
        else
            Utility.Tween(toggleContainer, {BackgroundColor3 = Color3.fromRGB(50, 50, 65)}, 0.2)
            Utility.Tween(toggleIndicator, {Position = UDim2.new(0, 3, 0.5, 0)}, 0.2)
        end
        
        if not skipCallback then
            callback(toggled)
        end
        
        if flag then
            self.ConfigData[flag] = toggled
        end
    end
    
    local toggleButton = Utility.Create("TextButton", {
        Name = "Button",
        Parent = toggleFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        ZIndex = 10
    })
    
    toggleButton.MouseButton1Click:Connect(function()
        Utility.PlaySound(Sounds.Toggle, 0.3)
        updateToggle(not toggled)
    end)
    
    -- Initialize
    updateToggle(default, true)
    
    self:UpdateContentSize(parent)
    
    local toggleObj = {
        Frame = toggleFrame,
        Value = toggled,
        Set = function(_, state)
            updateToggle(state)
        end,
        Get = function()
            return toggled
        end
    }
    
    if flag then
        self.Elements[flag] = toggleObj
    end
    
    return toggleObj
end

-- Slider
function QuantumUI:CreateSlider(parent, options)
    options = options or {}
    local sliderName = options.Name or "Slider"
    local min = options.Min or 0
    local max = options.Max or 100
    local default = options.Default or min
    local increment = options.Increment or 1
    local callback = options.Callback or function() end
    local suffix = options.Suffix or ""
    local flag = options.Flag
    
    local value = default
    
    local sliderFrame = Utility.Create("Frame", {
        Name = sliderName .. "_Slider",
        Parent = parent,
        BackgroundColor3 = Color3.fromRGB(30, 30, 45),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 55),
        ZIndex = 7
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 8)})
    })
    
    local label = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = sliderFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.6, 0, 0, 25),
        Position = UDim2.new(0, 15, 0, 5),
        Font = Enum.Font.GothamSemibold,
        Text = sliderName,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8
    })
    
    local valueLabel = Utility.Create("TextLabel", {
        Name = "Value",
        Parent = sliderFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.3, 0, 0, 25),
        Position = UDim2.new(0.7, -15, 0, 5),
        Font = Enum.Font.GothamSemibold,
        Text = tostring(value) .. suffix,
        TextColor3 = self.ThemeColor,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 8
    })
    
    local sliderContainer = Utility.Create("Frame", {
        Name = "SliderContainer",
        Parent = sliderFrame,
        BackgroundColor3 = Color3.fromRGB(50, 50, 65),
        BorderSizePixel = 0,
        Size = UDim2.new(1, -30, 0, 8),
        Position = UDim2.new(0, 15, 0, 35),
        ZIndex = 8
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0)})
    })
    
    local sliderFill = Utility.Create("Frame", {
        Name = "Fill",
        Parent = sliderContainer,
        BackgroundColor3 = self.ThemeColor,
        BorderSizePixel = 0,
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        ZIndex = 9
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0)}),
        Utility.CreateGradient({self.ThemeColor, Color3.fromRGB(255, 255, 255)}, 0)
    })
    
    local sliderKnob = Utility.Create("Frame", {
        Name = "Knob",
        Parent = sliderContainer,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new((default - min) / (max - min), -8, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        ZIndex = 10
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0)}),
        Utility.Create("UIStroke", {
            Color = self.ThemeColor,
            Thickness = 2
        })
    })
    
    local function updateSlider(newValue, skipCallback)
        value = math.clamp(newValue, min, max)
        value = math.floor(value / increment + 0.5) * increment
        
        local percent = (value - min) / (max - min)
        Utility.Tween(sliderFill, {Size = UDim2.new(percent, 0, 1, 0)}, 0.1)
        Utility.Tween(sliderKnob, {Position = UDim2.new(percent, -8, 0.5, 0)}, 0.1)
        valueLabel.Text = tostring(value) .. suffix
        
        if not skipCallback then
            callback(value)
        end
        
        if flag then
            self.ConfigData[flag] = value
        end
    end
    
    local dragging = false
    
    sliderContainer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            local percent = math.clamp((input.Position.X - sliderContainer.AbsolutePosition.X) / sliderContainer.AbsoluteSize.X, 0, 1)
            updateSlider(min + (max - min) * percent)
        end
    end)
    
    sliderContainer.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch) then
            local percent = math.clamp((input.Position.X - sliderContainer.AbsolutePosition.X) / sliderContainer.AbsoluteSize.X, 0, 1)
            updateSlider(min + (max - min) * percent)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    -- Initialize
    updateSlider(default, true)
    
    self:UpdateContentSize(parent)
    
    local sliderObj = {
        Frame = sliderFrame,
        Value = value,
        Set = function(_, newValue)
            updateSlider(newValue)
        end,
        Get = function()
            return value
        end
    }
    
    if flag then
        self.Elements[flag] = sliderObj
    end
    
    return sliderObj
end

-- Dropdown
function QuantumUI:CreateDropdown(parent, options)
    options = options or {}
    local dropdownName = options.Name or "Dropdown"
    local items = options.Items or {}
    local default = options.Default or (items[1] or nil)
    local multi = options.Multi or false
    local callback = options.Callback or function() end
    local flag = options.Flag
    
    local selected = multi and {} or default
    local isOpen = false
    
    if multi and default then
        for _, item in ipairs(type(default) == "table" and default or {default}) do
            selected[item] = true
        end
    end
    
    local dropdownFrame = Utility.Create("Frame", {
        Name = dropdownName .. "_Dropdown",
        Parent = parent,
        BackgroundColor3 = Color3.fromRGB(30, 30, 45),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 45),
        ClipsDescendants = true,
        ZIndex = 20
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 8)})
    })
    
    local label = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = dropdownFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, 0, 0, 45),
        Position = UDim2.new(0, 15, 0, 0),
        Font = Enum.Font.GothamSemibold,
        Text = dropdownName,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 21
    })
    
    local selectedLabel = Utility.Create("TextLabel", {
        Name = "Selected",
        Parent = dropdownFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.4, -20, 0, 45),
        Position = UDim2.new(0.5, 0, 0, 0),
        Font = Enum.Font.Gotham,
        Text = tostring(default or "Select..."),
        TextColor3 = self.ThemeColor,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 21
    })
    
    local arrow = Utility.Create("TextLabel", {
        Name = "Arrow",
        Parent = dropdownFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 20, 0, 45),
        Position = UDim2.new(1, -25, 0, 0),
        Font = Enum.Font.GothamBold,
        Text = "▼",
        TextColor3 = self.ThemeColor,
        TextSize = 12,
        ZIndex = 21
    })
    
    local itemContainer = Utility.Create("Frame", {
        Name = "ItemContainer",
        Parent = dropdownFrame,
        BackgroundColor3 = Color3.fromRGB(25, 25, 40),
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -20, 0, 0),
        Position = UDim2.new(0, 10, 0, 50),
        ClipsDescendants = true,
        ZIndex = 21
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
        Utility.Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 2)
        }),
        Utility.Create("UIPadding", {
            PaddingTop = UDim.new(0, 5),
            PaddingBottom = UDim.new(0, 5),
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 5)
        })
    })
    
    local function updateSelected()
        if multi then
            local selectedItems = {}
            for item, isSelected in pairs(selected) do
                if isSelected then
                    table.insert(selectedItems, item)
                end
            end
            selectedLabel.Text = #selectedItems > 0 and table.concat(selectedItems, ", ") or "Select..."
        else
            selectedLabel.Text = selected or "Select..."
        end
    end
    
    local function createItem(itemName)
        local itemButton = Utility.Create("TextButton", {
            Name = itemName,
            Parent = itemContainer,
            BackgroundColor3 = Color3.fromRGB(40, 40, 55),
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 30),
            Font = Enum.Font.Gotham,
            Text = itemName,
            TextColor3 = Color3.fromRGB(200, 200, 200),
            TextSize = 12,
            ZIndex = 22
        }, {
            Utility.Create("UICorner", {CornerRadius = UDim.new(0, 4)})
        })
        
        if multi then
            local check = Utility.Create("TextLabel", {
                Name = "Check",
                Parent = itemButton,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 20, 1, 0),
                Position = UDim2.new(1, -25, 0, 0),
                Font = Enum.Font.GothamBold,
                Text = selected[itemName] and "✓" or "",
                TextColor3 = self.ThemeColor,
                TextSize = 14,
                ZIndex = 23
            })
            
            itemButton.MouseButton1Click:Connect(function()
                Utility.PlaySound(Sounds.Click, 0.2)
                selected[itemName] = not selected[itemName]
                check.Text = selected[itemName] and "✓" or ""
                updateSelected()
                callback(selected)
                
                if flag then
                    self.ConfigData[flag] = selected
                end
            end)
        else
            itemButton.MouseButton1Click:Connect(function()
                Utility.PlaySound(Sounds.Click, 0.2)
                selected = itemName
                updateSelected()
                callback(selected)
                
                -- Close dropdown
                isOpen = false
                Utility.Tween(dropdownFrame, {Size = UDim2.new(1, 0, 0, 45)}, 0.3)
                Utility.Tween(arrow, {Rotation = 0}, 0.3)
                
                if flag then
                    self.ConfigData[flag] = selected
                end
            end)
        end
        
        itemButton.MouseEnter:Connect(function()
            Utility.Tween(itemButton, {BackgroundTransparency = 0.3}, 0.2)
        end)
        
        itemButton.MouseLeave:Connect(function()
            Utility.Tween(itemButton, {BackgroundTransparency = 0.5}, 0.2)
        end)
        
        return itemButton
    end
    
    -- Create items
    for _, item in ipairs(items) do
        createItem(item)
    end
    
    -- Toggle dropdown
    local toggleButton = Utility.Create("TextButton", {
        Name = "Toggle",
        Parent = dropdownFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 45),
        Text = "",
        ZIndex = 25
    })
    
    toggleButton.MouseButton1Click:Connect(function()
        Utility.PlaySound(Sounds.Click, 0.3)
        isOpen = not isOpen
        
        if isOpen then
            local itemCount = #items
            local height = math.min(itemCount * 32 + 15, 200)
            Utility.Tween(dropdownFrame, {Size = UDim2.new(1, 0, 0, 50 + height)}, 0.3)
            Utility.Tween(itemContainer, {Size = UDim2.new(1, -20, 0, height)}, 0.3)
            Utility.Tween(arrow, {Rotation = 180}, 0.3)
        else
            Utility.Tween(dropdownFrame, {Size = UDim2.new(1, 0, 0, 45)}, 0.3)
            Utility.Tween(itemContainer, {Size = UDim2.new(1, -20, 0, 0)}, 0.3)
            Utility.Tween(arrow, {Rotation = 0}, 0.3)
        end
        
        self:UpdateContentSize(parent)
    end)
    
    updateSelected()
    self:UpdateContentSize(parent)
    
    local dropdownObj = {
        Frame = dropdownFrame,
        Value = selected,
        Set = function(_, newValue)
            if multi then
                selected = {}
                for _, item in ipairs(type(newValue) == "table" and newValue or {newValue}) do
                    selected[item] = true
                end
            else
                selected = newValue
            end
            updateSelected()
            callback(selected)
        end,
        Get = function()
            return selected
        end,
        Refresh = function(_, newItems)
            items = newItems
            for _, child in ipairs(itemContainer:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            for _, item in ipairs(items) do
                createItem(item)
            end
        end,
        Add = function(_, item)
            table.insert(items, item)
            createItem(item)
        end,
        Remove = function(_, item)
            for i, v in ipairs(items) do
                if v == item then
                    table.remove(items, i)
                    break
                end
            end
            local itemBtn = itemContainer:FindFirstChild(item)
            if itemBtn then
                itemBtn:Destroy()
            end
        end
    }
    
    if flag then
        self.Elements[flag] = dropdownObj
    end
    
    return dropdownObj
end

-- Textbox
function QuantumUI:CreateTextbox(parent, options)
    options = options or {}
    local textboxName = options.Name or "Textbox"
    local placeholder = options.Placeholder or "Enter text..."
    local default = options.Default or ""
    local clearOnFocus = options.ClearOnFocus or false
    local callback = options.Callback or function() end
    local flag = options.Flag
    
    local textboxFrame = Utility.Create("Frame", {
        Name = textboxName .. "_Textbox",
        Parent = parent,
        BackgroundColor3 = Color3.fromRGB(30, 30, 45),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 45),
        ZIndex = 7
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 8)})
    })
    
    local label = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = textboxFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.4, 0, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        Font = Enum.Font.GothamSemibold,
        Text = textboxName,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8
    })
    
    local textboxContainer = Utility.Create("Frame", {
        Name = "Container",
        Parent = textboxFrame,
        BackgroundColor3 = Color3.fromRGB(40, 40, 55),
        BorderSizePixel = 0,
        Size = UDim2.new(0.55, -20, 0, 30),
        Position = UDim2.new(0.45, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        ZIndex = 8
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
        Utility.Create("UIStroke", {
            Color = self.ThemeColor,
            Thickness = 1,
            Transparency = 0.7
        })
    })
    
    local textbox = Utility.Create("TextBox", {
        Name = "Textbox",
        Parent = textboxContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Font = Enum.Font.Gotham,
        Text = default,
        PlaceholderText = placeholder,
        PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = clearOnFocus,
        ZIndex = 9
    })
    
    textbox.Focused:Connect(function()
        Utility.PlaySound(Sounds.Click, 0.2)
        Utility.Tween(textboxContainer:FindFirstChildOfClass("UIStroke"), {Transparency = 0.3}, 0.2)
    end)
    
    textbox.FocusLost:Connect(function(enterPressed)
        Utility.Tween(textboxContainer:FindFirstChildOfClass("UIStroke"), {Transparency = 0.7}, 0.2)
        callback(textbox.Text, enterPressed)
        
        if flag then
            self.ConfigData[flag] = textbox.Text
        end
    end)
    
    self:UpdateContentSize(parent)
    
    local textboxObj = {
        Frame = textboxFrame,
        Value = textbox.Text,
        Set = function(_, text)
            textbox.Text = text
            if flag then
                self.ConfigData[flag] = text
            end
        end,
        Get = function()
            return textbox.Text
        end
    }
    
    if flag then
        self.Elements[flag] = textboxObj
    end
    
    return textboxObj
end

-- Color Picker (Circular)
function QuantumUI:CreateColorPicker(parent, options)
    options = options or {}
    local pickerName = options.Name or "Color Picker"
    local default = options.Default or Color3.fromRGB(255, 255, 255)
    local presets = options.Presets or {
        Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(255, 127, 0),
        Color3.fromRGB(255, 255, 0),
        Color3.fromRGB(0, 255, 0),
        Color3.fromRGB(0, 255, 255),
        Color3.fromRGB(0, 0, 255),
        Color3.fromRGB(127, 0, 255),
        Color3.fromRGB(255, 0, 255),
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(0, 0, 0)
    }
    local callback = options.Callback or function() end
    local flag = options.Flag
    
    local currentColor = default
    local isOpen = false
    local h, s, v = Utility.RGBToHSV(default)
    
    local pickerFrame = Utility.Create("Frame", {
        Name = pickerName .. "_ColorPicker",
        Parent = parent,
        BackgroundColor3 = Color3.fromRGB(30, 30, 45),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 45),
        ClipsDescendants = true,
        ZIndex = 15
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 8)})
    })
    
    local label = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = pickerFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.6, 0, 0, 45),
        Position = UDim2.new(0, 15, 0, 0),
        Font = Enum.Font.GothamSemibold,
        Text = pickerName,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 16
    })
    
    local colorPreview = Utility.Create("Frame", {
        Name = "Preview",
        Parent = pickerFrame,
        BackgroundColor3 = currentColor,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 35, 0, 25),
        Position = UDim2.new(1, -50, 0, 10),
        ZIndex = 16
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
        Utility.Create("UIStroke", {
            Color = Color3.fromRGB(255, 255, 255),
            Thickness = 1,
            Transparency = 0.5
        })
    })
    
    -- Picker Container
    local pickerContainer = Utility.Create("Frame", {
        Name = "PickerContainer",
        Parent = pickerFrame,
        BackgroundColor3 = Color3.fromRGB(25, 25, 40),
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -20, 0, 0),
        Position = UDim2.new(0, 10, 0, 50),
        ClipsDescendants = true,
        ZIndex = 16
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 8)})
    })
    
    -- Circular Color Wheel
    local wheelSize = IsMobile and 150 or 180
    local wheelContainer = Utility.Create("Frame", {
        Name = "WheelContainer",
        Parent = pickerContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, wheelSize, 0, wheelSize),
        Position = UDim2.new(0, 15, 0, 15),
        ZIndex = 17
    })
    
    local colorWheel = Utility.Create("ImageLabel", {
        Name = "ColorWheel",
        Parent = wheelContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Image = "rbxassetid://6020299385",
        ZIndex = 18
    })
    
    -- Value/Brightness overlay
    local valueOverlay = Utility.Create("ImageLabel", {
        Name = "ValueOverlay",
        Parent = wheelContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Image = "rbxassetid://6020299385",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 1 - v,
        ZIndex = 19
    })
    
    -- Wheel Cursor
    local wheelCursor = Utility.Create("Frame", {
        Name = "Cursor",
        Parent = wheelContainer,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 16, 0, 16),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 20
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0)}),
        Utility.Create("UIStroke", {
            Color = Color3.fromRGB(0, 0, 0),
            Thickness = 2
        })
    })
    
    -- Value Slider (Vertical)
    local valueSliderContainer = Utility.Create("Frame", {
        Name = "ValueSlider",
        Parent = pickerContainer,
        BackgroundColor3 = Color3.fromRGB(50, 50, 65),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 20, 0, wheelSize),
        Position = UDim2.new(0, wheelSize + 30, 0, 15),
        ZIndex = 17
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
        Utility.Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
            }),
            Rotation = 90
        })
    })
    
    local valueSliderKnob = Utility.Create("Frame", {
        Name = "Knob",
        Parent = valueSliderContainer,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 6, 0, 8),
        Position = UDim2.new(0, -3, 1 - v, -4),
        ZIndex = 18
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 3)}),
        Utility.Create("UIStroke", {
            Color = Color3.fromRGB(0, 0, 0),
            Thickness = 1
        })
    })
    
    -- Hex Input
    local hexContainer = Utility.Create("Frame", {
        Name = "HexContainer",
        Parent = pickerContainer,
        BackgroundColor3 = Color3.fromRGB(40, 40, 55),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 100, 0, 30),
        Position = UDim2.new(0, 15, 0, wheelSize + 25),
        ZIndex = 17
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 6)})
    })
    
    local hexLabel = Utility.Create("TextLabel", {
        Name = "HexLabel",
        Parent = hexContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 25, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "#",
        TextColor3 = self.ThemeColor,
        TextSize = 14,
        ZIndex = 18
    })
    
    local hexInput = Utility.Create("TextBox", {
        Name = "HexInput",
        Parent = hexContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 25, 0, 0),
        Font = Enum.Font.Code,
        Text = string.format("%02X%02X%02X", currentColor.R * 255, currentColor.G * 255, currentColor.B * 255),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 12,
        ZIndex = 18
    })
    
    -- RGB Inputs
    local rgbContainer = Utility.Create("Frame", {
        Name = "RGBContainer",
        Parent = pickerContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 100, 0, 30),
        Position = UDim2.new(0, 120, 0, wheelSize + 25),
        ZIndex = 17
    })
    
    local function createRGBInput(name, defaultVal, xPos)
        local container = Utility.Create("Frame", {
            Name = name .. "Container",
            Parent = rgbContainer,
            BackgroundColor3 = Color3.fromRGB(40, 40, 55),
            BorderSizePixel = 0,
            Size = UDim2.new(0, 45, 0, 30),
            Position = UDim2.new(0, xPos, 0, 0),
            ZIndex = 17
        }, {
            Utility.Create("UICorner", {CornerRadius = UDim.new(0, 6)})
        })
        
        local lbl = Utility.Create("TextLabel", {
            Name = "Label",
            Parent = container,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 15, 1, 0),
            Font = Enum.Font.GothamBold,
            Text = name,
            TextColor3 = name == "R" and Color3.fromRGB(255, 100, 100) or 
                         name == "G" and Color3.fromRGB(100, 255, 100) or 
                         Color3.fromRGB(100, 100, 255),
            TextSize = 10,
            ZIndex = 18
        })
        
        local input = Utility.Create("TextBox", {
            Name = "Input",
            Parent = container,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -15, 1, 0),
            Position = UDim2.new(0, 15, 0, 0),
            Font = Enum.Font.Code,
            Text = tostring(defaultVal),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 11,
            ZIndex = 18
        })
        
        return input
    end
    
    local rInput = createRGBInput("R", math.floor(currentColor.R * 255), 0)
    local gInput = createRGBInput("G", math.floor(currentColor.G * 255), 50)
    local bInput = createRGBInput("B", math.floor(currentColor.B * 255), 100)
    
    -- Preset Colors
    local presetContainer = Utility.Create("Frame", {
        Name = "PresetContainer",
        Parent = pickerContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -30, 0, 35),
        Position = UDim2.new(0, 15, 0, wheelSize + 65),
        ZIndex = 17
    }, {
        Utility.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5)
        })
    })
    
    local function updateColor(newColor, skipCallback)
        currentColor = newColor
        h, s, v = Utility.RGBToHSV(newColor)
        
        colorPreview.BackgroundColor3 = newColor
        valueOverlay.ImageTransparency = v
        
        -- Update cursor position
        local angle = h * math.pi * 2
        local radius = s * (wheelSize / 2 - 10)
        local centerX = wheelSize / 2
        local centerY = wheelSize / 2
        wheelCursor.Position = UDim2.new(0, centerX + math.cos(angle) * radius, 0, centerY - math.sin(angle) * radius)
        
        -- Update value slider
        valueSliderKnob.Position = UDim2.new(0, -3, 1 - v, -4)
        
        -- Update inputs
        hexInput.Text = string.format("%02X%02X%02X", newColor.R * 255, newColor.G * 255, newColor.B * 255)
        rInput.Text = tostring(math.floor(newColor.R * 255))
        gInput.Text = tostring(math.floor(newColor.G * 255))
        bInput.Text = tostring(math.floor(newColor.B * 255))
        
        if not skipCallback then
            callback(newColor)
        end
        
        if flag then
            self.ConfigData[flag] = {R = newColor.R, G = newColor.G, B = newColor.B}
        end
    end
    
    -- Create preset buttons
    for i, preset in ipairs(presets) do
        local presetBtn = Utility.Create("TextButton", {
            Name = "Preset" .. i,
            Parent = presetContainer,
            BackgroundColor3 = preset,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 25, 0, 25),
            Text = "",
            ZIndex = 18
        }, {
            Utility.Create("UICorner", {CornerRadius = UDim.new(0, 4)}),
            Utility.Create("UIStroke", {
                Color = Color3.fromRGB(255, 255, 255),
                Thickness = 1,
                Transparency = 0.7
            })
        })
        
        presetBtn.MouseButton1Click:Connect(function()
            Utility.PlaySound(Sounds.Click, 0.2)
            updateColor(preset)
        end)
        
        presetBtn.MouseEnter:Connect(function()
            Utility.Tween(presetBtn:FindFirstChildOfClass("UIStroke"), {Transparency = 0.3}, 0.2)
        end)
        
        presetBtn.MouseLeave:Connect(function()
            Utility.Tween(presetBtn:FindFirstChildOfClass("UIStroke"), {Transparency = 0.7}, 0.2)
        end)
    end
    
    -- Wheel interaction
    local wheelDragging = false
    
    colorWheel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            wheelDragging = true
        end
    end)
    
    colorWheel.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            wheelDragging = false
        end
    end)
    
    local function updateWheelColor(input)
        local centerX = wheelContainer.AbsolutePosition.X + wheelSize / 2
        local centerY = wheelContainer.AbsolutePosition.Y + wheelSize / 2
        local dx = input.Position.X - centerX
        local dy = input.Position.Y - centerY
        local distance = math.sqrt(dx * dx + dy * dy)
        local maxRadius = wheelSize / 2 - 5
        
        if distance <= maxRadius then
            local angle = math.atan2(-dy, dx)
            if angle < 0 then angle = angle + math.pi * 2 end
            h = angle / (math.pi * 2)
            s = math.min(distance / maxRadius, 1)
            updateColor(Utility.HSVToRGB(h, s, v))
        end
    end
    
    UserInputService.InputChanged:Connect(function(input)
        if wheelDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch) then
            updateWheelColor(input)
        end
    end)
    
    colorWheel.InputChanged:Connect(function(input)
        if wheelDragging then
            updateWheelColor(input)
        end
    end)
    
    -- Value slider interaction
    local valueDragging = false
    
    valueSliderContainer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            valueDragging = true
            local percent = math.clamp((input.Position.Y - valueSliderContainer.AbsolutePosition.Y) / valueSliderContainer.AbsoluteSize.Y, 0, 1)
            v = 1 - percent
            updateColor(Utility.HSVToRGB(h, s, v))
        end
    end)
    
    valueSliderContainer.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            valueDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if valueDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch) then
            local percent = math.clamp((input.Position.Y - valueSliderContainer.AbsolutePosition.Y) / valueSliderContainer.AbsoluteSize.Y, 0, 1)
            v = 1 - percent
            updateColor(Utility.HSVToRGB(h, s, v))
        end
    end)
    
    -- Hex input
    hexInput.FocusLost:Connect(function()
        local hex = hexInput.Text:gsub("#", "")
        local success, r, g, b = pcall(function()
            return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
        end)
        if success and r and g and b then
            updateColor(Color3.fromRGB(r, g, b))
        else
            hexInput.Text = string.format("%02X%02X%02X", currentColor.R * 255, currentColor.G * 255, currentColor.B * 255)
        end
    end)
    
    -- RGB inputs
    local function updateFromRGB()
        local r = tonumber(rInput.Text) or 0
        local g = tonumber(gInput.Text) or 0
        local b = tonumber(bInput.Text) or 0
        r = math.clamp(r, 0, 255)
        g = math.clamp(g, 0, 255)
        b = math.clamp(b, 0, 255)
        updateColor(Color3.fromRGB(r, g, b))
    end
    
    rInput.FocusLost:Connect(updateFromRGB)
    gInput.FocusLost:Connect(updateFromRGB)
    bInput.FocusLost:Connect(updateFromRGB)
    
    -- Toggle picker
    local toggleButton = Utility.Create("TextButton", {
        Name = "Toggle",
        Parent = pickerFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 45),
        Text = "",
        ZIndex = 20
    })
    
    toggleButton.MouseButton1Click:Connect(function()
        Utility.PlaySound(Sounds.Click, 0.3)
        isOpen = not isOpen
        
        if isOpen then
            local height = wheelSize + 115
            Utility.Tween(pickerFrame, {Size = UDim2.new(1, 0, 0, 50 + height)}, 0.3)
            Utility.Tween(pickerContainer, {Size = UDim2.new(1, -20, 0, height)}, 0.3)
        else
            Utility.Tween(pickerFrame, {Size = UDim2.new(1, 0, 0, 45)}, 0.3)
            Utility.Tween(pickerContainer, {Size = UDim2.new(1, -20, 0, 0)}, 0.3)
        end
        
        self:UpdateContentSize(parent)
    end)
    
    -- Initialize
    updateColor(default, true)
    self:UpdateContentSize(parent)
    
    local pickerObj = {
        Frame = pickerFrame,
        Value = currentColor,
        Set = function(_, color)
            if type(color) == "table" then
                color = Color3.new(color.R, color.G, color.B)
            end
            updateColor(color)
        end,
        Get = function()
            return currentColor
        end
    }
    
    if flag then
        self.Elements[flag] = pickerObj
    end
    
    return pickerObj
end

-- Keybind
function QuantumUI:CreateKeybind(parent, options)
    options = options or {}
    local keybindName = options.Name or "Keybind"
    local default = options.Default or Enum.KeyCode.Unknown
    local callback = options.Callback or function() end
    local changedCallback = options.ChangedCallback or function() end
    local flag = options.Flag
    
    local currentKey = default
    local listening = false
    
    local keybindFrame = Utility.Create("Frame", {
        Name = keybindName .. "_Keybind",
        Parent = parent,
        BackgroundColor3 = Color3.fromRGB(30, 30, 45),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 45),
        ZIndex = 7
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 8)})
    })
    
    local label = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = keybindFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.6, 0, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        Font = Enum.Font.GothamSemibold,
        Text = keybindName,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8
    })
    
    local keyButton = Utility.Create("TextButton", {
        Name = "KeyButton",
        Parent = keybindFrame,
        BackgroundColor3 = Color3.fromRGB(40, 40, 55),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 80, 0, 28),
        Position = UDim2.new(1, -95, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Font = Enum.Font.GothamSemibold,
        Text = currentKey.Name or "None",
        TextColor3 = self.ThemeColor,
        TextSize = 12,
        ZIndex = 8
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
        Utility.Create("UIStroke", {
            Color = self.ThemeColor,
            Thickness = 1,
            Transparency = 0.5
        })
    })
    
    keyButton.MouseButton1Click:Connect(function()
        Utility.PlaySound(Sounds.Click, 0.3)
        listening = true
        keyButton.Text = "..."
        Utility.Tween(keyButton, {BackgroundColor3 = self.ThemeColor}, 0.2)
    end)
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Escape then
                    currentKey = Enum.KeyCode.Unknown
                    keyButton.Text = "None"
                else
                    currentKey = input.KeyCode
                    keyButton.Text = input.KeyCode.Name
                end
                listening = false
                Utility.Tween(keyButton, {BackgroundColor3 = Color3.fromRGB(40, 40, 55)}, 0.2)
                changedCallback(currentKey)
                
                if flag then
                    self.ConfigData[flag] = currentKey.Name
                end
            end
        else
            if input.KeyCode == currentKey and not gameProcessed then
                callback(currentKey)
            end
        end
    end)
    
    self:UpdateContentSize(parent)
    
    local keybindObj = {
        Frame = keybindFrame,
        Value = currentKey,
        Set = function(_, key)
            if type(key) == "string" then
                key = Enum.KeyCode[key] or Enum.KeyCode.Unknown
            end
            currentKey = key
            keyButton.Text = key.Name or "None"
            if flag then
                self.ConfigData[flag] = key.Name
            end
        end,
        Get = function()
            return currentKey
        end
    }
    
    if flag then
        self.Elements[flag] = keybindObj
    end
    
    return keybindObj
end

-- Label
function QuantumUI:CreateLabel(parent, options)
    options = options or {}
    local text = options.Text or "Label"
    
    local labelFrame = Utility.Create("Frame", {
        Name = "Label",
        Parent = parent,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 25),
        ZIndex = 7
    })
    
    local label = Utility.Create("TextLabel", {
        Name = "Text",
        Parent = labelFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        Font = Enum.Font.Gotham,
        Text = text,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        ZIndex = 8
    })
    
    self:UpdateContentSize(parent)
    
    return {
        Frame = labelFrame,
        SetText = function(_, newText)
            label.Text = newText
        end
    }
end

-- Paragraph
function QuantumUI:CreateParagraph(parent, options)
    options = options or {}
    local title = options.Title or "Paragraph"
    local content = options.Content or "Content"
    
    local paragraphFrame = Utility.Create("Frame", {
        Name = title .. "_Paragraph",
        Parent = parent,
        BackgroundColor3 = Color3.fromRGB(30, 30, 45),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 70),
        ZIndex = 7
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 8)})
    })
    
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = paragraphFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -30, 0, 25),
        Position = UDim2.new(0, 15, 0, 5),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = self.ThemeColor,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8
    })
    
    local contentLabel = Utility.Create("TextLabel", {
        Name = "Content",
        Parent = paragraphFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -30, 0, 35),
        Position = UDim2.new(0, 15, 0, 30),
        Font = Enum.Font.Gotham,
        Text = content,
        TextColor3 = Color3.fromRGB(180, 180, 180),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        ZIndex = 8
    })
    
    -- Auto-adjust height based on content
    local textSize = game:GetService("TextService"):GetTextSize(
        content, 12, Enum.Font.Gotham, Vector2.new(paragraphFrame.AbsoluteSize.X - 30, math.huge)
    )
    paragraphFrame.Size = UDim2.new(1, 0, 0, math.max(70, textSize.Y + 45))
    contentLabel.Size = UDim2.new(1, -30, 0, textSize.Y + 10)
    
    self:UpdateContentSize(parent)
    
    return {
        Frame = paragraphFrame,
        SetTitle = function(_, newTitle)
            titleLabel.Text = newTitle
        end,
        SetContent = function(_, newContent)
            contentLabel.Text = newContent
            local newTextSize = game:GetService("TextService"):GetTextSize(
                newContent, 12, Enum.Font.Gotham, Vector2.new(paragraphFrame.AbsoluteSize.X - 30, math.huge)
            )
            paragraphFrame.Size = UDim2.new(1, 0, 0, math.max(70, newTextSize.Y + 45))
            contentLabel.Size = UDim2.new(1, -30, 0, newTextSize.Y + 10)
            self:UpdateContentSize(parent)
        end
    }
end

-- Settings Tab
function QuantumUI:CreateSettingsTab()
    local settingsTab = self:AddTab({
        Name = "Settings",
        Icon = "rbxassetid://6031280882"
    })
    
    -- Config Section
    settingsTab:AddSection({Name = "📁 Config System"})
    
    -- Config Name Input
    local configNameInput = ""
    settingsTab:AddTextbox({
        Name = "Config Name",
        Placeholder = "Enter config name...",
        Callback = function(text)
            configNameInput = text
        end
    })
    
    -- Save Config Button
    settingsTab:AddButton({
        Name = "💾 Save Config",
        Callback = function()
            if configNameInput and configNameInput ~= "" then
                local success, err = ConfigSystem.SaveConfig(configNameInput, self.ConfigData)
                if success then
                    Utility.PlaySound(Sounds.ConfigSave, 0.5)
                    Utility.ScreenFlash(Color3.fromRGB(0, 255, 100), 0.3)
                    self:UpdateConfigDropdown()
                else
                    Utility.PlaySound(Sounds.Error, 0.5)
                end
            end
        end
    })
    
    -- Config Dropdown
    local configDropdown
    local function getConfigs()
        return ConfigSystem.GetConfigs()
    end
    
    configDropdown = settingsTab:AddDropdown({
        Name = "Select Config",
        Items = getConfigs(),
        Callback = function(selected)
            QuantumUI.CurrentConfig = selected
        end
    })
    
    self.ConfigDropdown = configDropdown
    
    -- Load Config Button
    settingsTab:AddButton({
        Name = "📂 Load Config",
        Callback = function()
            if QuantumUI.CurrentConfig then
                local config = ConfigSystem.LoadConfig(QuantumUI.CurrentConfig)
                if config then
                    Utility.PlaySound(Sounds.ConfigLoad, 0.6)
                    Utility.ScreenFlash(self.ThemeColor, 0.4)
                    self:ApplyConfig(config)
                else
                    Utility.PlaySound(Sounds.Error, 0.5)
                end
            end
        end
    })
    
    -- Delete Config Button
    settingsTab:AddButton({
        Name = "🗑️ Delete Config",
        Callback = function()
            if QuantumUI.CurrentConfig then
                local success = ConfigSystem.DeleteConfig(QuantumUI.CurrentConfig)
                if success then
                    Utility.PlaySound(Sounds.Close, 0.5)
                    self:UpdateConfigDropdown()
                    QuantumUI.CurrentConfig = nil
                end
            end
        end
    })
    
    -- Auto Load Config
    settingsTab:AddDropdown({
        Name = "Auto Load Config",
        Items = getConfigs(),
        Callback = function(selected)
            self.AutoLoadConfig = selected
        end
    })
    
    -- UI Settings Section
    settingsTab:AddSection({Name = "🎨 UI Settings"})
    
    -- Theme Color
    settingsTab:AddColorPicker({
        Name = "Theme Color",
        Default = self.ThemeColor,
        Callback = function(color)
            self.ThemeColor = color
            QuantumUI.ThemeColor = color
            -- Update all theme elements
        end
    })
    
    -- Transparency
    settingsTab:AddSlider({
        Name = "UI Transparency",
        Min = 0,
        Max = 90,
        Default = self.Transparency * 100,
        Suffix = "%",
        Callback = function(value)
            self.Transparency = value / 100
            QuantumUI.Transparency = value / 100
            self.MainFrame.BackgroundTransparency = self.Transparency
        end
    })
    
    -- Rainbow Border Toggle
    settingsTab:AddToggle({
        Name = "Rainbow Border",
        Default = QuantumUI.RainbowEnabled,
        Callback = function(state)
            QuantumUI.RainbowEnabled = state
        end
    })
    
    -- Rainbow Speed
    settingsTab:AddSlider({
        Name = "Rainbow Speed",
        Min = 0.1,
        Max = 5,
        Default = QuantumUI.RainbowSpeed,
        Increment = 0.1,
        Callback = function(value)
            QuantumUI.RainbowSpeed = value
        end
    })
    
    -- Game Actions Section
    settingsTab:AddSection({Name = "🎮 Game Actions"})
    
    -- Rejoin Button
    settingsTab:AddButton({
        Name = "🔄 Rejoin Server",
        Callback = function()
            Utility.PlaySound(Sounds.Click, 0.3)
            local teleportService = game:GetService("TeleportService")
            teleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    })
    
    -- Close All Features
    settingsTab:AddButton({
        Name = "❌ Close All Features",
        Callback = function()
            Utility.PlaySound(Sounds.Close, 0.4)
            -- Reset all toggles
            for flag, element in pairs(self.Elements) do
                if element.Set and type(element.Value) == "boolean" then
                    element:Set(false)
                end
            end
            Utility.ScreenFlash(Color3.fromRGB(255, 0, 0), 0.3)
        end
    })
    
    -- Destroy UI
    settingsTab:AddButton({
        Name = "💀 Destroy UI",
        Callback = function()
            Utility.PlaySound(Sounds.Close, 0.5)
            task.wait(0.3)
            self:Destroy()
        end
    })
    
    -- UI Keybind
    settingsTab:AddKeybind({
        Name = "Toggle UI Keybind",
        Default = self.Keybind,
        ChangedCallback = function(key)
            self.Keybind = key
        end
    })
    
    -- Credits Section
    settingsTab:AddSection({Name = "ℹ️ Information"})
    
    settingsTab:AddParagraph({
        Title = "Quantum UI",
        Content = "Version " .. QuantumUI.Version .. "\n\nA high-quality, sci-fi themed UI library with advanced features including rainbow borders, circular color picker, config system, and mobile support."
    })
    
    settingsTab:AddParagraph({
        Title = "Credits",
        Content = "Created by: log_quick\nGitHub: github.com/log_quick\n\nThank you for using Quantum UI!"
    })
    
    -- Version Label
    settingsTab:AddLabel({
        Text = "Quantum UI v" .. QuantumUI.Version .. " | Made with ❤️ by log_quick"
    })
end

function QuantumUI:UpdateConfigDropdown()
    if self.ConfigDropdown then
        self.ConfigDropdown:Refresh(ConfigSystem.GetConfigs())
    end
end

function QuantumUI:ApplyConfig(config)
    for flag, value in pairs(config) do
        local element = self.Elements[flag]
        if element and element.Set then
            if type(value) == "table" and value.R and value.G and value.B then
                element:Set(Color3.new(value.R, value.G, value.B))
            else
                element:Set(value)
            end
        end
    end
    self.ConfigData = config
end

function QuantumUI:UpdateContentSize(parent)
    if parent and parent:IsA("ScrollingFrame") then
        local layout = parent:FindFirstChildOfClass("UIListLayout")
        if layout then
            task.defer(function()
                parent.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
            end)
        end
    end
end

-- Notification System
function QuantumUI:Notify(options)
    options = options or {}
    local title = options.Title or "Notification"
    local content = options.Content or ""
    local duration = options.Duration or 3
    local notifType = options.Type or "Info"
    
    local typeColors = {
        Info = Color3.fromRGB(0, 170, 255),
        Success = Color3.fromRGB(0, 255, 100),
        Warning = Color3.fromRGB(255, 200, 0),
        Error = Color3.fromRGB(255, 80, 80)
    }
    
    local color = typeColors[notifType] or self.ThemeColor
    
    -- Create notification container if not exists
    if not self.NotificationContainer then
        self.NotificationContainer = Utility.Create("Frame", {
            Name = "NotificationContainer",
            Parent = self.ScreenGui,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 300, 1, 0),
            Position = UDim2.new(1, -320, 0, 0),
            ZIndex = 100
        }, {
            Utility.Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                Padding = UDim.new(0, 10)
            }),
            Utility.Create("UIPadding", {
                PaddingBottom = UDim.new(0, 20)
            })
        })
    end
    
    local notifFrame = Utility.Create("Frame", {
        Name = "Notification",
        Parent = self.NotificationContainer,
        BackgroundColor3 = Color3.fromRGB(20, 20, 35),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(1, 0, 0, 0),
        ZIndex = 101
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 10)}),
        Utility.Create("UIStroke", {
            Color = color,
            Thickness = 2,
            Transparency = 0.3
        })
    })
    
    -- Color accent bar
    local accentBar = Utility.Create("Frame", {
        Name = "AccentBar",
        Parent = notifFrame,
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 4, 1, -10),
        Position = UDim2.new(0, 5, 0, 5),
        ZIndex = 102
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 2)})
    })
    
    local notifTitle = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = notifFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -25, 0, 25),
        Position = UDim2.new(0, 15, 0, 5),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = color,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 102
    })
    
    local notifContent = Utility.Create("TextLabel", {
        Name = "Content",
        Parent = notifFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -25, 0, 40),
        Position = UDim2.new(0, 15, 0, 30),
        Font = Enum.Font.Gotham,
        Text = content,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        ZIndex = 102
    })
    
    -- Progress bar
    local progressBar = Utility.Create("Frame", {
        Name = "Progress",
        Parent = notifFrame,
        BackgroundColor3 = color,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 3),
        Position = UDim2.new(0, 0, 1, -3),
        ZIndex = 102
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(0, 2)})
    })
    
    -- Calculate height based on content
    local textService = game:GetService("TextService")
    local textSize = textService:GetTextSize(content, 12, Enum.Font.Gotham, Vector2.new(275, math.huge))
    local height = math.max(75, textSize.Y + 45)
    
    notifContent.Size = UDim2.new(1, -25, 0, textSize.Y + 10)
    
    -- Animate in
    Utility.PlaySound(Sounds.Open, 0.3)
    Utility.Tween(notifFrame, {Size = UDim2.new(1, 0, 0, height)}, 0.3, Enum.EasingStyle.Back)
    
    -- Progress animation
    Utility.Tween(progressBar, {Size = UDim2.new(0, 0, 0, 3)}, duration, Enum.EasingStyle.Linear)
    
    -- Auto close
    task.delay(duration, function()
        Utility.Tween(notifFrame, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, 0.3)
        task.wait(0.3)
        notifFrame:Destroy()
    end)
    
    return notifFrame
end

-- Mobile Toggle Button
if IsMobile then
    local mobileToggle = Utility.Create("TextButton", {
        Name = "MobileToggle",
        Parent = game:GetService("CoreGui"),
        BackgroundColor3 = QuantumUI.ThemeColor,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(0, 10, 0.5, 0),
        Font = Enum.Font.GothamBold,
        Text = "Q",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 24,
        ZIndex = 999
    }, {
        Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0)}),
        Utility.Create("UIStroke", {
            Color = Color3.fromRGB(255, 255, 255),
            Thickness = 2,
            Transparency = 0.5
        })
    })
    
    -- Make draggable
    local dragging = false
    local dragStart, startPos
    
    mobileToggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mobileToggle.Position
        end
    end)
    
    mobileToggle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            mobileToggle.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    QuantumUI.MobileToggle = mobileToggle
end

-- Return the library
return QuantumUI
